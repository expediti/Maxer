"""
Re-export module to satisfy crawlers/gemini_verifier.py path specification.
All core verification and structured extraction logic resides in engine.app.verification.gemini_verifier.
"""

from engine.app.verification.gemini_verifier import (
    DateWithEvidence,
    OpportunityExtracted,
    normalize_text_for_comparison,
    validate_iso_date,
    validate_deterministic_guardrails,
    get_genai_client,
    verify_and_clean_opportunity,
    stage_and_verify_opportunity,
    GEMINI_EXTRACTION_SYSTEM_PROMPT,
)

__all__ = [
    "DateWithEvidence",
    "OpportunityExtracted",
    "normalize_text_for_comparison",
    "validate_iso_date",
    "validate_deterministic_guardrails",
    "get_genai_client",
    "verify_and_clean_opportunity",
    "stage_and_verify_opportunity",
    "GEMINI_EXTRACTION_SYSTEM_PROMPT",
]

