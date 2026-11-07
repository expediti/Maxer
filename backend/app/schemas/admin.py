from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel

class CrawlerHealthStatus(BaseModel):
    source_name: str
    target_url: str
    last_scan_at: datetime
    status: str # "HEALTHY", "WARNING", "FAILED"
    records_discovered: int
    last_error: Optional[str] = None

class DiscoveredRecordReview(BaseModel):
    id: str
    source_url: str
    pdf_url: Optional[str] = None
    extracted_title: str
    extracted_organisation: str
    confidence_score: float
    status: str # "PENDING_REVIEW", "APPROVED", "REJECTED"
    created_at: datetime

class RecordApprovalAction(BaseModel):
    action: str # "APPROVE" or "REJECT"
    rejection_reason: Optional[str] = None
    corrected_data: Optional[dict] = None
