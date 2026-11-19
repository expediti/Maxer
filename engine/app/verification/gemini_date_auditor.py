"""
REXAM POST-SCRAPE GEMINI DATE AUDIT & REMEDIATION ENGINE
Module: engine/app/verification/gemini_date_auditor.py

Operates as a post-scrape audit layer directly on opportunity records in Supabase.
Reads scraped opportunity data (examinations and examination_dates), uses the official
Google GenAI SDK (Gemini 2.5 Flash via GEMINI_API_KEY) with structured Pydantic schema
enforcement, evaluates existing dates against official notifications, gazette calendars,
and source texts, and modifies / overwrites ONLY the date fields in Supabase.

CRITICAL INVARIANTS:
1. PRESERVE OPPORTUNITIES: Never delete, drop, or invalidate an examination record.
   Every job profile, eligibility requirement, vacancy count, and link is preserved.
2. DATES-ONLY OVERWRITE: Modifies and updates ONLY date fields:
   - In public.examinations: application_open_date, application_close_date,
     examination_date, application_status, last_verified_at, field_evidence_summary.
   - In public.examination_dates: application_opening_date, application_closing_date,
     examination_start_date, prelims_date, admit_card_release_date, result_date.
3. ZERO-HALLUCINATION: If dates are unannounced or tentative, sets dates to NULL
   and updates application_status to 'awaiting_notification'.
4. DETERMINISTIC GUARDRAILS: Enforces ISO format and chronological consistency
   (application_close_date >= application_open_date).
"""

import os
import re
import json
import logging
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional, Tuple
from urllib.parse import urlparse

from pydantic import BaseModel, Field

from engine.app.config.settings import settings
from engine.app.database.supabase_client import db_client
from engine.app.verification.date_validator import date_validator
from engine.app.verification.audit_and_repair_dates import VERIFIED_STATUTORY_SCHEDULES

logger = logging.getLogger("rexam.gemini_date_auditor")


# =============================================================================
# 1. STRUCTURED OUTPUT SCHEMA FOR GEMINI DATE AUDIT
# =============================================================================

class DateAuditResult(BaseModel):
    """
    Pydantic schema enforcing structured zero-hallucination date verification from Gemini.
    """
    is_date_correct: bool = Field(
        ...,
        description="True if the existing date in Supabase matches the official calendar/notification; False if dates need correction, are missing, or are synthetic."
    )
    application_open_date: Optional[str] = Field(
        default=None,
        description="Verified opening date in YYYY-MM-DD ISO format. If unannounced or tentative, set to null."
    )
    application_close_date: Optional[str] = Field(
        default=None,
        description="Verified closing deadline in YYYY-MM-DD ISO format. If unannounced or tentative, set to null."
    )
    examination_date: Optional[str] = Field(
        default=None,
        description="Verified preliminary/commencement examination date in YYYY-MM-DD. If unannounced or tentative, set to null."
    )
    admit_card_date: Optional[str] = Field(
        default=None,
        description="Verified admit card / hall ticket release date in YYYY-MM-DD. If unannounced, set to null."
    )
    result_date: Optional[str] = Field(
        default=None,
        description="Verified result declaration date in YYYY-MM-DD. If unannounced, set to null."
    )
    evidence_quote: Optional[str] = Field(
        default=None,
        description="Exact verbatim excerpt from official schedule, gazette notice, or calendar proving the dates."
    )
    status_reasoning: str = Field(
        ...,
        description="Concise technical reasoning: e.g. 'Dates confirmed via official UPSC 2026 calendar', 'Overwrote synthetic date cluster with official schedule', or 'Dates not yet announced by commission'."
    )


# =============================================================================
# 2. DETERMINISTIC GUARDRAILS FOR DATE INTEGRITY
# =============================================================================

def validate_iso_date_str(date_str: Optional[str]) -> Tuple[bool, Optional[str]]:
    """
    Validates and normalizes date string to YYYY-MM-DD format.
    Accepts ISO timestamps or YYYY-MM-DD and extracts YYYY-MM-DD.
    """
    if not date_str or str(date_str).strip() in ("", "None", "null"):
        return True, None
    s = str(date_str).strip()
    # Extract YYYY-MM-DD portion
    m = re.match(r"^(\d{4}-\d{2}-\d{2})", s)
    if not m:
        return False, None
    iso_date = m.group(1)
    try:
        dt = datetime.strptime(iso_date, "%Y-%m-%d")
        if dt.year < 2024 or dt.year > 2032:
            return False, None
        return True, iso_date
    except ValueError:
        return False, None


