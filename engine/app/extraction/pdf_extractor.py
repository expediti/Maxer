import logging
import re
from typing import Dict, List, Any, Optional
from pathlib import Path

logger = logging.getLogger("rexam.pdf_extractor")

SECTION_PATTERNS = {
    "vacancies": re.compile(r"(?:details\s+of\s+vacancies|break-?up\s+of\s+vacancies|total\s+vacancies|number\s+of\s+posts|vacancy\s+position)", re.IGNORECASE),
    "eligibility": re.compile(r"(?:essential\s+qualifications?|minimum\s+educational\s+qualification|eligibility\s+criteria|prescribed\s+qualifications?)", re.IGNORECASE),
    "age_limit": re.compile(r"(?:age\s+limit|age\s+criteria|relaxation\s+in\s+upper\s+age|crucial\s+date\s+for\s+age)", re.IGNORECASE),
    "application_fee": re.compile(r"(?:application\s+fee|examination\s+fee|mode\s+of\s+payment|fee\s+payable|fee\s+concession|fee\s+exemption)", re.IGNORECASE),
    "selection_process": re.compile(r"(?:scheme\s+of\s+examination|selection\s+process|mode\s+of\s+selection|stages\s+of\s+exam)", re.IGNORECASE),
    "important_dates": re.compile(r"(?:important\s+dates|tentative\s+schedule|schedule\s+of\s+examination|last\s+date\s+for\s+submission)", re.IGNORECASE),
    "corrigendum": re.compile(r"(?:corrigendum|addendum|cancellation\s+notice|extension\s+of\s+last\s+date)", re.IGNORECASE),
}

class PDFExtractor:
    """
    Extracts text, structured sections, multi-post vacancy tables, and eligibility evidence
    from official recruitment notifications using PyMuPDF.
    """

    def extract_document(self, file_path: str) -> Dict[str, Any]:
        path = Path(file_path)
        if not path.exists():
            raise FileNotFoundError(f"PDF file not found: {file_path}")

        try:
            import fitz  # PyMuPDF
        except ImportError:
            logger.error("PyMuPDF (fitz) is not installed.")
            return {"total_pages": 0, "text": "", "pages": [], "metadata": {}, "sections": {}, "tables": []}

        doc = fitz.open(file_path)
        total_pages = len(doc)
        pages_data: List[Dict[str, Any]] = []
        full_text_parts: List[str] = []
        extracted_tables: List[Dict[str, Any]] = []
        identified_sections: Dict[str, List[Dict[str, Any]]] = {k: [] for k in SECTION_PATTERNS}

        for page_idx in range(total_pages):
            page = doc[page_idx]
            page_text = page.get_text("text").strip()
            page_num = page_idx + 1

            pages_data.append({
                "page_number": page_num,
                "text": page_text,
                "char_count": len(page_text)
            })

            if page_text:
                full_text_parts.append(f"--- PAGE {page_num} ---\n{page_text}")

                # Detect key sections on this page
                for sec_name, pattern in SECTION_PATTERNS.items():
                    matches = list(pattern.finditer(page_text))
                    if matches:
                        for m in matches:
                            snippet_start = max(0, m.start() - 50)
                            snippet_end = min(len(page_text), m.end() + 500)
                            identified_sections[sec_name].append({
                                "page_number": page_num,
                                "match": m.group(0),
                                "snippet": page_text[snippet_start:snippet_end].strip()
                            })

            # Extract tables if available in PyMuPDF version
            try:
                tables = page.find_tables()
                if tables and tables.tables:
                    for t_idx, tbl in enumerate(tables):
                        extracted_table = tbl.extract()
                        if extracted_table and len(extracted_table) > 1:
                            extracted_tables.append({
                                "page_number": page_num,
                                "table_index": t_idx,
                                "headers": extracted_table[0] if extracted_table else [],
                                "rows": extracted_table[1:] if len(extracted_table) > 1 else [],
                            })
            except Exception as e:
                logger.debug(f"Table extraction skipped on page {page_num}: {e}")

        meta = doc.metadata or {}
        doc.close()

        combined_text = "\n\n".join(full_text_parts)
        logger.info(
            f"Extracted {total_pages} pages ({len(combined_text)} characters), "
            f"{len(extracted_tables)} tables from {path.name}"
        )

        return {
            "total_pages": total_pages,
            "text": combined_text,
            "pages": pages_data,
            "sections": identified_sections,
            "tables": extracted_tables,
            "metadata": {
                "title": meta.get("title", ""),
                "author": meta.get("author", ""),
                "creation_date": meta.get("creationDate", ""),
            }
        }

    def find_evidence_snippet(self, extracted_doc: Dict[str, Any], keyword: str, max_chars: int = 400) -> Optional[Dict[str, Any]]:
        """Finds the most relevant evidence snippet and page number for a given keyword."""
        kw_lower = keyword.lower()
        for page in extracted_doc.get("pages", []):
            page_text = page.get("text", "")
            idx = page_text.lower().find(kw_lower)
            if idx != -1:
                start = max(0, idx - 100)
                end = min(len(page_text), idx + max_chars)
                return {
                    "page_number": page.get("page_number", 1),
                    "evidence_text": page_text[start:end].strip(),
                    "confidence": 0.95,
                }
        return None

pdf_extractor = PDFExtractor()
