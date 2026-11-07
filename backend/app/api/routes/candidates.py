from datetime import datetime
from fastapi import APIRouter, Depends
from app.schemas.candidate import CandidateProfileResponse, CandidateProfileUpdate
from app.schemas.eligibility import EligibilityReportResponse, CriterionEvaluationResult
from app.core.security import get_current_user_id

router = APIRouter(prefix="/candidates", tags=["Candidate Profile"])

# In-memory mock profile for current candidate
CURRENT_PROFILE = {
    "id": "candidate-rexam-001",
    "email": "arjun.sharma@rexam.in",
    "full_name": "Arjun Sharma",
    "date_of_birth": datetime(1999, 7, 15),
    "gender": "Male",
    "nationality": "Indian",
    "state": "Delhi",
    "district": "New Delhi",
    "country_of_residence": "India",
    "social_category": "OBC-NCL",
    "is_pwbd": False,
    "pwbd_disability_type": None,
    "is_ex_serviceman": False,
    "additional_relaxations": [],
    "highest_qualification": "B.Tech / B.E.",
    "current_qualification": "B.Tech / B.E. (Graduated)",
    "degree_name": "Bachelor of Technology",
    "stream": "Computer Science & Engineering",
    "university_or_college": "Delhi Technological University (DTU)",
    "is_university_recognized": True,
    "graduation_year": 2023,
    "expected_graduation_year": None,
    "cgpa_or_percentage": 78.5,
    "has_active_backlogs": False,
    "current_semester": None,
    "gate_score": 682,
    "gate_year": 2025,
    "has_net_jrf": False,
    "net_subject": None,
    "competitive_exam_scores": {"GATE CS": "682/1000"},
    "certifications": ["AWS Certified Solutions Architect"],
    "work_experience_years": 1.5,
    "research_experience_months": 6,
    "preferred_categories": ["Government Recruitment", "PSU Recruitment"],
    "max_application_fee_budget": 1000.0,
    "willing_to_relocate": True,
    "preferred_states": ["Delhi", "Karnataka", "Maharashtra"],
    "willing_to_work_anywhere_in_india": True,
    "career_interests": ["Computer Science", "Engineering", "Administration"],
    "completion_percentage": 92,
    "created_at": datetime(2026, 1, 15, 10, 0),
    "updated_at": datetime(2026, 3, 1, 14, 0)
}

@router.get("/me", response_model=CandidateProfileResponse)
async def get_my_profile(user_id: str = Depends(get_current_user_id)):
    return CandidateProfileResponse(**CURRENT_PROFILE)

@router.put("/me", response_model=CandidateProfileResponse)
async def update_my_profile(update_data: CandidateProfileUpdate, user_id: str = Depends(get_current_user_id)):
    for field, val in update_data.model_dump(exclude_unset=True).items():
        CURRENT_PROFILE[field] = val
    CURRENT_PROFILE["updated_at"] = datetime.now()
    return CandidateProfileResponse(**CURRENT_PROFILE)

@router.get("/me/eligibility", response_model=EligibilityReportResponse)
async def get_my_eligibility_report(opportunity_id: str = "opp-upsc-cse-2026", user_id: str = Depends(get_current_user_id)):
    return EligibilityReportResponse(
        opportunity_id=opportunity_id,
        opportunity_title="Civil Services Examination (Preliminary) 2026",
        organisation="Union Public Service Commission (UPSC)",
        overall_status="Eligible",
        overall_summary="Candidate satisfies age cutoff, recognized graduation degree and Indian citizenship requirements.",
        criteria_results=[
            CriterionEvaluationResult(
                criterion_name="Age Limit & Cutoff",
                status="Satisfied",
                candidate_value="26 years (DOB: 15/07/1999)",
                requirement="21 to 32 years (Relaxation up to 35 for OBC-NCL)",
                details="Candidate age (26 years) falls squarely within the unreserved limit.",
                rule_evidence="Clause 3(b) 'Age Limits' of Examination Notice."
            ),
            CriterionEvaluationResult(
                criterion_name="Educational Qualification",
                status="Satisfied",
                candidate_value="B.Tech Computer Science (DTU)",
                requirement="Bachelor's degree in any discipline",
                details="Engineering degree from DTU recognized under UGC Act.",
                rule_evidence="Clause 3(c) 'Educational Qualification'."
            )
        ],
        applicable_relaxations=["OBC-NCL relaxation: up to 35 years and 9 attempts"],
        required_documents_for_verification=[
            "10th Board Certificate (DoB Proof)",
            "DTU Graduation Degree Certificate",
            "Central OBC-NCL Certificate issued in FY 2025-26"
        ],
        evaluated_at=datetime.now()
    )
