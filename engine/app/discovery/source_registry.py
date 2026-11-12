from dataclasses import dataclass, field
from typing import List, Optional, Dict, Any
from urllib.parse import urlparse

@dataclass
class RegisteredSource:
    id: str
    source_name: str
    organisation: str
    organisation_slug: str
    source_category: str  # central_govt, state_govt, defence, scientific, psu, teaching, healthcare, judicial, aviation_maritime, agriculture, apprenticeship, internship, fellowship, scholarship, private_sector, admission_qualification
    country: str = "India"
    official_url: str = ""
    domain: str = ""
    enabled_status: bool = True
    discovery_method: str = "html"  # html, pdf, api, rss, sitemap, json
    last_successful_crawl: Optional[str] = None
    last_failure: Optional[str] = None
    crawl_frequency: str = "daily"
    rate_limit_seconds: float = 2.0
    notes: str = ""
    state: Optional[str] = None
    crawler_adapter: str = "generic"

    def __post_init__(self):
        if not self.domain and self.official_url:
            parsed = urlparse(self.official_url)
            self.domain = parsed.netloc or parsed.path

    # Backwards-compatibility properties for existing code and tests
    @property
    def organisation_name(self) -> str:
        return self.organisation

    @property
    def organisation_type(self) -> str:
        return self.source_category

    @property
    def category(self) -> str:
        cat_map = {
            "central_govt": "Government Recruitment",
            "state_govt": "State Government Jobs",
            "defence": "Defence & Police",
            "scientific": "Research & Science",
            "psu": "PSU Recruitment",
            "teaching": "Teaching & Academia",
            "healthcare": "Healthcare & Medical",
            "judicial": "Law & Courts",
            "aviation_maritime": "Aviation & Transport",
            "agriculture": "Agriculture & Environment",
            "apprenticeship": "Apprenticeships",
            "internship": "Internships",
            "fellowship": "Fellowships",
            "scholarship": "Scholarships & Fellowships",
            "private_sector": "Private Jobs",
            "admission_qualification": "Entrance Examinations",
        }
        return cat_map.get(self.source_category, "Government Recruitment")

    @property
    def url(self) -> str:
        return self.official_url

    @property
    def crawler_type(self) -> str:
        return self.crawler_adapter

    @property
    def enabled(self) -> bool:
        return self.enabled_status

    @property
    def rate_limit_delay_seconds(self) -> float:
        return self.rate_limit_seconds


# =============================================================================
# MASTER INDIAN OPPORTUNITY SOURCE REGISTRY
# Seeded from India Examinations and Opportunities Master Catalogue (17 Pages)
# =============================================================================

