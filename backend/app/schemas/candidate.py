from datetime import datetime
from typing import List, Optional, Dict
from pydantic import BaseModel, Field

class CandidateProfileBase(BaseModel):
    full_name: str
    date_of_birth: Optional[datetime] = None
    gender: Optional[str] = None
    nationality: str = "Indian"
    state: Optional[str] = None
    district: Optional[str] = None
    country_of_residence: str = "India"
    
    # Category
    social_category: str = "General"
    is_pwbd: bool = False
    pwbd_disability_type: Optional[str] = None
    is_ex_serviceman: bool = False
    additional_relaxations: List[str] = Field(default_factory=list)
    
    # Education
    highest_qualification: Optional[str] = None
    current_qualification: Optional[str] = None
    degree_name: Optional[str] = None
    stream: Optional[str] = None
    university_or_college: Optional[str] = None
    is_university_recognized: bool = True
    graduation_year: Optional[int] = None
    expected_graduation_year: Optional[int] = None
    cgpa_or_percentage: Optional[float] = None
    has_active_backlogs: bool = False
    current_semester: Optional[int] = None
    
    # Additional Qualifications
    gate_score: Optional[int] = None
    gate_year: Optional[int] = None
    has_net_jrf: bool = False
    net_subject: Optional[str] = None
    competitive_exam_scores: Dict[str, str] = Field(default_factory=dict)
    certifications: List[str] = Field(default_factory=list)
    work_experience_years: float = 0.0
    research_experience_months: int = 0
    
    # Preferences
    preferred_categories: List[str] = Field(default_factory=list)
    max_application_fee_budget: Optional[float] = None
    willing_to_relocate: bool = True
    preferred_states: List[str] = Field(default_factory=list)
    willing_to_work_anywhere_in_india: bool = True
    career_interests: List[str] = Field(default_factory=list)

class CandidateProfileUpdate(CandidateProfileBase):
    pass

class CandidateProfileResponse(CandidateProfileBase):
    id: str
    email: str
    completion_percentage: int = 85
    created_at: datetime
    updated_at: datetime
