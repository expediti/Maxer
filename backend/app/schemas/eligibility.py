from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel

class CriterionEvaluationResult(BaseModel):
    criterion_name: str
    status: str # "Satisfied", "Satisfied with Relaxation", "Not Satisfied", "Needs Confirmation"
    candidate_value: str
    requirement: str
    details: str
    rule_evidence: Optional[str] = None

class EligibilityReportResponse(BaseModel):
    opportunity_id: str
    opportunity_title: str
    organisation: str
    overall_status: str # "Eligible", "Potentially Eligible", "Not Eligible", "Review Needed"
    overall_summary: str
    criteria_results: List[CriterionEvaluationResult]
    applicable_relaxations: List[str]
    required_documents_for_verification: List[str]
    evaluated_at: datetime
