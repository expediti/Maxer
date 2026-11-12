import logging
from typing import Dict, Any, List, Optional
from datetime import datetime, date

logger = logging.getLogger("rexam.matching")

VERIFIED_FORMULAS = {
    "aicte": {
        "institution_name": "AICTE Standard Norm",
        "description": "Percentage = (CGPA - 0.75) × 10",
        "source": "AICTE Approval Process Handbook & Gazette Notification",
        "convert": lambda cgpa: max(0.0, min(100.0, (cgpa - 0.75) * 10)),
    },
    "du": {
        "institution_name": "University of Delhi (DU)",
        "description": "Percentage = CGPA × 9.5",
        "source": "DU Notification No. Exam.VII/2019/338",
        "convert": lambda cgpa: max(0.0, min(100.0, cgpa * 9.5)),
    },
    "cbse": {
        "institution_name": "Central Board of Secondary Education (CBSE)",
        "description": "Percentage = CGPA × 9.5",
        "source": "CBSE Examination Bye-Laws Circular No. Coord/SO(EC-RO)/2017",
        "convert": lambda cgpa: max(0.0, min(100.0, cgpa * 9.5)),
    },
    "vtu": {
        "institution_name": "Visvesvaraya Technological University (VTU)",
        "description": "Percentage = (CGPA - 0.75) × 10",
        "source": "VTU Academic Regulations for B.E./B.Tech",
        "convert": lambda cgpa: max(0.0, min(100.0, (cgpa - 0.75) * 10)),
    },
    "anna_university": {
        "institution_name": "Anna University",
        "description": "Percentage = CGPA × 10",
        "source": "Anna University Regulations 2021 Clause 12.4",
        "convert": lambda cgpa: max(0.0, min(100.0, cgpa * 10.0)),
    },
    "mumbai_university": {
        "institution_name": "University of Mumbai",
        "description": "Percentage = 7.25 × CGPA + 11",
        "source": "University of Mumbai UG CBCS Ordinance",
        "convert": lambda cgpa: max(0.0, min(100.0, 7.25 * cgpa + 11.0)),
    },
    "jntu": {
        "institution_name": "JNTU (Hyderabad / Kakinada)",
        "description": "Percentage = (CGPA - 0.5) × 10",
        "source": "JNTUH Academic Regulations R18/R22",
        "convert": lambda cgpa: max(0.0, min(100.0, (cgpa - 0.5) * 10)),
    },
    "ugc_linear": {
        "institution_name": "UGC 10-Point Linear Scale",
        "description": "Percentage = CGPA × 10",
        "source": "UGC Guidelines on Adoption of Choice Based Credit System",
        "convert": lambda cgpa: max(0.0, min(100.0, cgpa * 10.0)),
    },
}

