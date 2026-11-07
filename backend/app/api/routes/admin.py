from datetime import datetime
from typing import List
from fastapi import APIRouter, HTTPException
from app.schemas.admin import CrawlerHealthStatus, DiscoveredRecordReview, RecordApprovalAction

router = APIRouter(prefix="/admin", tags=["Admin Operations"])

MOCK_CRAWLERS = [
    {
        "source_name": "UPSC Official Notices RSS & Gazette",
        "target_url": "https://upsc.gov.in/examinations/active-examinations",
        "last_scan_at": datetime(2026, 3, 5, 8, 0),
        "status": "HEALTHY",
        "records_discovered": 14,
        "last_error": None
    },
    {
        "source_name": "ISRO ICRB Recruitment Portal",
        "target_url": "https://apps.isac.gov.in/icrb-2026",
        "last_scan_at": datetime(2026, 3, 5, 7, 30),
        "status": "HEALTHY",
        "records_discovered": 4,
        "last_error": None
    }
]

MOCK_PENDING_RECORDS = [
    {
        "id": "raw-scan-upsc-01",
        "source_url": "https://upsc.gov.in/sites/default/files/ExamNotice_CSE_2026.pdf",
        "pdf_url": "https://upsc.gov.in/sites/default/files/ExamNotice_CSE_2026.pdf",
        "extracted_title": "Civil Services Examination (Preliminary) 2026",
        "extracted_organisation": "Union Public Service Commission (UPSC)",
        "confidence_score": 0.98,
        "status": "APPROVED",
        "created_at": datetime(2026, 2, 14, 11, 0)
    }
]

@router.get("/crawlers/health", response_model=List[CrawlerHealthStatus])
async def get_crawlers_health():
    return [CrawlerHealthStatus(**c) for c in MOCK_CRAWLERS]

@router.get("/records/pending-review", response_model=List[DiscoveredRecordReview])
async def get_pending_records():
    return [DiscoveredRecordReview(**r) for r in MOCK_PENDING_RECORDS]

@router.post("/records/{id}/action")
async def review_record(id: str, action_data: RecordApprovalAction):
    for r in MOCK_PENDING_RECORDS:
        if r["id"] == id:
            r["status"] = "APPROVED" if action_data.action == "APPROVE" else "REJECTED"
            return {"status": "success", "record_id": id, "new_status": r["status"]}
    raise HTTPException(status_code=404, detail="Pending review record not found")
