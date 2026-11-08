import argparse
import asyncio
import logging
from engine.app.discovery.source_registry import get_source_by_slug, RegisteredSource
from engine.app.jobs.discovery_job import get_crawler_for_source
from engine.app.downloading.downloader import downloader
from engine.app.extraction.pdf_extractor import pdf_extractor
from engine.app.ai.cloudflare_ai import cloudflare_ai_client
from engine.app.verification.verifier import verifier

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("rexam.jobs.manual_scan")

async def scan_single_source(source_slug: str, direct_url: str = ""):
    logger.info(f"Initiating manual scan for source: '{source_slug}'...")
    source = get_source_by_slug(source_slug)

    if not source:
        if direct_url:
            source = RegisteredSource(
                id=f"manual-{source_slug}",
                organisation_name=source_slug.upper(),
                organisation_slug=source_slug,
                organisation_type="central_govt",
                category="govt_recruitment",
                url=direct_url,
                crawler_type="generic_html"
            )
        else:
            logger.error(f"Unknown source slug '{source_slug}'. Available: upsc, ssc, isro, drdo, ibps, pmrf")
            return

    crawler = get_crawler_for_source(source)
    notices = await crawler.discover_notices()
    logger.info(f"Discovered {len(notices)} notices:")
    for idx, notice in enumerate(notices, 1):
        logger.info(f"  {idx}. {notice['title']} -> PDF: {notice.get('pdf_url')}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Manual opportunity scanner for Rexam Data Engine")
    parser.add_argument("--source", type=str, default="upsc", help="Source slug (upsc, ssc, isro, drdo, ibps)")
    parser.add_argument("--url", type=str, default="", help="Direct URL to scan")
    args = parser.parse_args()

    asyncio.run(scan_single_source(args.source, args.url))

