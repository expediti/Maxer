import pytest
from engine.app.ai.cloudflare_ai import StructuredExtractionResult, cloudflare_ai_client

def test_structured_extraction_result_validation():
    sample_data = {
        "title": "ISRO Scientist/Engineer SC Recruitment 2026",
        "organisation": "ISRO",
        "overview": "Recruitment for 320 Group A Gazetted posts.",
        "vacancies": 320,
        "min_age": 18,
        "max_age": 28,
        "category_age_relaxations": {"OBC": "3 years", "SC/ST": "5 years"},
        "educational_qualifications": ["B.E. / B.Tech in CS/Mechanical/ECE"],
        "eligible_streams": ["Computer Science", "Mechanical Engineering"],
        "min_percentage": 65.0,
        "application_opening_date": "2026-02-01",
        "application_closing_date": "2026-02-28",
        "prelims_exam_date": "2026-05-15",
        "application_fee": 250.0,
        "fee_exemptions": "All female, SC, ST, PwBD candidates are exempt.",
        "required_documents": ["Degree Certificate", "Class 10th Certificate"],
        "selection_procedure": "Written Test + Interview",
        "confidence_score": 0.95
    }

    result = StructuredExtractionResult(**sample_data)
    assert result.vacancies == 320
    assert result.max_age == 28
    assert len(result.eligible_streams) == 2

def test_heuristic_fallback_extraction():
    notice_text = """
    UNION PUBLIC SERVICE COMMISSION
    EXAMINATION NOTICE NO. 05/2026-CSP
    CIVIL SERVICES EXAMINATION, 2026
    The Union Public Service Commission will hold the Civil Services Preliminary Examination on 25th May 2026.
    Candidates should note that there are approximately 1056 vacancies.
    Age limit: 21 to 32 years on 1st of August, 2026.
    Candidates must pay an application fee of Rs. 100.
    """
    context = {"title": "Civil Services Examination 2026", "organisation_name": "UPSC"}
    extracted = cloudflare_ai_client._heuristic_fallback(notice_text, context)

    assert extracted["vacancies"] == 1056
    assert extracted["min_age"] == 21
    assert extracted["max_age"] == 32
    assert extracted["application_fee"] == 100.0
    assert extracted["requires_human_review"] is True

