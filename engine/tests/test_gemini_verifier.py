"""
Tests for Gemini 2.5 Flash Verifier, Pydantic Structured Output Schemas,
Deterministic Guardrails, and Staging Ingestion.
"""

import pytest
from unittest.mock import MagicMock, AsyncMock, patch

from engine.app.verification.gemini_verifier import (
    DateWithEvidence,
    OpportunityExtracted,
    normalize_text_for_comparison,
    validate_iso_date,
    validate_deterministic_guardrails,
    verify_and_clean_opportunity,
    stage_and_verify_opportunity,
)


def test_date_with_evidence_model():
    d = DateWithEvidence(date="2026-02-01", evidence_snippet="Applications open on 01.02.2026")
    assert d.date == "2026-02-01"
    assert d.evidence_snippet == "Applications open on 01.02.2026"

    # Nullable dates
    d_empty = DateWithEvidence(date=None, evidence_snippet=None)
    assert d_empty.date is None
    assert d_empty.evidence_snippet is None


def test_opportunity_extracted_json_schema():
    raw_json = """{
        "title": "Civil Services Examination 2026",
        "organisation_name": "Union Public Service Commission",
        "opportunity_type": "recruitment_examination",
        "start_date": {
            "date": "2026-02-01",
            "evidence_snippet": "Online Applications can be filled from 1st February 2026"
        },
        "closing_date": {
            "date": "2026-02-21",
            "evidence_snippet": "till 21st February 2026 up to 6:00 PM"
        },
        "exam_date": {
            "date": "2026-05-24",
            "evidence_snippet": "Preliminary Examination will be held on 24th May, 2026"
        },
        "application_url": "https://upsconline.nic.in",
        "vacancies": 1056,
        "salary_or_stipend": "Pay Level 10 (Rs. 56,100 - 1,77,500)",
        "minimum_age": 21,
        "maximum_age": 32
    }"""
    model = OpportunityExtracted.model_validate_json(raw_json)
    assert model.title == "Civil Services Examination 2026"
    assert model.start_date.date == "2026-02-01"
    assert model.closing_date.date == "2026-02-21"
    assert model.vacancies == 1056


def test_deterministic_guardrails_pass_valid_record():
    raw_source = (
        "UNION PUBLIC SERVICE COMMISSION\n"
        "EXAMINATION NOTICE NO. 05/2026-CSP\n"
        "Online Applications can be filled from 1st February 2026 till 21st February 2026 up to 6:00 PM.\n"
        "Preliminary Examination will be held on 24th May, 2026.\n"
        "Candidates must apply online at https://upsconline.nic.in."
    )
    extracted = OpportunityExtracted(
        title="UPSC CSE 2026",
        organisation_name="UPSC",
        start_date=DateWithEvidence(date="2026-02-01", evidence_snippet="Online Applications can be filled from 1st February 2026"),
        closing_date=DateWithEvidence(date="2026-02-21", evidence_snippet="till 21st February 2026 up to 6:00 PM"),
        exam_date=DateWithEvidence(date="2026-05-24", evidence_snippet="Preliminary Examination will be held on 24th May, 2026"),
        application_url="https://upsconline.nic.in",
        minimum_age=21,
        maximum_age=32,
    )

    errors, is_verified, clean = validate_deterministic_guardrails(extracted, raw_source, "https://upsc.gov.in")
    assert is_verified is True
    assert len(errors) == 0
    assert "start_date" in clean["date_evidence"]
    assert clean["date_evidence"]["start_date"]["verified_substring"] is True


def test_deterministic_guardrails_rejects_inverted_dates():
    raw_source = "Opening date: 15-05-2026. Closing date: 15-04-2026."
    extracted = OpportunityExtracted(
        title="Flawed Dates Exam",
        organisation_name="State PSC",
        start_date=DateWithEvidence(date="2026-05-15", evidence_snippet="Opening date: 15-05-2026"),
        closing_date=DateWithEvidence(date="2026-04-15", evidence_snippet="Closing date: 15-04-2026"),
        application_url="https://psc.state.gov.in",
    )

    errors, is_verified, clean = validate_deterministic_guardrails(extracted, raw_source, "https://psc.state.gov.in")
    assert is_verified is False
    assert any("strictly before" in err.lower() for err in errors)


def test_deterministic_guardrails_detects_hallucinated_evidence_snippet():
    raw_source = "Staff Selection Commission Combined Graduate Level Examination 2026 notice will be released soon."
    extracted = OpportunityExtracted(
        title="SSC CGL 2026",
        organisation_name="SSC",
        start_date=DateWithEvidence(
            date="2026-06-10",
            evidence_snippet="Online registration starts from 10th June 2026"  # Absent from raw_source
        ),
        application_url="https://ssc.gov.in",
    )

    errors, is_verified, clean = validate_deterministic_guardrails(extracted, raw_source, "https://ssc.gov.in")
    assert is_verified is False
    assert any("not found verbatim in source text" in err for err in errors)


