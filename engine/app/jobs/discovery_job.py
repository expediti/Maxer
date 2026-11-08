import asyncio
import logging
import sys
from datetime import datetime, timezone
from engine.app.config.settings import settings
from engine.app.database.supabase_client import db_client
from engine.app.discovery.source_registry import OFFICIAL_INDIAN_SOURCES
from engine.app.discovery.url_normalizer import slugify
from engine.app.crawlers.upsc_crawler import UPSCCrawler
from engine.app.crawlers.ssc_crawler import SSCCrawler
from engine.app.crawlers.isro_crawler import ISROCrawler
from engine.app.crawlers.drdo_crawler import DRDOCrawler
from engine.app.crawlers.generic_crawler import GenericHTMLCrawler
from engine.app.downloading.downloader import downloader
from engine.app.extraction.pdf_extractor import pdf_extractor
from engine.app.ai.cloudflare_ai import cloudflare_ai_client
from engine.app.verification.verifier import verifier
from engine.app.matching.eligibility_engine import matcher

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("rexam.jobs.discovery")

def get_crawler_for_source(source):
    if source.crawler_type == "upsc":
        return UPSCCrawler(source)
    elif source.crawler_type == "ssc":
        return SSCCrawler(source)
    elif source.crawler_type == "isro":
        return ISROCrawler(source)
    elif source.crawler_type == "drdo":
        return DRDOCrawler(source)
    return GenericHTMLCrawler(source)

async def run_discovery_pipeline():
    logger.info("==================================================")
    logger.info("REXAM DISCOVERY & EXTRACTION PIPELINE STARTED")
    logger.info("==================================================")

    total_discovered = 0
    total_processed = 0

    for source in OFFICIAL_INDIAN_SOURCES:
        if not source.enabled:
            continue

        run_id = db_client.insert_crawler_run({
            "source_id": source.id,
            "crawler_name": f"{source.organisation_slug}_crawler",
            "status": "running",
            "started_at": datetime.now(timezone.utc).isoformat(),
        })

        try:
            crawler = get_crawler_for_source(source)
            notices = await crawler.discover_notices()
            total_discovered += len(notices)

            for notice in notices:
                title = notice.get("title", "")
                pdf_url = notice.get("pdf_url")
                notice_url = notice.get("notice_url") or source.url
                exam_slug = slugify(title)

                logger.info(f"Processing notice: '{title}' ({source.organisation_slug})")

                extracted_data = {}
                doc_hash = ""

                # Download PDF if available
                if pdf_url and pdf_url.startswith("http"):
                    download_res = await downloader.download_file(pdf_url)
                    if download_res:
                        file_path, doc_hash, _ = download_res
                        # Check deduplication
                        if db_client.is_document_processed(doc_hash):
                            logger.info(f"Document {doc_hash[:12]} already processed. Skipping duplicate extraction.")
                            continue

                        pdf_content = pdf_extractor.extract_document(file_path)
                        extracted_data = await cloudflare_ai_client.extract_examination_data(
                            pdf_content.get("text", ""),
                            {"title": title, "organisation_name": source.organisation_name}
                        )
                else:
                    # Heuristic fallback for text notices
                    extracted_data = await cloudflare_ai_client.extract_examination_data(
                        title,
                        {"title": title, "organisation_name": source.organisation_name}
                    )

                # Verification and confidence scoring
                status, uncertain_fields, verified_data = verifier.verify_examination_data(
                    extracted_data,
                    notice_url
                )

                # Upsert into database
                exam_id = db_client.upsert_examination({
                    "slug": exam_slug,
                    "title": verified_data.get("title") or title,
                    "organisation_id": None,
                    "category": source.category,
                    "status": status,
                    "vacancies": verified_data.get("vacancies"),
                    "overview": verified_data.get("overview", ""),
                    "application_url": notice_url,
                    "notification_url": pdf_url,
                    "is_confirmed": verified_data.get("is_confirmed", False),
                    "uncertain_fields": uncertain_fields,
                    "last_crawled_at": datetime.now(timezone.utc).isoformat(),
                })

                if exam_id and exam_id != "exam-mock-id":
                    # Upsert dates
                    db_client.upsert_examination_dates(exam_id, {
                        "application_opening_date": verified_data.get("application_opening_date"),
                        "application_closing_date": verified_data.get("application_closing_date"),
                        "prelims_date": verified_data.get("prelims_exam_date"),
                    })

                    # Upsert rules
                    db_client.upsert_eligibility_rules(exam_id, {
                        "min_age": verified_data.get("min_age"),
                        "max_age": verified_data.get("max_age"),
                        "min_percentage": verified_data.get("min_percentage"),
                        "eligible_streams": verified_data.get("eligible_streams", []),
                        "educational_qualifications": verified_data.get("educational_qualifications", []),
                        "fee_exemptions": verified_data.get("fee_exemptions", ""),
                    })

                    if doc_hash:
                        db_client.record_processed_document({
                            "examination_id": exam_id,
                            "sha256_hash": doc_hash,
                            "url": pdf_url,
                            "extracted_fields": verified_data,
                            "status": "success"
                        })

                total_processed += 1

                # Polite delay between items
                await asyncio.sleep(source.rate_limit_delay_seconds)

            db_client.update_crawler_run(run_id, {
                "status": "success",
                "completed_at": datetime.now(timezone.utc).isoformat(),
                "examinations_found": len(notices),
                "examinations_updated": len(notices),
            })

        except Exception as e:
            logger.error(f"Error executing crawler for {source.organisation_slug}: {e}")
            db_client.update_crawler_run(run_id, {
                "status": "failed",
                "completed_at": datetime.now(timezone.utc).isoformat(),
                "error_message": str(e),
            })

    logger.info(f"Pipeline completed: {total_discovered} notices found, {total_processed} processed.")

if __name__ == "__main__":
    asyncio.run(run_discovery_pipeline())

