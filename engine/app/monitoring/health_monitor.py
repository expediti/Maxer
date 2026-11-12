import logging
from typing import Dict, Any, List, Optional
from datetime import datetime, timezone
from dataclasses import dataclass, field

logger = logging.getLogger("rexam.health_monitor")

@dataclass
class SourceCrawlMetric:
    source_id: str
    source_slug: str
    source_name: str
    category: str
    crawl_started_at: str
    crawl_completed_at: Optional[str] = None
    crawl_duration_seconds: float = 0.0
    http_status: Optional[int] = None
    health_status: str = "no_new_opportunities" # successfully_crawled, partially_crawled, blocked, temporarily_unavailable, unsupported, no_new_opportunities
    pages_discovered: int = 0
    documents_downloaded: int = 0
    opportunities_discovered: int = 0
    opportunities_updated: int = 0
    duplicates_skipped: int = 0
    extraction_failures: int = 0
    verification_failures: int = 0
    error_message: Optional[str] = None
    details: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "source_id": self.source_id,
            "source_slug": self.source_slug,
            "crawl_started_at": self.crawl_started_at,
            "crawl_completed_at": self.crawl_completed_at,
            "crawl_duration_seconds": round(self.crawl_duration_seconds, 2),
            "http_status": self.http_status,
            "health_status": self.health_status,
            "pages_discovered": self.pages_discovered,
            "documents_downloaded": self.documents_downloaded,
            "opportunities_discovered": self.opportunities_discovered,
            "opportunities_updated": self.opportunities_updated,
            "duplicates_skipped": self.duplicates_skipped,
            "extraction_failures": self.extraction_failures,
            "verification_failures": self.verification_failures,
            "error_message": self.error_message,
            "details": self.details,
        }

class HealthMonitor:
    """Collects per-source telemetry and generates observability summaries."""

    def __init__(self):
        self.metrics: Dict[str, SourceCrawlMetric] = {}

    def start_crawl(self, source_id: str, slug: str, name: str, category: str) -> SourceCrawlMetric:
        metric = SourceCrawlMetric(
            source_id=source_id,
            source_slug=slug,
            source_name=name,
            category=category,
            crawl_started_at=datetime.now(timezone.utc).isoformat(),
        )
        self.metrics[slug] = metric
        return metric

    def finish_crawl(
        self,
        slug: str,
        http_status: Optional[int] = 200,
        error: Optional[str] = None
    ) -> SourceCrawlMetric:
        metric = self.metrics.get(slug)
        if not metric:
            return SourceCrawlMetric(
                source_id="", source_slug=slug, source_name=slug, category="",
                crawl_started_at=datetime.now(timezone.utc).isoformat()
            )

        now = datetime.now(timezone.utc)
        metric.crawl_completed_at = now.isoformat()
        try:
            start_dt = datetime.fromisoformat(metric.crawl_started_at)
            metric.crawl_duration_seconds = (now - start_dt).total_seconds()
        except Exception:
            metric.crawl_duration_seconds = 0.0

        metric.http_status = http_status

        if error:
            metric.error_message = str(error)
            err_lower = str(error).lower()
            if "403" in err_lower or "cloudflare" in err_lower or "captcha" in err_lower or "block" in err_lower:
                metric.health_status = "blocked"
            elif "timeout" in err_lower or "502" in err_lower or "503" in err_lower or "connect" in err_lower:
                metric.health_status = "temporarily_unavailable"
            else:
                metric.health_status = "partially_crawled"
        elif metric.opportunities_discovered > 0:
            if metric.extraction_failures == 0:
                metric.health_status = "successfully_crawled"
            else:
                metric.health_status = "partially_crawled"
        else:
            metric.health_status = "no_new_opportunities"

        return metric

    def generate_daily_summary_report(self) -> str:
        """Produces a human-readable execution and observability report."""
        total_sources = len(self.metrics)
        success = [m for m in self.metrics.values() if m.health_status == "successfully_crawled"]
        partial = [m for m in self.metrics.values() if m.health_status == "partially_crawled"]
        blocked = [m for m in self.metrics.values() if m.health_status == "blocked"]
        unavailable = [m for m in self.metrics.values() if m.health_status == "temporarily_unavailable"]
        no_new = [m for m in self.metrics.values() if m.health_status == "no_new_opportunities"]

        total_discovered = sum(m.opportunities_discovered for m in self.metrics.values())
        total_updated = sum(m.opportunities_updated for m in self.metrics.values())
        total_docs = sum(m.documents_downloaded for m in self.metrics.values())

        report = [
            "================================================================================",
            "                   REXAM OPPORTUNITY ENGINE - CRAWL SUMMARY                     ",
            "================================================================================",
            f"Execution Timestamp : {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')}",
            f"Total Sources Monitored : {total_sources}",
            f"  - Successfully Crawled  : {len(success)}",
            f"  - No New Notices Found  : {len(no_new)}",
            f"  - Partially Crawled     : {len(partial)}",
            f"  - Blocked (Anti-bot)    : {len(blocked)}",
            f"  - Temporarily Down      : {len(unavailable)}",
            "--------------------------------------------------------------------------------",
            f"Total Opportunities Discovered : {total_discovered}",
            f"Total Opportunities Ingested   : {total_updated}",
            f"Official Documents Downloaded  : {total_docs}",
            "================================================================================",
        ]

        if blocked:
            report.append("\n[BLOCKED SOURCES - REQUIRES REVIEW / OFFICIAL DIRECT LINK]")
            for m in blocked:
                report.append(f"  * {m.source_name} ({m.source_slug}): {m.error_message}")

        if partial:
            report.append("\n[PARTIALLY CRAWLED SOURCES]")
            for m in partial:
                report.append(f"  * {m.source_name} ({m.source_slug}): {m.error_message or 'Some items failed'}")

        report.append("================================================================================\n")
        return "\n".join(report)

health_monitor = HealthMonitor()

