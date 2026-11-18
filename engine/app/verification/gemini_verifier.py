"""
REXAM GEMINI 2.5 FLASH VERIFIER & DETERMINISTIC GUARDRAILS ENGINE
Module: engine/app/verification/gemini_verifier.py

Accepts raw scraped notice text/HTML/PDF contents and source URLs,
uses the official Google GenAI SDK (from google import genai) with Gemini 2.5 Flash
and structured JSON schema enforcement (Pydantic), executes strict deterministic
guardrails (chronological coherence, verbatim substring evidence verification,
URL validation), and stages verified opportunity records before reflecting to users.
"""

import os
import re
import logging
from datetime import datetime, timezone
from typing import Optional, Dict, Any, List, Tuple
from urllib.parse import urlparse

from pydantic import BaseModel, Field

from engine.app.config.settings import settings
from engine.app.discovery.url_normalizer import slugify

logger = logging.getLogger("rexam.gemini_verifier")


# =============================================================================
# 1. PYDANTIC STRUCTURED OUTPUT SCHEMAS
# =============================================================================

class DateWithEvidence(BaseModel):
    """
    Structured date field coupled with immutable verbatim evidence from source text.
    """
    date: Optional[str] = Field(
        default=None,
        description="Normalized date in YYYY-MM-DD ISO 8601 format. If date is absent or tentative/unknown, set to null."
    )
    evidence_snippet: Optional[str] = Field(
        default=None,
        description="Exact verbatim quotation extracted directly from the source text mentioning this date. Must match source text word-for-word."
    )


class OpportunityExtracted(BaseModel):
    """
    Comprehensive structured extraction schema for Indian examinations, scholarships,
    internships, apprenticeships, and recruitments.
    """
    title: str = Field(
        ...,
        description="Official title or standard name of the examination, scholarship, or recruitment opportunity."
    )
    organisation_name: str = Field(
        ...,
        description="Official name of conducting agency or recruiting organization (e.g. UPSC, SSC, ISRO, DRDO)."
    )
    opportunity_type: Optional[str] = Field(
        default="recruitment_examination",
        description="One of: recruitment_examination, scholarship, internship, apprenticeship, admission_entrance, private_job."
    )
    notification_date: Optional[DateWithEvidence] = Field(
        default=None,
        description="Date when the official gazette/notification was published with verbatim evidence snippet."
    )
    start_date: Optional[DateWithEvidence] = Field(
        default=None,
        description="Online application commencement / opening date with verbatim evidence snippet."
    )
    closing_date: Optional[DateWithEvidence] = Field(
        default=None,
        description="Online application submission deadline / closing date with verbatim evidence snippet."
    )
    correction_start_date: Optional[DateWithEvidence] = Field(
        default=None,
        description="Application correction window opening date with verbatim evidence snippet."
    )
    correction_end_date: Optional[DateWithEvidence] = Field(
        default=None,
        description="Application correction window closing date with verbatim evidence snippet."
    )
    admit_card_date: Optional[DateWithEvidence] = Field(
        default=None,
        description="Release date for admit card / hall ticket with verbatim evidence snippet."
    )
    exam_date: Optional[DateWithEvidence] = Field(
        default=None,
        description="Date of examination / prelims commencement with verbatim evidence snippet."
    )
    exam_end_date: Optional[DateWithEvidence] = Field(
        default=None,
        description="Concluding date of multi-day examination with verbatim evidence snippet."
    )
    result_date: Optional[DateWithEvidence] = Field(
        default=None,
        description="Expected or declared result publication date with verbatim evidence snippet."
    )
    application_url: Optional[str] = Field(
        default=None,
        description="Official portal link to apply online."
    )
    official_notification_url: Optional[str] = Field(
        default=None,
        description="Direct URL to official advertisement / notification PDF or page."
    )
    vacancies: Optional[int] = Field(
        default=None,
        description="Total number of vacancies advertised (integer count)."
    )
    salary_or_stipend: Optional[str] = Field(
        default=None,
        description="Pay scale, CTC, basic pay, or monthly stipend amount."
    )
    fee_details: Optional[str] = Field(
        default=None,
        description="Application fee amounts and categories exempted from fee payment."
    )
    eligibility_summary: Optional[str] = Field(
        default=None,
        description="Summary of required educational qualification, degree, and age limits."
    )
    minimum_age: Optional[int] = Field(
        default=None,
        description="Minimum eligible age as on cutoff date."
    )
    maximum_age: Optional[int] = Field(
        default=None,
        description="Maximum eligible general category age as on cutoff date."
    )
    educational_qualifications: Optional[List[str]] = Field(
        default=None,
        description="List of acceptable educational qualifications."
    )
    eligible_streams: Optional[List[str]] = Field(
        default=None,
        description="List of eligible engineering or academic disciplines / streams."
    )


