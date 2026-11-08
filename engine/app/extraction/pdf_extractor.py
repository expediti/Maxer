import logging
from typing import Dict, List, Any, Optional
from pathlib import Path

logger = logging.getLogger("rexam.pdf_extractor")

class PDFExtractor:
    """Extracts text, metadata, and structural sections from official recruitment PDF notices using PyMuPDF."""

    def extract_document(self, file_path: str) -> Dict[str, Any]:
        path = Path(file_path)
        if not path.exists():
            raise FileNotFoundError(f"PDF file not found: {file_path}")

        try:
            import fitz  # PyMuPDF
        except ImportError:
            logger.error("PyMuPDF (fitz) is not installed.")
            return {"total_pages": 0, "text": "", "pages": [], "metadata": {}}

        doc = fitz.open(file_path)
        total_pages = len(doc)
        pages_data: List[Dict[str, Any]] = []
        full_text_parts: List[str] = []

        for page_idx in range(total_pages):
            page = doc[page_idx]
            page_text = page.get_text("text").strip()
            pages_data.append({
                "page_number": page_idx + 1,
                "text": page_text,
                "char_count": len(page_text)
            })
            if page_text:
                full_text_parts.append(f"--- PAGE {page_idx + 1} ---\n{page_text}")

        meta = doc.metadata or {}
        doc.close()

        combined_text = "\n\n".join(full_text_parts)
        logger.info(f"Extracted {total_pages} pages ({len(combined_text)} characters) from {path.name}")

        return {
            "total_pages": total_pages,
            "text": combined_text,
            "pages": pages_data,
            "metadata": {
                "title": meta.get("title", ""),
                "author": meta.get("author", ""),
                "creation_date": meta.get("creationDate", ""),
            }
        }

pdf_extractor = PDFExtractor()