OFFICIAL_INDIAN_SOURCES: List[RegisteredSource] = [
    # -------------------------------------------------------------------------
    # A. CENTRAL GOVERNMENT RECRUITMENT & EXAMINATIONS
    # -------------------------------------------------------------------------
    RegisteredSource(
        id="source-upsc-01",
        source_name="UPSC Active Examinations",
        organisation="Union Public Service Commission (UPSC)",
        organisation_slug="upsc",
        source_category="central_govt",
        official_url="https://upsc.gov.in/examinations/active-exams",
        crawler_adapter="upsc",
        notes="National competitive examinations (CSE, IFS, ESE, CDS, NDA, CAPF, CMS, Geo-Scientist)",
    ),
    RegisteredSource(
        id="source-upsc-ora-01",
        source_name="UPSC Online Recruitment Application (ORA)",
        organisation="Union Public Service Commission (UPSC)",
        organisation_slug="upsc-ora",
        source_category="central_govt",
        official_url="https://upsconline.nic.in/",
        crawler_adapter="upsc",
        notes="Recruitment by selection, specialist, scientific, and administrative posts",
    ),
    RegisteredSource(
        id="source-ssc-01",
        source_name="Staff Selection Commission Notices",
        organisation="Staff Selection Commission (SSC)",
        organisation_slug="ssc",
        source_category="central_govt",
        official_url="https://ssc.gov.in/api/notices",
        crawler_adapter="ssc",
        notes="Central Group B & C recruitments: CGL, CHSL, MTS, GD Constable, JE, Steno, Selection Posts",
    ),
    RegisteredSource(
        id="source-rrb-01",
        source_name="Railway Recruitment Boards (RRB Central)",
        organisation="Ministry of Railways / RRB",
        organisation_slug="rrb",
        source_category="central_govt",
        official_url="https://www.rrbcdg.gov.in/",
        crawler_adapter="central_govt",
        notes="Railway CENs: NTPC UG & Graduate, ALP, Technician, JE, Paramedical, Level-1 Group D",
    ),
    RegisteredSource(
        id="source-rpf-01",
        source_name="Railway Protection Force (RPF) Recruitment",
        organisation="Indian Railways / RPF",
        organisation_slug="rpf",
        source_category="defence",
        official_url="https://rpf.indianrailways.gov.in/",
        crawler_adapter="defence",
        notes="RPF Constable and Sub-Inspector recruitments",
    ),
    RegisteredSource(
        id="source-ibps-01",
        source_name="IBPS Common Recruitment Process",
        organisation="Institute of Banking Personnel Selection (IBPS)",
        organisation_slug="ibps",
        source_category="central_govt",
        official_url="https://www.ibps.in/",
        crawler_adapter="central_govt",
        notes="Banking PO/MT, Clerk (CSA), Specialist Officer (SO), RRB Officers Scale I-III & Assistants",
    ),
    RegisteredSource(
        id="source-sbi-01",
        source_name="State Bank of India Careers",
        organisation="State Bank of India (SBI)",
        organisation_slug="sbi",
        source_category="central_govt",
        official_url="https://sbi.bank.in/en/web/careers",
        crawler_adapter="central_govt",
        notes="SBI PO, Junior Associate, Specialist Cadre Officers",
    ),
    RegisteredSource(
        id="source-rbi-01",
        source_name="Reserve Bank of India Opportunities",
        organisation="Reserve Bank of India (RBI)",
        organisation_slug="rbi",
        source_category="central_govt",
        official_url="https://opportunities.rbi.org.in/",
        crawler_adapter="central_govt",
        notes="RBI Grade B Officers, Assistant, Specialist Legal/Tech/Research",
    ),
    RegisteredSource(
        id="source-nabard-01",
        source_name="NABARD Recruitment & Careers",
        organisation="National Bank for Agriculture and Rural Development (NABARD)",
        organisation_slug="nabard",
        source_category="central_govt",
        official_url="https://www.nabard.org/",
        crawler_adapter="central_govt",
        notes="NABARD Grade A & B Officers, Development Assistant",
    ),
    RegisteredSource(
        id="source-sebi-01",
        source_name="SEBI Careers",
        organisation="Securities and Exchange Board of India (SEBI)",
        organisation_slug="sebi",
        source_category="central_govt",
        official_url="https://www.sebi.gov.in/",
        crawler_adapter="central_govt",
        notes="SEBI Grade A Assistant Manager across General, Legal, IT, Research, Official Language",
    ),
    RegisteredSource(
        id="source-ncs-01",
        source_name="National Career Service (NCS) Portal",
        organisation="Ministry of Labour and Employment (MoLE)",
        organisation_slug="ncs",
        source_category="central_govt",
        official_url="https://www.ncs.gov.in/",
        crawler_adapter="generic",
        notes="Government of India job and internship discovery portal across public and private sectors",
    ),
    RegisteredSource(
        id="source-employment-news-01",
        source_name="Employment News / Rozgar Samachar",
        organisation="Ministry of Information and Broadcasting (MIB)",
        organisation_slug="employment-news",
        source_category="central_govt",
        official_url="https://employmentnews.gov.in/",
        crawler_adapter="generic",
        notes="Weekly official publication indexing Central and State recruitment notifications",
    ),

    # -------------------------------------------------------------------------
    # B. ALL 28 INDIAN STATES & 8 UNION TERRITORIES (COMPLETE DIRECTORY)
    # -------------------------------------------------------------------------
    RegisteredSource(
        id="source-state-ap-01",
        source_name="Andhra Pradesh Public Service Commission (APPSC)",
        organisation="APPSC",
        organisation_slug="appsc",
        source_category="state_govt",
        state="Andhra Pradesh",
        official_url="https://psc.ap.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-ar-01",
        source_name="Arunachal Pradesh Public Service Commission (APPSC)",
        organisation="Arunachal APPSC",
        organisation_slug="arunachal-appsc",
        source_category="state_govt",
        state="Arunachal Pradesh",
        official_url="https://appsc.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-as-01",
        source_name="Assam Public Service Commission (APSC)",
        organisation="APSC Assam",
        organisation_slug="apsc-assam",
        source_category="state_govt",
        state="Assam",
        official_url="https://apsc.nic.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-br-01",
        source_name="Bihar Public Service Commission (BPSC)",
        organisation="BPSC Bihar",
        organisation_slug="bpsc",
        source_category="state_govt",
        state="Bihar",
        official_url="https://bpsc.bih.nic.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-cg-01",
        source_name="Chhattisgarh Public Service Commission (CGPSC)",
        organisation="CGPSC",
        organisation_slug="cgpsc",
        source_category="state_govt",
        state="Chhattisgarh",
        official_url="https://psc.cg.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-ga-01",
        source_name="Goa Public Service Commission (GPSC)",
        organisation="GPSC Goa",
        organisation_slug="gpsc-goa",
        source_category="state_govt",
        state="Goa",
        official_url="https://gpsc.goa.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-gj-01",
        source_name="Gujarat Public Service Commission (GPSC)",
        organisation="GPSC Gujarat",
        organisation_slug="gpsc-gujarat",
        source_category="state_govt",
        state="Gujarat",
        official_url="https://gpsc.gujarat.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-hr-01",
        source_name="Haryana Public Service Commission (HPSC)",
        organisation="HPSC",
        organisation_slug="hpsc",
        source_category="state_govt",
        state="Haryana",
        official_url="https://hpsc.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-hp-01",
        source_name="Himachal Pradesh Public Service Commission (HPPSC)",
        organisation="HPPSC",
        organisation_slug="hppsc",
        source_category="state_govt",
        state="Himachal Pradesh",
        official_url="https://hppsc.hp.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-jh-01",
        source_name="Jharkhand Public Service Commission (JPSC)",
        organisation="JPSC",
        organisation_slug="jpsc",
        source_category="state_govt",
        state="Jharkhand",
        official_url="https://jpsc.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-ka-01",
        source_name="Karnataka Public Service Commission (KPSC)",
        organisation="KPSC Karnataka",
        organisation_slug="kpsc-kar",
        source_category="state_govt",
        state="Karnataka",
        official_url="https://kpsc.kar.nic.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-kl-01",
        source_name="Kerala Public Service Commission (KPSC)",
        organisation="Kerala PSC",
        organisation_slug="kerala-psc",
        source_category="state_govt",
        state="Kerala",
        official_url="https://www.keralapsc.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-mp-01",
        source_name="Madhya Pradesh Public Service Commission (MPPSC)",
        organisation="MPPSC",
        organisation_slug="mppsc",
        source_category="state_govt",
        state="Madhya Pradesh",
        official_url="https://mppsc.mp.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-mh-01",
        source_name="Maharashtra Public Service Commission (MPSC)",
        organisation="MPSC Maharashtra",
        organisation_slug="mpsc-mah",
        source_category="state_govt",
        state="Maharashtra",
        official_url="https://mpsc.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-mn-01",
        source_name="Manipur Public Service Commission (MPSC)",
        organisation="MPSC Manipur",
        organisation_slug="mpsc-manipur",
        source_category="state_govt",
        state="Manipur",
        official_url="https://mpscmanipur.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-ml-01",
        source_name="Meghalaya Public Service Commission (MPSC)",
        organisation="MPSC Meghalaya",
        organisation_slug="mpsc-meghalaya",
        source_category="state_govt",
        state="Meghalaya",
        official_url="https://mpsc.nic.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-mz-01",
        source_name="Mizoram Public Service Commission (MPSC)",
        organisation="MPSC Mizoram",
        organisation_slug="mpsc-mizoram",
        source_category="state_govt",
        state="Mizoram",
        official_url="https://mpsc.mizoram.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-nl-01",
        source_name="Nagaland Public Service Commission (NPSC)",
        organisation="NPSC Nagaland",
        organisation_slug="npsc-nagaland",
        source_category="state_govt",
        state="Nagaland",
        official_url="https://npsc.nagaland.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-od-01",
        source_name="Odisha Public Service Commission (OPSC)",
        organisation="OPSC Odisha",
        organisation_slug="opsc",
        source_category="state_govt",
        state="Odisha",
        official_url="https://opsc.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-pb-01",
        source_name="Punjab Public Service Commission (PPSC)",
        organisation="PPSC Punjab",
        organisation_slug="ppsc",
        source_category="state_govt",
        state="Punjab",
        official_url="https://ppsc.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-rj-01",
        source_name="Rajasthan Public Service Commission (RPSC)",
        organisation="RPSC Rajasthan",
        organisation_slug="rpsc",
        source_category="state_govt",
        state="Rajasthan",
        official_url="https://rpsc.rajasthan.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-sk-01",
        source_name="Sikkim Public Service Commission (SPSC)",
        organisation="SPSC Sikkim",
        organisation_slug="spsc-sikkim",
        source_category="state_govt",
        state="Sikkim",
        official_url="https://spsc.sikkim.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-tn-01",
        source_name="Tamil Nadu Public Service Commission (TNPSC)",
        organisation="TNPSC",
        organisation_slug="tnpsc",
        source_category="state_govt",
        state="Tamil Nadu",
        official_url="https://www.tnpsc.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-ts-01",
        source_name="Telangana Public Service Commission (TGPSC)",
        organisation="TGPSC Telangana",
        organisation_slug="tgpsc",
        source_category="state_govt",
        state="Telangana",
        official_url="https://tspsc.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-tr-01",
        source_name="Tripura Public Service Commission (TPSC)",
        organisation="TPSC Tripura",
        organisation_slug="tpsc-tripura",
        source_category="state_govt",
        state="Tripura",
        official_url="https://tpsc.tripura.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-up-01",
        source_name="Uttar Pradesh Public Service Commission (UPPSC)",
        organisation="UPPSC",
        organisation_slug="uppsc",
        source_category="state_govt",
        state="Uttar Pradesh",
        official_url="https://uppsc.up.nic.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-uk-01",
        source_name="Uttarakhand Public Service Commission (UKPSC)",
        organisation="UKPSC Uttarakhand",
        organisation_slug="ukpsc",
        source_category="state_govt",
        state="Uttarakhand",
        official_url="https://psc.uk.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-wb-01",
        source_name="West Bengal Public Service Commission (WBPSC)",
        organisation="WBPSC",
        organisation_slug="wbpsc",
        source_category="state_govt",
        state="West Bengal",
        official_url="https://psc.wb.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-dl-01",
        source_name="Delhi Subordinate Services Selection Board (DSSSB)",
        organisation="DSSSB Delhi",
        organisation_slug="dsssb",
        source_category="state_govt",
        state="Delhi (NCT)",
        official_url="https://dsssb.delhi.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-jk-01",
        source_name="Jammu & Kashmir Public Service Commission (JKPSC)",
        organisation="JKPSC",
        organisation_slug="jkpsc",
        source_category="state_govt",
        state="Jammu and Kashmir",
        official_url="https://jkpsc.nic.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-la-01",
        source_name="Administration of Union Territory of Ladakh",
        organisation="Ladakh Administration",
        organisation_slug="ladakh-admin",
        source_category="state_govt",
        state="Ladakh",
        official_url="https://ladakh.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-py-01",
        source_name="Puducherry Recruitment Portal",
        organisation="Government of Puducherry",
        organisation_slug="puducherry-govt",
        source_category="state_govt",
        state="Puducherry",
        official_url="https://recruitment.py.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-ch-01",
        source_name="Chandigarh Administration Recruitment",
        organisation="Chandigarh Administration",
        organisation_slug="chandigarh-admin",
        source_category="state_govt",
        state="Chandigarh",
        official_url="https://chandigarh.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-an-01",
        source_name="Andaman & Nicobar Administration",
        organisation="Andaman & Nicobar Administration",
        organisation_slug="andaman-admin",
        source_category="state_govt",
        state="Andaman and Nicobar",
        official_url="https://andaman.gov.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-dd-01",
        source_name="Dadra & Nagar Haveli and Daman & Diu Administration",
        organisation="DNH & DD Administration",
        organisation_slug="dnh-dd-admin",
        source_category="state_govt",
        state="Dadra and Nagar Haveli and Daman and Diu",
        official_url="https://daman.nic.in/",
        crawler_adapter="state_psc",
    ),
    RegisteredSource(
        id="source-state-ld-01",
        source_name="Lakshadweep Administration Portal",
        organisation="Lakshadweep Administration",
        organisation_slug="lakshadweep-admin",
        source_category="state_govt",
        state="Lakshadweep",
        official_url="https://lakshadweep.gov.in/",
        crawler_adapter="state_psc",
    ),

    # -------------------------------------------------------------------------
    # C. DEFENCE AND UNIFORMED SERVICES
    # -------------------------------------------------------------------------
    RegisteredSource(
        id="source-def-army-01",
        source_name="Join Indian Army Official Portal",
        organisation="Indian Army",
        organisation_slug="indian-army",
        source_category="defence",
        official_url="https://joinindianarmy.nic.in/",
        crawler_adapter="defence",
        notes="Officer entries (TES, TGC, SSC Tech, NCC, JAG) and Agniveer Army rallies",
    ),
    RegisteredSource(
        id="source-def-navy-01",
        source_name="Join Indian Navy Official Portal",
        organisation="Indian Navy",
        organisation_slug="indian-navy",
        source_category="defence",
        official_url="https://joinindiannavy.gov.in/",
        crawler_adapter="defence",
        notes="Navy officer entries, B.Tech Cadet Entry, Agniveer SSR and MR",
    ),
    RegisteredSource(
        id="source-def-iaf-01",
        source_name="Indian Air Force AFCAT & Officer Induction",
        organisation="Indian Air Force",
        organisation_slug="iaf-afcat",
        source_category="defence",
        official_url="https://afcat.cdac.in/",
        crawler_adapter="defence",
        notes="Air Force Common Admission Test (AFCAT), Flying and Ground Duty technical/non-technical",
    ),
    RegisteredSource(
        id="source-def-iaf-agnipath-01",
        source_name="Indian Air Force Agnipath Vayu",
        organisation="Indian Air Force",
        organisation_slug="agnipath-vayu",
        source_category="defence",
        official_url="https://agnipathvayu.cdac.in/",
        crawler_adapter="defence",
        notes="Agniveervayu intake for Science and non-Science streams",
    ),
    RegisteredSource(
        id="source-def-icg-01",
        source_name="Indian Coast Guard Recruitment",
        organisation="Indian Coast Guard (ICG)",
        organisation_slug="coast-guard",
        source_category="defence",
        official_url="https://joinindiancoastguard.cdac.in/",
        crawler_adapter="defence",
        notes="Assistant Commandant, Navik GD, Navik DB, Yantrik entries",
    ),
    RegisteredSource(
        id="source-def-ar-01",
        source_name="Assam Rifles Recruitment",
        organisation="Assam Rifles",
        organisation_slug="assam-rifles",
        source_category="defence",
        official_url="https://www.assamrifles.gov.in/",
        crawler_adapter="defence",
        notes="Rifleman, Tradesman, Havildar, Warrant Officer entries",
    ),

    # -------------------------------------------------------------------------
    # D. SCIENTIFIC AND RESEARCH ORGANISATIONS
    # -------------------------------------------------------------------------
    RegisteredSource(
        id="source-isro-01",
        source_name="ISRO Careers & Job Opportunities",
        organisation="Indian Space Research Organisation (ISRO)",
        organisation_slug="isro",
        source_category="scientific",
        official_url="https://www.isro.gov.in/Careers.html",
        crawler_adapter="isro",
        notes="Scientist/Engineer, Technical Assistant, Scientific Assistant, JRF, Project Scientist",
    ),
    RegisteredSource(
        id="source-drdo-01",
        source_name="DRDO Recruitment & Assessment Centre (RAC)",
        organisation="Defence Research and Development Organisation (DRDO)",
        organisation_slug="drdo",
        source_category="scientific",
        official_url="https://www.drdo.gov.in/drdo/offerings/vacancies/",
        crawler_adapter="drdo",
        notes="Scientist B, Research Fellow (JRF), Research Associate, Project Scientist",
    ),
    RegisteredSource(
        id="source-barc-01",
        source_name="Bhabha Atomic Research Centre (BARC) Careers",
        organisation="Department of Atomic Energy / BARC",
        organisation_slug="barc",
        source_category="scientific",
        official_url="https://barc.gov.in/careers/",
        crawler_adapter="scientific",
        notes="OCES/DGFS Scientific Officer, Scientific Assistant, Stipendiary Trainee, Technician",
    ),
    RegisteredSource(
        id="source-csir-01",
        source_name="CSIR Central Career Opportunities & Recruitment",
        organisation="Council of Scientific & Industrial Research (CSIR)",
        organisation_slug="csir",
        source_category="scientific",
        official_url="https://www.csir.res.in/en/career-opportunities/recruitment",
        crawler_adapter="scientific",
        notes="CSIR Lab Scientists, Technical Officer, Technical Assistant, Project Associate I/II, JRF/SRF",
    ),
    RegisteredSource(
        id="source-icar-01",
        source_name="ICAR & ASRB Vacancies",
        organisation="Indian Council of Agricultural Research (ICAR)",
        organisation_slug="icar",
        source_category="scientific",
        official_url="https://icar.gov.in/en/vacancies",
        crawler_adapter="scientific",
        notes="Agricultural Research Service (ARS), Subject Matter Specialist, Senior Scientist",
    ),
    RegisteredSource(
        id="source-icmr-01",
        source_name="ICMR Career Opportunities",
        organisation="Indian Council of Medical Research (ICMR)",
        organisation_slug="icmr",
        source_category="scientific",
        official_url="https://www.icmr.gov.in/",
        crawler_adapter="scientific",
        notes="Scientist, Technical Assistant, Project Research Scientist, JRF, Clinical Trial staff",
    ),
    RegisteredSource(
        id="source-cdac-01",
        source_name="Centre for Development of Advanced Computing (C-DAC)",
        organisation="C-DAC / MeitY",
        organisation_slug="cdac",
        source_category="scientific",
        official_url="https://www.cdac.in/",
        crawler_adapter="scientific",
        notes="Project Engineer, Project Associate, Scientist/Engineer, technical staff",
    ),
    RegisteredSource(
        id="source-nielit-01",
        source_name="National Institute of Electronics & IT (NIELIT)",
        organisation="NIELIT / MeitY",
        organisation_slug="nielit",
        source_category="scientific",
        official_url="https://www.nielit.gov.in/",
        crawler_adapter="scientific",
        notes="Scientist B/C, Scientific/Technical Assistant, Programmer",
    ),
    RegisteredSource(
        id="source-meity-01",
        source_name="Ministry of Electronics and Information Technology (MeitY)",
        organisation="MeitY",
        organisation_slug="meity",
        source_category="scientific",
        official_url="https://www.meity.gov.in/",
        crawler_adapter="scientific",
        notes="NIC Scientist B/C, Scientific Assistant, Digital India internships and project positions",
    ),

    # -------------------------------------------------------------------------
    # E. PUBLIC SECTOR UNDERTAKINGS (PSU) & STATUTORY CORPORATIONS
    # -------------------------------------------------------------------------
    RegisteredSource(
        id="source-powergrid-01",
        source_name="POWERGRID Job Opportunities",
        organisation="Power Grid Corporation of India Limited (POWERGRID)",
        organisation_slug="powergrid",
        source_category="psu",
        official_url="https://www.powergrid.in/en/job-opportunities",
        crawler_adapter="psu",
        notes="Engineer Trainee, Diploma Trainee, Junior Officer Trainee, Field Engineer, Apprentices",
    ),
    RegisteredSource(
        id="source-iocl-01",
        source_name="IOCL Latest Job Openings",
        organisation="Indian Oil Corporation Limited (IOCL)",
        organisation_slug="iocl",
        source_category="psu",
        official_url="https://iocl.com/latest-job-opening",
        crawler_adapter="psu",
        notes="Officers/Engineers, Non-executive technicians, Trade Apprentices, Junior Operators",
    ),
    RegisteredSource(
        id="source-ongc-01",
        source_name="ONGC Recruitment & Careers",
        organisation="Oil and Natural Gas Corporation (ONGC)",
        organisation_slug="ongc",
        source_category="psu",
        official_url="https://ongcindia.com/",
        crawler_adapter="psu",
        notes="Graduate Trainees, AEE, Geoscientist, HR, Medical, Technical and Apprentice roles",
    ),
    RegisteredSource(
        id="source-gail-01",
        source_name="GAIL Vacancies",
        organisation="GAIL (India) Limited",
        organisation_slug="gail",
        source_category="psu",
        official_url="https://www.gailonline.com/vacancies.html",
        crawler_adapter="psu",
        notes="Executive Trainee, Engineers, Senior Officers, Technicians and Apprentices",
    ),
    RegisteredSource(
        id="source-ntpc-01",
        source_name="NTPC Careers",
        organisation="NTPC Limited",
        organisation_slug="ntpc",
        source_category="psu",
        official_url="https://careers.ntpc.co.in/",
        crawler_adapter="psu",
        notes="Engineering Executive Trainee (EET), Diploma Trainee, Assistant Executive, Finance",
    ),
    RegisteredSource(
        id="source-bhel-01",
        source_name="BHEL Careers",
        organisation="Bharat Heavy Electricals Limited (BHEL)",
        organisation_slug="bhel",
        source_category="psu",
        official_url="https://careers.bhel.in/",
        crawler_adapter="psu",
        notes="Engineer Trainee, Supervisor Trainee, Artisan, Technician, Project Engineers",
    ),
    RegisteredSource(
        id="source-coalindia-01",
        source_name="Coal India Recruitment",
        organisation="Coal India Limited (CIL)",
        organisation_slug="coal-india",
        source_category="psu",
        official_url="https://www.coalindia.in/",
        crawler_adapter="psu",
        notes="Management Trainee, Mining Sirdar, Overman, Technician and Apprentices",
    ),
    RegisteredSource(
        id="source-sail-01",
        source_name="SAIL Careers",
        organisation="Steel Authority of India Limited (SAIL)",
        organisation_slug="sail",
        source_category="psu",
        official_url="https://www.sail.co.in/",
        crawler_adapter="psu",
        notes="Management Trainee, Operator-cum-Technician, Attendant-cum-Technician",
    ),
    RegisteredSource(
        id="source-nalco-01",
        source_name="NALCO Careers",
        organisation="National Aluminium Company Limited (NALCO)",
        organisation_slug="nalco",
        source_category="psu",
        official_url="https://nalcoindia.com/",
        crawler_adapter="psu",
        notes="Graduate Engineer Trainee, Manager, Junior Operative Trainee",
    ),
    RegisteredSource(
        id="source-npcil-01",
        source_name="NPCIL Careers",
        organisation="Nuclear Power Corporation of India Limited (NPCIL)",
        organisation_slug="npcil",
        source_category="psu",
        official_url="https://www.npcilcareers.co.in/",
        crawler_adapter="psu",
        notes="Executive Trainee, Scientific Assistant, Stipendiary Trainee, Technician",
    ),
    RegisteredSource(
        id="source-hal-01",
        source_name="HAL Careers",
        organisation="Hindustan Aeronautics Limited (HAL)",
        organisation_slug="hal",
        source_category="psu",
        official_url="https://hal-india.co.in/",
        crawler_adapter="psu",
        notes="Management Trainee, Design Trainee, Engineers, Operators and Apprentices",
    ),
    RegisteredSource(
        id="source-bel-01",
        source_name="BEL Careers",
        organisation="Bharat Electronics Limited (BEL)",
        organisation_slug="bel",
        source_category="psu",
        official_url="https://bel-india.in/",
        crawler_adapter="psu",
        notes="Probationary Engineer, Trainee Engineer, Project Engineer, Technician",
    ),
    RegisteredSource(
        id="source-aai-01",
        source_name="Airports Authority of India (AAI) Careers",
        organisation="Airports Authority of India (AAI)",
        organisation_slug="aai",
        source_category="aviation_maritime",
        official_url="https://www.aai.aero/en/careers",
        crawler_adapter="psu",
        notes="Junior Executive ATC, Airport Operations, Engineering, Fire Services",
    ),

    # -------------------------------------------------------------------------
    # F. TEACHING AND ACADEMIC CAREERS
    # -------------------------------------------------------------------------
    RegisteredSource(
        id="source-ctet-01",
        source_name="Central Teacher Eligibility Test (CTET)",
        organisation="Central Board of Secondary Education (CBSE)",
        organisation_slug="ctet",
        source_category="teaching",
        official_url="https://ctet.nic.in/",
        crawler_adapter="central_govt",
        notes="Teacher Eligibility Test for Central schools (KVS, NVS, Central Tibetan Schools)",
    ),
    RegisteredSource(
        id="source-ugc-01",
        source_name="University Grants Commission (UGC) Portal",
        organisation="University Grants Commission (UGC)",
        organisation_slug="ugc",
        source_category="teaching",
        official_url="https://www.ugc.gov.in/",
        crawler_adapter="central_govt",
        notes="Faculty recruitment norms, Assistant Professor eligibility, scholarships & fellowships",
    ),
    RegisteredSource(
        id="source-kvs-01",
        source_name="Kendriya Vidyalaya Sangathan (KVS) Recruitment",
        organisation="Kendriya Vidyalaya Sangathan (KVS)",
        organisation_slug="kvs",
        source_category="teaching",
        official_url="https://kvsangathan.nic.in/",
        crawler_adapter="central_govt",
        notes="Primary Teacher (PRT), TGT, PGT, Principal, Vice-Principal, Non-teaching roles",
    ),
    RegisteredSource(
        id="source-nvs-01",
        source_name="Navodaya Vidyalaya Samiti (NVS) Recruitment",
        organisation="Navodaya Vidyalaya Samiti (NVS)",
        organisation_slug="nvs",
        source_category="teaching",
        official_url="https://navodaya.gov.in/",
        crawler_adapter="central_govt",
        notes="TGT, PGT, Principal, Non-teaching residential school cadre",
    ),

    # -------------------------------------------------------------------------
    # G. HEALTHCARE AND MEDICAL RECRUITMENT
    # -------------------------------------------------------------------------
    RegisteredSource(
        id="source-aiims-01",
        source_name="AIIMS Exams & Recruitment Portal",
        organisation="All India Institute of Medical Sciences (AIIMS)",
        organisation_slug="aiims",
        source_category="healthcare",
        official_url="https://www.aiimsexams.ac.in/",
        crawler_adapter="healthcare",
        notes="NORCET Nursing Officer, Faculty, Medical Officer, Paramedical & Administrative posts",
    ),
    RegisteredSource(
        id="source-esic-01",
        source_name="Employees' State Insurance Corporation (ESIC) Recruitment",
        organisation="ESIC / MoLE",
        organisation_slug="esic",
        source_category="healthcare",
        official_url="https://www.esic.gov.in/",
        crawler_adapter="healthcare",
        notes="Insurance Medical Officer, Specialist Doctor, Nursing Staff, Paramedical staff",
    ),

    # -------------------------------------------------------------------------
    # H. LAW, COURTS AND ADMINISTRATION
    # -------------------------------------------------------------------------
    RegisteredSource(
        id="source-sci-01",
        source_name="Supreme Court of India Recruitments",
        organisation="Supreme Court of India",
        organisation_slug="supreme-court",
        source_category="judicial",
        official_url="https://www.sci.gov.in/recruitments/",
        crawler_adapter="central_govt",
        notes="Junior Court Assistant, Court Master, Law Researcher, Registrar",
    ),
    RegisteredSource(
        id="source-aibe-01",
        source_name="All India Bar Examination (AIBE)",
        organisation="Bar Council of India",
        organisation_slug="aibe",
        source_category="judicial",
        official_url="https://www.allindiabarexamination.com/",
        crawler_adapter="admission",
        notes="Certificate of Practice pathway for law graduates (licensing/eligibility, not job vacancy)",
    ),

    # -------------------------------------------------------------------------
    # I. AVIATION, MARITIME AND TRANSPORT
    # -------------------------------------------------------------------------
    RegisteredSource(
        id="source-dgca-01",
        source_name="Directorate General of Civil Aviation (DGCA)",
        organisation="DGCA / Ministry of Civil Aviation",
        organisation_slug="dgca",
        source_category="aviation_maritime",
        official_url="https://www.dgca.gov.in/",
        crawler_adapter="admission",
        notes="Pilot licensing examinations, Flight Operations Inspector, Airworthiness Officer",
    ),
    RegisteredSource(
        id="source-dg-shipping-01",
        source_name="Directorate General of Shipping",
        organisation="DG Shipping / Ministry of Ports, Shipping and Waterways",
        organisation_slug="dg-shipping",
        source_category="aviation_maritime",
        official_url="https://www.dgshipping.gov.in/",
        crawler_adapter="admission",
        notes="Merchant Navy competency exams, Deck Cadet, Marine Engineer certification",
    ),

    # -------------------------------------------------------------------------
    # J. APPRENTICESHIPS, INTERNSHIPS AND FELLOWSHIPS
    # -------------------------------------------------------------------------
    RegisteredSource(
        id="source-nats-01",
        source_name="National Apprenticeship Training Scheme (NATS 2.0)",
        organisation="Ministry of Education (MoE) / BOAT",
        organisation_slug="nats",
        source_category="apprenticeship",
        official_url="https://nats.education.gov.in/",
        crawler_adapter="apprenticeship",
        notes="Graduate, diploma and vocational apprenticeships across public and private sectors",
    ),
    RegisteredSource(
        id="source-naps-01",
        source_name="Apprenticeship India (NAPS)",
        organisation="MSDE / NSDC",
        organisation_slug="apprenticeship-india",
        source_category="apprenticeship",
        official_url="https://www.apprenticeshipindia.gov.in/",
        crawler_adapter="apprenticeship",
        notes="Trade apprentices (ITI) and optional trade apprentices across Indian industry",
    ),
    RegisteredSource(
        id="source-aicte-internship-01",
        source_name="AICTE National Internship Portal",
        organisation="All India Council for Technical Education (AICTE)",
        organisation_slug="aicte-internship",
        source_category="internship",
        official_url="https://internship.aicte-india.org/",
        crawler_adapter="apprenticeship",
        notes="Government, PSU, corporate, Smart Cities (TULIP) and municipal internships",
    ),
    RegisteredSource(
        id="source-pm-internship-01",
        source_name="Prime Minister's Internship Scheme",
        organisation="Ministry of Corporate Affairs (MCA)",
        organisation_slug="pm-internship",
        source_category="internship",
        official_url="https://pminternship.mca.gov.in/",
        crawler_adapter="apprenticeship",
        notes="Corporate internships in top 500 companies with monthly stipend and grant",
    ),
    RegisteredSource(
        id="source-pmrf-01",
        source_name="Prime Minister's Research Fellowship (PMRF)",
        organisation="Ministry of Education, Government of India",
        organisation_slug="pmrf",
        source_category="fellowship",
        official_url="https://www.pmrf.in/",
        crawler_adapter="scholarship",
        notes="Doctoral research fellowship at IITs, IISc, IISERs with ₹70,000-80,000/mo stipend",
    ),
    RegisteredSource(
        id="source-gsoc-01",
        source_name="Google Summer of Code",
        organisation="Google Open Source",
        organisation_slug="gsoc",
        source_category="internship",
        official_url="https://summerofcode.withgoogle.com/",
        crawler_adapter="generic",
        notes="Global open-source software engineering programme for students & early career developers",
    ),

    # -------------------------------------------------------------------------
    # K. SCHOLARSHIPS AND EDUCATION FUNDING
    # -------------------------------------------------------------------------
    RegisteredSource(
        id="source-nsp-01",
        source_name="National Scholarship Portal (NSP)",
        organisation="Ministry of Electronics and Information Technology (MeitY)",
        organisation_slug="nsp",
        source_category="scholarship",
        official_url="https://scholarships.gov.in/",
        crawler_adapter="scholarship",
        notes="Central sector, centrally sponsored, post-matric, pre-matric, merit-cum-means schemes",
    ),
    RegisteredSource(
        id="source-aicte-01",
        source_name="AICTE Student Development Schemes",
        organisation="All India Council for Technical Education (AICTE)",
        organisation_slug="aicte-scholarships",
        source_category="scholarship",
        official_url="https://www.aicte-india.org/schemes/students-development-schemes",
        crawler_adapter="scholarship",
        notes="AICTE Pragati (girls), Saksham (PwD), Swanath and PG GATE scholarship schemes",
    ),
    RegisteredSource(
        id="source-inspire-01",
        source_name="INSPIRE Programme (SHE & Fellowships)",
        organisation="Department of Science and Technology (DST)",
        organisation_slug="inspire",
        source_category="scholarship",
        official_url="https://online-inspire.gov.in/",
        crawler_adapter="scholarship",
        notes="Scholarship for Higher Education (SHE) and INSPIRE Doctoral Fellowships",
    ),

    # -------------------------------------------------------------------------
    # L. PRIVATE SECTOR EMPLOYER CAREER ECOSYSTEMS
    # -------------------------------------------------------------------------
    RegisteredSource(
        id="source-pvt-tcs-01",
        source_name="Tata Consultancy Services Careers",
        organisation="Tata Consultancy Services (TCS)",
        organisation_slug="tcs",
        source_category="private_sector",
        official_url="https://www.tcs.com/careers",
        crawler_adapter="private_job",
        notes="TCS NQT, Ninja, Digital, Prime and lateral Software/Data/Cloud engineering roles",
    ),
    RegisteredSource(
        id="source-pvt-infy-01",
        source_name="Infosys Careers",
        organisation="Infosys Limited",
        organisation_slug="infosys",
        source_category="private_sector",
        official_url="https://www.infosys.com/careers",
        crawler_adapter="private_job",
        notes="Systems Engineer, Specialist Programmer, Digital Specialist Engineer roles",
    ),
    RegisteredSource(
        id="source-pvt-wipro-01",
        source_name="Wipro Careers",
        organisation="Wipro Limited",
        organisation_slug="wipro",
        source_category="private_sector",
        official_url="https://careers.wipro.com/",
        crawler_adapter="private_job",
        notes="Elite NTH, Turbo, Project Engineer and technology specialist requisitions",
    ),
    RegisteredSource(
        id="source-pvt-hcl-01",
        source_name="HCLTech Careers",
        organisation="HCL Technologies",
        organisation_slug="hcltech",
        source_category="private_sector",
        official_url="https://www.hcltech.com/careers",
        crawler_adapter="private_job",
        notes="Graduate Engineer Trainee, Software Engineer, Cloud and Infrastructure roles",
    ),
    RegisteredSource(
        id="source-pvt-techm-01",
        source_name="Tech Mahindra Careers",
        organisation="Tech Mahindra",
        organisation_slug="tech-mahindra",
        source_category="private_sector",
        official_url="https://www.techmahindra.com/careers",
        crawler_adapter="private_job",
        notes="Associate Software Engineer, Telecom solutions, Enterprise applications",
    ),
    RegisteredSource(
        id="source-pvt-lti-01",
        source_name="LTIMindtree Careers",
        organisation="LTIMindtree",
        organisation_slug="ltimindtree",
        source_category="private_sector",
        official_url="https://www.ltimindtree.com/careers",
        crawler_adapter="private_job",
        notes="Graduate Trainee, Software Engineer, Full Stack & Data Engineering requisitions",
    ),
    RegisteredSource(
        id="source-pvt-tatamotors-01",
        source_name="Tata Motors Careers",
        organisation="Tata Motors / Tata Group",
        organisation_slug="tata-motors",
        source_category="private_sector",
        official_url="https://www.tatamotors.com/careers",
        crawler_adapter="private_job",
        notes="Graduate Engineer Trainee (GET), Automotive Engineer, EV Systems, Plant Operations",
    ),
    RegisteredSource(
        id="source-pvt-mahindra-01",
        source_name="Mahindra & Mahindra Careers",
        organisation="Mahindra Group",
        organisation_slug="mahindra",
        source_category="private_sector",
        official_url="https://www.mahindra.com/careers",
        crawler_adapter="private_job",
        notes="Management Trainee, Engineering, Farm equipment, Auto R&D positions",
    ),
    RegisteredSource(
        id="source-pvt-maruti-01",
        source_name="Maruti Suzuki Careers",
        organisation="Maruti Suzuki India Limited",
        organisation_slug="maruti-suzuki",
        source_category="private_sector",
        official_url="https://www.marutisuzuki.com/corporate/careers",
        crawler_adapter="private_job",
        notes="GET, Executive Trainee, Quality Engineer, Supply Chain and Production roles",
    ),
    RegisteredSource(
        id="source-pvt-lt-01",
        source_name="Larsen & Toubro (L&T) Careers",
        organisation="Larsen & Toubro Limited",
        organisation_slug="larsen-toubro",
        source_category="private_sector",
        official_url="https://www.larsentoubro.com/corporate/careers",
        crawler_adapter="private_job",
        notes="Graduate Engineer Trainee (GET), Post Graduate Trainee, Civil/Mechanical/Electrical",
    ),
    RegisteredSource(
        id="source-pvt-deloitte-01",
        source_name="Deloitte India Careers",
        organisation="Deloitte India",
        organisation_slug="deloitte-india",
        source_category="private_sector",
        official_url="https://www.deloitte.com/in/en/careers",
        crawler_adapter="private_job",
        notes="Analyst, Consultant, Technology Consulting, Risk & Financial Advisory roles",
    ),
    RegisteredSource(
        id="source-pvt-jio-01",
        source_name="Reliance Jio Careers",
        organisation="Reliance Jio Infocomm",
        organisation_slug="jio",
        source_category="private_sector",
        official_url="https://careers.jio.com/",
        crawler_adapter="private_job",
        notes="Software Developer, Network Engineer, 5G solutions, Data Analyst roles",
    ),

    # -------------------------------------------------------------------------
    # M. ADMISSIONS & PROFESSIONAL QUALIFICATION ROUTES (NON-VACANCY PATHWAYS)
    # -------------------------------------------------------------------------
    RegisteredSource(
        id="source-nta-01",
        source_name="National Testing Agency (NTA)",
        organisation="National Testing Agency (NTA)",
        organisation_slug="nta",
        source_category="admission_qualification",
        official_url="https://nta.ac.in/",
        crawler_adapter="admission",
        notes="National level entrance exams: JEE Main, NEET-UG, CUET-UG, CUET-PG, UGC-NET",
    ),
    RegisteredSource(
        id="source-gate-01",
        source_name="Graduate Aptitude Test in Engineering (GATE)",
        organisation="IITs / IISc (GATE Committee)",
        organisation_slug="gate",
        source_category="admission_qualification",
        official_url="https://gate2026.iitg.ac.in/",
        crawler_adapter="admission",
        notes="National examination for M.Tech admissions and PSU recruitment pathway",
    ),
    RegisteredSource(
        id="source-jam-01",
        source_name="Joint Admission Test for Masters (JAM)",
        organisation="IITs (JAM Committee)",
        organisation_slug="jam",
        source_category="admission_qualification",
        official_url="https://jam2026.iitb.ac.in/",
        crawler_adapter="admission",
        notes="M.Sc. and integrated science postgraduate admissions across IITs & IISc",
    ),
    RegisteredSource(
        id="source-clat-01",
        source_name="Consortium of National Law Universities (CLAT)",
        organisation="Consortium of NLUs",
        organisation_slug="clat",
        source_category="admission_qualification",
        official_url="https://consortiumofnlus.ac.in/",
        crawler_adapter="admission",
        notes="Undergraduate & Postgraduate law admission entrance (not direct recruitment)",
    ),
    RegisteredSource(
        id="source-icai-01",
        source_name="Institute of Chartered Accountants of India (ICAI)",
        organisation="ICAI",
        organisation_slug="icai",
        source_category="admission_qualification",
        official_url="https://www.icai.org/",
        crawler_adapter="admission",
        notes="Chartered Accountancy professional qualification route (Foundation, Inter, Final)",
    ),
]


