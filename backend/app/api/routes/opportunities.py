from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, HTTPException, Query, status
from app.schemas.opportunity import OpportunityResponse, OpportunityListResponse

router = APIRouter(prefix="/opportunities", tags=["Opportunities"])

# In-memory realistic initial dataset matching Flutter mock data
MOCK_OPPORTUNITIES = [
    {
        "id": "opp-upsc-cse-2026",
        "title": "Civil Services Examination (Preliminary) 2026",
        "organisation": "Union Public Service Commission (UPSC)",
        "issuing_authority": "Department of Personnel and Training (DoPT), Government of India",
        "category": "Government Recruitment",
        "overview": "The Civil Services Examination is conducted annually by UPSC to recruit officers into premier Indian administrative services including IAS, IFS, IPS, and Central Group A & B services.",
        "vacancies": 1056,
        "eligibility_criteria_summary": "Must hold a degree of any recognized university. Age 21 to 32 years as on 1st August 2026, with statutory relaxation for reserved categories.",
        "min_age": 21,
        "max_age": 32,
        "category_age_relaxation": {
            "General / EWS": "No relaxation (32 years maximum, 6 attempts)",
            "OBC-NCL": "3 years relaxation (up to 35 years, 9 attempts)",
            "SC / ST": "5 years relaxation (up to 37 years, unlimited attempts)",
            "PwBD": "10 years relaxation (up to 42 years)"
        },
        "educational_qualifications": [
            "Bachelor’s Degree in any discipline from a recognized University.",
            "Candidates appearing in final year degree examination are eligible to apply provisionally."
        ],
        "eligible_streams": ["All Disciplines (Engineering, Sciences, Arts, Commerce, Medicine, Law)"],
        "min_percentage": None,
        "nationality": "Citizen of India",
        "gender_requirements": "All genders eligible.",
        "work_experience": "No prior work experience required.",
        "application_fee": 100.0,
        "fee_exemptions": "Female candidates, SC, ST, and PwBD are fully exempted.",
        "required_documents": [
            "Government Photo ID Proof",
            "Class 10th Certificate",
            "Graduation Degree / Bonafide Certificate"
        ],
        "important_dates": {
            "Application Deadline": datetime(2026, 3, 6, 18, 0),
            "Preliminary Examination": datetime(2026, 5, 25)
        },
        "selection_procedure": "Prelims (Objective) -> Mains (Written) -> Personality Interview.",
        "exam_pattern": "Prelims: Paper 1 GS (200 marks), Paper 2 CSAT (200 marks qualifying 33%).",
        "salary_or_pay_scale": "Level 10 (₹56,100 to ₹1,77,500 base pay).",
        "location": "All India Service.",
        "application_instructions": "Apply exclusively via UPSC OTR at upsconline.nic.in.",
        "official_notification_pdf_url": "https://upsc.gov.in/sites/default/files/ExamNotice_CSE_2026.pdf",
        "official_application_url": "https://upsconline.nic.in",
        "source_url": "https://upsc.gov.in",
        "application_deadline": datetime(2026, 3, 6, 18, 0),
        "is_central_government": True,
        "state": None,
        "is_confirmed": True,
        "last_verified_at": datetime(2026, 3, 1, 10, 30),
        "is_official_source": True,
        "uncertain_fields": []
    },
    {
        "id": "opp-isro-scientist-2026",
        "title": 'Recruitment of Scientist/Engineer "SC" (Computer Science / Mechanical / Electronics)',
        "organisation": "Indian Space Research Organisation (ISRO)",
        "issuing_authority": "Department of Space, Vikram Sarabhai Space Centre & URSC",
        "category": "PSU Recruitment",
        "overview": "ISRO invites online applications for Scientist/Engineer 'SC' positions across ISRO centres.",
        "vacancies": 320,
        "eligibility_criteria_summary": "First Class B.E. / B.Tech or equivalent in CS, Electronics, or Mechanical with minimum 65% aggregate or 6.84 CGPA.",
        "min_age": 18,
        "max_age": 28,
        "category_age_relaxation": {
            "OBC-NCL": "31 years (3 years relaxation)",
            "SC / ST": "33 years (5 years relaxation)"
        },
        "educational_qualifications": [
            "B.E. / B.Tech in CS / IT / Mechanical / ECE.",
            "Minimum 65% aggregate or 6.84 CGPA."
        ],
        "eligible_streams": ["Computer Science & Engineering", "Mechanical Engineering", "Electronics & Communication"],
        "min_percentage": 65.0,
        "nationality": "Citizen of India",
        "gender_requirements": "All genders eligible.",
        "work_experience": "Fresh engineering graduates eligible.",
        "application_fee": 250.0,
        "fee_exemptions": "All women, SC/ST/PwBD and Ex-Servicemen are exempted.",
        "required_documents": ["10th and 12th Marksheets", "B.Tech Consolidated Marksheet"],
        "important_dates": {
            "Application Deadline": datetime(2026, 3, 15, 23, 59),
            "Written Examination": datetime(2026, 5, 10)
        },
        "selection_procedure": "Written CBT test followed by technical interview in 1:5 ratio.",
        "exam_pattern": "80 discipline questions + 20 aptitude questions.",
        "salary_or_pay_scale": "Level 10 (Gross ~₹92,000/month).",
        "location": "Bengaluru, Thiruvananthapuram, Sriharikota, Ahmedabad.",
        "application_instructions": "Register online via ICRB portal.",
        "official_notification_pdf_url": "https://www.isro.gov.in/media_isro/pdf/recruitment/ICRB_01_2026.pdf",
        "official_application_url": "https://apps.isac.gov.in/icrb-2026",
        "source_url": "https://isro.gov.in",
        "application_deadline": datetime(2026, 3, 15, 23, 59),
        "is_central_government": True,
        "state": None,
        "is_confirmed": True,
        "last_verified_at": datetime(2026, 3, 2, 14, 0),
        "is_official_source": True,
        "uncertain_fields": []
    }
]

