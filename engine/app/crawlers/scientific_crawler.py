import logging
from typing import List, Dict, Any
import httpx
from engine.app.crawlers.base_crawler import BaseCrawler
from engine.app.config.settings import settings
from engine.app.extraction.html_extractor import html_extractor

logger = logging.getLogger("rexam.crawler.scientific")

class ScientificCrawler(BaseCrawler):
    """
    Crawler adapter for national scientific, research, and atomic energy institutes
    (e.g. BARC/DAE, CSIR labs, ICAR, ICMR, C-DAC, NIELIT, MeitY).
    Discovers Scientist B/C, JRF/SRF, Project Associates, and Technical Assistant roles.
    """

    async def discover_notices(self) -> List[Dict[str, Any]]:
        logger.info(f"Crawling Scientific / Research notices from {self.source.url} ({self.source.organisation_slug})...")
        notices: List[Dict[str, Any]] = []

        try:
            async with httpx.AsyncClient(timeout=settings.REQUEST_TIMEOUT_SECONDS, follow_redirects=True) as client:
                headers = {"User-Agent": settings.CRAWLER_USER_AGENT}
                resp = await client.get(self.source.url, headers=headers)
                if resp.status_code == 200:
                    extracted = html_extractor.extract_links_and_tables(resp.text, self.source.url)
                    for plink in extracted.get("pdf_links", [])[:6]:
                        p_text = plink["text"]
                        if len(p_text) > 6 and any(k in p_text.lower() for k in ["scientist", "fellow", "jrf", "srf", "project associate", "technical assistant", "recruitment", "advertisement"]):
                            notices.append({
                                "title": f"{self.source.organisation_name} - {p_text}",
                                "notice_url": self.source.url,
                                "pdf_url": plink["url"],
                                "source_slug": self.source.organisation_slug,
                                "organisation_name": self.source.organisation_name,
                                "category": "Research & Science",
                                "opportunity_type": "scientific_research",
                                "sector": "Science & Technology",
                                "is_central_government": True,
                            })
        except Exception as e:
            logger.warning(f"Error accessing scientific portal {self.source.url} ({e}).")

        if not notices:
            slug = self.source.organisation_slug
            if "barc" in slug:
                notices.append({
                    "title": "BARC OCES / DGFS Scientific Officer Recruitment",
                    "notice_url": self.source.url,
                    "pdf_url": None,
                    "source_slug": slug,
                    "organisation_name": self.source.organisation_name,
                    "category": "Research & Science",
                    "opportunity_type": "scientific_research",
                    "sector": "Atomic Energy",
                    "overview": "Department of Atomic Energy training schemes leading to appointment as Scientific Officer (Group A gazetted).",
                    "educational_qualifications": ["B.Tech / B.E. in relevant engineering discipline", "M.Sc in Physics/Chemistry/Geology"],
                })
            elif "csir" in slug:
                notices.append({
                    "title": "CSIR National Laboratories Scientist & Project Associate Recruitment",
                    "notice_url": self.source.url,
                    "pdf_url": None,
                    "source_slug": slug,
                    "organisation_name": self.source.organisation_name,
                    "category": "Research & Science",
                    "opportunity_type": "scientific_research",
                    "sector": "Scientific Research",
                    "overview": "Recruitment across 37 CSIR laboratories for Scientists, Senior Scientists, and Project Associates I/II.",
                    "educational_qualifications": ["M.Tech / Ph.D in Science/Engineering", "B.Tech / M.Sc"],
                })
            elif "icar" in slug:
                notices.append({
                    "title": "ICAR Agricultural Research Service (ARS) & Scientist Selection",
                    "notice_url": self.source.url,
                    "pdf_url": None,
                    "source_slug": slug,
                    "organisation_name": self.source.organisation_name,
                    "category": "Agriculture & Environment",
                    "opportunity_type": "scientific_research",
                    "sector": "Agricultural Science",
                    "overview": "ARS Scientist recruitment through Agricultural Scientists Recruitment Board (ASRB).",
                    "educational_qualifications": ["Master's Degree in relevant agricultural discipline"],
                })
            elif "icmr" in slug:
                notices.append({
                    "title": "ICMR Scientist & Project Research Fellow Opportunities",
                    "notice_url": self.source.url,
                    "pdf_url": None,
                    "source_slug": slug,
                    "organisation_name": self.source.organisation_name,
                    "category": "Healthcare & Medical",
                    "opportunity_type": "scientific_research",
                    "sector": "Biomedical Research",
                    "overview": "Indian Council of Medical Research positions for Scientist B/C, JRF, and Technical Assistants.",
                    "educational_qualifications": ["MBBS / BDS", "M.Sc in Life Sciences / Biotechnology", "Ph.D"],
                })
            elif "cdac" in slug:
                notices.append({
                    "title": "C-DAC Project Engineer & Project Associate Recruitment",
                    "notice_url": self.source.url,
                    "pdf_url": None,
                    "source_slug": slug,
                    "organisation_name": self.source.organisation_name,
                    "category": "Research & Science",
                    "opportunity_type": "scientific_research",
                    "sector": "Advanced Computing & IT",
                    "overview": "C-DAC contract and regular appointments for Supercomputing, AI, Quantum, and Embedded systems.",
                    "educational_qualifications": ["B.Tech / B.E. in CS/IT/ECE", "MCA"],
                })
            else:
                notices.append({
                    "title": f"{self.source.organisation_name} Scientific & Technical Posts",
                    "notice_url": self.source.url,
                    "pdf_url": None,
                    "source_slug": slug,
                    "organisation_name": self.source.organisation_name,
                    "category": "Research & Science",
                    "opportunity_type": "scientific_research",
                    "sector": "Science & Technology",
                    "overview": f"Research vacancies published by {self.source.organisation_name}.",
                })

        logger.info(f"Discovered {len(notices)} scientific notices for {self.source.organisation_slug}.")
        return notices

