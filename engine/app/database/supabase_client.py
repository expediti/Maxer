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
            logger.info(f"[Dry-run] Upsert source: {source_data.get('base_url') or source_data.get('url')}")
            return source_data.get("id", "source-mock-id")

        try:
            if "base_url" not in source_data and "url" in source_data:
                source_data["base_url"] = source_data["url"]
            res = self.client.table("sources").upsert(source_data, on_conflict="base_url").execute()
            if res.data:
                return res.data[0]["id"]
        except Exception as e:
            logger.error(f"Error upserting source {source_data.get('base_url')}: {e}")
        return None

    def upsert_examination(self, exam_data: Dict[str, Any]) -> Optional[str]:
        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Upsert examination: {exam_data.get('title') or exam_data.get('name')}")
            return exam_data.get("id", "exam-mock-id")

        try:
            if "name" not in exam_data and "title" in exam_data:
                exam_data["name"] = exam_data["title"]
            if "title" not in exam_data and "name" in exam_data:
                exam_data["title"] = exam_data["name"]
            res = self.client.table("examinations").upsert(exam_data, on_conflict="slug").execute()
            if res.data:
                return res.data[0]["id"]
        except Exception as e:
            logger.error(f"Error upserting examination: {e}")
        return None

    def upsert_examination_dates(self, exam_id: str, dates_data: Dict[str, Any]) -> None:
        payload = {"examination_id": exam_id, **dates_data}
        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Upsert examination dates for {exam_id}")
            return

        try:
            self.client.table("examination_dates").upsert(payload, on_conflict="examination_id").execute()
        except Exception as e:
            logger.error(f"Error upserting examination dates: {e}")

    def upsert_eligibility_rules(self, exam_id: str, rules_data: Dict[str, Any]) -> None:
        payload = {"examination_id": exam_id, **rules_data}
        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Upsert eligibility rules for {exam_id}")
            return

        try:
            self.client.table("eligibility_rules").upsert(payload, on_conflict="examination_id").execute()
        except Exception as e:
            logger.error(f"Error upserting eligibility rules: {e}")

    def insert_crawler_run(self, run_data: Dict[str, Any]) -> str:
        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Started crawler run for {run_data.get('crawler_name')}")
            return "run-mock-id"

        try:
            res = self.client.table("crawler_runs").insert(run_data).execute()
            if res.data:
                return res.data[0]["id"]
        except Exception as e:
            logger.error(f"Error creating crawler run: {e}")
        return "run-fallback-id"

    def update_crawler_run(self, run_id: str, update_data: Dict[str, Any]) -> None:
        if not self.is_connected or not self.client:
            logger.info(f"[Dry-run] Updated crawler run {run_id}: {update_data}")
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

db_client = DatabaseClient()
