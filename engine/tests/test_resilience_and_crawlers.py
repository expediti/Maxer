import pytest
from engine.app.monitoring.health_monitor import HealthMonitor
from engine.app.discovery.source_registry import get_source_by_slug
from engine.app.crawlers.state_psc_crawler import StatePSCCrawler
from engine.app.crawlers.central_govt_crawler import CentralGovtCrawler
from engine.app.crawlers.defence_crawler import DefenceCrawler
from engine.app.crawlers.psu_crawler import PSUCrawler
from engine.app.crawlers.private_job_crawler import PrivateJobCrawler
from engine.app.crawlers.admission_crawler import AdmissionLicensingCrawler
from engine.app.crawlers.apprenticeship_crawler import ApprenticeshipInternshipCrawler
from engine.app.jobs.discovery_job import get_crawler_for_source

def test_crawler_routing_for_all_adapters():
    cases = [
        ("upsc", "UPSCCrawler"),
        ("ssc", "SSCCrawler"),
        ("appsc", "StatePSCCrawler"),
        ("bpsc", "StatePSCCrawler"),
        ("rrb", "CentralGovtCrawler"),
        ("indian-army", "DefenceCrawler"),
        ("powergrid", "PSUCrawler"),
        ("barc", "ScientificCrawler"),
        ("tcs", "PrivateJobCrawler"),
        ("gate", "AdmissionLicensingCrawler"),
        ("nats", "ApprenticeshipInternshipCrawler"),
    ]
    for slug, expected_class_name in cases:
        src = get_source_by_slug(slug)
        assert src is not None, f"Source '{slug}' must exist"
        crawler = get_crawler_for_source(src)
        assert crawler.__class__.__name__ == expected_class_name, f"Expected {expected_class_name} for {slug}, got {crawler.__class__.__name__}"

def test_health_monitor_isolation_and_statuses():
    hm = HealthMonitor()

    # Case 1: Success
    hm.start_crawl("s1", "src-upsc", "UPSC", "central_govt")
    hm.metrics["src-upsc"].opportunities_discovered = 2
    hm.metrics["src-upsc"].opportunities_updated = 2
    hm.finish_crawl("src-upsc", http_status=200)
    assert hm.metrics["src-upsc"].health_status == "successfully_crawled"

    # Case 2: Blocked by Cloudflare / anti-bot
    hm.start_crawl("s2", "src-blocked", "Protected Site", "psu")
    hm.finish_crawl("src-blocked", http_status=403, error="403 Forbidden: Cloudflare challenge required")
    assert hm.metrics["src-blocked"].health_status == "blocked"

    # Case 3: Network timeout
    hm.start_crawl("s3", "src-timeout", "Slow Server", "state_govt")
    hm.finish_crawl("src-timeout", http_status=504, error="ConnectTimeout: Request timed out")
    assert hm.metrics["src-timeout"].health_status == "temporarily_unavailable"

    report = hm.generate_daily_summary_report()
    assert "UPSC" in report or "Total Sources Monitored : 3" in report
    assert "Blocked (Anti-bot)" in report

@pytest.mark.asyncio
async def test_state_psc_crawler_fallback_structure():
    src = get_source_by_slug("uppsc")
    crawler = StatePSCCrawler(src)
    notices = await crawler.discover_notices()
    assert len(notices) >= 1
    assert "UPPSC" in notices[0]["title"] or "Uttar Pradesh" in notices[0]["title"]
    assert notices[0]["opportunity_type"] == "state_recruitment"
    assert notices[0]["is_central_government"] is False

@pytest.mark.asyncio
async def test_private_job_crawler_structure():
    src = get_source_by_slug("tcs")
    crawler = PrivateJobCrawler(src)
    requisitions = await crawler.discover_notices()
    assert len(requisitions) >= 1
    req = requisitions[0]
    assert "TCS" in req["title"] or "Tata" in req["title"]
    assert req["opportunity_type"] == "private_job"
    assert "requisition_id" in req

