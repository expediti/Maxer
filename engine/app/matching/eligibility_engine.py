import logging
from typing import Dict, Any, List, Optional
from datetime import datetime, date

logger = logging.getLogger("rexam.matching")

class DeterministicMatcher:
    """
    Deterministic rule-based eligibility evaluation engine.
    Matches candidate profile against examination eligibility requirements.
    Zero AI calls are made for eligibility evaluations.
    """

    def evaluate_candidate_for_examination(
        self,
        candidate: Dict[str, Any],
        examination: Dict[str, Any],
        rules: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Evaluates candidate eligibility and returns match score and criteria breakdown.
        """
        rules = rules or {}
        reasons: List[str] = []
        is_eligible = True
        match_score = 100

        # 1. Age Verification
        dob_str = candidate.get("date_of_birth")
        min_age = rules.get("min_age") or examination.get("min_age")
        max_age = rules.get("max_age") or examination.get("max_age")

        if dob_str and (min_age is not None or max_age is not None):
            try:
                dob = date.fromisoformat(dob_str)
                today = date.today()
                age = today.year - dob.year - ((today.month, today.day) < (dob.month, dob.day))

                # Statutory relaxation
                social_cat = (candidate.get("social_category") or "General").upper()
                relaxation = 0
                if "OBC" in social_cat:
                    relaxation += 3
                elif "SC" in social_cat or "ST" in social_cat:
                    relaxation += 5

                if candidate.get("is_pwbd"):
                    relaxation += 10

                effective_max = (max_age or 100) + relaxation

                if min_age and age < min_age:
                    is_eligible = False
                    match_score -= 50
                    reasons.append(f"Candidate age ({age}) is below minimum requirement of {min_age} years.")
                elif max_age and age > effective_max:
                    is_eligible = False
                    match_score -= 50
                    reasons.append(f"Candidate age ({age}) exceeds relaxed upper age limit of {effective_max} years.")
                else:
                    reasons.append(f"Meets age criteria ({age} years, max allowable: {effective_max}).")
            except Exception as e:
                logger.warning(f"Error computing candidate age: {e}")

        # 2. Backlog Check
        if candidate.get("has_active_backlogs"):
            is_eligible = False
            match_score -= 40
            reasons.append("Active backlogs reported; recruitment requires cleared course record.")

        # 3. Stream & Degree Check
        eligible_streams = rules.get("eligible_streams") or examination.get("eligible_streams", [])
        candidate_stream = candidate.get("stream", "")
        if eligible_streams and candidate_stream:
            matches_all = any("all" in s.lower() or "any" in s.lower() for s in eligible_streams)
            if not matches_all:
                stream_match = any(
                    candidate_stream.lower() in s.lower() or s.lower() in candidate_stream.lower()
                    for s in eligible_streams
                )
                if not stream_match:
                    is_eligible = False
                    match_score -= 40
                    reasons.append(f"Discipline '{candidate_stream}' does not match required streams: {', '.join(eligible_streams)}.")
                else:
                    reasons.append(f"Discipline '{candidate_stream}' matches educational requirements.")

        # 4. Minimum Percentage Check
        min_pct = rules.get("min_percentage") or examination.get("min_percentage")
        cand_pct = candidate.get("cgpa_or_percentage")
        if min_pct is not None and cand_pct is not None:
            if cand_pct < min_pct:
                is_eligible = False
                match_score -= 30
                reasons.append(f"Aggregate marks ({cand_pct}%) below mandatory cutoff of {min_pct}%.")
            else:
                reasons.append(f"Satisfies minimum percentage cutoff ({cand_pct}% >= {min_pct}%).")

        final_score = max(0, match_score) if is_eligible else 0

        return {
            "candidate_id": candidate.get("id"),
            "examination_id": examination.get("id"),
            "is_eligible": is_eligible,
            "match_score": final_score,
            "reasons": reasons,
            "status": "eligible" if is_eligible else "not_eligible"
        }

matcher = DeterministicMatcher()