@router.get("", response_model=OpportunityListResponse)
async def list_opportunities(
    category: Optional[str] = None,
    is_central_government: Optional[bool] = None,
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
):
    items = MOCK_OPPORTUNITIES
    if category:
        items = [i for i in items if i["category"].lower() == category.lower()]
    if is_central_government is not None:
        items = [i for i in items if i["is_central_government"] == is_central_government]
    
    start = (page - 1) * size
    end = start + size
    return OpportunityListResponse(
        items=[OpportunityResponse(**i) for i in items[start:end]],
        total=len(items),
        page=page,
        size=size
    )

@router.get("/search", response_model=List[OpportunityResponse])
async def search_opportunities(q: str = Query(..., min_length=1)):
    query = q.lower()
    results = [
        OpportunityResponse(**i) for i in MOCK_OPPORTUNITIES
        if query in i["title"].lower() or query in i["organisation"].lower() or any(query in s.lower() for s in i["eligible_streams"])
    ]
    return results

@router.get("/recommended", response_model=List[OpportunityResponse])
async def recommended_opportunities():
    return [OpportunityResponse(**i) for i in MOCK_OPPORTUNITIES]

@router.get("/closing-soon", response_model=List[OpportunityResponse])
async def closing_soon_opportunities():
    sorted_items = sorted(MOCK_OPPORTUNITIES, key=lambda x: x["application_deadline"])
    return [OpportunityResponse(**i) for i in sorted_items[:5]]

@router.get("/{id}", response_model=OpportunityResponse)
async def get_opportunity(id: str):
    for i in MOCK_OPPORTUNITIES:
        if i["id"] == id:
            return OpportunityResponse(**i)
    raise HTTPException(status_code=404, detail="Opportunity not found")

@router.post("/{id}/save", status_code=status.HTTP_201_CREATED)
async def save_opportunity(id: str):
    return {"status": "success", "message": f"Opportunity {id} saved to candidate bookmarks"}

@router.delete("/{id}/save", status_code=status.HTTP_200_OK)
async def unsave_opportunity(id: str):
    return {"status": "success", "message": f"Opportunity {id} removed from bookmarks"}
