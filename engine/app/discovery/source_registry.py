from dataclasses import dataclass
from typing import List, Optional

@dataclass
class RegisteredSource:
    id: str
    organisation_name: str
    organisation_slug: str
    organisation_type: str # central_govt, psu, state_govt, autonomous, university
    category: str # govt_recruitment, psu, entrance_exam, scholarship
    url: str
    crawler_type: str # upsc, ssc, isro, drdo, ibps, generic_rss, generic_html
    enabled: bool = True
    rate_limit_delay_seconds: float = 2.0

OFFICIAL_INDIAN_SOURCES: List[RegisteredSource] = [
    RegisteredSource(
        id="source-upsc-01",
        organisation_name="Union Public Service Commission (UPSC)",
        organisation_slug="upsc",
        organisation_type="central_govt",
        category="govt_recruitment",
        url="https://upsc.gov.in/examinations/active-exams",
        crawler_type="upsc",
        rate_limit_delay_seconds=2.0,
    ),
    RegisteredSource(
        id="source-ssc-01",
        organisation_name="Staff Selection Commission (SSC)",
        organisation_slug="ssc",
        organisation_type="central_govt",
        category="govt_recruitment",
        url="https://ssc.gov.in/api/notices",
        crawler_type="ssc",
        rate_limit_delay_seconds=2.5,
    ),
    RegisteredSource(
        id="source-isro-01",
        organisation_name="Indian Space Research Organisation (ISRO)",
        organisation_slug="isro",
        organisation_type="psu",
        category="psu",
        url="https://www.isro.gov.in/Careers.html",
        crawler_type="isro",
        rate_limit_delay_seconds=2.0,
    ),
    RegisteredSource(
        id="source-drdo-01",
        organisation_name="Defence Research and Development Organisation (DRDO)",
        organisation_slug="drdo",
        organisation_type="central_govt",
        category="govt_recruitment",
        url="https://www.drdo.gov.in/drdo/careers",
        crawler_type="drdo",
        rate_limit_delay_seconds=2.0,
    ),
    RegisteredSource(
        id="source-ibps-01",
        organisation_name="Institute of Banking Personnel Selection (IBPS)",
        organisation_slug="ibps",
        organisation_type="psu",
        category="govt_recruitment",
        url="https://www.ibps.in",
        crawler_type="ibps",
        rate_limit_delay_seconds=2.0,
    ),
    RegisteredSource(
        id="source-pmrf-01",
        organisation_name="Prime Minister's Research Fellowship (PMRF)",
        organisation_slug="pmrf",
        organisation_type="autonomous",
        category="scholarship",
        url="https://www.pmrf.in",
        crawler_type="generic_html",
        rate_limit_delay_seconds=1.5,
    ),
]

def get_source_by_slug(slug: str) -> Optional[RegisteredSource]:
    for src in OFFICIAL_INDIAN_SOURCES:
        if src.organisation_slug == slug or src.id == slug:
            return src
    return None