# =============================================================================
# 2. DETERMINISTIC GUARDRAILS
# =============================================================================

def normalize_text_for_comparison(text: str) -> str:
    """
    Normalizes whitespace, linebreaks, and unicode quotation marks for reliable
    verbatim substring searching.
    """
    if not text:
        return ""
    text = text.lower()
    # Normalize common Unicode dashes and quotes
    text = re.sub(r'[\u2010\u2012\u2013\u2014\u2015\u2212]', '-', text)
    text = re.sub(r'[\u2018\u2019\u201a\u201b]', "'", text)
    text = re.sub(r'[\u201c\u201d\u201e\u201f]', '"', text)
    text = re.sub(r'[\r\n\t]+', ' ', text)
    text = re.sub(r'\s+', ' ', text)
    return text.strip()


def validate_iso_date(date_str: Optional[str]) -> Tuple[bool, Optional[datetime]]:
    """
    Validates that a date string matches YYYY-MM-DD and is a real calendar date
    within reasonable operational bounds (2024 to 2032).
    """
    if not date_str:
        return True, None
    try:
        dt = datetime.strptime(date_str, "%Y-%m-%d")
        if dt.year < 2024 or dt.year > 2032:
            return False, dt
        return True, dt
    except ValueError:
        return False, None


def validate_deterministic_guardrails(
    extracted: OpportunityExtracted,
    raw_text: str,
    source_url: str
) -> Tuple[List[str], bool, Dict[str, Any]]:
    """
    Executes rigorous deterministic verification checks:
    1. Temporal Order: closing_date strictly >= start_date, exam_date >= start_date, etc.
    2. Evidence Verbatim Substring: Every date's evidence_snippet MUST exist verbatim in raw_text.
    3. URL Validity: Application URL must have valid scheme and network location.
    4. Date Sanity: Valid YYYY-MM-DD formats within operating timeline.
    5. Age Constraints: min_age <= max_age.

    Returns:
        (validation_errors, is_verified, cleaned_dict)
    """
    errors: List[str] = []
    normalized_source = normalize_text_for_comparison(raw_text)

    date_fields = [
        ("notification_date", extracted.notification_date),
        ("start_date", extracted.start_date),
        ("closing_date", extracted.closing_date),
        ("correction_start_date", extracted.correction_start_date),
        ("correction_end_date", extracted.correction_end_date),
        ("admit_card_date", extracted.admit_card_date),
        ("exam_date", extracted.exam_date),
        ("exam_end_date", extracted.exam_end_date),
        ("result_date", extracted.result_date),
    ]

    parsed_dates: Dict[str, Optional[datetime]] = {}
    cleaned_date_evidence: Dict[str, Any] = {}

    # Check 1: Format & Verbatim Substring Evidence for each date field
    for field_name, d_obj in date_fields:
        if not d_obj:
            parsed_dates[field_name] = None
            continue

        raw_val = d_obj.date
        snippet = d_obj.evidence_snippet

        # If date is supplied
        if raw_val:
            is_valid_fmt, dt = validate_iso_date(raw_val)
            if not is_valid_fmt or not dt:
                errors.append(f"Invalid date format or out-of-range year for '{field_name}': '{raw_val}' (must be YYYY-MM-DD)")
                parsed_dates[field_name] = None
            else:
                parsed_dates[field_name] = dt

            # Verify evidence snippet is present
            if not snippet or not snippet.strip():
                errors.append(f"Missing verbatim evidence snippet for date field '{field_name}' ({raw_val})")
            else:
                norm_snip = normalize_text_for_comparison(snippet)
                if norm_snip not in normalized_source:
                    errors.append(
                        f"Evidence snippet for '{field_name}' not found verbatim in source text: '{snippet[:80]}...'"
                    )
                else:
                    cleaned_date_evidence[field_name] = {
                        "date": raw_val,
                        "evidence_snippet": snippet.strip(),
                        "verified_substring": True
                    }
        elif snippet:
            # Snippet provided without date - warn or record
            errors.append(f"Snippet provided for '{field_name}' but parsed date is null: '{snippet[:60]}'")

    # Check 2: Chronological / Temporal Order
    dt_start = parsed_dates.get("start_date")
    dt_closing = parsed_dates.get("closing_date")
    dt_exam = parsed_dates.get("exam_date")
    dt_exam_end = parsed_dates.get("exam_end_date")
    dt_corr_start = parsed_dates.get("correction_start_date")
    dt_corr_end = parsed_dates.get("correction_end_date")

    # Closing date strictly after or equal to start date
    if dt_start and dt_closing:
        if dt_closing < dt_start:
            errors.append(
                f"Closing date ({extracted.closing_date.date}) cannot be strictly before start date ({extracted.start_date.date})"
            )

    # Exam date after or equal to start date
    if dt_start and dt_exam:
        if dt_exam < dt_start:
            errors.append(
                f"Exam date ({extracted.exam_date.date}) cannot occur before application start date ({extracted.start_date.date})"
            )

    # Multi-day exam order
    if dt_exam and dt_exam_end:
        if dt_exam_end < dt_exam:
            errors.append(
                f"Exam end date ({extracted.exam_end_date.date}) cannot be before exam start date ({extracted.exam_date.date})"
            )

    # Correction window order
    if dt_corr_start and dt_corr_end:
        if dt_corr_end < dt_corr_start:
            errors.append(
                f"Correction window end ({extracted.correction_end_date.date}) cannot be before correction window start ({extracted.correction_start_date.date})"
            )

    # Check 3: Application URL validation
    app_url = extracted.application_url
    if app_url:
        parsed_url = urlparse(app_url)
        if parsed_url.scheme not in ("http", "https") or not parsed_url.netloc:
            errors.append(f"Invalid application URL format: '{app_url}' (must be valid HTTP/HTTPS)")

    # Check 4: Age bounds
    min_a = extracted.minimum_age
    max_a = extracted.maximum_age
    if min_a is not None and max_a is not None:
        if min_a > max_a:
            errors.append(f"Minimum age ({min_a}) cannot be greater than maximum age ({max_a})")

    # Overall verification decision
    is_verified = len(errors) == 0

    cleaned_dict = extracted.model_dump()
    cleaned_dict["date_evidence"] = cleaned_date_evidence

    return errors, is_verified, cleaned_dict


