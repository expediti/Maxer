import pytest
from engine.app.discovery.source_registry import (
    OFFICIAL_INDIAN_SOURCES,
    get_all_sources,
    get_source_by_slug,
    get_sources_by_category,
    get_sources_by_state,
)

ALL_36_STATES_AND_UTS = [
    "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh",
    "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka",
    "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram",
    "Nagaland", "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu",
    "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal",
    "Delhi", "Jammu and Kashmir", "Ladakh", "Puducherry", "Chandigarh",
    "Andaman and Nicobar", "Dadra and Nagar Haveli and Daman and Diu", "Lakshadweep"
]

def test_source_registry_population():
    sources = get_all_sources(enabled_only=False)
    assert len(sources) >= 50, f"Expected at least 50 sources, found {len(sources)}"

def test_all_36_states_and_uts_covered():
    """Verify that every single Indian state and UT has official recruitment source coverage."""
    registered_states = {s.state.lower() for s in OFFICIAL_INDIAN_SOURCES if s.state}

    for state_name in ALL_36_STATES_AND_UTS:
        matched = any(state_name.lower() in reg or reg in state_name.lower() for reg in registered_states)
        assert matched is True, f"State/UT '{state_name}' is missing from the source registry!"

def test_all_core_opportunity_categories_present():
    """Verify central government, state govt, defence, scientific, psu, scholarship, private, and admissions are seeded."""
    categories = {s.source_category for s in OFFICIAL_INDIAN_SOURCES}
    expected_categories = [
        "central_govt",
        "state_govt",
        "defence",
        "scientific",
        "psu",
        "teaching",
        "healthcare",
        "judicial",
        "aviation_maritime",
        "apprenticeship",
        "internship",
        "scholarship",
        "private_sector",
        "admission_qualification",
    ]
    for exp_cat in expected_categories:
        assert exp_cat in categories, f"Category '{exp_cat}' missing from source registry!"

def test_key_national_authorities_seeded():
    """Verify national authorities from Master Catalogue PDF are properly indexed."""
    slugs = [s.organisation_slug for s in OFFICIAL_INDIAN_SOURCES]
    required_slugs = [
        "upsc", "ssc", "rrb", "ibps", "sbi", "rbi", "nabard", "sebi", "ncs",
        "employment-news", "isro", "drdo", "barc", "csir", "icar", "aiims",
        "ctet", "supreme-court", "aai", "dgca", "dg-shipping", "powergrid",
        "iocl", "gail", "pmrf", "nsp", "nats", "tcs", "infosys", "gate"
    ]
    for slug in required_slugs:
        found = get_source_by_slug(slug)
        assert found is not None, f"Required official authority '{slug}' not found in registry!"

def test_source_domain_and_rate_limits():
    for source in OFFICIAL_INDIAN_SOURCES:
        assert source.domain != "", f"Domain must be set for {source.id}"
        assert source.official_url.startswith("https://") or source.official_url.startswith("http://")
        assert source.rate_limit_seconds >= 1.0

