import pytest
from engine.app.discovery.source_registry import get_source_by_slug
from engine.app.crawlers.scholarship_crawler import ScholarshipCrawler
from engine.app.discovery.scholarship_models import ScholarshipScheme

@pytest.mark.asyncio
async def test_scholarship_scheme_validation():
    scheme = ScholarshipScheme(
        title="Prime Minister's Research Fellowship (PMRF) Scheme",
        organisation_name="Ministry of Education, Government of India",
        financial_benefit="₹70,000 to ₹80,000/mo + ₹2 Lakh contingency",
        overview="National research fellowship for doctoral scholars in IITs and IISc.",
        eligibility_criteria="B.Tech CGPA >= 8.0 or valid GATE score >= 750",
        official_application_url="https://www.pmrf.in",
        official_notification_url="https://www.pmrf.in/guidelines",
        application_closing_date="2026-12-31T23:59:59Z",
    )
    assert scheme.title.startswith("Prime Minister")
    assert scheme.is_valid_deadline() is True
    assert "₹70,000" in scheme.financial_benefit

@pytest.mark.asyncio
async def test_scholarship_crawler_discovery_pmrf():
    source = get_source_by_slug("pmrf")
    assert source is not None
    crawler = ScholarshipCrawler(source)
    notices = await crawler.discover_notices()
    assert len(notices) >= 1
    pmrf_notice = notices[0]
    assert "PMRF" in pmrf_notice["title"] or "Prime Minister" in pmrf_notice["title"]
    assert pmrf_notice["category"] == "Scholarships & Fellowships"

@pytest.mark.asyncio
async def test_scholarship_crawler_discovery_aicte():
    source = get_source_by_slug("aicte-scholarships")
    assert source is not None
    crawler = ScholarshipCrawler(source)
    notices = await crawler.discover_notices()
    assert len(notices) >= 2
    titles = [n["title"] for n in notices]
    assert any("Post Graduate" in t or "PG" in t for t in titles)
    assert any("Pragati" in t for t in titles)
