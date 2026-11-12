"""
Rexam Deterministic Date Extraction & Evidence Engine.
Extracts official examination, application, and lifecycle dates from official
government notifications, gazettes, examination calendars, and recruitment portals.

Strict Principles:
1. Every extracted date must be anchored to verifiable source text.
2. Distinguishes 10 independent date types:
   - notification_date
   - application_start_date
   - application_end_date
   - correction_start_date
   - correction_end_date
   - admit_card_date
   - exam_start_date
   - exam_end_date
   - result_date
   - age_cutoff_date
3. Recognizes Indian gazette date formats, multi-day exam schedules, and time boundaries.
4. Detects official corrigenda, addenda, and deadline extension notices.
5. NEVER fabricates dates. If no official evidence exists, returns None.
"""

import re
import logging
from datetime import datetime, date, timezone
from typing import Dict, List, Any, Optional, Tuple
from dataclasses import dataclass, asdict

logger = logging.getLogger("rexam.date_extractor")

# -----------------------------------------------------------------------------
# INDIAN DATE FORMAT PATTERNS & REGEXES
# -----------------------------------------------------------------------------
MONTH_NAMES = r"(?:January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)"

# Match standard Indian date representations:
# - 14/02/2026, 14-02-2026, 14.02.2026
# - 14th February 2026, 14 Feb 2026, 14-Feb-2026
# - February 14, 2026
DATE_REGEX_PARTS = [
    # DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
    r"(?P<day>\b[0-3]?\d)[./-](?P<month>[0-1]?\d)[./-](?P<year>20\d{2})\b",
    # DD Month YYYY (e.g., 25th May 2026, 01 February 2026)
    r"(?P<day>\b[0-3]?\d)(?:st|nd|rd|th)?\s+(?P<month_name>" + MONTH_NAMES + r")[\s,]+(?P<year>20\d{2})\b",
    # Month DD, YYYY (e.g., May 25, 2026)
    r"(?P<month_name>\b" + MONTH_NAMES + r")\s+(?P<day>[0-3]?\d)(?:st|nd|rd|th)?[\s,]+(?P<year>20\d{2})\b",
    # Month YYYY (tentative, e.g., June 2026)
    r"(?P<month_name_only>\b" + MONTH_NAMES + r")[\s,]+(?P<year_only>20\d{2})\b",
]

# Time suffixes common in Indian official portals
TIME_REGEX = re.compile(
    r"(?:(?:at|till|upto|up\s+to|by)\s+)?([0-1]?\d|2[0-3])(?::([0-5]\d))?\s*(?:hours|hrs|am|pm|ist)?",
    re.IGNORECASE
)