def lookup_formula(university: Optional[str], custom_formula: Optional[str] = None):
    if custom_formula:
        cf = custom_formula.lower().replace(" ", "")
        if "9.5" in cf:
            return VERIFIED_FORMULAS["cbse"]
        if "0.75" in cf and "10" in cf:
            return VERIFIED_FORMULAS["aicte"]
        if "0.5" in cf and "10" in cf:
            return VERIFIED_FORMULAS["jntu"]
        if "*10" in cf or "x10" in cf:
            return VERIFIED_FORMULAS["anna_university"]

    if not university:
        return None
    u = university.lower().strip()
    if "delhi" in u or "du" in u:
        return VERIFIED_FORMULAS["du"]
    if "vtu" in u or "visvesvaraya" in u:
        return VERIFIED_FORMULAS["vtu"]
    if "anna" in u:
        return VERIFIED_FORMULAS["anna_university"]
    if "mumbai" in u:
        return VERIFIED_FORMULAS["mumbai_university"]
    if "jntu" in u:
        return VERIFIED_FORMULAS["jntu"]
    if "cbse" in u:
        return VERIFIED_FORMULAS["cbse"]
    if "aicte" in u:
        return VERIFIED_FORMULAS["aicte"]
    return None

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
        status = "eligible"
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

        # 4. Academic Score & Grading System Cutoff (Separated CGPA & Percentage)
        min_pct = rules.get("min_percentage") or examination.get("min_percentage")
        min_cgpa = rules.get("min_cgpa") or examination.get("min_cgpa")
        cgpa_scale_max = rules.get("cgpa_scale_max") or examination.get("cgpa_scale_max", 10.0)

        # Candidate score resolution
        cand_system = (candidate.get("grading_system") or candidate.get("grading_type") or "").lower().strip()
        cand_cgpa = candidate.get("cgpa")
        cand_pct = candidate.get("percentage")
        raw_score = candidate.get("score_value") or candidate.get("cgpa_or_percentage")

        if not cand_system:
            if cand_cgpa is not None:
                cand_system = "cgpa"
            elif cand_pct is not None:
                cand_system = "percentage"
            elif raw_score is not None and raw_score <= 10.0:
                cand_system = "cgpa"
            else:
                cand_system = "percentage"

        cand_score = cand_cgpa if cand_system == "cgpa" else (cand_pct if cand_system == "percentage" else raw_score)
        if cand_score is None and raw_score is not None:
            cand_score = raw_score

        if cand_score is not None:
            if cand_system == "cgpa":
                cand_display = f"{cand_score:.2f} CGPA (10-point scale)"
            elif cand_system == "gpa":
                cand_display = f"{cand_score:.2f} GPA"
            else:
                cand_display = f"{cand_score:.1f}%"

            # Scenario A: Candidate has CGPA, Exam requires CGPA
            if cand_system in ("cgpa", "gpa") and min_cgpa is not None:
                if cand_score >= min_cgpa:
                    reasons.append(f"Satisfies minimum CGPA cutoff ({cand_display} >= {min_cgpa:.2f} CGPA).")
                else:
                    is_eligible = False
                    match_score -= 30
                    reasons.append(f"Candidate CGPA ({cand_score:.2f}) is below mandatory cutoff of {min_cgpa:.2f} CGPA.")

            # Scenario B: Candidate has Percentage, Exam requires Percentage
            elif cand_system == "percentage" and min_pct is not None:
                if cand_score >= min_pct:
                    reasons.append(f"Satisfies minimum percentage cutoff ({cand_score:.1f}% >= {min_pct}%).")
                else:
                    is_eligible = False
                    match_score -= 30
                    reasons.append(f"Aggregate marks ({cand_score:.1f}%) below mandatory cutoff of {min_pct}%.")

            # Scenario C: Candidate has CGPA, Exam requires Percentage
            elif cand_system in ("cgpa", "gpa") and min_pct is not None:
                univ = candidate.get("university") or candidate.get("institution")
                custom_f = candidate.get("conversion_formula")
                formula = lookup_formula(univ, custom_f)

                if formula:
                    converted = round(formula["convert"](cand_score), 2)
                    if converted >= min_pct:
                        reasons.append(
                            f"Candidate CGPA of {cand_score:.2f} equates to {converted:.1f}% under verified {formula['institution_name']} formula ({formula['description']}), satisfying the minimum {min_pct}% requirement."
                        )
                    else:
                        is_eligible = False
                        match_score -= 30
                        reasons.append(
                            f"Candidate CGPA of {cand_score:.2f} equates to {converted:.1f}% under verified {formula['institution_name']} formula, below mandatory cutoff of {min_pct}%."
                        )
                else:
                    # Unverified formula: DO NOT convert, DO NOT display 7.5%, DO NOT compare 7.5 to 50
                    if is_eligible:
                        status = "requires_verification"
                    match_score -= 15
                    reasons.append(
                        f"Candidate entered {cand_score:.2f} CGPA; examination requires minimum {min_pct}% aggregate marks. No verified conversion formula on record for '{univ or 'candidate university'}'. Official university conversion certificate required."
                    )

            # Scenario D: Candidate has Percentage, Exam requires CGPA
            elif cand_system == "percentage" and min_cgpa is not None:
                if is_eligible:
                    status = "requires_verification"
                match_score -= 15
                reasons.append(
                    f"Candidate entered {cand_score:.1f}% marks; examination specifies cutoff of {min_cgpa:.2f} CGPA. Official university equivalence certification required."
                )

        final_score = max(0, match_score) if (is_eligible or status == "requires_verification") else 0

        if not is_eligible:
            status = "not_eligible"

        return {
            "candidate_id": candidate.get("id"),
            "examination_id": examination.get("id"),
            "is_eligible": is_eligible and status != "requires_verification",
            "match_score": final_score,
            "reasons": reasons,
            "status": status,
        }

matcher = DeterministicMatcher()
