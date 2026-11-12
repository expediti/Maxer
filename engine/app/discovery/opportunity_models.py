from enum import Enum
from typing import Optional, List, Dict, Any
from datetime import datetime, date
from pydantic import BaseModel, Field

class VerificationStatus(str, Enum):
    DISCOVERED = "discovered"
    EXTRACTED = "extracted"
    NEEDS_REVIEW = "needs_review"
    VERIFIED = "verified"
    PUBLISHED = "published"
    REJECTED = "rejected"
    ARCHIVED = "archived"

class ApplicationStatus(str, Enum):
    UPCOMING = "upcoming"
    OPEN = "open"
    CLOSED = "closed"
    SUSPENDED = "suspended"
    CANCELLED = "cancelled"
    RESULT = "result"
    ARCHIVED = "archived"

class OpportunityType(str, Enum):
    RECRUITMENT_EXAMINATION = "recruitment_examination"
    DIRECT_RECRUITMENT = "direct_recruitment"
    STATE_RECRUITMENT = "state_recruitment"
    DEFENCE_RECRUITMENT = "defence_recruitment"
    SCIENTIFIC_RESEARCH = "scientific_research"
    PSU_RECRUITMENT = "psu_recruitment"
    TEACHING_FACULTY = "teaching_faculty"
    HEALTHCARE_MEDICAL = "healthcare_medical"
    JUDICIAL_LEGAL = "judicial_legal"
    AVIATION_MARITIME = "aviation_maritime"
    AGRICULTURE_RESOURCES = "agriculture_resources"
    APPRENTICESHIP = "apprenticeship"
    INTERNSHIP = "internship"
    FELLOWSHIP = "fellowship"
    SCHOLARSHIP = "scholarship"
    PRIVATE_JOB = "private_job"
    ADMISSION_ENTRANCE = "admission_entrance"
    PROFESSIONAL_LICENSING = "professional_licensing"

class QualificationLevel(str, Enum):
    CLASS_10 = "10th"
    CLASS_12 = "12th"
    ITI = "ITI"
    DIPLOMA = "Diploma"
    UNDERGRADUATE = "Undergraduate"
    POSTGRADUATE = "Postgraduate"
    DOCTORATE = "Doctorate"
    PROFESSIONAL = "Professional"
    EXPERIENCE = "Experience"

class EvidenceModel(BaseModel):
    document_url: Optional[str] = None
    document_hash: Optional[str] = None
    page_number: Optional[int] = None
    section_title: Optional[str] = None
    evidence_text: Optional[str] = None
    extraction_timestamp: Optional[str] = None
    confidence: float = 1.0

class RecruitmentPostModel(BaseModel):
    post_code: Optional[str] = None
    post_name: str
    department: Optional[str] = None
    pay_scale: Optional[str] = None
    pay_level: Optional[str] = None
    vacancies: Optional[int] = None
    category_vacancies: Dict[str, int] = Field(default_factory=dict)
    min_age: Optional[int] = None
    max_age: Optional[int] = None
    educational_qualification: Optional[str] = None
    experience_required: Optional[str] = None
    selection_method: Optional[str] = None
    evidence: Optional[EvidenceModel] = None

class ScholarshipDetailModel(BaseModel):
    scheme_code: Optional[str] = None
    scholarship_type: str = "merit_cum_means"
    funding_agency: str = "Government of India"
    amount_per_year: Optional[float] = None
    financial_benefit_description: str = ""
    income_ceiling_annual: Optional[float] = None
    eligible_courses: List[str] = Field(default_factory=list)
    eligible_categories: List[str] = Field(default_factory=list)
    domicile_state: Optional[str] = None
    academic_marks_requirement: Optional[str] = None
    minimum_marks_percentage: Optional[float] = None
    institution_eligibility: Optional[str] = None
    renewal_conditions: Optional[str] = None
    guidelines_pdf_url: Optional[str] = None
    application_portal_url: Optional[str] = None
    disbursement_mode: str = "DBT"

class InternshipDetailModel(BaseModel):
    program_name: str
    internship_type: str = "government"
    duration_weeks: Optional[int] = None
    stipend_amount_per_month: Optional[float] = None
    stipend_description: Optional[str] = None
    eligible_academic_years: List[str] = Field(default_factory=list)
    eligible_degrees: List[str] = Field(default_factory=list)
    required_skills: List[str] = Field(default_factory=list)
    work_location_type: str = "On-site"
    number_of_openings: Optional[int] = None
    mentor_department: Optional[str] = None
    certificate_provided: bool = True

