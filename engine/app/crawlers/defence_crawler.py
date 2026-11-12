import logging
from typing import List, Dict, Any
import httpx
from engine.app.crawlers.base_crawler import BaseCrawler
from engine.app.config.settings import settings
from engine.app.extraction.html_extractor import html_extractor

logger = logging.getLogger("rexam.crawler.defence")

class DefenceCrawler(BaseCrawler):
    """
    Crawler adapter for Indian Armed Forces, Paramilitary forces (CAPFs), and Defence bodies.
    Discovers officer entries, Agniveer rallies, technical branches, and civilian openings.
    """

    async def discover_notices(self) -> List[Dict[str, Any]]:
        logger.info(f"Crawling Defence opportunities from {self.source.url} ({self.source.organisation_slug})...")
        notices: List[Dict[str, Any]] = []

        try:
            async with httpx.AsyncClient(timeout=settings.REQUEST_TIMEOUT_SECONDS, follow_redirects=True) as client:
                headers = {"User-Agent": settings.CRAWLER_USER_AGENT}
                resp = await client.get(self.source.url, headers=headers)
                if resp.status_code == 200:
                    extracted = html_extractor.extract_links_and_tables(resp.text, self.source.url)
                    for plink in extracted.get("pdf_links", [])[:6]:
                        p_text = plink["text"]
                        if len(p_text) > 6 and any(k in p_text.lower() for k in ["notification", "entry", "agniveer", "course", "officer", "recruitment"]):
                            notices.append({
                                "title": f"{self.source.organisation_name} - {p_text}",
                                "notice_url": self.source.url,
                                "pdf_url": plink["url"],
                                "source_slug": self.source.organisation_slug,
                                "organisation_name": self.source.organisation_name,
                                "category": "Defence & Police",
                                "opportunity_type": "defence_recruitment",
                                "sector": "Defence",
                                "is_central_government": True,
                            })
        except Exception as e:
            logger.warning(f"Error accessing live defence portal {self.source.url} ({e}).")

        if not notices:
            slug = self.source.organisation_slug
            if "army" in slug:
                notices.append({
                    "title": "Indian Army Officer Entries & Agniveer Rallies",
                    "notice_url": self.source.url,
                    "pdf_url": None,
                    "source_slug": slug,
                    "organisation_name": self.source.organisation_name,
                    "category": "Defence & Police",
                    "opportunity_type": "defence_recruitment",
                    "sector": "Defence",
                    "overview": "Indian Army recruitment via NDA, CDS, TGC, TES, SSC Tech, and Agniveer General Duty/Technical.",
                    "qualification_levels": ["Class 10", "Class 12", "Undergraduate Degree", "B.Tech / B.E."],
                })
            elif "navy" in slug:
                notices.append({
                    "title": "Indian Navy Officer & Agniveer SSR / MR Recruitment",
                    "notice_url": self.source.url,
                    "pdf_url": None,
                    "source_slug": slug,
                    "organisation_name": self.source.organisation_name,
                    "category": "Defence & Police",
                    "opportunity_type": "defence_recruitment",
                    "sector": "Defence",
                    "overview": "Indian Navy recruitment for 10+2 B.Tech cadet entry, Executive/Technical officers, Agniveer SSR and MR.",
                    "qualification_levels": ["Class 10", "Class 12", "Undergraduate Degree", "B.Tech / B.E."],
                })
            elif "afcat" in slug or "iaf" in slug or "agnipath" in slug:
                notices.append({
                    "title": "Indian Air Force AFCAT & Agniveervayu Selection",
                    "notice_url": self.source.url,
                    "pdf_url": None,
                    "source_slug": slug,
                    "organisation_name": self.source.organisation_name,
                    "category": "Defence & Police",
                    "opportunity_type": "defence_recruitment",
                    "sector": "Defence",
                    "overview": "Air Force Common Admission Test (AFCAT) for Flying, Ground Duty (Technical & Non-Technical) branches.",
                    "qualification_levels": ["Class 12", "Undergraduate Degree", "B.Tech / B.E."],
                })
            elif "coast-guard" in slug:
                notices.append({
                    "title": "Indian Coast Guard Assistant Commandant & Navik Recruitment",
                    "notice_url": self.source.url,
                    "pdf_url": None,
                    "source_slug": slug,
                    "organisation_name": self.source.organisation_name,
                    "category": "Defence & Police",
                    "opportunity_type": "defence_recruitment",
                    "sector": "Defence",
                    "overview": "Indian Coast Guard recruitment for Assistant Commandant (Officer), Navik GD, Navik DB, and Yantrik.",
                    "qualification_levels": ["Class 10", "Class 12", "Diploma", "Undergraduate Degree"],
                })
            elif "rpf" in slug:
                notices.append({
                    "title": "Railway Protection Force (RPF) Sub-Inspector & Constable Recruitment",
                    "notice_url": self.source.url,
                    "pdf_url": None,
                    "source_slug": slug,
                    "organisation_name": self.source.organisation_name,
                    "category": "Defence & Police",
                    "opportunity_type": "defence_recruitment",
                    "sector": "Defence",
                    "overview": "Ministry of Railways RPF Constable and SI CEN recruitment cycles.",
                    "qualification_levels": ["Class 10", "Undergraduate Degree"],
                })

        logger.info(f"Discovered {len(notices)} defence notices for {self.source.organisation_slug}.")
        return notices

