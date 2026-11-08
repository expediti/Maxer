import logging
from typing import Dict, Any, List, Tuple
from urllib.parse import urlparse
from datetime import datetime

logger = logging.getLogger("rexam.verifier")

TRUSTED_DOMAINS = {
    ".gov.in",
    ".nic.in",
    ".ac.in",
    ".res.in",
    ".org.in",
    ".edu.in",
    "isro.gov.in",
    "drdo.gov.in",
    "upsc.gov.in",
    "ssc.gov.in",
    "ibps.in",
    "nta.ac.in",
    "pmrf.in",
}

class ExaminationVerifier:
    """Verifies authenticity, date coherence, and data sanity of parsed recruitment notices."""

    def verify_provenance(self, source_url: str) -> bool:
        if not source_url:
            return False
        hostname = urlparse(source_url).hostname or ""
        hostname = hostname.lower()
        return any(hostname.endswith(domain) or domain in hostname for domain in TRUSTED_DOMAINS)

    def verify_examination_data(self, data: Dict[str, Any], source_url: str) -> Tuple[str, List[str], Dict[str, Any]]:
        """
        Runs validation rules against extracted data.
        Returns:
            Tuple of (status: 'published'|'under_review', uncertain_fields: List[str], cleaned_data: Dict[str, Any])
        """
        uncertain_fields: List[str] = []
        is_official = self.verify_provenance(source_url)

        if not is_official:
            uncertain_fields.append("source_provenance_unverified")

        # 1. Validate Age bounds
        min_age = data.get("min_age")
        max_age = data.get("max_age")
        if min_age is not None and max_age is not None:
            if not (16 <= min_age < max_age <= 70):
                uncertain_fields.append("age_bounds_incoherent")
                logger.warning(f"Sanity check failed: min_age={min_age}, max_age={max_age}")

        # 2. Validate Dates coherence
        open_date_str = data.get("application_opening_date")
        close_date_str = data.get("application_closing_date")
        exam_date_str = data.get("prelims_exam_date")

        open_dt, close_dt, exam_dt = None, None, None
        if open_date_str:
            try:
                open_dt = datetime.fromisoformat(open_date_str)
            except ValueError:
                uncertain_fields.append("invalid_opening_date_format")

        if close_date_str:
            try:
                close_dt = datetime.fromisoformat(close_date_str)
            except ValueError:
                uncertain_fields.append("invalid_closing_date_format")

        if exam_date_str:
            try:
                exam_dt = datetime.fromisoformat(exam_date_str)
            except ValueError:
                uncertain_fields.append("invalid_exam_date_format")

        if open_dt and close_dt and open_dt > close_dt:
            uncertain_fields.append("opening_date_after_closing_date")

        if close_dt and exam_dt and close_dt > exam_dt:
            uncertain_fields.append("closing_date_after_examination_date")

        # 3. Vacancy sanity
        vacancies = data.get("vacancies")
        if vacancies is not None and vacancies <= 0:
            uncertain_fields.append("non_positive_vacancies")

        # Determine published vs under_review status
        confidence = data.get("confidence_score", 0.0)
        status = "published"
        if len(uncertain_fields) > 0 or confidence < 0.75 or not is_official or data.get("requires_human_review"):
            status = "under_review"

        data["is_confirmed"] = (status == "published")
        data["uncertain_fields"] = uncertain_fields

        return status, uncertain_fields, data

verifier = ExaminationVerifier()

