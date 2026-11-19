"""
REXAM UNIT TESTS FOR GEMINI DATE AUDITOR & POST-SCRAPE REMEDIATION
Module: engine/tests/test_gemini_date_auditor.py
"""

import pytest
from datetime import datetime, timezone
from unittest.mock import MagicMock

from engine.app.verification.gemini_date_auditor import (
    DateAuditResult,
    validate_iso_date_str,
    apply_deterministic_date_guardrails,
    compute_application_lifecycle_status,
    GeminiDateAuditor,
)


def test_validate_iso_date_str():
    # Valid ISO formats
    ok, dt_str = validate_iso_date_str("2026-05-24")
    assert ok is True
    assert dt_str == "2026-05-24"

    ok, dt_str = validate_iso_date_str("2026-02-14T10:00:00+05:30")
    assert ok is True
    assert dt_str == "2026-02-14"

    # None and empty
    ok, dt_str = validate_iso_date_str(None)
    assert ok is True
    assert dt_str is None

    # Invalid formats
    ok, dt_str = validate_iso_date_str("invalid-date")
    assert ok is False
    assert dt_str is None

    # Out of range year
    ok, dt_str = validate_iso_date_str("1995-01-01")
    assert ok is False


def test_deterministic_date_guardrails_closing_before_opening():
    audit = DateAuditResult(
        is_date_correct=False,
        application_open_date="2026-05-01",
        application_close_date="2026-04-01",  # Temporal inversion!
        examination_date="2026-06-01",
        status_reasoning="Test inversion",
    )
    cleaned, issues = apply_deterministic_date_guardrails(audit, "Test Exam")
    assert len(issues) == 1
    assert "Closing date" in issues[0]
    # Closing date cleared, opening date and exam date preserved!
    assert cleaned.application_close_date is None
    assert cleaned.application_open_date == "2026-05-01"
    assert cleaned.examination_date == "2026-06-01"


def test_deterministic_date_guardrails_exam_before_opening():
    audit = DateAuditResult(
        is_date_correct=False,
        application_open_date="2026-06-01",
        application_close_date="2026-06-30",
        examination_date="2026-05-15",  # Exam before application!
        status_reasoning="Test inversion",
    )
    cleaned, issues = apply_deterministic_date_guardrails(audit, "Test Exam")
    assert len(issues) == 1
    assert "Exam date" in issues[0]
    assert cleaned.examination_date is None
    assert cleaned.application_open_date == "2026-06-01"
    assert cleaned.application_close_date == "2026-06-30"


def test_compute_application_lifecycle_status():
    fixed_now = datetime(2026, 3, 1, tzinfo=timezone.utc)

    # Both null -> awaiting_notification
    assert compute_application_lifecycle_status(None, None, now=fixed_now) == "awaiting_notification"

    # Closed in past
    assert compute_application_lifecycle_status("2026-01-01", "2026-02-15", now=fixed_now) == "closed"

    # Upcoming in future
    assert compute_application_lifecycle_status("2026-04-01", "2026-04-30", now=fixed_now) == "upcoming"

    # Currently open
    assert compute_application_lifecycle_status("2026-02-15", "2026-03-15", now=fixed_now) == "open"


def test_deterministic_date_audit_statutory_benchmark():
    auditor = GeminiDateAuditor(client=None)
    statutory_entry = {
        "title": "Civil Services Examination (CSE) 2026",
        "notification_date": "2026-02-14",
        "application_start_date": "2026-02-14T10:00:00+05:30",
        "application_end_date": "2026-03-06T18:00:00+05:30",
        "exam_start_date": "2026-05-24",
        "source_url": "https://upsc.gov.in",
        "doc_title": "UPSC Annual Programme 2026",
        "quote": "Civil Services Prelims 2026: 24.05.2026",
    }

    # If current DB dates match statutory
    res, issues = auditor._deterministic_date_audit(
        title="UPSC CSE 2026",
        slug="upsc-civil-services-examination-2026",
        curr_open="2026-02-14",
        curr_close="2026-03-06",
        curr_exam="2026-05-24",
        statutory_entry=statutory_entry,
        overview="UPSC exam",
    )
    assert res.is_date_correct is True
    assert res.application_open_date == "2026-02-14"
    assert res.application_close_date == "2026-03-06"
    assert res.examination_date == "2026-05-24"
    assert res.evidence_quote == statutory_entry["quote"]

    # If current DB dates were missing
    res, issues = auditor._deterministic_date_audit(
        title="UPSC CSE 2026",
        slug="upsc-civil-services-examination-2026",
        curr_open=None,
        curr_close=None,
        curr_exam=None,
        statutory_entry=statutory_entry,
        overview="UPSC exam",
    )
    assert res.is_date_correct is False
    assert res.application_open_date == "2026-02-14"
    assert res.application_close_date == "2026-03-06"
    assert res.examination_date == "2026-05-24"


def test_deterministic_date_audit_cleanses_synthetic_clusters():
    auditor = GeminiDateAuditor(client=None)

    # Synthetic timestamp cluster with subseconds
    res, issues = auditor._deterministic_date_audit(
        title="Random Exam",
        slug="random-exam-unknown",
        curr_open="2026-02-14T04:30:00.220834+00:00",
        curr_close="2026-03-06T12:30:00.220834+00:00",
        curr_exam=None,
        statutory_entry=None,
        overview="No dates mentioned",
    )
    assert res.is_date_correct is False
    assert res.application_open_date is None
    assert res.application_close_date is None
    assert "Synthetic dates cleansed" in issues[0]


def test_apply_date_audit_dry_run_updates_only_date_fields():
    auditor = GeminiDateAuditor(client=None)
    audit = DateAuditResult(
        is_date_correct=True,
        application_open_date="2026-02-14",
        application_close_date="2026-03-06",
        examination_date="2026-05-24",
        evidence_quote="Official gazette quote",
        status_reasoning="Confirmed dates",
    )

    out = auditor.apply_date_audit_to_supabase(
        exam_id="test-uuid",
        slug="upsc-cse-2026",
        audit=audit,
        dry_run=True
    )
    assert out["status"] == "dry_run"
    updates = out["exam_updates"]
    # Verify ONLY date-related fields are in updates
    assert "title" not in updates
    assert "slug" not in updates
    assert "vacancies" not in updates
    assert "salary_or_pay_scale" not in updates
    assert "educational_eligibility" not in updates
    assert "application_url" not in updates
    assert updates["application_open_date"] == "2026-02-14"
    assert updates["application_close_date"] == "2026-03-06"
    assert updates["examination_date"] == "2026-05-24"
