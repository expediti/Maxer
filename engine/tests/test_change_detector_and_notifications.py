import pytest
from engine.app.verification.change_detector import change_detector

def test_detect_deadline_extension():
    prev_record = {
        "application_closing_date": "2026-04-15",
        "vacancies": 100,
        "application_fee": 100.0,
    }
    new_record = {
        "application_closing_date": "2026-04-30", # Extended
        "vacancies": 100,
        "application_fee": 100.0,
    }

    changes = change_detector.detect_changes(prev_record, new_record, "https://upsc.gov.in/corrigendum.pdf")
    assert len(changes) == 1
    ch = changes[0]
    assert ch["field_name"] == "application_closing_date"
    assert ch["old_value"] == "2026-04-15"
    assert ch["new_value"] == "2026-04-30"
    assert "extended" in ch["change_summary"].lower()

def test_detect_vacancy_revision():
    prev_record = {"vacancies": 500}
    new_record = {"vacancies": 650}

    changes = change_detector.detect_changes(prev_record, new_record)
    assert len(changes) == 1
    assert changes[0]["field_name"] == "vacancies"
    assert changes[0]["new_value"] == "650"

def test_no_spurious_changes_when_identical():
    prev_record = {
        "application_closing_date": "2026-05-15",
        "vacancies": 200,
    }
    new_record = {
        "application_closing_date": "2026-05-15",
        "vacancies": 200,
    }
    changes = change_detector.detect_changes(prev_record, new_record)
    assert len(changes) == 0

def test_generate_notifications_for_followers():
    changes = [{
        "field_name": "application_closing_date",
        "old_value": "2026-05-01",
        "new_value": "2026-05-15",
        "change_summary": "Application Deadline extended to 2026-05-15",
        "change_type": "deadline_extended",
        "source_document_url": "https://ssc.gov.in/notice",
    }]
    followers = ["user-1", "user-2", "user-3"]

    notifs = change_detector.generate_notifications_for_changes(
        exam_id="exam-uuid-123",
        exam_title="SSC CGL 2026",
        changes=changes,
        follower_ids=followers
    )

    assert len(notifs) == 3
    assert notifs[0]["candidate_id"] == "user-1"
    assert notifs[1]["candidate_id"] == "user-2"
    assert notifs[2]["candidate_id"] == "user-3"
    assert "Deadline extended" in notifs[0]["body"]

