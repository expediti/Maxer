import logging
from typing import Dict, List, Any
from bs4 import BeautifulSoup
from engine.app.discovery.url_normalizer import normalize_url

logger = logging.getLogger("rexam.html_extractor")

class HTMLExtractor:
    """Extracts tables, notice links, text content, and linked PDF documents from HTML pages."""

    def extract_links_and_tables(self, html_content: str, base_url: str) -> Dict[str, Any]:
        soup = BeautifulSoup(html_content, "html.parser")

        # Extract all hyperlinks
        links: List[Dict[str, str]] = []
        pdf_links: List[Dict[str, str]] = []

        for a in soup.find_all("a", href=True):
            href = a["href"].strip()
            text = a.get_text(strip=True)
            if not href or href.startswith("javascript:") or href.startswith("#"):
                continue

            full_url = normalize_url(base_url, href)
            link_entry = {"text": text, "url": full_url}

            if full_url.lower().endswith(".pdf") or "download" in full_url.lower() or "pdf" in text.lower():
                pdf_links.append(link_entry)
            else:
                links.append(link_entry)

        # Extract text content
        for script_or_style in soup(["script", "style", "noscript", "header", "footer", "nav"]):
            script_or_style.extract()

        clean_text = soup.get_text(separator="\n", strip=True)

        return {
            "title": soup.title.string.strip() if soup.title and soup.title.string else "",
            "clean_text": clean_text,
            "all_links": links,
            "pdf_links": pdf_links,
        }

html_extractor = HTMLExtractor()

