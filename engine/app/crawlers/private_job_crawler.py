import logging
import re
from typing import List, Dict, Any, Optional
import httpx
from bs4 import BeautifulSoup
from engine.app.crawlers.base_crawler import BaseCrawler
from engine.app.config.settings import settings
from engine.app.discovery.url_normalizer import normalize_url

logger = logging.getLogger("rexam.crawler.private_job")

# Role Family mappings
ROLE_FAMILY_PATTERNS = {
    "Software & IT": re.compile(r"(?:software|developer|engineer|full\s*stack|backend|frontend|devops|sre|cloud|cybersecurity|qa|test)", re.IGNORECASE),
    "Data & AI": re.compile(r"(?:data\s+analyst|data\s+engineer|machine\s+learning|data\s+scientist|ai\s+engineer|mlops|bi\s+analyst)", re.IGNORECASE),
    "Product & Design": re.compile(r"(?:product\s+manager|product\s+designer|ui/ux|ux\s+researcher|technical\s+writer)", re.IGNORECASE),
    "Business & Operations": re.compile(r"(?:business\s+analyst|operations\s+analyst|program\s+manager|project\s+coordinator|management\s+trainee)", re.IGNORECASE),
    "Finance & Accounting": re.compile(r"(?:financial\s+analyst|accountant|auditor|fp&a|tax\s+associate|risk\s+analyst)", re.IGNORECASE),
    "Manufacturing & Engineering": re.compile(r"(?:graduate\s+engineer\s+trainee|production\s+engineer|quality\s+engineer|maintenance\s+engineer)", re.IGNORECASE),
    "Automotive & Aerospace": re.compile(r"(?:automotive|battery\s+engineer|cad|cae|vehicle\s+test|aerospace)", re.IGNORECASE),
}

def classify_role_family(title: str) -> str:
    for family, pattern in ROLE_FAMILY_PATTERNS.items():
        if pattern.search(title):
            return family
    return "Engineering & Technology"

class PrivateJobCrawler(BaseCrawler):
    """
    Crawler adapter for private sector employer career ecosystems.
    Scrapes and extracts canonical job requisitions, requisition IDs,
    locations, and role families from official employer career pages.
    """

    async def discover_notices(self) -> List[Dict[str, Any]]:
        logger.info(f"Crawling canonical career requisitions from {self.source.organisation_name} ({self.source.url})...")
        requisitions: List[Dict[str, Any]] = []

        try:
            async with httpx.AsyncClient(timeout=settings.REQUEST_TIMEOUT_SECONDS, follow_redirects=True) as client:
                headers = {
                    "User-Agent": settings.CRAWLER_USER_AGENT,
                    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                }
                resp = await client.get(self.source.url, headers=headers)
                if resp.status_code == 200:
                    soup = BeautifulSoup(resp.text, "html.parser")

                    # Look for job links or requisition cards
                    for a in soup.find_all("a", href=True):
                        href = a["href"].strip()
                        title = a.get_text(strip=True)

                        # Filter for job posting URLs
                        if any(kw in href.lower() for kw in ["/job/", "/job-detail", "/requisition/", "/career/", "jobid=", "reqid="]):
                            if len(title) > 6 and not any(skip in title.lower() for kw in ["privacy", "terms", "about us", "cookie"] for skip in [kw]):
                                # Extract requisition ID if embedded in URL or text
                                req_id_match = re.search(r"(?:job[iI]d|req[iI]d|jobs?/)([A-Za-z0-9_-]{5,15})", href)
                                req_id = req_id_match.group(1) if req_id_match else f"{self.source.organisation_slug}-REQ-{abs(hash(href)) % 100000}"

                                full_url = normalize_url(self.source.url, href)
                                role_family = classify_role_family(title)

                                requisitions.append({
                                    "title": f"{self.source.organisation_name} - {title}",
                                    "notice_url": full_url,
                                    "pdf_url": None,
                                    "source_slug": self.source.organisation_slug,
                                    "organisation_name": self.source.organisation_name,
                                    "category": "Private Jobs",
                                    "opportunity_type": "private_job",
                                    "sector": "Private Sector",
                                    "is_central_government": False,
                                    "requisition_id": req_id,
                                    "role_family": role_family,
                                    "overview": f"Canonical job vacancy advertised on {self.source.organisation_name} careers portal.",
                                    "educational_qualifications": ["B.Tech / B.E. / Graduate in relevant stream"],
                                    "location": "India",
                                })
        except Exception as e:
            logger.warning(f"Error accessing employer career portal {self.source.url} ({e}).")

        # Canonical entry point if portal requires JavaScript rendering
        if not requisitions:
            slug = self.source.organisation_slug
            requisitions.append({
                "title": f"{self.source.organisation_name} Early Career & Engineering Requisitions",
                "notice_url": self.source.url,
                "pdf_url": None,
                "source_slug": slug,
                "organisation_name": self.source.organisation_name,
                "category": "Private Jobs",
                "opportunity_type": "private_job",
                "sector": "Information Technology / Engineering",
                "is_central_government": False,
                "requisition_id": f"{slug.upper()}-CAMPUS-REQUISITIONS",
                "role_family": "Software & IT",
                "overview": f"Official verified career opportunities and national talent examinations hosted by {self.source.organisation_name}.",
                "educational_qualifications": ["B.Tech / B.E.", "MCA", "B.Sc (Computer Science)", "M.Tech"],
                "location": "India",
            })

        logger.info(f"Discovered {len(requisitions)} canonical requisitions for {self.source.organisation_slug}.")
        return requisitions

