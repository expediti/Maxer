from datetime import datetime
from typing import List
from fastapi import APIRouter, HTTPException, Depends, status
from app.schemas.application import ApplicationCreate, ApplicationUpdate, ApplicationResponse
from app.api.routes.opportunities import MOCK_OPPORTUNITIES
from app.schemas.opportunity import OpportunityResponse
from app.core.security import get_current_user_id

router = APIRouter(prefix="/applications", tags=["Application Tracker"])

MOCK_APPLICATIONS = [
    {
        "id": "app-tracker-001",
        "candidate_id": "candidate-rexam-001",
        "opportunity_id": "opp-upsc-cse-2026",
        "opportunity": OpportunityResponse(**MOCK_OPPORTUNITIES[0]),
        "status": "Applied",
        "application_number": "UPSC-2026-948201",
        "applied_date": datetime(2026, 2, 18),
        "exam_date": datetime(2026, 5, 25),
        "personal_notes": "OTR completed. Exam center: Delhi Central.",
        "completed_checklist": ["ID uploaded", "Fee paid"],
        "last_updated": datetime(2026, 2, 18, 14, 20)
    }
]

@router.get("", response_model=List[ApplicationResponse])
async def list_applications(user_id: str = Depends(get_current_user_id)):
    return [ApplicationResponse(**app) for app in MOCK_APPLICATIONS]

@router.post("", response_model=ApplicationResponse, status_code=status.HTTP_201_CREATED)
async def create_application(app_in: ApplicationCreate, user_id: str = Depends(get_current_user_id)):
    opp = next((o for o in MOCK_OPPORTUNITIES if o["id"] == app_in.opportunity_id), None)
    if not opp:
        raise HTTPException(status_code=404, detail="Opportunity not found")
    
    new_app = {
        "id": f"app-tracker-{int(datetime.now().timestamp())}",
        "candidate_id": user_id,
        "opportunity_id": app_in.opportunity_id,
        "opportunity": OpportunityResponse(**opp),
        "status": app_in.status,
        "application_number": app_in.application_number,
        "applied_date": datetime.now(),
        "exam_date": app_in.exam_date,
        "personal_notes": app_in.personal_notes,
        "completed_checklist": [],
        "last_updated": datetime.now()
    }
    MOCK_APPLICATIONS.append(new_app)
    return ApplicationResponse(**new_app)

@router.patch("/{id}", response_model=ApplicationResponse)
async def update_application(id: str, app_update: ApplicationUpdate, user_id: str = Depends(get_current_user_id)):
    for app in MOCK_APPLICATIONS:
        if app["id"] == id:
            for k, v in app_update.model_dump(exclude_unset=True).items():
                app[k] = v
            app["last_updated"] = datetime.now()
            return ApplicationResponse(**app)
    raise HTTPException(status_code=404, detail="Application tracker record not found")