def apply_deterministic_date_guardrails(
    audit: DateAuditResult,
    title: str
) -> Tuple[DateAuditResult, List[str]]:
    """
    Ensures dates satisfy chronological sanity:
    1. application_close_date >= application_open_date
    2. examination_date >= application_open_date
    If contradictory dates exist, corrupt field is set to None rather than rejecting the record.
    """
    issues: List[str] = []

    # Format checks
    _, open_norm = validate_iso_date_str(audit.application_open_date)
    _, close_norm = validate_iso_date_str(audit.application_close_date)
    _, exam_norm = validate_iso_date_str(audit.examination_date)
    _, admit_norm = validate_iso_date_str(audit.admit_card_date)
    _, result_norm = validate_iso_date_str(audit.result_date)

    audit.application_open_date = open_norm
    audit.application_close_date = close_norm
    audit.examination_date = exam_norm
    audit.admit_card_date = admit_norm
    audit.result_date = result_norm

    # Chronology checks
    if audit.application_open_date and audit.application_close_date:
        if audit.application_close_date < audit.application_open_date:
            issues.append(
                f"Closing date ({audit.application_close_date}) precedes opening date ({audit.application_open_date}). Omitted conflicting closing date."
            )
            audit.application_close_date = None

    if audit.application_open_date and audit.examination_date:
        if audit.examination_date < audit.application_open_date:
            issues.append(
                f"Exam date ({audit.examination_date}) precedes opening date ({audit.application_open_date}). Omitted conflicting exam date."
            )
            audit.examination_date = None

    return audit, issues


def compute_application_lifecycle_status(
    open_date: Optional[str],
    close_date: Optional[str],
    now: Optional[datetime] = None
) -> str:
    """
    Computes candidate-facing lifecycle status from verified dates.
    Possible statuses: 'open', 'upcoming', 'closed', 'awaiting_notification'.
    """
    if now is None:
        now = datetime.now(timezone.utc)
    today = now.date().isoformat()

    if not open_date and not close_date:
        return "awaiting_notification"

    if close_date and close_date < today:
        return "closed"

    if open_date and open_date > today:
        return "upcoming"

    if open_date and close_date and open_date <= today <= close_date:
        return "open"

    if close_date and close_date >= today:
        return "open"

    return "awaiting_notification"


# =============================================================================
# 3. GEMINI 2.5 FLASH PROMPT & CLIENT
# =============================================================================

def get_gemini_client() -> Optional[Any]:
    """
    Initializes the official google-genai Client using GEMINI_API_KEY.
    """
    api_key = settings.GEMINI_API_KEY or os.environ.get("GEMINI_API_KEY", "")
    if not api_key:
        return None
    try:
        from google import genai
        return genai.Client(api_key=api_key)
    except Exception as e:
        logger.warning(f"Could not initialize Google GenAI SDK client: {e}")
        return None


GEMINI_DATE_AUDIT_PROMPT = """
You are Rexam's Senior Date Verification and Statutory Calendar Auditor for Indian examinations, admissions, and recruitments.
Your task is to inspect an existing opportunity record already scraped into Supabase and verify/correct ONLY its schedule dates.

MANDATORY RULES:
1. VERIFY AND OVERWRITE DATES ONLY: Evaluate the existing dates in the database against the provided official notification snippet, source URLs, and official statutory calendar.
2. ACCURACY DECISION:
   - If the existing dates are already correct according to the official schedule: set is_date_correct = true, keep the confirmed dates, and supply the verbatim evidence quote.
   - If the dates in the database are missing, incorrect, synthetic, or contradictory: set is_date_correct = false, and provide the correct verified dates with an exact evidence quote.
   - If the official notification has not yet been issued or dates are tentative/unannounced ('to be declared later', 'will be notified in due course'): set dates to null, and explain in status_reasoning.
3. ZERO HALLUCINATION: Extract dates ONLY from explicit calendar dates in the text or verified commission schedules. Never guess or fabricate dates.
4. FORMAT: Format all dates strictly as YYYY-MM-DD.
"""


# =============================================================================
# 4. GEMINI DATE AUDITOR CLASS
# =============================================================================

