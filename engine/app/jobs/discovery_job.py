import asyncio
import logging
import sys
import argparse
import json
from pathlib import Path
from datetime import datetime, timezone
from typing import List, Dict, Any, Optional

from engine.app.config.settings import settings
from engine.app.database.supabase_client import db_client
from engine.app.discovery.source_registry import (
    OFFICIAL_INDIAN_SOURCES,
    RegisteredSource,
    get_all_sources,
    get_source_by_slug,
    get_sources_by_category,
)
from engine.app.discovery.url_normalizer import slugify
from engine.app.crawlers.upsc_crawler import UPSCCrawler
from engine.app.crawlers.ssc_crawler import SSCCrawler
from engine.app.crawlers.isro_crawler import ISROCrawler
from engine.app.crawlers.drdo_crawler import DRDOCrawler
from engine.app.crawlers.scholarship_crawler import ScholarshipCrawler
from engine.app.crawlers.state_psc_crawler import StatePSCCrawler
from engine.app.crawlers.central_govt_crawler import CentralGovtCrawler
from engine.app.crawlers.defence_crawler import DefenceCrawler
from engine.app.crawlers.psu_crawler import PSUCrawler
from engine.app.crawlers.scientific_crawler import ScientificCrawler
from engine.app.crawlers.private_job_crawler import PrivateJobCrawler
from engine.app.crawlers.admission_crawler import AdmissionLicensingCrawler
from engine.app.crawlers.apprenticeship_crawler import ApprenticeshipInternshipCrawler
from engine.app.crawlers.healthcare_crawler import HealthcareCrawler
from engine.app.crawlers.generic_crawler import GenericHTMLCrawler
from engine.app.downloading.downloader import downloader
from engine.app.extraction.pdf_extractor import pdf_extractor
from engine.app.ai.cloudflare_ai import cloudflare_ai_client
from engine.app.verification.verifier import verifier
from engine.app.verification.url_validator import url_validator
from engine.app.verification.change_detector import change_detector
from engine.app.monitoring.health_monitor import health_monitor

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("rexam.jobs.discovery")

CHECKPOINT_FILE = Path("/tmp/rexam_discovery_checkpoint.json")

def get_crawler_for_source(source: RegisteredSource):
    adapter = source.crawler_adapter.lower()
    if adapter == "upsc":
        return UPSCCrawler(source)
    elif adapter == "ssc":
        return SSCCrawler(source)
    elif adapter == "isro":
        return ISROCrawler(source)
    elif adapter == "drdo":
        return DRDOCrawler(source)
    elif adapter == "scholarship":
        return ScholarshipCrawler(source)
    elif adapter == "state_psc":
        return StatePSCCrawler(source)
    elif adapter == "central_govt":
        return CentralGovtCrawler(source)
    elif adapter == "defence":
        return DefenceCrawler(source)
    elif adapter == "psu":
        return PSUCrawler(source)
    elif adapter == "scientific":
        return ScientificCrawler(source)
    elif adapter == "private_job":
        return PrivateJobCrawler(source)
    elif adapter == "admission":
        return AdmissionLicensingCrawler(source)
    elif adapter in ("apprenticeship", "internship"):
        return ApprenticeshipInternshipCrawler(source)
    elif adapter == "healthcare":
        return HealthcareCrawler(source)
    return GenericHTMLCrawler(source)

def load_checkpoint() -> set:
    if CHECKPOINT_FILE.exists():
        try:
            data = json.loads(CHECKPOINT_FILE.read_text())
            return set(data.get("completed_sources", []))
        except Exception:
            return set()
    return set()

def save_checkpoint(completed: set):
    try:
        CHECKPOINT_FILE.write_text(json.dumps({"completed_sources": list(completed)}))
    except Exception as e:
        logger.debug(f"Failed to save checkpoint: {e}")

