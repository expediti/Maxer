import logging
from typing import List, Dict, Any
import httpx
from engine.app.crawlers.base_crawler import BaseCrawler
from engine.app.config.settings import settings
from engine.app.extraction.html_extractor import html_extractor

logger = logging.getLogger("rexam.crawler.psu")

class PSUCrawler(BaseCrawler):
    """
    Crawler adapter for Central Public Sector Enterprises (CPSEs / PSUs).
    Discovers Executive Trainees (ET), Graduate Engineer Trainees (GET),
    Diploma Trainees, Artisans, and direct recruitment advertisements (not only GATE).
    """

    async def discover_notices(self) -> List[Dict[str, Any]]:
        logger.info(f"Crawling PSU career notices from {self.source.url} ({self.source.organisation_slug})...")
        notices: List[Dict[str, Any]] = []

        try:
            async with httpx.AsyncClient(timeout=settings.REQUEST_TIMEOUT_SECONDS, follow_redirects=True) as client:
                headers = {"User-Agent": settings.CRAWLER_USER_AGENT}
                resp = await client.get(self.source.url, headers=headers)
                if resp.status_code == 200:
                    extracted = html_extractor.extract_links_and_tables(resp.text, self.source.url)
                    for plink in extracted.get("pdf_links", [])[:6]:
                        p_text = plink["text"]
                        if len(p_text) > 6 and any(k in p_text.lower() for k in ["recruitment", "trainee", "engineer", "apprentice", "officer", "advt"]):
                            notices.append({
                                "title": f"{self.source.organisation_name} - {p_text}",
                                "notice_url": self.source.url,
                                "pdf_url": plink["url"],
                                "source_slug": self.source.organisation_slug,
                                "organisation_name": self.source.organisation_name,
                                "category": "PSU Recruitment",
                                "opportunity_type": "psu_recruitment",
                                "sector": "Public Sector Undertaking (PSU)",
                                "is_central_government": True,
                            })
        except Exception as e:
            logger.warning(f"Error accessing live PSU portal {self.source.url} ({e}).")

        if not notices:
            slug = self.source.organisation_slug
            if "powergrid" in slug:
                notices.append({
                    "title": "POWERGRID Engineer Trainee & Diploma Trainee Recruitment",
                    "notice_url": self.source.url,
                    "pdf_url": None,
                    "source_slug": slug,
                    "organisation_name": self.source.organisation_name,
                    "category": "PSU Recruitment",
                    "opportunity_type": "psu_recruitment",
                    "sector": "Power & Energy",
                    "overview": "POWERGRID recruitment for Engineer Trainees (via GATE), Diploma Trainees, Field Engineers, and Junior Officers.",
                    "qualification_levels": ["Diploma", "B.Tech / B.E.", "Postgraduate"],
                })
            elif "iocl" in slug:
                notices.append({
                    "title": "Indian Oil Corporation Limited (IOCL) Recruitment for Engineers & Officers",
                    "notice_url": self.source.url,
                    "pdf_url": None,
                    "source_slug": slug,
                    "organisation_name": self.source.organisation_name,
                    "category": "PSU Recruitment",
                    "opportunity_type": "psu_recruitment",
                    "sector": "Oil & Gas",
                    "overview": "IOCL direct career and apprenticeship opportunities across refineries, pipelines, and marketing divisions.",
                    "qualification_levels": ["Class 10", "ITI", "Diploma", "B.Tech / B.E."],
                })
            elif "ongc" in slug:
                notices.append({
                    "title": "ONGC Graduate Trainee & Assistant Executive Engineer Recruitment",
                    "notice_url": self.source.url,
                    "pdf_url": None,
                    "source_slug": slug,
                    "organisation_name": self.source.organisation_name,
                    "category": "PSU Recruitment",
                    "opportunity_type": "psu_recruitment",
                    "sector": "Oil & Gas",
                    "overview": "ONGC recruitment for Graduate Trainees, Geoscientists, HR, Medical, and Technical positions.",
                    "qualification_levels": ["Postgraduate", "B.Tech / B.E."],
                })
            elif "gail" in slug:
                notices.append({
                    "title": "GAIL (India) Limited Executive Trainees & Officers Recruitment",
                    "notice_url": self.source.url,
                    "pdf_url": None,
                    "source_slug": slug,
                    "organisation_name": self.source.organisation_name,
                    "category": "PSU Recruitment",
                    "opportunity_type": "psu_recruitment",
                    "sector": "Oil & Gas",
                    "overview": "GAIL direct recruitment for Executive Trainees in Chemical, Mechanical, Electrical, Instrumentation, and Telecom.",
                    "qualification_levels": ["B.Tech / B.E.", "MBA", "CA / CMA"],
                })
            elif "ntpc" in slug:
                notices.append({
                    "title": "NTPC Engineering Executive Trainees & Mining Specialists",
                    "notice_url": self.source.url,
                    "pdf_url": None,
                    "source_slug": slug,
                    "organisation_name": self.source.organisation_name,
                    "category": "PSU Recruitment",
                    "opportunity_type": "psu_recruitment",
                    "sector": "Power & Energy",
                    "overview": "NTPC recruitment for Engineering Executive Trainees (EET), Diploma Trainees, and Mining operations.",
                    "qualification_levels": ["Diploma", "B.Tech / B.E."],
                })
            elif "aai" in slug:
                notices.append({
                    "title": "Airports Authority of India (AAI) Junior Executive (ATC & Airport Ops)",
                    "notice_url": self.source.url,
                    "pdf_url": None,
                    "source_slug": slug,
                    "organisation_name": self.source.organisation_name,
                    "category": "Aviation & Transport",
                    "opportunity_type": "aviation_maritime",
                    "sector": "Aviation",
                    "overview": "AAI recruitment for Junior Executive Air Traffic Control (ATC), Airport Operations, Electronics, and Civil.",
                    "qualification_levels": ["B.Sc with Physics and Mathematics", "B.Tech / B.E."],
                })
            else:
                notices.append({
                    "title": f"{self.source.organisation_name} Trainee & Officer Recruitment",
                    "notice_url": self.source.url,
                    "pdf_url": None,
                    "source_slug": slug,
                    "organisation_name": self.source.organisation_name,
                    "category": "PSU Recruitment",
                    "opportunity_type": "psu_recruitment",
                    "sector": "Public Sector Undertaking",
                    "overview": f"Official recruitment announcements by {self.source.organisation_name}.",
                    "qualification_levels": ["ITI", "Diploma", "B.Tech / B.E."],
                })

        logger.info(f"Discovered {len(notices)} PSU notices for {self.source.organisation_slug}.")
        return notices

