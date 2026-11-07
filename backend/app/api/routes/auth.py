from fastapi import APIRouter
from pydantic import BaseModel, EmailStr
from app.core.security import create_access_token

router = APIRouter(prefix="/auth", tags=["Authentication"])

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str

@router.post("/token", response_model=TokenResponse)
async def login_for_access_token(form_data: LoginRequest):
    # Generates JWT token for candidate session
    token = create_access_token(subject="candidate-rexam-001")
    return TokenResponse(access_token=token, user_id="candidate-rexam-001")