# =============================================================================
# 3. GEMINI 2.5 FLASH STRUCTURED VERIFICATION
# =============================================================================

def get_genai_client() -> Optional[Any]:
    """
    Initializes the official google-genai Client using GEMINI_API_KEY.
    """
    api_key = settings.GEMINI_API_KEY or os.environ.get("GEMINI_API_KEY", "")
    if not api_key:
        logger.debug("GEMINI_API_KEY is not configured. Running in offline/deterministic mode.")
        return None

    try:
        from google import genai
        return genai.Client(api_key=api_key)
    except Exception as e:
        logger.warning(f"Could not initialize Google GenAI SDK client: {e}")
        return None


GEMINI_EXTRACTION_SYSTEM_PROMPT = """
You are the Rexam Senior Verification & Provenance Engine for Indian examinations, admissions, and recruitment opportunities.
Your mission is to perform zero-hallucination data extraction and date verification from official Indian government and agency source documents.

RULES OF ABSOLUTE INTEGRITY:
1. Every date extracted (notification_date, start_date, closing_date, correction dates, admit_card_date, exam_date, result_date) MUST be paired with an exact, verbatim 'evidence_snippet' from the source text.
2. The 'evidence_snippet' MUST be a word-for-word quote from the text provided. Do NOT rephrase, summarize, or edit the snippet.
3. Normalize all confirmed dates to standard ISO 8601 'YYYY-MM-DD'.
4. If a date is not explicitly mentioned in the text, or if it says 'To be notified later', leave the date and evidence_snippet as null.
5. Identify the exact application URL and official notification link if present.
6. Extract vacancies as an integer count, or null if unspecified.
7. Capture eligibility criteria, minimum/maximum age limits, and pay scale accurately.
"""


