from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel

class NotificationItem(BaseModel):
    id: str
    title: str
    message: str
    type: str
    opportunity_id: Optional[str] = None
    timestamp: datetime
    is_read: bool = False
    official_source_url: Optional[str] = None

class NotificationListResponse(BaseModel):
    items: List[NotificationItem]
    unread_count: int