def get_all_sources(enabled_only: bool = True) -> List[RegisteredSource]:
    """Returns all registered sources, optionally filtering by enabled status."""
    if enabled_only:
        return [s for s in OFFICIAL_INDIAN_SOURCES if s.enabled_status]
    return list(OFFICIAL_INDIAN_SOURCES)


def get_source_by_slug(slug: str) -> Optional[RegisteredSource]:
    """Look up a source by its organisation slug or source ID."""
    clean_slug = slug.strip().lower()
    for src in OFFICIAL_INDIAN_SOURCES:
        if (
            src.organisation_slug.lower() == clean_slug
            or src.id.lower() == clean_slug
            or clean_slug in src.id.lower()
        ):
            return src
    return None


def get_sources_by_category(category: str) -> List[RegisteredSource]:
    """Filter sources by source_category or user-facing category name."""
    clean_cat = category.strip().lower()
    return [
        src
        for src in OFFICIAL_INDIAN_SOURCES
        if (
            src.source_category.lower() == clean_cat
            or src.category.lower() == clean_cat
            or clean_cat in src.source_category.lower()
        )
    ]


def get_sources_by_state(state: str) -> List[RegisteredSource]:
    """Filter state-level sources by state or UT name."""
    clean_state = state.strip().lower()
    return [
        src
        for src in OFFICIAL_INDIAN_SOURCES
        if src.state and clean_state in src.state.lower()
    ]
