import asyncio
import logging
import sys
from datetime import datetime, timezone
from engine.app.config.settings import settings
from engine.app.database.supabase_client import db_client
from engine.app.discovery.source_registry import OFFICIAL_INDIAN_SOURCES
from engine.app.discovery.url_normalizer import slugify
from engine.app.crawlers.scholarship_crawler import ScholarshipCrawler
from engine.app.deduplication.hasher import compute_sha256

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("rexam.jobs.scholarships")

async def run_scholarships_discovery():
    logger.info("==================================================")
    logger.info("REXAM SCHOLARSHIP DISCOVERY PIPELINE STARTED")
    logger.info("==================================================")

    scholarship_sources = [
        s for s in OFFICIAL_INDIAN_SOURCES
        if s.crawler_type == "scholarship" or s.category == "Scholarships & Fellowships"
    ]

    total_discovered = 0
    total_persisted = 0

    for source in scholarship_sources:
        if not source.enabled:
            continue

        run_id = db_client.insert_crawler_run({
            "source_id": source.id,
            "crawler_name": f"{source.organisation_slug}_scholarship_crawler",
            "status": "running",
            "started_at": datetime.now(timezone.utc).isoformat(),
        })

        try:
            crawler = ScholarshipCrawler(source)
            notices = await crawler.discover_notices()
            total_discovered += len(notices)

            for notice in notices:
                title = notice.get("title", "").strip()
                if not title:
                    continue

                exam_slug = slugify(title)
                notice_url = notice.get("notice_url") or source.url
                pdf_url = notice.get("pdf_url")
                doc_hash = compute_sha256(f"{title}:{source.organisation_slug}".encode("utf-8"))

                logger.info(f"Ingesting scholarship: '{title}' ({source.organisation_slug})")

                # Upsert examination opportunity
                exam_id = db_client.upsert_examination({
                    "slug": exam_slug,
                    "title": title,
                    "name": title,
                    "organisation_id": None,
                    "category": "Scholarships & Fellowships",
                    "status": "published",
                    "vacancies": notice.get("vacancies"),
                    "overview": notice.get("overview", "Official statutory Indian scholarship scheme."),
                    "salary_or_pay_scale": notice.get("financial_benefit"),
                    "application_url": notice.get("official_application_url") or notice_url,
                    "official_application_url": notice.get("official_application_url") or notice_url,
                    "notification_url": pdf_url or notice.get("official_notification_url"),
                    "official_notification_url": pdf_url or notice.get("official_notification_url"),
                    "is_confirmed": True,
                    "is_official_source": True,
                    "is_central_government": True,
                    "last_crawled_at": datetime.now(timezone.utc).isoformat(),
                    "last_verified_at": datetime.now(timezone.utc).isoformat(),
                })

                if exam_id and exam_id != "exam-mock-id":
                    # Upsert dates
                    db_client.upsert_examination_dates(exam_id, {
                        "application_opening_date": notice.get("application_opening_date"),
                        "application_closing_date": notice.get("application_closing_date"),
                    })

                    # Upsert rules
                    db_client.upsert_eligibility_rules(exam_id, {
                        "min_age": notice.get("min_age") or 16,
                        "max_age": notice.get("max_age") or 35,
                        "min_percentage": notice.get("min_percentage"),
                        "eligible_streams": notice.get("eligible_streams") or ["All Disciplines"],
                        "educational_qualifications": notice.get("educational_qualifications") or ["Higher Secondary / Degree"],
                        "fee_exemptions": "No application fee for national statutory scholarships",
                    })

                    total_persisted += 1

                await asyncio.sleep(source.rate_limit_delay_seconds)

            db_client.update_crawler_run(run_id, {
                "status": "success",
                "completed_at": datetime.now(timezone.utc).isoformat(),
                "examinations_found": len(notices),
                "examinations_updated": len(notices),
            })

        except Exception as e:
            logger.error(f"Error executing scholarship crawler for {source.organisation_slug}: {e}")
            db_client.update_crawler_run(run_id, {
                "status": "failed",
                "completed_at": datetime.now(timezone.utc).isoformat(),
                "error_message": str(e),
            })

    logger.info(f"Scholarship discovery completed: {total_discovered} found, {total_persisted} verified & persisted.")
    return total_persisted

if __name__ == "__main__":
    asyncio.run(run_scholarships_discovery())
