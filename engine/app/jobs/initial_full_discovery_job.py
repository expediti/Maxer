import asyncio
import logging
import argparse
from engine.app.jobs.discovery_job import run_discovery_pipeline

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("rexam.jobs.initial_full_discovery")

def main():
    parser = argparse.ArgumentParser(description="Rexam Initial Full Discovery Pipeline")
    parser.add_argument("--category", type=str, help="Filter by specific category", default=None)
    parser.add_argument("--source", type=str, help="Filter by specific source slug or ID", default=None)
    parser.add_argument("--limit", type=int, help="Limit number of sources to crawl", default=None)
    parser.add_argument("--rescan", action="store_true", help="Bypass deduplication cache", default=False)
    args = parser.parse_args()

    logger.info("================================================================================")
    logger.info("               REXAM INITIAL FULL DISCOVERY JOB INITIATED                       ")
    logger.info("================================================================================")

    asyncio.run(run_discovery_pipeline(
        category_filter=args.category,
        source_filter=args.source,
        limit=args.limit,
        force_rescan=args.rescan,
        is_initial_full_run=True,
    ))

if __name__ == "__main__":
    main()

