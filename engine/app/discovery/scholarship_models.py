from typing import List, Optional, Dict, Any
from datetime import datetime, timezone
from pydantic import BaseModel, Field, HttpUrl

class ScholarshipScheme(BaseModel):
    title: str = Field(..., min_length=5, description="Full official title of the scholarship scheme")
    organisation_name: str = Field(..., description="Official ministry, council, or conducting institution")
    category: str = Field(default="Scholarships & Fellowships")
    financial_benefit: str = Field(..., description="Stipend, tuition waiver, or grant amount")
    overview: str = Field(..., min_length=20, description="Comprehensive summary of scheme objectives")
    eligibility_criteria: str = Field(..., description="Statutory eligibility, minimum marks, degree requirements")
    eligible_streams: List[str] = Field(default_factory=lambda: ["All Streams"])
    educational_qualifications: List[str] = Field(default_factory=lambda: ["Undergraduate", "Postgraduate", "Doctoral"])
    min_percentage: Optional[float] = Field(default=None, ge=0.0, le=100.0)
    min_cgpa: Optional[float] = Field(default=None, ge=0.0, le=10.0)
    grading_type: str = Field(default="percentage")
    cgpa_scale_max: float = Field(default=10.0)
    min_age: Optional[int] = Field(default=16, ge=10, le=100)
    max_age: Optional[int] = Field(default=35, ge=10, le=100)
    family_income_ceiling: Optional[str] = Field(default=None)
    application_opening_date: Optional[str] = None
    application_closing_date: Optional[str] = None
    official_application_url: str = Field(..., description="Official portal to register and submit application")
    official_notification_url: Optional[str] = Field(default=None, description="Official guidelines PDF or notice URL")
    is_central_scheme: bool = True
    is_confirmed: bool = True

    def is_valid_deadline(self) -> bool:
        """Returns True if closing date is in the future or open cycle."""
        if not self.application_closing_date:
            return True
        try:
            closing_dt = datetime.fromisoformat(self.application_closing_date.replace("Z", "+00:00"))
            return closing_dt > datetime.now(timezone.utc)
        except Exception:
            return True

