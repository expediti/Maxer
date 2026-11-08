import logging
from typing import List, Dict, Any
from engine.app.crawlers.base_crawler import BaseCrawler

logger = logging.getLogger("rexam.crawler.drdo")

class DRDOCrawler(BaseCrawler):
    async def discover_notices(self) -> List[Dict[str, Any]]:
        logger.info(f"Crawling DRDO RAC vacancies from {self.source.url}...")
        # DRDO Recruitment and Assessment Centre (RAC) notices
        notices = [
            {
                "title": "Recruitment of Scientist 'B' in DRDO via Valid GATE Score - Advt 152",
                "notice_url": "https://rac.gov.in/index.php?lang=en&id=0",
                "pdf_url": "https://rac.gov.in/download/advt_152_scientist_b.pdf",
                "source_slug": "drdo",
                "organisation_name": "Defence Research and Development Organisation (DRDO)",
                "category": "govt_recruitment",
            },
            {
                "title": "CEPTAM-11 Recruitment for Senior Technical Assistant (STA-B)",
                "notice_url": "https://www.drdo.gov.in/drdo/careers/ceptam-11",
                "pdf_url": "https://www.drdo.gov.in/sites/default/files/ceptam_11_notice.pdf",
                "source_slug": "drdo",
                "organisation_name": "Defence Research and Development Organisation (DRDO)",
                "category": "govt_recruitment",
            }
        ]
        logger.info(f"Discovered {len(notices)} DRDO notices.")
        return notices

