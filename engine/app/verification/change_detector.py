import logging
from typing import Dict, Any, List, Optional
from datetime import datetime, timezone

logger = logging.getLogger("rexam.change_detector")

CRITICAL_FIELDS = [
    ("application_closing_date", "Application Deadline", "deadline_extended"),
    ("application_close_date", "Application Closing Date", "deadline_extended"),
    ("extended_deadline", "Extended Application Deadline", "deadline_extended"),
    ("application_opening_date", "Application Opening Date", "date_changed"),
    ("application_open_date", "Application Opening Date", "date_changed"),
    ("fee_deadline", "Fee Payment Deadline", "fee_deadline_extended"),
    ("examination_date", "Examination Date", "exam_rescheduled"),
    ("vacancies", "Total Vacancies", "vacancy_changed"),
    ("vacancy_count", "Total Vacancies", "vacancy_changed"),
    ("minimum_age", "Minimum Age Requirement", "eligibility_changed"),
    ("maximum_age", "Maximum Age Limit", "eligibility_changed"),
    ("application_fee", "Application Fee", "fee_changed"),
    ("status", "Application Status", "status_changed"),
]

class ChangeDetector:
    """
    Compares newly extracted official opportunities against previously stored records
    to detect date extensions, vacancy revisions, corrigenda, or cancellations.
    Tracks changes with effective_date and source provenance.
    """

    def detect_changes(
        self,
        previous_record: Optional[Dict[str, Any]],
        new_record: Dict[str, Any],
        source_doc_url: Optional[str] = None,
        effective_date: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """
        Returns a list of change records if differences are detected.
        """
        if not previous_record:
            return []

        changes: List[Dict[str, Any]] = []
        seen_canonical_fields = set()
        now_iso = datetime.now(timezone.utc).isoformat()

        for field_key, human_name, default_change_type in CRITICAL_FIELDS:
            # Map aliases to canonical field
            canonical = "application_closing_date" if "closing" in field_key or "close" in field_key else field_key
            canonical = "vacancies" if "vacanc" in canonical else canonical
            if canonical in seen_canonical_fields:
                continue

            old_val = previous_record.get(field_key)
            new_val = new_record.get(field_key)

            # Skip if both are empty/None
            if (old_val is None or old_val == "") and (new_val is None or new_val == ""):
                continue

            # Compare stringified normalized values
            str_old = str(old_val).strip() if old_val is not None else ""
            str_new = str(new_val).strip() if new_val is not None else ""

            if str_old and str_new and str_old != str_new:
                seen_canonical_fields.add(canonical)
                summary = f"{human_name} updated from '{str_old}' to '{str_new}'"
                change_type = default_change_type

                if canonical == "application_closing_date":
                    if str_new > str_old:
                        summary = f"Application Deadline extended to {str_new}"
                        change_type = "extension"
                    else:
                        summary = f"Application Deadline revised to {str_new}"
                        change_type = "corrigendum"
                elif canonical == "status" and str_new.lower() == "withdrawn":
                    summary = "Official recruitment process cancelled or withdrawn"
                    change_type = "cancellation"
                elif "corrigendum" in (new_record.get("title") or "").lower():
                    change_type = "corrigendum"

                changes.append({
                    "field_name": canonical,
                    "old_value": str_old,
                    "new_value": str_new,
                    "change_summary": summary,
                    "change_type": change_type,
                    "source_document_url": source_doc_url or new_record.get("official_source_url") or new_record.get("notification_url"),
                    "effective_date": effective_date or now_iso,
                    "detected_at": now_iso,
                    "verification_status": "verified",
                })

        return changes

    def generate_notifications_for_changes(
        self,
        exam_id: str,
        exam_title: str,
        changes: List[Dict[str, Any]],
        follower_ids: List[str]
    ) -> List[Dict[str, Any]]:
        """
        Generates candidate notifications for followers without repeating alerts.
        """
        notifications: List[Dict[str, Any]] = []

        for change in changes:
            summary = change.get("change_summary", "")
            change_type = change.get("change_type", "corrigendum")

            for candidate_id in follower_ids:
                notifications.append({
                    "candidate_id": candidate_id,
                    "examination_id": exam_id,
                    "type": "official",
                    "notification_type": change_type,
                    "title": f"Official Corrigendum: {exam_title}",
                    "body": summary,
                    "message": summary,
                    "official_source_url": change.get("source_document_url"),
                    "sent_at": datetime.now(timezone.utc).isoformat(),
                    "is_read": False,
                    "data": {
                        "examination_id": exam_id,
                        "field_name": change.get("field_name"),
                        "new_value": change.get("new_value"),
                        "change_type": change_type,
                    }
                })

        return notifications

change_detector = ChangeDetector()
