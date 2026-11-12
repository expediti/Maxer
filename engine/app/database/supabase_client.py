import logging
from typing import Optional, Dict, Any, List
from engine.app.config.settings import settings

logger = logging.getLogger("rexam.database")

class DatabaseClient:
    def __init__(self):
        self.is_connected = False
        self.client = None
        self._mock_processed_hashes: set[str] = set()

        if settings.SUPABASE_URL and not settings.SUPABASE_URL.startswith("https://demo-project"):
            try:
                from supabase import create_client, Client
                self.client: Optional[Client] = create_client(
                    settings.SUPABASE_URL,
                    settings.SUPABASE_SERVICE_ROLE_KEY
                )
                self.is_connected = True
                logger.info("Connected to Supabase PostgreSQL via Service Role.")
            except Exception as e:
                logger.warning(f"Could not connect to Supabase: {e}. Operating in dry-run mode.")
                self.client = None
        else:
            logger.info("Using dry-run / mock database mode (demo credentials).")

    def is_document_processed(self, sha256_hash: str) -> bool:
        if not self.is_connected or not self.client:
            return sha256_hash in self._mock_processed_hashes

        try:
            res = self.client.table("processed_documents").select("id").eq("sha256_hash", sha256_hash).execute()
            return len(res.data) > 0
        except Exception as e:
            logger.error(f"Error checking processed document: {e}")
            return False

    def record_processed_document(self, doc_data: Dict[str, Any]) -> None:
        sha256_hash = doc_data.get("sha256_hash", "")
        self._mock_processed_hashes.add(sha256_hash)

        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Recorded document {sha256_hash[:12]}...")
            return

        try:
            self.client.table("processed_documents").upsert(doc_data, on_conflict="sha256_hash").execute()
        except Exception as e:
            logger.error(f"Error saving processed document record: {e}")

    def upsert_organisation(self, org_data: Dict[str, Any]) -> Optional[str]:
        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Upsert organisation: {org_data.get('name')}")
            return org_data.get("id", "org-mock-id")

        try:
            conflict = "slug" if org_data.get("slug") else "name"
            res = self.client.table("organisations").upsert(org_data, on_conflict=conflict).execute()
            if res.data:
                return res.data[0]["id"]
        except Exception as e:
            logger.error(f"Error upserting organisation {org_data.get('name')}: {e}")
        return None

    def upsert_source(self, source_data: Dict[str, Any]) -> Optional[str]:
        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Upsert source: {source_data.get('base_url') or source_data.get('official_url') or source_data.get('url')}")
            return source_data.get("id", "source-mock-id")

        try:
            if "base_url" not in source_data and "official_url" in source_data:
                source_data["base_url"] = source_data["official_url"]
            elif "base_url" not in source_data and "url" in source_data:
                source_data["base_url"] = source_data["url"]
            res = self.client.table("sources").upsert(source_data, on_conflict="base_url").execute()
            if res.data:
                return res.data[0]["id"]
        except Exception as e:
            logger.error(f"Error upserting source {source_data.get('base_url')}: {e}")
        return None

    def get_examination_by_slug(self, slug: str) -> Optional[Dict[str, Any]]:
        if not self.is_connected or not self.client:
            return None
        try:
            res = self.client.table("examinations").select("*").eq("slug", slug).maybe_single().execute()
            return res.data if res else None
        except Exception as e:
            logger.error(f"Error fetching examination by slug {slug}: {e}")
            return None

    BASE_EXAMINATION_COLUMNS = {
        "slug", "name", "title", "category", "status", "overview", "vacancies",
        "salary_or_pay_scale", "location", "official_notification_url", "notification_url",
        "official_application_url", "application_url", "source_url", "last_verified_at",
        "last_crawled_at", "is_official_source", "is_confirmed", "is_central_government",
        "state", "selection_procedure", "exam_pattern", "application_instructions",
        "uncertain_fields", "organisation_id", "source_id", "application_status",
        "opportunity_type", "qualification_levels", "minimum_age", "maximum_age",
        "application_open_date", "application_close_date", "educational_eligibility",
        "required_disciplines", "verification_status", "advertisement_number", "requisition_id",
        "verification_tier", "is_application_url_verified", "application_url_status",
        "verified_application_url", "verified_notification_url", "field_evidence_summary"
    }

    def upsert_examination(self, exam_data: Dict[str, Any]) -> Optional[str]:
        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Upsert examination: {exam_data.get('title') or exam_data.get('name')}")
            return exam_data.get("id", "exam-mock-id")

        payload = dict(exam_data)
        if "name" not in payload and "title" in payload:
            payload["name"] = payload["title"]
        if "title" not in payload and "name" in payload:
            payload["title"] = payload["name"]

        try:
            res = self.client.table("examinations").upsert(payload, on_conflict="slug").execute()
            if res.data:
                return res.data[0]["id"]
        except Exception as e:
            err_msg = str(e)
            # If migration 20261110000001 has not yet been applied in Supabase dashboard,
            # gracefully fall back to baseline columns to ensure 100% uninterrupted operation
            if "column of 'examinations'" in err_msg or "PGRST204" in err_msg:
                try:
                    baseline_payload = {k: v for k, v in payload.items() if k in self.BASE_EXAMINATION_COLUMNS}
                    res = self.client.table("examinations").upsert(baseline_payload, on_conflict="slug").execute()
                    if res.data:
                        return res.data[0]["id"]
                except Exception as inner_e:
                    logger.error(f"Error upserting examination with baseline columns: {inner_e}")
            else:
                logger.error(f"Error upserting examination: {e}")
        return None

    def upsert_examination_dates(self, exam_id: str, dates_data: Dict[str, Any]) -> None:
        """
        Upserts structured dates into examination_dates ensuring separate,
        unmerged date columns and synchronization with examinations table.
        """
        # Clean & map to examination_dates schema
        payload = {
            "examination_id": exam_id,
            "notification_date": dates_data.get("notification_date"),
            "application_opening_date": (
                dates_data.get("application_start_date") or
                dates_data.get("application_opening_date") or
                dates_data.get("application_open_date")
            ),
            "application_closing_date": (
                dates_data.get("application_end_date") or
                dates_data.get("application_closing_date") or
                dates_data.get("application_close_date")
            ),
            "correction_window_start": (
                dates_data.get("correction_start_date") or
                dates_data.get("correction_window_start")
            ),
            "correction_window_end": (
                dates_data.get("correction_end_date") or
                dates_data.get("correction_window_end")
            ),
            "admit_card_release_date": (
                dates_data.get("admit_card_date") or
                dates_data.get("admit_card_release_date")
            ),
            "examination_start_date": (
                dates_data.get("exam_start_date") or
                dates_data.get("examination_start_date") or
                dates_data.get("examination_date") or
                dates_data.get("prelims_date")
            ),
            "examination_end_date": (
                dates_data.get("exam_end_date") or
                dates_data.get("examination_end_date")
            ),
            "result_date": dates_data.get("result_date"),
            "prelims_date": (
                dates_data.get("exam_start_date") or
                dates_data.get("prelims_date") or
                dates_data.get("examination_start_date")
            ),
            "fee_payment_deadline": dates_data.get("fee_payment_deadline"),
            "is_tentative": dates_data.get("is_tentative", False),
        }

        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Upsert examination dates for {exam_id}")
            return

        try:
            self.client.table("examination_dates").upsert(payload, on_conflict="examination_id").execute()
        except Exception as e:
            logger.error(f"Error upserting examination dates: {e}")

    def upsert_examination_cycle(self, exam_id: str, cycle_data: Dict[str, Any]) -> Optional[str]:
        """
        Maintains distinct examination cycles (e.g., GATE 2026 vs GATE 2027),
        preserving historical dates and multi-stage milestones.
        """
        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Upsert examination cycle {cycle_data.get('cycle_name')} for {exam_id}")
            return "cycle-mock-id"

        payload = {
            "examination_id": exam_id,
            "cycle_year": cycle_data.get("cycle_year") or 2026,
            "cycle_name": cycle_data.get("cycle_name") or f"Cycle {cycle_data.get('cycle_year', 2026)}",
            "notification_date": cycle_data.get("notification_date"),
            "application_start_date": cycle_data.get("application_start_date"),
            "application_end_date": cycle_data.get("application_end_date"),
            "prelims_date": cycle_data.get("prelims_date") or cycle_data.get("exam_start_date"),
            "mains_date": cycle_data.get("mains_date") or cycle_data.get("exam_end_date"),
            "interview_date": cycle_data.get("interview_date"),
            "admit_card_date": cycle_data.get("admit_card_date"),
            "result_date": cycle_data.get("result_date"),
            "is_active": cycle_data.get("is_active", True),
        }

        try:
            # Check existing cycle
            res = self.client.table("examination_cycles").select("id").eq("examination_id", exam_id).eq("cycle_year", payload["cycle_year"]).execute()
            if res.data:
                cycle_id = res.data[0]["id"]
                self.client.table("examination_cycles").update(payload).eq("id", cycle_id).execute()
                return cycle_id
            else:
                ins = self.client.table("examination_cycles").insert(payload).execute()
                if ins.data:
                    return ins.data[0]["id"]
        except Exception as e:
            logger.error(f"Error upserting examination cycle: {e}")
        return None

    def upsert_date_evidence(self, exam_id: str, date_evidences: List[Dict[str, Any]]) -> None:
        """
        Persists independent date evidence records containing source URL, verbatim text quote,
        page number, extraction method, and verification status.
        """
        if not date_evidences:
            return
        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Storing {len(date_evidences)} date evidence records for {exam_id}")
            return

        # 1. Try dedicated opportunity_date_evidence table if present
        date_evidence_payloads = []
        field_evidence_payloads = []

        for ev in date_evidences:
            field_name = ev.get("date_field") or ev.get("field_name")
            val = ev.get("extracted_value") or ev.get("field_value")
            quote = ev.get("original_text") or ev.get("snippet_or_quote") or ""
            source = ev.get("source_url") or ""
            doc_title = ev.get("source_document_title") or ev.get("document_url")
            page_num = ev.get("page_number")
            is_corrigendum = ev.get("is_corrigendum", False)

            date_evidence_payloads.append({
                "opportunity_id": exam_id,
                "date_field": field_name,
                "extracted_value": val,
                "original_text": quote,
                "source_url": source,
                "source_document_title": doc_title,
                "page_number": page_num if isinstance(page_num, int) else None,
                "extraction_method": ev.get("extraction_method", "deterministic_regex"),
                "verification_status": ev.get("verification_status", "VERIFIED"),
                "is_corrigendum": is_corrigendum,
            })

            field_evidence_payloads.append({
                "examination_id": exam_id,
                "field_name": field_name,
                "field_value": val,
                "snippet_or_quote": quote,
                "source_url": source,
                "document_url": doc_title,
                "page_or_paragraph": f"Page {page_num}" if page_num else None,
                "confidence_score": 1.0 if not is_corrigendum else 0.95,
                "verified_by": ev.get("extraction_method", "deterministic_regex"),
            })

        try:
            self.client.table("opportunity_date_evidence").insert(date_evidence_payloads).execute()
        except Exception:
            # Fall back to examination_field_evidence
            self.upsert_field_evidence(exam_id, field_evidence_payloads)

    def upsert_eligibility_rules(self, exam_id: str, rules_data: Dict[str, Any]) -> None:
        payload = {"examination_id": exam_id, **rules_data}
        if payload.get("min_age") is None:
            payload["min_age"] = 18
        if payload.get("max_age") is None:
            payload["max_age"] = 35
        if not payload.get("educational_qualifications"):
            payload["educational_qualifications"] = ["Refer official scheme guidelines"]
        if not payload.get("eligible_branches"):
            payload["eligible_branches"] = ["All disciplines eligible"]
        if not payload.get("eligible_streams"):
            payload["eligible_streams"] = ["All disciplines eligible"]

        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Upsert eligibility rules for {exam_id}")
            return

        try:
            self.client.table("eligibility_rules").upsert(payload, on_conflict="examination_id").execute()
        except Exception as e:
            logger.error(f"Error upserting eligibility rules: {e}")

    def upsert_recruitment_posts(self, exam_id: str, posts: List[Dict[str, Any]]) -> None:
        if not posts:
            return
        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Upserting {len(posts)} posts for exam {exam_id}")
            return
        for post in posts:
            payload = {"examination_id": exam_id, **post}
            try:
                self.client.table("recruitment_posts").insert(payload).execute()
            except Exception as e:
                logger.error(f"Error upserting recruitment post: {e}")

    def upsert_scholarship_details(self, exam_id: str, details: Dict[str, Any]) -> None:
        payload = {"examination_id": exam_id, **details}
        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Upsert scholarship details for {exam_id}")
            return
        try:
            self.client.table("opportunity_scholarships").upsert(payload, on_conflict="examination_id").execute()
        except Exception as e:
            logger.error(f"Error upserting scholarship details: {e}")

    def upsert_internship_details(self, exam_id: str, details: Dict[str, Any]) -> None:
        payload = {"examination_id": exam_id, **details}
        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Upsert internship details for {exam_id}")
            return
        try:
            self.client.table("opportunity_internships").upsert(payload, on_conflict="examination_id").execute()
        except Exception as e:
            logger.error(f"Error upserting internship details: {e}")

    def upsert_apprenticeship_details(self, exam_id: str, details: Dict[str, Any]) -> None:
        payload = {"examination_id": exam_id, **details}
        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Upsert apprenticeship details for {exam_id}")
            return
        try:
            self.client.table("opportunity_apprenticeships").upsert(payload, on_conflict="examination_id").execute()
        except Exception as e:
            logger.error(f"Error upserting apprenticeship details: {e}")

    def upsert_fellowship_details(self, exam_id: str, details: Dict[str, Any]) -> None:
        payload = {"examination_id": exam_id, **details}
        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Upsert fellowship details for {exam_id}")
            return
        try:
            self.client.table("opportunity_fellowships").upsert(payload, on_conflict="examination_id").execute()
        except Exception as e:
            logger.error(f"Error upserting fellowship details: {e}")

    def upsert_private_job_requisition(self, exam_id: str, details: Dict[str, Any]) -> None:
        payload = {"examination_id": exam_id, **details}
        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Upsert private job requisition for {exam_id}")
            return
        try:
            self.client.table("private_job_requisitions").upsert(payload, on_conflict="examination_id").execute()
        except Exception as e:
            logger.error(f"Error upserting private job requisition: {e}")

    def upsert_admission_qualification(self, exam_id: str, details: Dict[str, Any]) -> None:
        payload = {"examination_id": exam_id, **details}
        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Upsert admission qualification for {exam_id}")
            return
        try:
            self.client.table("admission_qualifications").upsert(payload, on_conflict="examination_id").execute()
        except Exception as e:
            logger.error(f"Error upserting admission qualification: {e}")

    def record_change_history(self, change_data: Dict[str, Any]) -> None:
        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Change detected: {change_data.get('change_summary')}")
            return
        try:
            # Insert into canonical examination_change_history and opportunity_change_history for full compatibility
            self.client.table("examination_change_history").insert(change_data).execute()
        except Exception:
            try:
                self.client.table("opportunity_change_history").insert(change_data).execute()
            except Exception as e:
                logger.error(f"Error recording change history: {e}")

    def upsert_field_evidence(self, exam_id: str, field_evidences: List[Dict[str, Any]]) -> None:
        if not field_evidences:
            return
        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Upserting {len(field_evidences)} field evidence records for {exam_id}")
            return

        payloads = [{"examination_id": exam_id, **ev} for ev in field_evidences]
        try:
            self.client.table("examination_field_evidence").upsert(
                payloads,
                on_conflict="examination_id,field_name"
            ).execute()
        except Exception as e:
            logger.error(f"Error upserting examination field evidence: {e}")

    def upsert_url_validation(self, url_val_data: Dict[str, Any]) -> None:
        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] URL validation for {url_val_data.get('url')}: {url_val_data.get('validation_status')}")
            return

        try:
            self.client.table("url_validations").upsert(
                url_val_data,
                on_conflict="url"
            ).execute()
        except Exception as e:
            logger.error(f"Error recording URL validation: {e}")

    def record_source_health(self, health_data: Dict[str, Any]) -> None:
        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Source health logged: {health_data.get('source_slug')} - {health_data.get('health_status')}")
            return
        try:
            self.client.table("source_health_logs").insert(health_data).execute()
        except Exception as e:
            logger.error(f"Error recording source health: {e}")

    def insert_crawler_run(self, run_data: Dict[str, Any]) -> str:
        payload = dict(run_data)
        if "source_id" in payload:
            sid = str(payload["source_id"])
            if len(sid) != 36 or sid.startswith("source-"):
                payload["source_id"] = None

        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Started crawler run for {payload.get('crawler_name')}")
            return "run-mock-id"

        try:
            res = self.client.table("crawler_runs").insert(payload).execute()
            if res.data:
                return res.data[0]["id"]
        except Exception as e:
            logger.error(f"Error creating crawler run: {e}")
        return "run-fallback-id"

    def update_crawler_run(self, run_id: str, update_data: Dict[str, Any]) -> None:
        if not run_id or run_id in ("run-fallback-id", "run-mock-id"):
            return
        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Update crawler run {run_id}: {update_data}")
            return

        try:
            self.client.table("crawler_runs").update(update_data).eq("id", run_id).execute()
        except Exception as e:
            logger.error(f"Error updating crawler run: {e}")

    def insert_notification(self, notif_data: Dict[str, Any]) -> None:
        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Notification generated: {notif_data.get('title')}")
            return

        try:
            self.client.table("notifications").insert(notif_data).execute()
        except Exception as e:
            logger.error(f"Error inserting notification: {e}")

    def get_followers_for_examination(self, exam_id: str) -> List[str]:
        if not self.is_connected or not self.client:
            return ["candidate-rexam-001"]
        try:
            res = self.client.table("candidate_followed_examinations").select("candidate_id").eq("examination_id", exam_id).execute()
            return [row["candidate_id"] for row in (res.data or [])]
        except Exception as e:
            logger.error(f"Error fetching followers for exam {exam_id}: {e}")
            return []

    def get_active_candidates_for_matching(self) -> List[Dict[str, Any]]:
        if not self.is_connected or not self.client:
            return [{
                "id": "candidate-rexam-001",
                "email": "candidate@rexam.in",
                "social_category": "OBC-NCL",
                "is_pwbd": False,
                "highest_qualification": "B.Tech",
                "stream": "Computer Science & Engineering",
                "date_of_birth": "1998-05-10",
                "cgpa_or_percentage": 78.5,
                "has_active_backlogs": False,
            }]

        try:
            res = self.client.table("profiles").select(
                "id, email, social_category, is_pwbd, is_ex_serviceman, date_of_birth, candidate_education(*), candidate_preferences(*)"
            ).execute()
            return res.data or []
        except Exception as e:
            logger.error(f"Error fetching active candidates: {e}")
            return []

    def fetch_examinations_for_verification(self, limit: int = 200) -> List[Dict[str, Any]]:
        if not self.is_connected or not self.client:
            return []
        try:
            res = (
                self.client.table("examinations")
                .select("id, slug, title, status, application_status, verification_tier, official_application_url, application_url, official_notification_url, notification_url, source_url, application_open_date, application_close_date, examination_date, last_verified_at, examination_dates(*)")
                .order("last_verified_at", desc=False)
                .limit(limit)
                .execute()
            )
            return res.data or []
        except Exception as e:
            logger.error(f"Error fetching examinations for verification: {e}")
            return []

    def update_examination_verification_result(self, exam_id: str, updates: Dict[str, Any]) -> bool:
        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Updating exam {exam_id}: {updates}")
            return True
        try:
            self.client.table("examinations").update(updates).eq("id", exam_id).execute()
            return True
        except Exception as e:
            logger.error(f"Error updating examination verification result for {exam_id}: {e}")
            return False

db_client = DatabaseClient()