async def run_discovery_pipeline(
    category_filter: Optional[str] = None,
    source_filter: Optional[str] = None,
    limit: Optional[int] = None,
    force_rescan: bool = False,
    is_initial_full_run: bool = False,
):
    logger.info("================================================================================")
    logger.info("REXAM COMPLETE OPPORTUNITY DISCOVERY & DAILY VERIFICATION ENGINE")
    logger.info(f"Start Time (UTC): {datetime.now(timezone.utc).isoformat()}")
    logger.info("================================================================================")

    # 1. Filter sources
    sources: List[RegisteredSource] = []
    if source_filter:
        s = get_source_by_slug(source_filter)
        if s:
            sources = [s]
        else:
            logger.error(f"Source with slug/id '{source_filter}' not found in registry.")
            return
    elif category_filter:
        sources = get_sources_by_category(category_filter)
    else:
        sources = get_all_sources(enabled_only=True)

    if limit and limit > 0:
        sources = sources[:limit]

    logger.info(f"Targeting {len(sources)} registered official source(s).")

    completed_checkpoint = set() if force_rescan else load_checkpoint()
    total_discovered = 0
    total_processed = 0
    total_changes_detected = 0

    for idx, source in enumerate(sources, 1):
        if source.organisation_slug in completed_checkpoint and not force_rescan and not is_initial_full_run:
            logger.info(f"[{idx}/{len(sources)}] Source {source.organisation_slug} already in checkpoint. Skipping.")
            continue

        logger.info(f"[{idx}/{len(sources)}] >>> Scanning {source.source_name} ({source.organisation_slug})...")

        # Telemetry start
        metric = health_monitor.start_crawl(
            source_id=source.id,
            slug=source.organisation_slug,
            name=source.source_name,
            category=source.source_category,
        )

        run_id = db_client.insert_crawler_run({
            "source_id": source.id,
            "crawler_name": f"{source.organisation_slug}_crawler",
            "source_name": source.source_name,
            "status": "running",
            "started_at": datetime.now(timezone.utc).isoformat(),
        })

        notices: List[Dict[str, Any]] = []
        try:
            crawler = get_crawler_for_source(source)
            notices = await crawler.discover_notices()
            metric.opportunities_discovered = len(notices)
            metric.pages_discovered = 1
            total_discovered += len(notices)

            for notice in notices:
                title = notice.get("title", "").strip()
                if not title:
                    continue

                pdf_url = notice.get("pdf_url")
                notice_url = notice.get("notice_url") or source.url
                exam_slug = slugify(title)

                # Fetch previous record to support change detection
                prev_record = db_client.get_examination_by_slug(exam_slug)

                extracted_data: Dict[str, Any] = {}
                doc_hash = ""

                # Download PDF if available
                if pdf_url and pdf_url.startswith("http"):
                    download_res = await downloader.download_file(pdf_url)
                    if download_res:
                        file_path, doc_hash, _ = download_res
                        metric.documents_downloaded += 1

                        if not force_rescan and db_client.is_document_processed(doc_hash):
                            metric.duplicates_skipped += 1
                            logger.info(f"Document {doc_hash[:12]} already processed. Skipping duplicate.")
                            continue

                        pdf_content = pdf_extractor.extract_document(file_path)
                        extracted_data = await cloudflare_ai_client.extract_examination_data(
                            pdf_content.get("text", "")[:8000],
                            {"title": title, "organisation_name": source.organisation_name}
                        )
                else:
                    extracted_data = await cloudflare_ai_client.extract_examination_data(
                        title,
                        {"title": title, "organisation_name": source.organisation_name}
                    )

                # Verification & Provenance Scoring across 5 stages with 28-field evidence
                status_str, verification_tier, uncertain_fields, verified_data, field_evidences = verifier.verify_opportunity_record(
                    extracted_data,
                    source_url=notice_url,
                    document_url=pdf_url,
                    existing_record=prev_record,
                )

                # Validate application URL with URLValidator
                app_url_res = await url_validator.validate_url_async(notice_url)
                db_client.upsert_url_validation(app_url_res.to_dict())

                notif_url_res = None
                if pdf_url and pdf_url.startswith("http"):
                    notif_url_res = await url_validator.validate_url_async(pdf_url)
                    db_client.upsert_url_validation(notif_url_res.to_dict())

                # Merge attributes from structured crawler
                final_overview = notice.get("overview") or verified_data.get("overview") or ""
                final_salary = notice.get("financial_benefit") or notice.get("salary_or_pay_scale") or verified_data.get("salary_or_pay_scale")
                final_stipend = notice.get("stipend") or notice.get("financial_benefit")
                final_opening = notice.get("application_opening_date") or verified_data.get("application_opening_date")
                final_closing = notice.get("application_closing_date") or verified_data.get("application_closing_date")
                final_exam_date = notice.get("examination_date") or verified_data.get("examination_date") or verified_data.get("prelims_exam_date")
                final_min_age = notice.get("min_age") or verified_data.get("min_age")
                final_max_age = notice.get("max_age") or verified_data.get("max_age")
                final_min_perc = notice.get("min_percentage") or verified_data.get("min_percentage")
                final_min_cgpa = notice.get("min_cgpa") or verified_data.get("min_cgpa")
                final_grading_type = notice.get("grading_type") or verified_data.get("grading_type", "percentage")
                final_streams = notice.get("eligible_streams") or verified_data.get("eligible_streams") or []
                final_quals = notice.get("educational_qualifications") or notice.get("qualification_levels") or verified_data.get("educational_qualifications") or []
                final_vacancies = notice.get("vacancies") or verified_data.get("vacancies")
                opportunity_type = notice.get("opportunity_type") or "recruitment_examination"
                sector = notice.get("sector") or source.source_category

                # Detect changes if record already existed
                new_record_for_diff = {
                    "application_closing_date": final_closing,
                    "application_opening_date": final_opening,
                    "examination_date": final_exam_date,
                    "vacancies": final_vacancies,
                    "minimum_age": final_min_age,
                    "maximum_age": final_max_age,
                    "application_fee": verified_data.get("application_fee"),
                    "status": status_str,
                    "official_source_url": notice_url,
                }
                detected_changes = change_detector.detect_changes(prev_record, new_record_for_diff, pdf_url)
                if detected_changes:
                    total_changes_detected += len(detected_changes)
                    logger.info(f"Detected {len(detected_changes)} change(s) in {title}")

                # Upsert into examinations table
                exam_payload = {
                    "slug": exam_slug,
                    "title": verified_data.get("title") or title,
                    "name": verified_data.get("title") or title,
                    "category": source.category,
                    "opportunity_type": opportunity_type,
                    "sector": sector,
                    "state": notice.get("state") or source.state,
                    "location": notice.get("location", "All India"),
                    "is_central_government": notice.get("is_central_government", True),
                    "status": verified_data.get("status", "published"),
                    "verification_status": status_str,
                    "verification_tier": verification_tier,
                    "is_application_url_verified": app_url_res.validation_status in ("VERIFIED", "REDIRECTED_VERIFIED"),
                    "application_url_status": app_url_res.validation_status,
                    "verified_application_url": app_url_res.final_url if app_url_res.is_valid else notice_url,
                    "verified_notification_url": (notif_url_res.final_url if notif_url_res and notif_url_res.is_valid else pdf_url),
                    "field_evidence_summary": verified_data.get("field_evidence_summary", {}),
                    "vacancies": final_vacancies,
                    "vacancy_count": final_vacancies,
                    "overview": final_overview,
                    "salary_or_pay_scale": final_salary,
                    "salary": final_salary,
                    "stipend": final_stipend,
                    "application_url": app_url_res.final_url if app_url_res.is_valid else notice_url,
                    "official_application_url": app_url_res.final_url if app_url_res.is_valid else notice_url,
                    "notification_url": notif_url_res.final_url if notif_url_res and notif_url_res.is_valid else pdf_url,
                    "official_notification_url": notif_url_res.final_url if notif_url_res and notif_url_res.is_valid else pdf_url,
                    "source_url": source.url,
                    "is_confirmed": verified_data.get("is_confirmed", True),
                    "uncertain_fields": uncertain_fields,
                    "qualification_levels": final_quals,
                    "requisition_id": notice.get("requisition_id"),
                    "advertisement_number": notice.get("advertisement_number"),
                    "application_open_date": final_opening,
                    "application_close_date": final_closing,
                    "examination_date": final_exam_date,
                    "minimum_age": final_min_age,
                    "maximum_age": final_max_age,
                    "minimum_percentage": final_min_perc,
                    "minimum_cgpa": final_min_cgpa,
                    "educational_eligibility": final_quals,
                    "required_disciplines": final_streams,
                    "last_crawled_at": datetime.now(timezone.utc).isoformat(),
                    "last_verified_at": datetime.now(timezone.utc).isoformat(),
                }

                exam_id = db_client.upsert_examination(exam_payload)
                metric.opportunities_updated += 1

                if exam_id and exam_id != "exam-mock-id":
                    # Persist field-level evidence & provenance records
                    db_client.upsert_field_evidence(exam_id, field_evidences)
                    # Upsert Dates
                    db_client.upsert_examination_dates(exam_id, {
                        "application_opening_date": final_opening,
                        "application_closing_date": final_closing,
                        "examination_start_date": final_exam_date,
                        "prelims_date": final_exam_date,
                    })

                    # Upsert Eligibility Rules
                    db_client.upsert_eligibility_rules(exam_id, {
                        "min_age": final_min_age or 18,
                        "max_age": final_max_age or 35,
                        "min_percentage": final_min_perc,
                        "min_cgpa": final_min_cgpa,
                        "grading_type": final_grading_type,
                        "eligible_streams": final_streams if final_streams else ["All disciplines eligible"],
                        "educational_qualifications": final_quals if final_quals else ["Refer official notice"],
                        "fee_exemptions": verified_data.get("fee_exemptions", ""),
                    })

                    # Upsert Typed Details
                    if opportunity_type == "scholarship" or source.source_category == "scholarship":
                        db_client.upsert_scholarship_details(exam_id, {
                            "funding_agency": source.organisation_name,
                            "financial_benefit_description": final_salary or "Financial scholarship as per scheme norms",
                            "application_portal_url": notice_url,
                            "guidelines_pdf_url": pdf_url,
                        })
                    elif opportunity_type == "internship":
                        db_client.upsert_internship_details(exam_id, {
                            "program_name": title,
                            "internship_type": "government" if source.source_category == "central_govt" else "corporate",
                            "stipend_description": final_stipend or "As per internship norms",
                            "work_location_type": "On-site",
                        })
                    elif opportunity_type == "apprenticeship":
                        db_client.upsert_apprenticeship_details(exam_id, {
                            "portal_type": "NATS" if "nats" in source.organisation_slug else "NAPS",
                            "designated_trade": notice.get("role_family", "General Engineering & Technical Trades"),
                            "training_duration_months": 12,
                        })
                    elif opportunity_type == "private_job":
                        db_client.upsert_private_job_requisition(exam_id, {
                            "requisition_id": notice.get("requisition_id", f"{source.organisation_slug.upper()}-REQ"),
                            "company_name": source.organisation_name,
                            "industry_sector": sector,
                            "role_family": notice.get("role_family", "Software & IT"),
                            "career_page_url": notice_url,
                        })
                    elif opportunity_type in ("admission_entrance", "professional_licensing"):
                        db_client.upsert_admission_qualification(exam_id, {
                            "conducting_agency": source.organisation_name,
                            "admission_level": "Undergraduate / Postgraduate",
                        })

                    # Record Changes and Notifications
                    if detected_changes:
                        for ch in detected_changes:
                            db_client.record_change_history({"examination_id": exam_id, **ch})

                        follower_ids = db_client.get_followers_for_examination(exam_id)
                        notifs = change_detector.generate_notifications_for_changes(
                            exam_id, title, detected_changes, follower_ids
                        )
                        for notif in notifs:
                            db_client.insert_notification(notif)

                    # Deduplication record
                    if doc_hash:
                        db_client.record_processed_document({
                            "examination_id": exam_id,
                            "sha256_hash": doc_hash,
                            "url": pdf_url,
                            "extracted_fields": verified_data,
                            "status": "success",
                        })

                total_processed += 1
                await asyncio.sleep(source.rate_limit_seconds)

            health_monitor.finish_crawl(source.organisation_slug, http_status=200)
            db_client.update_crawler_run(run_id, {
                "status": "success",
                "completed_at": datetime.now(timezone.utc).isoformat(),
                "examinations_found": len(notices),
                "examinations_updated": len(notices),
            })
            completed_checkpoint.add(source.organisation_slug)
            save_checkpoint(completed_checkpoint)

        except Exception as e:
            logger.error(f"Error scanning source {source.organisation_slug}: {e}")
            health_monitor.finish_crawl(source.organisation_slug, http_status=500, error=str(e))
            db_client.update_crawler_run(run_id, {
                "status": "failed",
                "completed_at": datetime.now(timezone.utc).isoformat(),
                "error_message": str(e),
            })

    # Print daily execution and observability summary
    summary_report = health_monitor.generate_daily_summary_report()
    print(summary_report)
    logger.info(f"Pipeline finished: {total_discovered} notices found, {total_processed} processed, {total_changes_detected} changes detected.")

def main():
    parser = argparse.ArgumentParser(description="Rexam Opportunity Discovery & Daily Verification Engine")
    parser.add_argument("--category", type=str, help="Filter by source category", default=None)
    parser.add_argument("--source", type=str, help="Filter by specific source slug or ID", default=None)
    parser.add_argument("--limit", type=int, help="Limit number of sources to crawl", default=None)
    parser.add_argument("--rescan", action="store_true", help="Bypass document deduplication cache")
    parser.add_argument("--initial-run", action="store_true", help="Run initial full crawl across all sources")
    args = parser.parse_args()

    asyncio.run(run_discovery_pipeline(
        category_filter=args.category,
        source_filter=args.source,
        limit=args.limit,
        force_rescan=args.rescan,
        is_initial_full_run=args.initial_run,
    ))

if __name__ == "__main__":
    main()
