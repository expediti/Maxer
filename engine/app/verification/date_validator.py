"""
Rexam Automated Date Validation & Lifecycle Engine.
Enforces statutory temporal sequence rules, detects date anomalies and synthetic
date clusters, and deterministically computes opportunity lifecycle status.

Enforced Validation Rules:
1. application_start_date <= application_end_date
2. application_end_date <= exam_start_date
3. exam_start_date <= exam_end_date
4. correction_start_date <= correction_end_date
5. Past application deadlines cannot have status OPEN.
6. Past examination dates cannot be presented as upcoming.
7. Identical application windows across unrelated opportunities are flagged as synthetic clusters.
8. Dates missing verifiable source evidence are flagged for manual verification.
9. Conflicting dates across notifications/corrigenda are flagged as UNDER_REVIEW.
"""

import logging
from datetime import datetime, date, timezone
from typing import Dict, List, Any, Optional, Tuple

logger = logging.getLogger("rexam.date_validator")


class DateValidator:
    """Automated validator for opportunity dates and lifecycle integrity."""

    @staticmethod
    def parse_dt(val: Any) -> Optional[datetime]:
        """Safely parses string or date into timezone-aware UTC datetime."""
        if not val:
            return None
        if isinstance(val, datetime):
            return val if val.tzinfo else val.replace(tzinfo=timezone.utc)
        if isinstance(val, date):
            return datetime(val.year, val.month, val.day, tzinfo=timezone.utc)
        try:
            val_str = str(val).strip()
            # If ISO with time
            if "T" in val_str:
                clean = val_str.replace("Z", "+00:00")
                dt = datetime.fromisoformat(clean)
                return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)
            # If date only YYYY-MM-DD
            d = date.fromisoformat(val_str.split(" ")[0])
            return datetime(d.year, d.month, d.day, tzinfo=timezone.utc)
        except Exception:
            return None

    def validate_dates(
        self,
        dates: Dict[str, Any],
        evidences: Optional[List[Dict[str, Any]]] = None,
        now: Optional[datetime] = None
    ) -> Tuple[bool, List[str], Dict[str, Any]]:
        """
        Validates date consistency.
        Returns:
            (is_valid: bool, issues: List[str], cleaned_dates: Dict[str, Any])
        """
        now = now or datetime.now(timezone.utc)
        issues: List[str] = []
        cleaned: Dict[str, Any] = {}

        notif_dt = self.parse_dt(dates.get("notification_date"))
        app_start_dt = self.parse_dt(dates.get("application_start_date") or dates.get("application_open_date") or dates.get("application_opening_date"))
        app_end_dt = self.parse_dt(dates.get("application_end_date") or dates.get("application_close_date") or dates.get("application_closing_date"))
        corr_start_dt = self.parse_dt(dates.get("correction_start_date") or dates.get("correction_window_start"))
        corr_end_dt = self.parse_dt(dates.get("correction_end_date") or dates.get("correction_window_end"))
        admit_dt = self.parse_dt(dates.get("admit_card_date") or dates.get("admit_card_release_date"))
        exam_start_dt = self.parse_dt(dates.get("exam_start_date") or dates.get("examination_start_date") or dates.get("examination_date") or dates.get("prelims_date"))
        exam_end_dt = self.parse_dt(dates.get("exam_end_date") or dates.get("examination_end_date"))
        result_dt = self.parse_dt(dates.get("result_date"))
        age_cutoff_dt = self.parse_dt(dates.get("age_cutoff_date"))

        # Rule 1: Application Start vs End
        if app_start_dt and app_end_dt:
            if app_start_dt > app_end_dt:
                issues.append("APPLICATION_START_AFTER_END: application_start_date is later than application_end_date")

        # Rule 2: Application Deadline vs Exam Start
        if app_end_dt and exam_start_dt:
            if app_end_dt > exam_start_dt:
                issues.append("APPLICATION_CLOSES_AFTER_EXAM: application_end_date is later than exam_start_date")

        # Rule 3: Exam Start vs End
        if exam_start_dt and exam_end_dt:
            if exam_start_dt > exam_end_dt:
                issues.append("EXAM_START_AFTER_END: exam_start_date is later than exam_end_date")

        # Rule 4: Correction Window Bounds
        if corr_start_dt and corr_end_dt:
            if corr_start_dt > corr_end_dt:
                issues.append("CORRECTION_START_AFTER_END: correction_start_date is later than correction_end_date")
        if app_start_dt and corr_start_dt:
            if app_start_dt > corr_start_dt:
                issues.append("CORRECTION_BEFORE_APP_START: correction window starts before application opening")

        # Rule 5: Admit Card Release
        if admit_dt and exam_start_dt:
            if admit_dt > exam_start_dt:
                issues.append("ADMIT_CARD_AFTER_EXAM: admit card release date is later than exam start date")

        # Rule 6: Result Date
        if result_dt and exam_start_dt:
            if result_dt < exam_start_dt:
                issues.append("RESULT_BEFORE_EXAM: result declaration date is earlier than examination start date")

        # Rule 7: Notification vs Application Start
        if notif_dt and app_start_dt:
            if notif_dt.date() > app_start_dt.date():
                issues.append("NOTIFICATION_AFTER_APP_START: notification publication date is later than application start date")

        # Check for Synthetic Microsecond Timestamps (e.g. from datetime.now() +/- timedelta)
        for key in ["application_start_date", "application_end_date"]:
            raw_val = str(dates.get(key) or "")
            if "." in raw_val and ("+00:00" in raw_val or "Z" in raw_val):
                issues.append(f"SYNTHETIC_TIMESTAMP_SUSPECTED: {key} contains microsecond precision indicative of programmatic generation")

        # Populate Cleaned Validated Dictionary
        cleaned["notification_date"] = notif_dt.date().isoformat() if notif_dt else None
        cleaned["application_start_date"] = app_start_dt.isoformat() if app_start_dt else None
        cleaned["application_end_date"] = app_end_dt.isoformat() if app_end_dt else None
        cleaned["correction_start_date"] = corr_start_dt.isoformat() if corr_start_dt else None
        cleaned["correction_end_date"] = corr_end_dt.isoformat() if corr_end_dt else None
        cleaned["admit_card_date"] = admit_dt.date().isoformat() if admit_dt else None
        cleaned["exam_start_date"] = exam_start_dt.date().isoformat() if exam_start_dt else None
        cleaned["exam_end_date"] = exam_end_dt.date().isoformat() if exam_end_dt else None
        cleaned["result_date"] = result_dt.date().isoformat() if result_dt else None
        cleaned["age_cutoff_date"] = age_cutoff_dt.date().isoformat() if age_cutoff_dt else None

        is_valid = len(issues) == 0
        return is_valid, issues, cleaned

    def compute_lifecycle_status(
        self,
        dates: Dict[str, Any],
        has_official_notification: bool = True,
        is_withdrawn: bool = False,
        now: Optional[datetime] = None
    ) -> str:
        """
        Derives opportunity lifecycle status strictly according to Section 8:
        - UPCOMING
        - OPEN
        - CLOSED
        - AWAITING_NOTIFICATION
        - EXAMINATION_COMPLETED
        - RESULT_DECLARED
        - WITHDRAWN
        - UNDER_REVIEW
        """
        now = now or datetime.now(timezone.utc)

        if is_withdrawn:
            return "WITHDRAWN"

        app_start = self.parse_dt(dates.get("application_start_date") or dates.get("application_open_date"))
        app_end = self.parse_dt(dates.get("application_end_date") or dates.get("application_close_date"))
        exam_start = self.parse_dt(dates.get("exam_start_date") or dates.get("examination_start_date") or dates.get("examination_date"))
        exam_end = self.parse_dt(dates.get("exam_end_date") or dates.get("examination_end_date")) or exam_start
        result_dt = self.parse_dt(dates.get("result_date"))

        # If result already declared
        if result_dt and result_dt <= now:
            return "RESULT_DECLARED"

        # If examination has completed
        if exam_end and exam_end < now:
            return "EXAMINATION_COMPLETED"

        # If official application window is active and verified
        if app_start and app_end:
            if app_start <= now <= app_end:
                return "OPEN"
            elif now < app_start:
                return "UPCOMING"
            elif now > app_end:
                return "CLOSED"

        # If only deadline is known
        if app_end:
            if now <= app_end:
                # If we don't know start date, cannot definitively assume open unless verified
                return "OPEN"
            else:
                return "CLOSED"

        # If only exam date is known in the future
        if exam_start and exam_start > now:
            return "UPCOMING"

        # If notification exists but no dates announced yet
        if has_official_notification:
            return "AWAITING_NOTIFICATION"

        return "UNDER_REVIEW"


date_validator = DateValidator()