class GeminiDateAuditor:
    """
    Direct Supabase date auditor that reads scraped opportunity records,
    calls Gemini 2.5 Flash to verify and correct dates, and updates ONLY
    the date columns in Supabase.
    """

    def __init__(self, client: Optional[Any] = None):
        self.gemini_client = client or get_gemini_client()

    def audit_single_opportunity(
        self,
        exam: Dict[str, Any],
        dates_record: Optional[Dict[str, Any]] = None
    ) -> Tuple[DateAuditResult, List[str]]:
        """
        Audits dates for a single examination record using Gemini 2.5 Flash
        with fallback to verified statutory calendar and deterministic heuristics.
        """
        title = exam.get("title") or exam.get("name") or "Opportunity"
        slug = exam.get("slug") or ""
        curr_open = exam.get("application_open_date") or (dates_record or {}).get("application_opening_date")
        curr_close = exam.get("application_close_date") or (dates_record or {}).get("application_closing_date")
        curr_exam = exam.get("examination_date") or (dates_record or {}).get("examination_start_date") or (dates_record or {}).get("prelims_date")
        curr_status = exam.get("application_status") or "awaiting_notification"
        overview = exam.get("overview") or ""
        official_url = exam.get("official_notification_url") or exam.get("source_url") or ""

        # Check if benchmark statutory schedule is registered
        statutory_entry = VERIFIED_STATUTORY_SCHEDULES.get(slug)

        # Build prompt context
        context_payload = {
            "opportunity_title": title,
            "opportunity_slug": slug,
            "current_database_dates": {
                "application_open_date": str(curr_open) if curr_open else None,
                "application_close_date": str(curr_close) if curr_close else None,
                "examination_date": str(curr_exam) if curr_exam else None,
                "application_status": curr_status,
            },
            "official_source_url": official_url,
            "overview_snippet": overview[:1500] if overview else "",
        }

        if statutory_entry:
            context_payload["official_commission_calendar"] = {
                "doc_title": statutory_entry.get("doc_title"),
                "notification_date": statutory_entry.get("notification_date"),
                "application_start_date": statutory_entry.get("application_start_date"),
                "application_end_date": statutory_entry.get("application_end_date"),
                "exam_start_date": statutory_entry.get("exam_start_date"),
                "quote": statutory_entry.get("quote"),
            }

        # If Gemini client is available, run live GenAI verification
        if self.gemini_client:
            try:
                from google.genai import types

                prompt = (
                    f"{GEMINI_DATE_AUDIT_PROMPT}\n\n"
                    f"OPPORTUNITY DATA FROM SUPABASE:\n"
                    f"{json.dumps(context_payload, indent=2)}\n"
                )

                response = self.gemini_client.models.generate_content(
                    model=settings.GEMINI_MODEL or "gemini-2.5-flash",
                    contents=prompt,
                    config=types.GenerateContentConfig(
                        response_mime_type="application/json",
                        response_schema=DateAuditResult,
                        temperature=0.0,
                    ),
                )

                if response and response.text:
                    audit_res = DateAuditResult.model_validate_json(response.text)
                    audit_res, guardrail_issues = apply_deterministic_date_guardrails(audit_res, title)
                    return audit_res, guardrail_issues
            except Exception as e:
                logger.warning(f"Gemini API call failed on {title} ({e}). Falling back to deterministic audit.")

        # Offline / Deterministic Fallback Mode
        return self._deterministic_date_audit(title, slug, curr_open, curr_close, curr_exam, statutory_entry, overview)

    def _deterministic_date_audit(
        self,
        title: str,
        slug: str,
        curr_open: Any,
        curr_close: Any,
        curr_exam: Any,
        statutory_entry: Optional[Dict[str, Any]],
        overview: str
    ) -> Tuple[DateAuditResult, List[str]]:
        """
        Deterministic fallback when GEMINI_API_KEY is not configured or network call fails.
        """
        # If registered in statutory benchmark calendar
        if statutory_entry:
            _, s_open = validate_iso_date_str(statutory_entry.get("application_start_date"))
            _, s_close = validate_iso_date_str(statutory_entry.get("application_end_date"))
            _, s_exam = validate_iso_date_str(statutory_entry.get("exam_start_date"))
            _, s_admit = validate_iso_date_str(statutory_entry.get("admit_card_date"))
            _, s_result = validate_iso_date_str(statutory_entry.get("result_date"))

            # Check if current DB matches statutory
            _, cur_o_norm = validate_iso_date_str(curr_open)
            _, cur_c_norm = validate_iso_date_str(curr_close)
            _, cur_e_norm = validate_iso_date_str(curr_exam)

            is_correct = (cur_o_norm == s_open and cur_c_norm == s_close and cur_e_norm == s_exam)

            res = DateAuditResult(
                is_date_correct=is_correct,
                application_open_date=s_open,
                application_close_date=s_close,
                examination_date=s_exam,
                admit_card_date=s_admit,
                result_date=s_result,
                evidence_quote=statutory_entry.get("quote"),
                status_reasoning=f"Dates aligned with official statutory schedule ({statutory_entry.get('doc_title')}).",
            )
            return apply_deterministic_date_guardrails(res, title)

        # Check for synthetic timestamps (.220834 / ISO subseconds)
        is_synthetic = bool(curr_open and "." in str(curr_open)) or bool(curr_close and "." in str(curr_close))
        if is_synthetic:
            res = DateAuditResult(
                is_date_correct=False,
                application_open_date=None,
                application_close_date=None,
                examination_date=None,
                admit_card_date=None,
                result_date=None,
                evidence_quote=None,
                status_reasoning="Overwrote unverified synthetic date cluster with NULL pending official notice.",
            )
            return res, ["Synthetic dates cleansed to NULL"]

        # Validate existing dates with DateValidator
        _, o_norm = validate_iso_date_str(curr_open)
        _, c_norm = validate_iso_date_str(curr_close)
        _, e_norm = validate_iso_date_str(curr_exam)

        res = DateAuditResult(
            is_date_correct=True,
            application_open_date=o_norm,
            application_close_date=c_norm,
            examination_date=e_norm,
            admit_card_date=None,
            result_date=None,
            evidence_quote=None,
            status_reasoning="Preserved valid existing dates or marked awaiting notification.",
        )
        return apply_deterministic_date_guardrails(res, title)

    def apply_date_audit_to_supabase(
        self,
        exam_id: str,
        slug: str,
        audit: DateAuditResult,
        dry_run: bool = False
    ) -> Dict[str, Any]:
        """
        Modifies and overwrites ONLY the date fields in Supabase:
        - examinations (application_open_date, application_close_date, examination_date, application_status, last_verified_at, field_evidence_summary)
        - examination_dates (application_opening_date, application_closing_date, examination_start_date, prelims_date, admit_card_release_date, result_date)
        Leaves all other fields completely untouched.
        """
        now = datetime.now(timezone.utc)
        now_iso = now.isoformat()

        # Compute dynamic lifecycle status
        lifecycle_status = compute_application_lifecycle_status(
            audit.application_open_date,
            audit.application_close_date,
            now=now
        )

        evidence_payload = {
            "date_audit_method": "gemini_2_5_flash_post_scrape_audit" if self.gemini_client else "deterministic_statutory_audit",
            "audited_at": now_iso,
            "status_reasoning": audit.status_reasoning,
            "verbatim_evidence_quote": audit.evidence_quote,
            "dates_confirmed": audit.is_date_correct,
        }

        exam_updates = {
            "application_open_date": audit.application_open_date,
            "application_close_date": audit.application_close_date,
            "examination_date": audit.examination_date,
            "application_status": lifecycle_status,
            "last_verified_at": now_iso,
            "field_evidence_summary": {"date_audit": evidence_payload},
        }

        dates_table_payload = {
            "application_opening_date": audit.application_open_date,
            "application_closing_date": audit.application_close_date,
            "examination_start_date": audit.examination_date,
            "prelims_date": audit.examination_date,
            "admit_card_release_date": audit.admit_card_date,
            "result_date": audit.result_date,
            "is_tentative": bool(audit.application_open_date is None and audit.application_close_date is None),
        }

        if dry_run or not db_client.is_connected or not db_client.client:
            logger.info(f"[Dry Run] Would update dates for {slug} -> open={audit.application_open_date}, close={audit.application_close_date}, exam={audit.examination_date}, status={lifecycle_status}")
            return {
                "exam_id": exam_id,
                "slug": slug,
                "status": "dry_run",
                "exam_updates": exam_updates,
                "dates_updates": dates_table_payload
            }

        try:
            # 1. Update ONLY date fields in examinations
            db_client.client.table("examinations").update(exam_updates).eq("id", exam_id).execute()

            # 2. Update date fields in examination_dates
            db_client.upsert_examination_dates(exam_id, dates_table_payload)

            logger.info(f"[DATE OVERWRITE] {slug}: open={audit.application_open_date}, close={audit.application_close_date}, exam={audit.examination_date}, lifecycle={lifecycle_status}")
            return {
                "exam_id": exam_id,
                "slug": slug,
                "status": "updated",
                "lifecycle_status": lifecycle_status,
                "open_date": audit.application_open_date,
                "close_date": audit.application_close_date,
                "exam_date": audit.examination_date,
            }
        except Exception as e:
            logger.error(f"Error updating Supabase dates for {slug}: {e}")
            return {"exam_id": exam_id, "slug": slug, "status": "error", "error": str(e)}

    def audit_all_opportunities(
        self,
        limit: Optional[int] = None,
        dry_run: bool = False
    ) -> Dict[str, Any]:
        """
        Iterates over all published opportunities in Supabase, checks dates via Gemini 2.5 Flash,
        and overwrites only the corrected date fields.
        """
        logger.info("================================================================================")
        logger.info("REXAM POST-SCRAPE GEMINI DATE AUDIT & REMEDIATION PIPELINE")
        logger.info(f"Model: {settings.GEMINI_MODEL or 'gemini-2.5-flash'} | Live Client: {bool(self.gemini_client)}")
        logger.info(f"Mode: {'DRY RUN' if dry_run else 'LIVE DATABASE OVERWRITE'}")
        logger.info("================================================================================")

        if not db_client.is_connected or not db_client.client:
            logger.error("DatabaseClient is not connected. Cannot read or write Supabase.")
            return {"error": "Database not connected"}

        # Fetch opportunities from Supabase
        query = db_client.client.table("examinations").select(
            "id, slug, title, name, category, status, application_status, overview, "
            "source_url, official_notification_url, application_open_date, "
            "application_close_date, examination_date"
        ).eq("status", "published")

        if limit and limit > 0:
            query = query.limit(limit)

        res = query.execute()
        records = res.data or []
        logger.info(f"Fetched {len(records)} published opportunities from Supabase for date audit.")

        metrics = {
            "total_audited": len(records),
            "dates_confirmed": 0,
            "dates_corrected": 0,
            "dates_set_to_awaiting": 0,
            "errors": 0,
            "results": [],
        }

        for idx, exam in enumerate(records, 1):
            exam_id = exam["id"]
            slug = exam.get("slug") or ""
            title = exam.get("title") or exam.get("name") or slug

            # Fetch linked examination_dates record if present
            d_res = db_client.client.table("examination_dates").select("*").eq("examination_id", exam_id).execute()
            dates_rec = d_res.data[0] if d_res.data else None

            logger.info(f"[{idx}/{len(records)}] Auditing dates for: {title} ({slug})...")

            # Execute Gemini Date Audit
            audit_result, issues = self.audit_single_opportunity(exam, dates_rec)

            if issues:
                logger.warning(f"Guardrail notices on {slug}: {issues}")

            # Apply date overwrite in Supabase
            update_res = self.apply_date_audit_to_supabase(exam_id, slug, audit_result, dry_run=dry_run)

            if audit_result.is_date_correct:
                metrics["dates_confirmed"] += 1
            elif audit_result.application_open_date or audit_result.application_close_date:
                metrics["dates_corrected"] += 1
            else:
                metrics["dates_set_to_awaiting"] += 1

            metrics["results"].append({
                "slug": slug,
                "title": title,
                "is_correct": audit_result.is_date_correct,
                "open_date": audit_result.application_open_date,
                "close_date": audit_result.application_close_date,
                "exam_date": audit_result.examination_date,
                "reasoning": audit_result.status_reasoning,
            })

        logger.info("================================================================================")
        logger.info(f"Date Audit Complete: {metrics['dates_confirmed']} confirmed, {metrics['dates_corrected']} corrected, {metrics['dates_set_to_awaiting']} awaiting notification.")
        logger.info("================================================================================")
        return metrics


# Module singleton
gemini_date_auditor = GeminiDateAuditor()
