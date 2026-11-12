import pytest
from engine.app.verification.verifier import ExaminationVerifier

@pytest.fixture
def verifier():
    return ExaminationVerifier()

def test_provenance_verification(verifier):
    assert verifier.verify_provenance("https://upsc.gov.in/active-exams") is True
    assert verifier.verify_provenance("https://ssc.gov.in/notices") is True
    assert verifier.verify_provenance("https://bpsc.bih.nic.in/default.htm") is True
    assert verifier.verify_provenance("https://iocl.com/latest-jobs") is True
    assert verifier.verify_provenance("https://www.tcs.com/careers") is True
    assert verifier.verify_provenance("https://fakejobportal99.biz/jobs") is False

def test_strict_cgpa_vs_percentage_rule(verifier):
    """
    CRITICAL: Never interpret a CGPA such as 7.5 as 7.5 percent.
    Percentage under 30% must be flagged as suspicious.
    CGPA over 10.0 scale must be flagged.
    """
    # 1. Conflation attempt: 7.5 entered as percentage
    perc, cgpa, errs = verifier.verify_academic_cutoffs(min_percentage=7.5, min_cgpa=None, grading_type="percentage")
    assert any("percentage_suspiciously_low" in e for e in errs)

    # 2. Valid percentage 60.0%
    perc, cgpa, errs = verifier.verify_academic_cutoffs(min_percentage=60.0, min_cgpa=None, grading_type="percentage")
    assert len(errs) == 0
    assert perc == 60.0

    # 3. Valid CGPA 7.5 on 10.0 scale
    perc, cgpa, errs = verifier.verify_academic_cutoffs(min_percentage=None, min_cgpa=7.5, grading_type="cgpa")
    assert len(errs) == 0
    assert cgpa == 7.5

    # 4. Conflation attempt: 65.0 entered as CGPA on 10-point scale
    perc, cgpa, errs = verifier.verify_academic_cutoffs(min_percentage=None, min_cgpa=65.0, grading_type="cgpa")
    assert any("cgpa_exceeds_standard_scale" in e for e in errs)

def test_dates_coherence_and_temporal_order(verifier):
    # Invalid: opening date after closing date
    record = {
        "title": "Test Notice",
        "application_opening_date": "2026-05-10",
        "application_closing_date": "2026-04-10",
        "min_age": 21,
        "max_age": 30,
    }
    status, uncertain, cleaned = verifier.verify_opportunity_record(record, "https://upsc.gov.in")
    assert "opening_date_after_closing_date" in uncertain
    assert status == "needs_review"

def test_verification_status_lifecycle(verifier):
    # Valid verified and published opportunity
    valid_record = {
        "title": "Civil Services Examination 2026",
        "application_opening_date": "2026-02-01",
        "application_closing_date": "2026-03-05",
        "examination_date": "2026-05-24",
        "min_age": 21,
        "max_age": 32,
        "vacancies": 1056,
        "min_percentage": 50.0,
        "confidence_score": 0.95,
    }
    status, uncertain, cleaned = verifier.verify_opportunity_record(valid_record, "https://upsc.gov.in/cse")
    assert status == "published"
    assert len(uncertain) == 0
    assert cleaned["is_confirmed"] is True

def test_unverified_untrusted_domain_forces_needs_review(verifier):
    record = {
        "title": "High Paying Job Notice",
        "min_age": 20,
        "max_age": 35,
        "confidence_score": 0.95,
    }
    status, uncertain, cleaned = verifier.verify_opportunity_record(record, "https://unverified-third-party-aggregator.net")
    assert status == "needs_review"
    assert "source_provenance_unverified" in uncertain
    assert cleaned["is_confirmed"] is False

