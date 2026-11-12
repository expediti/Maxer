"""
REXAM DAILY VERIFICATION & LINK INTEGRITY ENGINE
Runs daily to audit all active and published opportunities:
1. Re-validates official application URLs and notification links.
2. Checks DNS, TLS certificate validity, and HTTP redirect chains.
3. Detects expired application deadlines and transitions lifecycle states.
4. Records URL health metrics and syncs examination verification tiers.
5. Emits corrigenda and change history records for candidates tracking opportunities.
"""

import sys
import logging
import argparse
from datetime import datetime, timezone
from typing import Dict, Any, List

from engine.app.database.supabase_client import db_client
from engine.app.verification.url_validator import url_validator
from engine.app.verification.change_detector import change_detector
from engine.app.verification.date_validator import date_validator

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("rexam.daily_verification")


def parse_args():
    parser = argparse.ArgumentParser(description="Rexam Daily Verification & Link Health Job")
    parser.add_argument("--limit", type=int, default=250, help="Maximum examinations to audit in this run")
    parser.add_argument("--dry-run", action="store_true", help="Audit without writing to database")
    parser.add_argument("--force", action="store_true", help="Force re-verification regardless of last_verified_at")
    return parser.parse_args()


def run_daily_verification(limit: int = 250, dry_run: bool = False, force: bool = False) -> Dict[str, Any]:
    logger.info(f"Starting Rexam Daily Verification Run (limit={limit}, dry_run={dry_run}, force={force})")
    
    now = datetime.now(timezone.utc)
    now_iso = now.isoformat()

    metrics = {
        "audited_count": 0,
        "urls_verified": 0,
        "urls_redirected": 0,
        "urls_unhealthy": 0,
        "deadlines_expired": 0,
        "tiers_updated": 0,
        "changes_recorded": 0,
    }

    exams = db_client.fetch_examinations_for_verification(limit=limit)
    if not exams:
        logger.info("No examinations returned for verification audit (or operating in mock mode).")
        return metrics

    logger.info(f"Fetched {len(exams)} examinations for verification.")

    for exam in exams:
        exam_id = exam.get("id")
        slug = exam.get("slug")
        title = exam.get("title") or exam.get("name") or slug
        current_status = (exam.get("status") or "active").lower()
        current_app_status = (exam.get("application_status") or "awaiting_notification").lower()
        current_tier = exam.get("verification_tier") or "PARTIALLY_VERIFIED"
        app_url = exam.get("official_application_url") or exam.get("application_url")
        notif_url = exam.get("official_notification_url") or exam.get("notification_url")
        
        # Extract structured date dictionary
        dt_record = exam.get("examination_dates") or {}
        if isinstance(dt_record, list) and dt_record:
            dt_record = dt_record[0]
        elif not isinstance(dt_record, dict):
            dt_record = {}

        dates_payload = {
            "notification_date": dt_record.get("notification_date"),
            "application_start_date": dt_record.get("application_opening_date") or exam.get("application_open_date"),
            "application_end_date": dt_record.get("application_closing_date") or exam.get("application_close_date"),
            "correction_start_date": dt_record.get("correction_window_start"),
            "correction_end_date": dt_record.get("correction_window_end"),
            "admit_card_date": dt_record.get("admit_card_release_date"),
            "exam_start_date": dt_record.get("examination_start_date") or exam.get("examination_date"),
            "exam_end_date": dt_record.get("examination_end_date"),
            "result_date": dt_record.get("result_date"),
        }

        # Validate dates deterministically
        is_dates_valid, date_issues, cleaned_dates = date_validator.validate_dates(dates_payload, now=now)
        lifecycle_status = date_validator.compute_lifecycle_status(
            cleaned_dates,
            has_official_notification=bool(notif_url or dt_record.get("notification_date")),
            now=now
        )
        lifecycle_status_lower = lifecycle_status.lower()

        metrics["audited_count"] += 1
        exam_updates = {
            "last_verified_at": now_iso,
        }

        # 1. Audit Application Portal URL
        if app_url:
            val_result = url_validator.validate_url(app_url)
            status = val_result.get("status", "NEEDS_REVIEW")
            resolved = val_result.get("resolved_url") or app_url
            is_valid = val_result.get("is_valid", False)

            exam_updates["is_application_url_verified"] = is_valid
            exam_updates["application_url_status"] = status
            exam_updates["verified_application_url"] = resolved

            if not dry_run:
                db_client.upsert_url_validation({
                    "url": app_url,
                    "resolved_url": resolved,
                    "validation_status": status,
                    "http_status_code": val_result.get("status_code"),
                    "is_https": val_result.get("is_https", False),
                    "is_official_domain": val_result.get("is_official_domain", False),
                    "redirect_chain": val_result.get("redirect_chain", []),
                    "last_checked_at": now_iso,
                    "error_message": val_result.get("error_message"),
                })

            if status in ("VERIFIED", "REDIRECTED_VERIFIED"):
                metrics["urls_verified"] += 1
                if status == "REDIRECTED_VERIFIED":
                    metrics["urls_redirected"] += 1
            else:
                metrics["urls_unhealthy"] += 1
                logger.warning(f"Unhealthy application URL for [{slug}]: {app_url} -> {status}")

        # 2. Audit Notification PDF / Notice URL if present
        if notif_url:
            notif_val = url_validator.validate_url(notif_url)
            notif_resolved = notif_val.get("resolved_url") or notif_url
            exam_updates["verified_notification_url"] = notif_resolved

            if not dry_run:
                db_client.upsert_url_validation({
                    "url": notif_url,
                    "resolved_url": notif_resolved,
                    "validation_status": notif_val.get("status", "NEEDS_REVIEW"),
                    "http_status_code": notif_val.get("status_code"),
                    "is_https": notif_val.get("is_https", False),
                    "is_official_domain": notif_val.get("is_official_domain", False),
                    "redirect_chain": notif_val.get("redirect_chain", []),
                    "last_checked_at": now_iso,
                    "error_message": notif_val.get("error_message"),
                })

        # 3. Check Lifecycle Status & Deadline Expiry
        is_expired = lifecycle_status in ("CLOSED", "EXAMINATION_COMPLETED", "RESULT_DECLARED")
        if is_expired:
            exam_updates["status"] = "expired"
            metrics["deadlines_expired"] += 1
        exam_updates["application_status"] = lifecycle_status_lower

        # 4. Sync Verification Tier
        if not is_dates_valid or date_issues:
            new_tier = "UNDER_REVIEW"
        elif is_expired:
            new_tier = "EXPIRED"
        else:
            app_url_status = exam_updates.get("application_url_status")
            if app_url_status in ("VERIFIED", "REDIRECTED_VERIFIED"):
                new_tier = "VERIFIED"
            elif app_url_status == "TEMPORARILY_UNAVAILABLE":
                new_tier = "UNDER_REVIEW"
            else:
                new_tier = "PARTIALLY_VERIFIED"
            
        if new_tier != current_tier:
            exam_updates["verification_tier"] = new_tier
            metrics["tiers_updated"] += 1

        # 5. Persist Updates & Record Change History
        if not dry_run:
            success = db_client.update_examination_verification_result(exam_id, exam_updates)
            if success and lifecycle_status_lower != current_app_status:
                db_client.record_change_history({
                    "examination_id": exam_id,
                    "field_changed": "application_status",
                    "previous_value": current_app_status,
                    "new_value": lifecycle_status_lower,
                    "change_type": "status_update",
                    "change_summary": f"Lifecycle transitioned to {lifecycle_status} via automated statutory date verification.",
                    "detected_at": now_iso,
                })
                metrics["changes_recorded"] += 1

    logger.info("Daily Verification Run Complete. Summary: " + str(metrics))
    return metrics


if __name__ == "__main__":
    args = parse_args()
    summary = run_daily_verification(
        limit=args.limit,
        dry_run=args.dry_run,
        force=args.force
    )
    sys.exit(0)

