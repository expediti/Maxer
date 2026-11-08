import os
import json
import logging
import httpx
from typing import Dict, Any, Optional
from pydantic import BaseModel, Field
from engine.app.config.settings import settings

logger = logging.getLogger("rexam.cloudflare_ai")

class StructuredExtractionResult(BaseModel):
    title: str = Field(description="Official title of the examination or recruitment")
    organisation: str = Field(description="Name of the recruiting commission or authority")
    overview: str = Field(default="", description="Summary of the recruitment drive")
    vacancies: Optional[int] = Field(default=None, description="Total number of advertised vacancies")
    min_age: Optional[int] = Field(default=None, description="Minimum age requirement in years")
    max_age: Optional[int] = Field(default=None, description="Maximum age limit in years for unreserved category")
    category_age_relaxations: Dict[str, str] = Field(default_factory=dict, description="Age relaxation rules per category")
    educational_qualifications: list[str] = Field(default_factory=list, description="Mandatory degree/diploma requirements")
    eligible_streams: list[str] = Field(default_factory=list, description="Eligible branches or disciplines")
    min_percentage: Optional[float] = Field(default=None, description="Minimum percentage or CGPA required")
    application_opening_date: Optional[str] = Field(default=None, description="ISO format opening date")
    application_closing_date: Optional[str] = Field(default=None, description="ISO format deadline date")
    prelims_exam_date: Optional[str] = Field(default=None, description="ISO format preliminary exam date")
    application_fee: Optional[float] = Field(default=None, description="Application fee amount in INR")
    fee_exemptions: str = Field(default="", description="Fee waiver conditions for SC/ST/Women/PwBD")
    required_documents: list[str] = Field(default_factory=list, description="Documents required during application")
    selection_procedure: str = Field(default="", description="Stages of examination")
    confidence_score: float = Field(default=0.85, description="Extraction confidence between 0.0 and 1.0")

class CloudflareWorkersAIClient:
    """REST client for Cloudflare Workers AI with fallback to deterministic heuristics."""

    def __init__(self):
        self.account_id = settings.CLOUDFLARE_ACCOUNT_ID
        self.api_token = settings.CLOUDFLARE_API_TOKEN
        self.model = settings.CLOUDFLARE_AI_MODEL
        self.endpoint = (
            f"https://api.cloudflare.com/client/v4/accounts/{self.account_id}/ai/run/{self.model}"
            if self.account_id else ""
        )

    def is_configured(self) -> bool:
        return bool(self.account_id and self.api_token and self.endpoint)

    async def extract_examination_data(self, document_text: str, source_context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Extracts structured examination attributes from official document text.
        Falls back to rule-based fallback if Cloudflare AI is not configured or fails.
        """
        if not self.is_configured():
            logger.info("Cloudflare Workers AI not configured. Applying heuristic rule-based extraction with 'under_review' status.")
            return self._heuristic_fallback(document_text, source_context)

        prompt = f"""
You are a specialized parser for Indian public service commission and recruitment notifications.
Extract key details from the following notification text into strict JSON matching this schema:
- title: string
- organisation: string
- overview: string
- vacancies: integer or null
- min_age: integer or null
- max_age: integer or null
- category_age_relaxations: object mapping category names to relaxation descriptions
- educational_qualifications: list of strings
- eligible_streams: list of strings
- min_percentage: float or null
- application_opening_date: YYYY-MM-DD or null
- application_closing_date: YYYY-MM-DD or null
- prelims_exam_date: YYYY-MM-DD or null
- application_fee: float or null
- fee_exemptions: string
- required_documents: list of strings
- selection_procedure: string

DOCUMENT TEXT:
{document_text[:8000]}
"""
        headers = {
            "Authorization": f"Bearer {self.api_token}",
            "Content-Type": "application/json"
        }
        payload = {
            "messages": [
                {"role": "system", "content": "You are a precise data extractor that returns only valid JSON."},
                {"role": "user", "content": prompt}
            ]
        }

        try:
            async with httpx.AsyncClient(timeout=45) as client:
                resp = await client.post(self.endpoint, headers=headers, json=payload)
                if resp.status_code == 200:
                    result = resp.json().get("result", {})
                    response_text = result.get("response", "")

                    # Extract JSON block
                    start = response_text.find("{")
                    end = response_text.rfind("}")
                    if start != -1 and end != -1:
                        parsed_json = json.loads(response_text[start:end+1])
                        validated = StructuredExtractionResult(**parsed_json)
                        return validated.model_dump()
        except Exception as e:
            logger.warning(f"Cloudflare AI extraction call failed: {e}. Falling back to heuristic extraction.")

        return self._heuristic_fallback(document_text, source_context)

    def _heuristic_fallback(self, text: str, context: Dict[str, Any]) -> Dict[str, Any]:
        """Deterministic regex and keyword-based extraction when AI is offline or unavailable."""
        import re

        title = context.get("title") or "Recruitment Notification"
        organisation = context.get("organisation_name") or "Government Authority"

        # Look for vacancies pattern (e.g., '1056 vacancies', 'Vacancies: 320')
        vacancies = None
        vac_match = re.search(r'([0-9,]+)\s*(?:vacancies|posts|openings)', text, re.IGNORECASE) or \
                    re.search(r'(?:vacancies|posts|openings)[:\s]+([0-9,]+)', text, re.IGNORECASE)
        if vac_match:
            try:
                vacancies = int(vac_match.group(1).replace(",", ""))
            except ValueError:
                pass

        # Look for age limit pattern (e.g., 'Age limit: 21 to 32 years')
        min_age, max_age = None, None
        age_match = re.search(r'([0-9]{2})\s*(?:to|-)\s*([0-9]{2})\s*years', text, re.IGNORECASE)
        if age_match:
            min_age = int(age_match.group(1))
            max_age = int(age_match.group(2))

        # Look for application fee
        fee = None
        fee_match = re.search(r'(?:application fee|fee)[:\s]+(?:Rs\.?|₹)\s*([0-9]+)', text, re.IGNORECASE)
        if fee_match:
            try:
                fee = float(fee_match.group(1))
            except ValueError:
                pass

        return {
            "title": title,
            "organisation": organisation,
            "overview": f"Official recruitment announcement published by {organisation}.",
            "vacancies": vacancies,
            "min_age": min_age or 18,
            "max_age": max_age or 32,
            "category_age_relaxations": {
                "OBC-NCL": "3 years upper age relaxation",
                "SC/ST": "5 years upper age relaxation",
                "PwBD": "10 years upper age relaxation"
            },
            "educational_qualifications": ["Bachelor's Degree from a recognized University or equivalent."],
            "eligible_streams": ["All Disciplines"],
            "min_percentage": None,
            "application_opening_date": None,
            "application_closing_date": None,
            "prelims_exam_date": None,
            "application_fee": fee or 100.0,
            "fee_exemptions": "SC, ST, Female, and PwBD candidates are exempted from payment of fee.",
            "required_documents": [
                "Class 10th Certificate for proof of date of birth",
                "Degree Certificate / Provisional Degree Certificate",
                "Category / Caste / UDID Certificate if claiming relaxation"
            ],
            "selection_procedure": "Written examination followed by Document Verification.",
            "confidence_score": 0.70,
            "requires_human_review": True
        }

cloudflare_ai_client = CloudflareWorkersAIClient()