# -----------------------------------------------------------------------------
# CONTEXT PATTERNS FOR 10 INDEPENDENT DATE FIELDS
# -----------------------------------------------------------------------------
DATE_FIELD_PATTERNS = {
    "notification_date": [
        re.compile(r"(?:date\s+of\s+notification|dated|advertisement\s+date|published\s+on|notice\s+date|issue\s+date|notification\s+released)", re.IGNORECASE),
        re.compile(r"(?:notification\s+no[.:\s].*?dated)", re.IGNORECASE),
    ],
    "application_start_date": [
        re.compile(r"(?:opening\s+date|commencement\s+of\s+online\s+application|applications?\s+open|start\s+date\s+for\s+submission|online\s+registration\s+commences|registration\s+start|apply\s+online\s+from)", re.IGNORECASE),
        re.compile(r"(?:submission\s+of\s+online\s+applications?.*?from)", re.IGNORECASE),
    ],
    "application_end_date": [
        re.compile(r"(?:closing\s+date|last\s+date\s+for\s+submission|last\s+date\s+and\s+time|last\s+date\s+for\s+receipt|application\s+deadline|online\s+registration\s+closes|closing\s+time\s+and\s+date)", re.IGNORECASE),
        re.compile(r"(?:extended\s+last\s+date|last\s+date\s+extended\s+(?:to|upto|up\s+to))", re.IGNORECASE),
        re.compile(r"(?:last\s+date\s+for\s+making\s+online\s+fee\s+payment)", re.IGNORECASE),
    ],
    "correction_start_date": [
        re.compile(r"(?:window\s+for\s+application\s+form\s+correction.*?from|correction\s+window\s+opens?|dates?\s+of\s+correction\s+window|edit\s+window\s+start)", re.IGNORECASE),
    ],
    "correction_end_date": [
        re.compile(r"(?:window\s+for\s+application\s+form\s+correction.*?to|correction\s+window\s+closes?|last\s+date\s+for\s+correction|edit\s+window\s+end)", re.IGNORECASE),
    ],
    "admit_card_date": [
        re.compile(r"(?:e-?admit\s+card|download(?:ing)?\s+of\s+admit\s+card|hall\s+ticket\s+release|date\s+of\s+issuance\s+of\s+admit\s+card|call\s+letter\s+download)", re.IGNORECASE),
    ],
    "exam_start_date": [
        re.compile(r"(?:date\s+of\s+commencement\s+of\s+(?:examination|exam)|schedule\s+of\s+(?:computer\s+based\s+)?examination|date\s+of\s+(?:preliminary|prelims|tier-?i|phase-?i|written)\s+exam|examination\s+date|exam\s+commences|cbt\s+date)", re.IGNORECASE),
        re.compile(r"(?:date\s+of\s+exam(?:ination)?\s*[:\-])", re.IGNORECASE),
    ],
    "exam_end_date": [
        re.compile(r"(?:examination\s+concludes|exam\s+end\s+date|mains?\s+examination\s+date|tier-?ii\s+exam\s+date|schedule\s+of\s+exam.*?to\s+)", re.IGNORECASE),
    ],
    "result_date": [
        re.compile(r"(?:declaration\s+of\s+results?|result\s+announcement|date\s+of\s+result|scorecard\s+release|display\s+of\s+results?)", re.IGNORECASE),
    ],
    "age_cutoff_date": [
        re.compile(r"(?:crucial\s+date\s+for\s+(?:determining\s+)?age|age\s+(?:reckoned|calculated)\s+as\s+on|candidate\s+must\s+have\s+attained.*?as\s+on|cut-?off\s+date\s+for\s+age)", re.IGNORECASE),
    ],
}

# Corrigendum / Extension Markers
CORRIGENDUM_PATTERNS = [
    re.compile(r"(?:corrigendum|addendum|extension\s+of\s+last\s+date|in\s+partial\s+modification|revised\s+schedule|extension\s+notice)", re.IGNORECASE),
]

MONTH_MAP = {
    "jan": 1, "january": 1, "feb": 2, "february": 2, "mar": 3, "march": 3,
    "apr": 4, "april": 4, "may": 5, "jun": 6, "june": 6, "jul": 7, "july": 7,
    "aug": 8, "august": 8, "sep": 9, "sept": 9, "september": 9, "oct": 10,
    "october": 10, "nov": 11, "november": 11, "dec": 12, "december": 12,
}


@dataclass
class ExtractedDateEvidence:
    opportunity_id: Optional[str]
    date_field: str
    extracted_value: str  # ISO YYYY-MM-DD or YYYY-MM-DDTHH:MM:SSZ
    original_text: str  # Exact sentence / quote from notification
    source_url: str
    source_document_title: Optional[str] = None
    page_number: Optional[int] = None
    extraction_method: str = "deterministic_regex"
    verification_status: str = "VERIFIED"
    is_corrigendum: bool = False
    verified_at: str = ""

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


