import pytest
from engine.app.matching.eligibility_engine import matcher

def test_matcher_qualifies_matching_candidate():
    candidate = {
        "id": "c1",
        "date_of_birth": "1998-06-15",
        "social_category": "General",
        "stream": "Mechanical Engineering",
        "grading_system": "percentage",
        "percentage": 72.0,
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

def test_matcher_cgpa_requires_verification_when_formula_unavailable():
    # Test A: 7.5 CGPA, scale 10. Requirement: 50%. No verified conversion formula.
    candidate = {
        "id": "c_cgpa_no_formula",
        "date_of_birth": "2001-05-10",
        "social_category": "General",
        "stream": "Computer Science",
        "grading_system": "cgpa",
        "cgpa": 7.5,
        "university": "Unknown College Without Verified Formula",
        "has_active_backlogs": False,
    }
    examination = {
        "id": "e_50pct",
        "min_percentage": 50.0,
        "eligible_streams": ["Computer Science"],
    }

    result = matcher.evaluate_candidate_for_examination(candidate, examination)
    assert result["status"] == "requires_verification"
    # Crucial: 7.5 must NEVER be treated as 7.5%
    for reason in result["reasons"]:
        assert "7.5%" not in reason
    assert any("No verified conversion formula on record" in r for r in result["reasons"])

def test_matcher_cgpa_against_cgpa_cutoff_satisfied():
    # Test B: 7.5 CGPA, scale 10. Requirement: 7.0 CGPA, scale 10 -> Satisfied
    candidate = {
        "id": "c_cgpa_7_5",
        "date_of_birth": "2001-05-10",
        "social_category": "General",
        "stream": "Computer Science",
        "grading_system": "cgpa",
        "cgpa": 7.5,
        "has_active_backlogs": False,
    }
    examination = {
        "id": "e_7_0_cgpa",
        "min_cgpa": 7.0,
        "cgpa_scale_max": 10.0,
        "eligible_streams": ["Computer Science"],
    }

    result = matcher.evaluate_candidate_for_examination(candidate, examination)
    assert result["is_eligible"] is True
    assert result["status"] == "eligible"
    assert any("7.50" in r and "7.00 CGPA" in r for r in result["reasons"])

def test_matcher_cgpa_against_cgpa_cutoff_not_satisfied():
    # Test C: 7.5 CGPA, scale 10. Requirement: 8.0 CGPA, scale 10 -> Not Satisfied
    candidate = {
        "id": "c_cgpa_7_5",
        "date_of_birth": "2001-05-10",
        "social_category": "General",
        "stream": "Computer Science",
        "grading_system": "cgpa",
        "cgpa": 7.5,
        "has_active_backlogs": False,
    }
    examination = {
        "id": "e_8_0_cgpa",
        "min_cgpa": 8.0,
        "cgpa_scale_max": 10.0,
        "eligible_streams": ["Computer Science"],
    }

    result = matcher.evaluate_candidate_for_examination(candidate, examination)
    assert result["is_eligible"] is False
    assert result["status"] == "not_eligible"
    assert any("below mandatory cutoff of 8.00 CGPA" in r for r in result["reasons"])

def test_matcher_percentage_against_percentage_satisfied():
    # Test D: 65% aggregate marks. Requirement: 50% -> Satisfied
    candidate = {
        "id": "c_pct_65",
        "date_of_birth": "2001-05-10",
        "social_category": "General",
        "stream": "Computer Science",
        "grading_system": "percentage",
        "percentage": 65.0,
        "has_active_backlogs": False,
    }
    examination = {
        "id": "e_50_pct",
        "min_percentage": 50.0,
        "eligible_streams": ["Computer Science"],
    }

    result = matcher.evaluate_candidate_for_examination(candidate, examination)
    assert result["is_eligible"] is True
    assert result["status"] == "eligible"
    assert any("65.0%" in r and "50.0%" in r for r in result["reasons"])

def test_matcher_cgpa_verified_conversion_formula():
    # Test E: 7.5 CGPA. Verified institutional formula (AICTE: (7.5 - 0.75)*10 = 67.5%). Requirement: 50% -> Satisfied
    candidate = {
        "id": "c_cgpa_aicte",
        "date_of_birth": "2001-05-10",
        "social_category": "General",
        "stream": "Computer Science",
        "grading_system": "cgpa",
        "cgpa": 7.5,
        "university": "AICTE approved institution",
        "has_active_backlogs": False,
    }
    examination = {
        "id": "e_50_pct",
        "min_percentage": 50.0,
        "eligible_streams": ["Computer Science"],
    }

    result = matcher.evaluate_candidate_for_examination(candidate, examination)
    assert result["is_eligible"] is True
    assert result["status"] == "eligible"
    assert any("67.5%" in r for r in result["reasons"])
    assert any("AICTE Standard Norm" in r for r in result["reasons"])