class ApprenticeshipDetailModel(BaseModel):
    portal_type: str = "NATS" # NATS, NAPS, Direct PSU, Railway
    apprentice_category: str = "Graduate Apprentice"
    designated_trade: str
    stipend_monthly: Optional[float] = None
    training_duration_months: int = 12
    qualification_required: Optional[str] = None
    establishment_registration_no: Optional[str] = None

class FellowshipDetailModel(BaseModel):
    fellowship_type: str = "JRF" # JRF, SRF, Postdoc, PMRF
    awarding_body: str
    fellowship_amount_monthly: Optional[float] = None
    contingency_grant_annual: Optional[float] = None
    tenure_years: int = 2
    qualifying_exam: Optional[str] = None
    subject_area: Optional[str] = None
    host_institution_type: Optional[str] = None

class PrivateJobRequisitionModel(BaseModel):
    requisition_id: str
    company_name: str
    industry_sector: str
    role_family: str
    work_experience_min_years: Optional[float] = 0.0
    work_experience_max_years: Optional[float] = None
    job_location: str = "Pan India"
    employment_type: str = "Full-time"
    salary_range_min: Optional[float] = None
    salary_range_max: Optional[float] = None
    salary_currency: str = "INR"
    primary_skills: List[str] = Field(default_factory=list)
    career_page_url: str
    verified_on_employer_site: bool = True
    employer_domain: Optional[str] = None

class AdmissionQualificationModel(BaseModel):
    admission_level: str = "Postgraduate"
    conducting_agency: str
    target_courses: List[str] = Field(default_factory=list)
    score_validity_years: int = 1
    leads_to_direct_recruitment: bool = False
    participating_institutes_count: Optional[int] = None
    counselling_authority: Optional[str] = None

class OpportunityCore(BaseModel):
    id: Optional[str] = None
    canonical_id: Optional[str] = None
    slug: str
    title: str
    name: Optional[str] = None
    organisation_name: str
    organisation_id: Optional[str] = None
    source_id: Optional[str] = None
    opportunity_type: OpportunityType = OpportunityType.RECRUITMENT_EXAMINATION
    category: str = "Government Recruitment"
    sector: Optional[str] = None
    sub_sector: Optional[str] = None
    state: Optional[str] = None
    location: str = "All India"
    is_central_government: bool = True
    qualification_levels: List[str] = Field(default_factory=list)
    advertisement_number: Optional[str] = None
    requisition_id: Optional[str] = None
    application_status: ApplicationStatus = ApplicationStatus.OPEN
    verification_status: VerificationStatus = VerificationStatus.DISCOVERED
    overview: str = ""
    vacancies: Optional[int] = None
    salary_or_pay_scale: Optional[str] = None
    stipend: Optional[str] = None
    application_fee: Optional[float] = None
    fee_exemptions: Optional[str] = None
    official_source_url: str
    official_apply_url: Optional[str] = None
    notification_document_url: Optional[str] = None
    application_open_date: Optional[str] = None
    application_close_date: Optional[str] = None
    examination_date: Optional[str] = None
    minimum_age: Optional[int] = None
    maximum_age: Optional[int] = None
    age_cutoff_date: Optional[str] = None
    category_age_relaxations: Dict[str, str] = Field(default_factory=dict)
    educational_eligibility: List[str] = Field(default_factory=list)
    required_disciplines: List[str] = Field(default_factory=list)
    minimum_percentage: Optional[float] = None
    minimum_cgpa: Optional[float] = None
    grading_type: str = "percentage"
    required_documents: List[str] = Field(default_factory=list)
    selection_process: Optional[str] = None
    evidence: Dict[str, Any] = Field(default_factory=dict)
    uncertain_fields: List[str] = Field(default_factory=list)
    first_seen_at: Optional[str] = None
    last_seen_at: Optional[str] = None
    last_verified_at: Optional[str] = None

    # Sub-records
    posts: List[RecruitmentPostModel] = Field(default_factory=list)
    scholarship_detail: Optional[ScholarshipDetailModel] = None
    internship_detail: Optional[InternshipDetailModel] = None
    apprenticeship_detail: Optional[ApprenticeshipDetailModel] = None
    fellowship_detail: Optional[FellowshipDetailModel] = None
    private_job_detail: Optional[PrivateJobRequisitionModel] = None
    admission_detail: Optional[AdmissionQualificationModel] = None

