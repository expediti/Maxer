import pytest
from engine.app.discovery.catalogue_expansion import get_master_opportunity_catalogue, seed_master_catalogue

def test_master_catalogue_record_counts():
    catalogue = get_master_opportunity_catalogue()
    assert len(catalogue) >= 80, f"Expected at least 80 master opportunities, got {len(catalogue)}"

def test_master_catalogue_all_36_states_and_uts_covered():
    catalogue = get_master_opportunity_catalogue()
    states = {item["state"] for item in catalogue if item.get("state")}
    
    # 28 States + 8 Union Territories = 36
    assert len(states) >= 36, f"Expected coverage for all 36 Indian States and UTs, got {len(states)}: {states}"

def test_master_catalogue_lifecycle_statuses():
    catalogue = get_master_opportunity_catalogue()
    valid_statuses = {"open", "upcoming", "notification_released", "awaiting_notification", "closed", "archived"}
    
    found_statuses = set()
    for item in catalogue:
        status = item.get("application_status")
        assert status in valid_statuses, f"Invalid application_status '{status}' in {item.get('title')}"
        found_statuses.add(status)
        
    assert "open" in found_statuses
    assert "upcoming" in found_statuses
    assert "awaiting_notification" in found_statuses
    assert "notification_released" in found_statuses

def test_master_catalogue_required_fields_and_integrity():
    catalogue = get_master_opportunity_catalogue()
    slugs = set()
    for item in catalogue:
        assert item.get("title"), "Opportunity missing title"
        assert item.get("slug"), f"Opportunity {item.get('title')} missing slug"
        assert item["slug"] not in slugs, f"Duplicate slug found: {item['slug']}"
        slugs.add(item["slug"])
        assert item.get("category"), f"Opportunity {item.get('title')} missing category"
        assert item.get("opportunity_type"), f"Opportunity {item.get('title')} missing opportunity_type"
        assert item.get("official_application_url") or item.get("application_url"), f"Opportunity {item.get('title')} missing official application url"
        assert item.get("qualification_levels"), f"Opportunity {item.get('title')} missing qualification_levels"

def test_seed_master_catalogue_dry_run():
    res = seed_master_catalogue(dry_run=True)
    assert res["total_catalogued"] >= 80
    assert res["upserted"] == res["total_catalogued"]
    assert res["failed"] == 0

