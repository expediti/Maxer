from datetime import datetime
from fastapi import APIRouter
from app.schemas.notification import NotificationListResponse, NotificationItem

router = APIRouter(prefix="/notifications", tags=["Notifications & Alerts"])

MOCK_NOTIFICATIONS = [
    {
        "id": "alert-1",
        "title": "Deadline Approaching: UPSC CSE 2026",
        "message": "Online registration for Civil Services Preliminary 2026 closes on 6th March 2026 at 18:00 IST.",
        "type": "Upcoming Deadline",
        "opportunity_id": "opp-upsc-cse-2026",
        "timestamp": datetime(2026, 3, 4, 9, 30),
        "is_read": False,
        "official_source_url": "https://upsc.gov.in"
    },
    {
        "id": "alert-2",
        "title": 'Corrigendum Issued: ISRO ICRB 01/2026',
        "message": "VSSC has issued an addendum clarifying CGPA-to-percentage conversion norm.",
        "type": "Corrigendum / Addendum",
        "opportunity_id": "opp-isro-scientist-2026",
        "timestamp": datetime(2026, 3, 1, 11, 0),
        "is_read": True,
        "official_source_url": "https://isro.gov.in"
    }
]

@router.get("", response_model=NotificationListResponse)
async def list_notifications():
    unread = sum(1 for n in MOCK_NOTIFICATIONS if not n["is_read"])
    return NotificationListResponse(
        items=[NotificationItem(**n) for n in MOCK_NOTIFICATIONS],
        unread_count=unread
    )
