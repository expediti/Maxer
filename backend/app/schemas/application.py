from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field
from .opportunity import OpportunityResponse

class ApplicationCreate(BaseModel):
    opportunity_id: str
    status: str = "Interested"
    application_number: Optional[str] = None
    exam_date: Optional[datetime] = None
    personal_notes: Optional[str] = None

class ApplicationUpdate(BaseModel):
    status: Optional[str] = None
    application_number: Optional[str] = None
    exam_date: Optional[datetime] = None
    personal_notes: Optional[str] = None
    completed_checklist: Optional[List[str]] = None

class ApplicationResponse(BaseModel):
    id: str
    candidate_id: str
    opportunity_id: str
    opportunity: OpportunityResponse
    status: str
    application_number: Optional[str] = None
    applied_date: datetime
    exam_date: Optional[datetime] = None
    personal_notes: Optional[str] = None
    completed_checklist: List[str] = Field(default_factory=list)
    last_updated: datetime