async def verify_and_clean_opportunity(
    raw_text: str,
    source_url: str,
    context: Optional[Dict[str, Any]] = None,
    client: Optional[Any] = None,
) -> Tuple[Optional[OpportunityExtracted], List[str], bool, Dict[str, Any]]:
    """
    Calls Gemini 2.5 Flash with structured Pydantic schema to extract and verify
    opportunity information, then passes it through deterministic guardrails.

    Returns:
        (extracted_model, validation_errors, is_verified, clean_payload)
    """
    if client is None:
        client = get_genai_client()

    context = context or {}
    source_name = context.get("organisation_name") or context.get("title") or "Indian Opportunity Authority"

    # Context window truncation (safely preserve up to 32,000 characters)
    clipped_text = raw_text[:32000] if raw_text else ""

    if not client:
        # Graceful dry-run fallback when GEMINI_API_KEY is not supplied
        logger.info(f"[Offline/Fallback] Processing {source_name} without live Gemini API.")
        fallback = OpportunityExtracted(
            title=context.get("title") or "Opportunity Notice",
            organisation_name=source_name,
            application_url=context.get("application_url") or source_url,
            official_notification_url=context.get("pdf_url") or source_url,
        )
        errors, is_v, clean = validate_deterministic_guardrails(fallback, clipped_text, source_url)
        return fallback, errors, is_v, clean

    try:
        from google.genai import types

        prompt = (
            f"{GEMINI_EXTRACTION_SYSTEM_PROMPT}\n\n"
            f"SOURCE URL: {source_url}\n"
            f"KNOWN CONTEXT: {context}\n\n"
            f"--- SOURCE DOCUMENT / WEBPAGE TEXT ---\n"
            f"{clipped_text}\n"
            f"--- END SOURCE DOCUMENT ---"
        )

        response = client.models.generate_content(
            model=settings.GEMINI_MODEL or "gemini-2.5-flash",
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=OpportunityExtracted,
                temperature=0.0,
            ),
        )

        if not response or not response.text:
            return None, ["Gemini model returned empty response"], False, {}

        extracted: OpportunityExtracted = OpportunityExtracted.model_validate_json(response.text)
        errors, is_verified, clean_dict = validate_deterministic_guardrails(extracted, clipped_text, source_url)

        return extracted, errors, is_verified, clean_dict

    except Exception as e:
        logger.error(f"Error during Gemini verification: {e}")
        return None, [f"Gemini verification error: {str(e)}"], False, {}


# =============================================================================
# 4. STAGING TABLE UPSERT & PIPELINE INTEGRATION
# =============================================================================

def stage_and_verify_opportunity(
    db: Any,
    extracted: Optional[OpportunityExtracted],
    validation_errors: List[str],
    is_verified: bool,
    raw_text: str,
    source_url: str,
    source_id: Optional[str] = None,
    organisation_id: Optional[str] = None,
    promote_if_valid: bool = True,
) -> Dict[str, Any]:
    """
    Writes the verified opportunity into public.staging_opportunities with full
    field-level provenance, date evidence, and validation audit errors.
    If promote_if_valid is True and record passed all deterministic guardrails,
    promotes the record to public.examinations so users see verified data.
    """
    if not extracted:
        return {"status": "failed", "reason": "No extracted data"}

    title = extracted.title.strip()
    slug = slugify(title)
    
    # Collect date evidence mapping
    date_evidence_map = {}
    for f_name in ["notification_date", "start_date", "closing_date", "correction_start_date",
                   "correction_end_date", "admit_card_date", "exam_date", "exam_end_date", "result_date"]:
        val = getattr(extracted, f_name, None)
        if val and (val.date or val.evidence_snippet):
            date_evidence_map[f_name] = {
                "date": val.date,
                "evidence_snippet": val.evidence_snippet
            }

    verification_status = "VERIFIED" if is_verified else ("REJECTED" if any("strictly before" in e for e in validation_errors) else "NEEDS_REVIEW")

    staging_payload = {
        "slug": slug,
        "source_id": source_id,
        "organisation_id": organisation_id,
        "title": title,
        "organisation_name": extracted.organisation_name,
        "application_url": extracted.application_url or source_url,
        "official_notification_url": extracted.official_notification_url or source_url,
        "source_url": source_url,
        "raw_text_snippet": raw_text[:2000] if raw_text else "",
        "notification_date": extracted.notification_date.date if extracted.notification_date else None,
        "start_date": extracted.start_date.date if extracted.start_date else None,
        "closing_date": extracted.closing_date.date if extracted.closing_date else None,
        "correction_start_date": extracted.correction_start_date.date if extracted.correction_start_date else None,
        "correction_end_date": extracted.correction_end_date.date if extracted.correction_end_date else None,
        "admit_card_date": extracted.admit_card_date.date if extracted.admit_card_date else None,
        "exam_date": extracted.exam_date.date if extracted.exam_date else None,
        "exam_end_date": extracted.exam_end_date.date if extracted.exam_end_date else None,
        "result_date": extracted.result_date.date if extracted.result_date else None,
        "date_evidence": date_evidence_map,
        "extracted_data": extracted.model_dump(),
        "validation_errors": validation_errors,
        "is_verified": is_verified,
        "verification_status": verification_status,
        "promoted_to_production": False,
    }

    staging_id = db.upsert_staging_opportunity(staging_payload)
    result = {
        "staging_id": staging_id,
        "slug": slug,
        "is_verified": is_verified,
        "verification_status": verification_status,
        "validation_errors": validation_errors,
        "promoted_to_production": False,
        "production_id": None
    }

    if is_verified and promote_if_valid:
        prod_id = db.promote_staging_opportunity_to_production(staging_id or slug)
        if prod_id:
            result["promoted_to_production"] = True
            result["production_id"] = prod_id

    return result