def test_deterministic_guardrails_rejects_invalid_url():
    raw_source = "Notification released for Technical Apprentices."
    extracted = OpportunityExtracted(
        title="Apprentice Recruitment 2026",
        organisation_name="DRDO",
        application_url="javascript:alert(1)",
    )

    errors, is_verified, clean = validate_deterministic_guardrails(extracted, raw_source, "https://drdo.gov.in")
    assert is_verified is False
    assert any("Invalid application URL format" in err for err in errors)


def test_normalize_text_for_comparison():
    raw = "Online   Application\n\tStarts—'01/02/2026'“test”"
    normalized = normalize_text_for_comparison(raw)
    assert "online application starts-'01/02/2026'\"test\"" == normalized


@pytest.mark.asyncio
async def test_verify_and_clean_opportunity_with_mocked_gemini():
    mock_client = MagicMock()
    mock_model_response = MagicMock()
    mock_model_response.text = """{
        "title": "SSC CGL 2026",
        "organisation_name": "Staff Selection Commission",
        "opportunity_type": "recruitment_examination",
        "start_date": {
            "date": "2026-06-24",
            "evidence_snippet": "Online applications may be submitted from 24.06.2026"
        },
        "closing_date": {
            "date": "2026-07-24",
            "evidence_snippet": "to 24.07.2026 (23:00 hours)"
        },
        "exam_date": {
            "date": "2026-09-15",
            "evidence_snippet": "Tier-I Computer Based Examination will be held tentatively in Sept-Oct 2026"
        },
        "application_url": "https://ssc.gov.in",
        "vacancies": 14000
    }"""
    mock_client.models.generate_content.return_value = mock_model_response

    sample_text = (
        "STAFF SELECTION COMMISSION NOTICE: Combined Graduate Level Examination, 2026.\n"
        "Online applications may be submitted from 24.06.2026 to 24.07.2026 (23:00 hours).\n"
        "Tier-I Computer Based Examination will be held tentatively in Sept-Oct 2026.\n"
        "Portal: https://ssc.gov.in"
    )

    extracted, errors, is_verified, clean_dict = await verify_and_clean_opportunity(
        raw_text=sample_text,
        source_url="https://ssc.gov.in/notice",
        context={"organisation_name": "SSC"},
        client=mock_client,
    )

    assert extracted is not None
    assert extracted.title == "SSC CGL 2026"
    assert extracted.vacancies == 14000
    assert is_verified is True
    assert len(errors) == 0


def test_stage_and_verify_opportunity_upsert_and_promotion():
    mock_db = MagicMock()
    mock_db.upsert_staging_opportunity.return_value = "stage-uuid-001"
    mock_db.promote_staging_opportunity_to_production.return_value = "exam-uuid-001"

    extracted = OpportunityExtracted(
        title="ISRO Scientist Engineer 2026",
        organisation_name="ISRO",
        start_date=DateWithEvidence(date="2026-03-01", evidence_snippet="Commencement of online application: 01-03-2026"),
        closing_date=DateWithEvidence(date="2026-03-31", evidence_snippet="Last date for submission of online application: 31-03-2026"),
        application_url="https://isro.gov.in/careers",
    )

    raw_text = "Commencement of online application: 01-03-2026. Last date for submission of online application: 31-03-2026."

    res = stage_and_verify_opportunity(
        db=mock_db,
        extracted=extracted,
        validation_errors=[],
        is_verified=True,
        raw_text=raw_text,
        source_url="https://isro.gov.in/careers",
        source_id="11111111-1111-1111-1111-111111111111",
        organisation_id="22222222-2222-2222-2222-222222222222",
        promote_if_valid=True,
    )

    assert res["staging_id"] == "stage-uuid-001"
    assert res["is_verified"] is True
    assert res["promoted_to_production"] is True
    assert res["production_id"] == "exam-uuid-001"
    assert mock_db.upsert_staging_opportunity.called
    assert mock_db.promote_staging_opportunity_to_production.called


def test_stage_and_verify_opportunity_unverified_quarantine():
    mock_db = MagicMock()
    mock_db.upsert_staging_opportunity.return_value = "stage-uuid-002"

    extracted = OpportunityExtracted(
        title="Unverified Suspicious Notice",
        organisation_name="ThirdParty",
        start_date=DateWithEvidence(date="2026-05-01", evidence_snippet="Not found snippet"),
    )

    res = stage_and_verify_opportunity(
        db=mock_db,
        extracted=extracted,
        validation_errors=["Evidence snippet for 'start_date' not found verbatim in source text"],
        is_verified=False,
        raw_text="No dates here.",
        source_url="https://example.com",
        promote_if_valid=True,
    )

    assert res["is_verified"] is False
    assert res["promoted_to_production"] is False
    assert res["verification_status"] == "NEEDS_REVIEW"
    assert not mock_db.promote_staging_opportunity_to_production.called

