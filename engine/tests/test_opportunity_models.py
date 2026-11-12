import pytest
from pydantic import ValidationError
from engine.app.discovery.opportunity_models import (
    OpportunityCore,
    RecruitmentPostModel,
    ScholarshipDetailModel,
    InternshipDetailModel,
    ApprenticeshipDetailModel,
    PrivateJobRequisitionModel,
    AdmissionQualificationModel,
    VerificationStatus,
    OpportunityType,
)

def test_opportunity_core_defaults_and_null_preservation():
    """Ensure missing fields remain None rather than being fabricated."""
    opp = OpportunityCore(
        slug="test-exam-2026",
        title="Test Examination 2026",
        organisation_name="Official Authority",
        official_source_url="https://example.gov.in/notice",
    )
    assert opp.vacancies is None
    assert opp.salary_or_pay_scale is None
    assert opp.stipend is None
    assert opp.minimum_age is None
    assert opp.maximum_age is None
    assert opp.minimum_percentage is None
    assert opp.minimum_cgpa is None
    assert opp.verification_status == VerificationStatus.DISCOVERED

def test_recruitment_multi_posts():
    """Verify notifications with multiple posts/cadres can be represented cleanly."""
    post1 = RecruitmentPostModel(
        post_code="P01",
        post_name="Assistant Executive Engineer (Civil)",
        vacancies=45,
        min_age=21,
        max_age=30,
        educational_qualification="B.Tech in Civil Engineering",
    )
    post2 = RecruitmentPostModel(
        post_code="P02",
        post_name="Assistant Executive Engineer (Electrical)",
        vacancies=30,
        min_age=21,
        max_age=30,
        educational_qualification="B.Tech in Electrical Engineering",
    )

    opp = OpportunityCore(
        slug="state-engineering-services-2026",
        title="Combined State Engineering Services 2026",
        organisation_name="State PSC",
        official_source_url="https://psc.state.gov.in/engg",
        opportunity_type=OpportunityType.STATE_RECRUITMENT,
        vacancies=75,
        posts=[post1, post2]
    )

    assert len(opp.posts) == 2
    assert opp.posts[0].post_code == "P01"
    assert opp.posts[1].post_name == "Assistant Executive Engineer (Electrical)"
    assert sum(p.vacancies for p in opp.posts) == 75

def test_scholarship_detail_model():
    scholarship = ScholarshipDetailModel(
        scheme_code="PRAGATI-GIRLS",
        scholarship_type="girls_technical_education",
        funding_agency="AICTE",
        amount_per_year=50000.0,
        income_ceiling_annual=800000.0,
        eligible_courses=["B.Tech", "Diploma"],
        disbursement_mode="DBT",
    )
    assert scholarship.amount_per_year == 50000.0
    assert scholarship.income_ceiling_annual == 800000.0
    assert "B.Tech" in scholarship.eligible_courses

def test_private_job_requisition_model():
    job = PrivateJobRequisitionModel(
        requisition_id="TCS-NQT-2026-098",
        company_name="Tata Consultancy Services",
        industry_sector="Information Technology",
        role_family="Software & IT",
        work_experience_min_years=0.0,
        job_location="Bengaluru / Hyderabad / Pune",
        career_page_url="https://www.tcs.com/careers/job/098",
    )
    assert job.requisition_id == "TCS-NQT-2026-098"
    assert job.role_family == "Software & IT"
    assert job.verified_on_employer_site is True

def test_admission_qualification_model():
    adm = AdmissionQualificationModel(
        conducting_agency="Consortium of NLUs",
        admission_level="Undergraduate",
        target_courses=["B.A. LL.B (Hons)", "B.B.A. LL.B (Hons)"],
        score_validity_years=1,
        leads_to_direct_recruitment=False,
    )
    assert adm.leads_to_direct_recruitment is False
    assert "B.A. LL.B (Hons)" in adm.target_courses

