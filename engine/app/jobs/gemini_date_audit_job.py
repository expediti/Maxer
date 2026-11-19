"""
REXAM POST-SCRAPE GEMINI DATE AUDIT JOB
Entry Point: python -m engine.app.jobs.gemini_date_audit_job

Runs after the opportunity scraping phase:
1. Queries opportunity records directly from Supabase.
2. Invokes Gemini 2.5 Flash (via official Google GenAI SDK and GEMINI_API_KEY)
   to evaluate existing schedule dates against official notifications and statutory calendars.
3. Modifies and overwrites ONLY date fields (examinations.application_open_date,
   application_close_date, examination_date, application_status, and examination_dates table)
   without modifying or dropping any job titles, descriptions, vacancies, or eligibility rules.
"""

import sys
import logging
import argparse
from datetime import datetime, timezone
from engine.app.verification.gemini_date_auditor import gemini_date_auditor

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("rexam.jobs.gemini_date_audit")


def parse_args():
    parser = argparse.ArgumentParser(description="Rexam Post-Scrape Gemini Date Audit Job")
    parser.add_argument("--limit", type=int, default=None, help="Maximum number of examinations to audit")
    parser.add_argument("--dry-run", action="store_true", help="Audit dates without writing changes to Supabase")
    return parser.parse_args()


def main():
    args = parse_args()
    logger.info("================================================================================")
    logger.info("               REXAM POST-SCRAPE GEMINI DATE AUDIT JOB                          ")
    logger.info(f"Start Time (UTC): {datetime.now(timezone.utc).isoformat()}")
    logger.info("================================================================================")

    results = gemini_date_auditor.audit_all_opportunities(
        limit=args.limit,
        dry_run=args.dry_run
    )

    logger.info(f"Summary: {results.get('total_audited', 0)} audited | "
                f"{results.get('dates_confirmed', 0)} confirmed | "
                f"{results.get('dates_corrected', 0)} corrected | "
                f"{results.get('dates_set_to_awaiting', 0)} awaiting notification.")


if __name__ == "__main__":
    main()
