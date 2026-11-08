import pytest
from engine.app.matching.eligibility_engine import matcher

def test_matcher_qualifies_matching_candidate():
    candidate = {
        "id": "c1",
        "date_of_birth": "1998-06-15",
        "social_category": "General",
        "stream": "Mechanical Engineering",
        "cgpa_or_percentage": 72.0,
        "has_active_backlogs": False,
    }
    examination = {
        "id": "e1",
        "min_age": 18,
        "max_age": 30,
        "eligible_streams": ["Mechanical Engineering", "Civil Engineering"],
        "min_percentage": 60.0,
    }

    result = matcher.evaluate_candidate_for_examination(candidate, examination)
    assert result["is_eligible"] is True
    assert result["match_score"] > 80
    assert result["status"] == "eligible"

def test_matcher_applies_obc_age_relaxation():
    candidate = {
        "id": "c2",
        "date_of_birth": "1994-01-01", # ~32 years old
        "social_category": "OBC-NCL",
        "stream": "Computer Science",
        "has_active_backlogs": False,
    }
    examination = {
        "id": "e2",
        "min_age": 18,
        "max_age": 30, # Standard 30 + 3 relaxation = 33 max
        "eligible_streams": ["Computer Science"],
    }

    result = matcher.evaluate_candidate_for_examination(candidate, examination)
    assert result["is_eligible"] is True
    assert result["status"] == "eligible"

def test_matcher_rejects_candidate_with_backlogs():
    candidate = {
        "id": "c3",
        "date_of_birth": "2000-01-01",
        "social_category": "General",
        "stream": "Electrical Engineering",
        "has_active_backlogs": True,
    }
    examination = {
        "id": "e3",
        "min_age": 18,
        "max_age": 30,
        "eligible_streams": ["Electrical Engineering"],
    }

    result = matcher.evaluate_candidate_for_examination(candidate, examination)
    assert result["is_eligible"] is False
    assert result["status"] == "not_eligible"
    assert any("backlogs" in r.lower() for r in result["reasons"])

