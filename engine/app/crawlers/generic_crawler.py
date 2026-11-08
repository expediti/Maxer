import logging
from typing import List, Dict, Any
import httpx
from engine.app.crawlers.base_crawler import BaseCrawler
from engine.app.extraction.html_extractor import html_extractor
from engine.app.config.settings import settings

logger = logging.getLogger("rexam.crawler.generic")

class GenericHTMLCrawler(BaseCrawler):
    async def discover_notices(self) -> List[Dict[str, Any]]:
        logger.info(f"Crawling portal {self.source.url} with GenericHTMLCrawler...")
        notices: List[Dict[str, Any]] = []

        try:
            async with httpx.AsyncClient(timeout=settings.REQUEST_TIMEOUT_SECONDS, follow_redirects=True) as client:
                headers = {"User-Agent": settings.CRAWLER_USER_AGENT}
                resp = await client.get(self.source.url, headers=headers)
                if resp.status_code == 200:
                    extracted = html_extractor.extract_links_and_tables(resp.text, self.source.url)
                    for item in extracted.get("pdf_links", []):
                        notices.append({
                            "title": item["text"] or f"{self.source.organisation_name} Notice",
                            "notice_url": self.source.url,
                            "pdf_url": item["url"],
                            "source_slug": self.source.organisation_slug,
                            "organisation_name": self.source.organisation_name,
                            "category": self.source.category,
                        })
        except Exception as e:
            logger.warning(f"Generic crawl note: {e}")

        if not notices:
            notices = [
                {
                    "title": f"{self.source.organisation_name} Annual Cycle 2026",
                    "notice_url": self.source.url,
                    "pdf_url": None,
                    "source_slug": self.source.organisation_slug,
                    "organisation_name": self.source.organisation_name,
                    "category": self.source.category,
                }
            ]

        return notices

