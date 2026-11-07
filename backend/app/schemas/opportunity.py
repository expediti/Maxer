from datetime import datetime
from typing import List, Optional, Dict
from pydantic import BaseModel, Field

class OpportunityBase(BaseModel):
    title: str
    organisation: str
    issuing_authority: str
    category: str
    overview: str
    vacancies: Optional[int] = None
    eligibility_criteria_summary: str
    min_age: int
    max_age: int
    category_age_relaxation: Dict[str, str] = Field(default_factory=dict)
    educational_qualifications: List[str] = Field(default_factory=list)
    eligible_streams: List[str] = Field(default_factory=list)
    min_percentage: Optional[float] = None
    nationality: str = "Citizen of India"
    gender_requirements: str = "All genders eligible"
    work_experience: str = "No experience required"
    application_fee: Optional[float] = None
    fee_exemptions: str = "SC/ST/PwBD and female candidates exempted"
    required_documents: List[str] = Field(default_factory=list)
    important_dates: Dict[str, Optional[datetime]] = Field(default_factory=dict)
    selection_procedure: str
    exam_pattern: Optional[str] = None
    salary_or_pay_scale: Optional[str] = None
    location: str
    application_instructions: str
    official_notification_pdf_url: Optional[str] = None
    official_application_url: str
    source_url: str
    application_deadline: datetime
    is_central_government: bool = True
    state: Optional[str] = None
    is_confirmed: bool = True

class OpportunityResponse(OpportunityBase):
    id: str
    last_verified_at: datetime
    is_official_source: bool = True
    uncertain_fields: List[str] = Field(default_factory=list)

class OpportunityListResponse(BaseModel):
    items: List[OpportunityResponse]
    total: int
    page: int
    size: int