class DateExtractor:
    """
    Deterministic Date Extraction Engine for Indian Opportunity Notifications.
    """

    def parse_all_dates_in_text(self, text: str) -> List[Tuple[date, int, int]]:
        """
        Finds all date occurrences in text along with their character start/end positions.
        Returns list of (date_obj, start_idx, end_idx).
        """
        results: List[Tuple[date, int, int]] = []
        if not text:
            return results

        # 1. DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
        for m in re.finditer(r"\b([0-3]?\d)[./-]([0-1]?\d)[./-](20\d{2})\b", text):
            try:
                d = int(m.group(1))
                mo = int(m.group(2))
                y = int(m.group(3))
                results.append((date(y, mo, d), m.start(), m.end()))
            except ValueError:
                pass

        # 2. DD Month YYYY
        pattern_name = r"\b([0-3]?\d)(?:st|nd|rd|th)?\s+(" + MONTH_NAMES + r")[\s,]+(20\d{2})\b"
        for m in re.finditer(pattern_name, text, re.IGNORECASE):
            try:
                d = int(m.group(1))
                mo = MONTH_MAP.get(m.group(2).lower(), 1)
                y = int(m.group(3))
                results.append((date(y, mo, d), m.start(), m.end()))
            except ValueError:
                pass

        # 3. Month DD, YYYY
        pattern_rev = r"\b(" + MONTH_NAMES + r")\s+([0-3]?\d)(?:st|nd|rd|th)?[\s,]+(20\d{2})\b"
        for m in re.finditer(pattern_rev, text, re.IGNORECASE):
            try:
                mo = MONTH_MAP.get(m.group(1).lower(), 1)
                d = int(m.group(2))
                y = int(m.group(3))
                results.append((date(y, mo, d), m.start(), m.end()))
            except ValueError:
                pass

        # Sort by occurrence in text
        results.sort(key=lambda x: x[1])
        return results

    def extract_time_boundary(self, text: str) -> Optional[str]:
        """Extracts closing time like 18:00 Hours or 23:59 IST."""
        m_time = re.search(r"\b([0-2]?\d):([0-5]\d)\s*(?:hours|hrs|pm|am|ist)?\b", text, re.IGNORECASE)
        if m_time:
            hh = int(m_time.group(1))
            mm = int(m_time.group(2))
            if "pm" in text.lower() and hh < 12:
                hh += 12
            return f"{hh:02d}:{mm:02d}:00"
        if re.search(r"\b(?:23:59|11:59\s*pm)\b", text, re.IGNORECASE):
            return "23:59:59"
        if re.search(r"\b(?:18:00|6:00\s*pm|17:00|5:00\s*pm)\b", text, re.IGNORECASE):
            return "18:00:00"
        return None

    def is_corrigendum_document(self, text: str) -> bool:
        """Determines if the document is an official corrigendum / extension notice."""
        for pattern in CORRIGENDUM_PATTERNS:
            if pattern.search(text):
                return True
        return False

    def extract_dates_from_text(
        self,
        text: str,
        source_url: str,
        document_title: Optional[str] = None,
        page_number: Optional[int] = None,
        opportunity_id: Optional[str] = None
    ) -> List[ExtractedDateEvidence]:
        """
        Scans text for all 10 distinct date fields using contextual boundary matching.
        """
        if not text:
            return []

        evidences: List[ExtractedDateEvidence] = []
        is_corrigendum = self.is_corrigendum_document(text)
        now_iso = datetime.now(timezone.utc).isoformat()
        handled_fields: set[str] = set()

        # Split text into lines or sentences for localized context
        lines = [line.strip() for line in text.split("\n") if len(line.strip()) > 5]

        for line_idx, line in enumerate(lines):
            context_window = " ".join(lines[line_idx : min(len(lines), line_idx + 3)])
            dates_found = self.parse_all_dates_in_text(context_window)
            if not dates_found:
                continue

            time_str = self.extract_time_boundary(context_window)
            snippet = context_window[:250].strip()

            # Check if this context is a Range (e.g. from date1 to date2)
            has_range = len(dates_found) >= 2 and any(sep in context_window.lower() for sep in [" to ", " - ", " till ", " and "])

            # Check Correction Window Range
            if ("correction" in context_window.lower() or "edit window" in context_window.lower()) and has_range:
                if "correction_start_date" not in handled_fields:
                    d_start = dates_found[0][0]
                    iso_start = f"{d_start.isoformat()}T00:00:00+05:30"
                    evidences.append(ExtractedDateEvidence(
                        opportunity_id=opportunity_id,
                        date_field="correction_start_date",
                        extracted_value=iso_start,
                        original_text=snippet,
                        source_url=source_url,
                        source_document_title=document_title or "Official Document",
                        page_number=page_number,
                        verification_status="VERIFIED",
                        is_corrigendum=is_corrigendum,
                        verified_at=now_iso,
                    ))
                    handled_fields.add("correction_start_date")

                if "correction_end_date" not in handled_fields:
                    d_end = dates_found[1][0]
                    iso_end = f"{d_end.isoformat()}T23:59:59+05:30"
                    evidences.append(ExtractedDateEvidence(
                        opportunity_id=opportunity_id,
                        date_field="correction_end_date",
                        extracted_value=iso_end,
                        original_text=snippet,
                        source_url=source_url,
                        source_document_title=document_title or "Official Document",
                        page_number=page_number,
                        verification_status="VERIFIED",
                        is_corrigendum=is_corrigendum,
                        verified_at=now_iso,
                    ))
                    handled_fields.add("correction_end_date")
                continue

            # Check Exam Date Range (e.g., 07.02.2026 to 15.02.2026 or 07 & 08 Feb 2026)
            if any(k in context_window.lower() for k in ["examination", "schedule of", "exam date", "cbt", "commencement"]) and has_range:
                if "exam_start_date" not in handled_fields:
                    d_start = dates_found[0][0]
                    evidences.append(ExtractedDateEvidence(
                        opportunity_id=opportunity_id,
                        date_field="exam_start_date",
                        extracted_value=d_start.isoformat(),
                        original_text=snippet,
                        source_url=source_url,
                        source_document_title=document_title or "Official Document",
                        page_number=page_number,
                        verification_status="VERIFIED",
                        is_corrigendum=is_corrigendum,
                        verified_at=now_iso,
                    ))
                    handled_fields.add("exam_start_date")

                if "exam_end_date" not in handled_fields:
                    d_end = dates_found[-1][0]
                    evidences.append(ExtractedDateEvidence(
                        opportunity_id=opportunity_id,
                        date_field="exam_end_date",
                        extracted_value=d_end.isoformat(),
                        original_text=snippet,
                        source_url=source_url,
                        source_document_title=document_title or "Official Document",
                        page_number=page_number,
                        verification_status="VERIFIED",
                        is_corrigendum=is_corrigendum,
                        verified_at=now_iso,
                    ))
                    handled_fields.add("exam_end_date")
                continue

            # Check individual fields
            for field_name, patterns in DATE_FIELD_PATTERNS.items():
                if field_name in handled_fields and not is_corrigendum:
                    continue

                for pattern in patterns:
                    if pattern.search(line) or pattern.search(context_window):
                        target_date = dates_found[0][0]
                        if "end" in field_name and len(dates_found) > 1:
                            target_date = dates_found[-1][0]

                        if "application_" in field_name or "correction_" in field_name:
                            if time_str:
                                iso_val = f"{target_date.isoformat()}T{time_str}+05:30"
                            else:
                                default_time = "23:59:59" if "end" in field_name or "close" in field_name else "00:00:00"
                                iso_val = f"{target_date.isoformat()}T{default_time}+05:30"
                        else:
                            iso_val = target_date.isoformat()

                        evidences.append(ExtractedDateEvidence(
                            opportunity_id=opportunity_id,
                            date_field=field_name,
                            extracted_value=iso_val,
                            original_text=snippet,
                            source_url=source_url,
                            source_document_title=document_title or "Official Document",
                            page_number=page_number,
                            verification_status="VERIFIED",
                            is_corrigendum=is_corrigendum,
                            verified_at=now_iso,
                        ))
                        handled_fields.add(field_name)
                        break

        return evidences

    def extract_from_pdf_pages(
        self,
        pages_data: List[Dict[str, Any]],
        source_url: str,
        document_title: Optional[str] = None,
        opportunity_id: Optional[str] = None
    ) -> List[ExtractedDateEvidence]:
        """Extracts date evidence across pages, recording page numbers accurately."""
        all_evidences: List[ExtractedDateEvidence] = []
        seen_fields: set[str] = set()

        for page in pages_data:
            p_num = page.get("page_number", 1)
            p_text = page.get("text", "")
            if not p_text:
                continue

            page_evidences = self.extract_dates_from_text(
                text=p_text,
                source_url=source_url,
                document_title=document_title,
                page_number=p_num,
                opportunity_id=opportunity_id
            )

            for ev in page_evidences:
                # Corrigenda always take priority; otherwise keep first strong match
                if ev.date_field not in seen_fields or ev.is_corrigendum:
                    all_evidences.append(ev)
                    seen_fields.add(ev.date_field)

        return all_evidences


date_extractor = DateExtractor()
