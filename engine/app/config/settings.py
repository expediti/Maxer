import os
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field

class Settings(BaseSettings):
    # Supabase credentials (Service role key for administrative data ingestion)
    SUPABASE_URL: str = Field(default=os.getenv("SUPABASE_URL", ""))
    SUPABASE_SERVICE_ROLE_KEY: str = Field(default=os.getenv("SUPABASE_SERVICE_ROLE_KEY", ""))

    # Cloudflare Workers AI configuration
    CLOUDFLARE_ACCOUNT_ID: str = Field(default=os.getenv("CLOUDFLARE_ACCOUNT_ID", ""))
    CLOUDFLARE_API_TOKEN: str = Field(default=os.getenv("CLOUDFLARE_API_TOKEN", ""))
    CLOUDFLARE_AI_MODEL: str = Field(default=os.getenv("CLOUDFLARE_AI_MODEL", "@cf/meta/llama-3.1-8b-instruct"))

    # Crawler & Rate Limiting
    CRAWLER_USER_AGENT: str = Field(
        default="RexamOpportunityBot/1.0 (+https://rexam.in; compliance@rexam.in)"
    )
    REQUEST_TIMEOUT_SECONDS: int = Field(default=30)
    RATE_LIMIT_DELAY_SECONDS: float = Field(default=1.5)
    MAX_RETRIES: int = Field(default=3)
    STORAGE_DIR: str = Field(default="/tmp/rexam_downloads")

    # Environment
    ENVIRONMENT: str = Field(default="development")

    model_config = SettingsConfigDict(
        env_file=(".env", "engine/.env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

settings = Settings()
