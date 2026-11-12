import logging
import re
from typing import Dict, List, Any, Optional
from bs4 import BeautifulSoup
from engine.app.discovery.url_normalizer import normalize_url

logger = logging.getLogger("rexam.html_extractor")

DATE_REGEX = re.compile(
    r"\b(\d{1,2}[./-]\d{1,2}[./-]\d{2,4}|\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4})\b",
    re.IGNORECASE
)

class HTMLExtractor:
    """Extracts tables, notice links, text content, and linked PDF documents from HTML pages."""

    def extract_links_and_tables(self, html_content: str, base_url: str) -> Dict[str, Any]:
        soup = BeautifulSoup(html_content, "html.parser")

        # Extract structured notices from tables if available
        table_notices: List[Dict[str, Any]] = []
        for table in soup.find_all("table"):
            for row in table.find_all("tr"):
                # Skip header rows
                if row.find_parent("thead") or row.find_all("th") and not row.find_all("td"):
                    continue
                cols = row.find_all(["td", "th"])
                if len(cols) >= 2:
                    row_text = " ".join(c.get_text(strip=True) for c in cols)
                    if len(row_text) < 8 or any(h in row_text.lower() for h in ["sr no", "exam title", "last date", "serial no"]):
                        continue

                    # Find links in this row
                    links_in_row = row.find_all("a", href=True)
                    pdf_link = None
                    notice_link = None

                    for a in links_in_row:
                        href = a["href"].strip()
                        full = normalize_url(base_url, href)
                        if full.lower().endswith(".pdf"):
                            pdf_link = full
                        elif not notice_link and not full.startswith("javascript:"):
                            notice_link = full

                    # Look for date in row
                    date_match = DATE_REGEX.search(row_text)
                    date_found = date_match.group(1) if date_match else None

                    # Extract title: prefer description column, avoid generic button text
                    title = ""
                    for c_idx, c in enumerate(cols):
                        c_text = c.get_text(strip=True)
                        if not c_text or c_text.isdigit() or len(c_text) < 5:
                            continue
                        if not any(g in c_text.lower() for g in ["download", "click here", "view details", "advertisement", "notification", "pdf"]):
                            title = c_text
                            break
                    if not title:
                        title = cols[1].get_text(strip=True) if len(cols) > 1 else cols[0].get_text(strip=True)

                    if len(title) >= 5:
                        table_notices.append({
                            "title": title,
                            "notice_url": notice_link or base_url,
                            "pdf_url": pdf_link,
                            "date_string": date_found,
                            "raw_row_text": row_text[:300],
                        })

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
            "table_notices": table_notices,
        }

html_extractor = HTMLExtractor()
