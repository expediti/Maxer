from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.logging import setup_logging, logger
from app.api.routes import (
    opportunities,
    candidates,
    applications,
    notifications,
    admin,
    auth,
)

@asynccontextmanager
async def lifespan(app: FastAPI):
    setup_logging()
    logger.info("Initializing Rexam Opportunity Intelligence Backend...")
    logger.info(f"Environment: {settings.ENVIRONMENT} | Version: {settings.VERSION}")
    yield
    logger.info("Shutting down Rexam backend services...")

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Backend API foundation for Rexam — Indian Examination, PSU Recruitment, and Education Discovery Platform.",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url=f"{settings.API_V1_PREFIX}/openapi.json",
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount Routes under /api/v1
api_v1_prefix = settings.API_V1_PREFIX

app.include_router(auth.router, prefix=api_v1_prefix)
app.include_router(opportunities.router, prefix=api_v1_prefix)
app.include_router(candidates.router, prefix=api_v1_prefix)
app.include_router(applications.router, prefix=api_v1_prefix)
app.include_router(notifications.router, prefix=api_v1_prefix)
app.include_router(admin.router, prefix=api_v1_prefix)

@app.get("/health", tags=["System Health"])
async def health_check():
    return {
        "status": "healthy",
        "service": "rexam-backend",
        "version": settings.VERSION,
        "environment": settings.ENVIRONMENT,
    }
