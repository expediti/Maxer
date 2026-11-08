import pytest
from engine.app.verification.verifier import verifier

def test_verify_provenance_official_domain():
    assert verifier.verify_provenance("https://upsc.gov.in/sites/default/files/cse.pdf") is True
    assert verifier.verify_provenance("https://isro.gov.in/Careers") is True
    assert verifier.verify_provenance("https://random-job-portal.com/upsc-leak") is False

def test_verifier_flags_inverted_dates():
    data = {
        "title": "Test Recruitment",
        "min_age": 21,
        "max_age": 32,
        "application_opening_date": "2026-04-10",
        "application_closing_date": "2026-03-01", # Earlier than opening
        "confidence_score": 0.90
    }
    status, uncertain, _ = verifier.verify_examination_data(data, "https://upsc.gov.in/exam")
    assert status == "under_review"
    assert "opening_date_after_closing_date" in uncertain

def test_verifier_flags_incoherent_age_bounds():
    data = {
        "title": "Test Recruitment",
        "min_age": 35,
        "max_age": 25, # Min greater than max
        "confidence_score": 0.90
    }
    status, uncertain, _ = verifier.verify_examination_data(data, "https://upsc.gov.in/exam")
    assert status == "under_review"
    assert "age_bounds_incoherent" in uncertain

def test_verifier_approves_valid_data():
    data = {
        "title": "Civil Services Examination 2026",
        "min_age": 21,
        "max_age": 32,
        "application_opening_date": "2026-02-14",
        "application_closing_date": "2026-03-06",
        "prelims_exam_date": "2026-05-25",
        "confidence_score": 0.92
    }
    status, uncertain, cleaned = verifier.verify_examination_data(data, "https://upsc.gov.in/cse")
    assert status == "published"
    assert len(uncertain) == 0
    assert cleaned["is_confirmed"] is True

