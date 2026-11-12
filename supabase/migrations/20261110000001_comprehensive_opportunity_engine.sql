-- =============================================================================
-- REXAM COMPREHENSIVE OPPORTUNITY DISCOVERY & VERIFICATION ENGINE MIGRATION
-- Migration: 20261110000001_comprehensive_opportunity_engine.sql
-- Target: Master Scope & Seed Taxonomy (India Examinations and Opportunities Master Catalogue)
-- Preserves all existing tables, profiles, onboarding data, and RLS policies.
-- Safe to run in the Supabase Dashboard SQL Editor without Supabase CLI.
-- =============================================================================

-- Extension Check
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- -----------------------------------------------------------------------------
-- 1. ENHANCE public.sources WITH CRAWLER REGISTRY ATTRIBUTES
-- -----------------------------------------------------------------------------
ALTER TABLE public.sources
    ADD COLUMN IF NOT EXISTS source_name TEXT,
    ADD COLUMN IF NOT EXISTS organisation TEXT,
    ADD COLUMN IF NOT EXISTS source_category TEXT DEFAULT 'central_govt',
    ADD COLUMN IF NOT EXISTS country TEXT DEFAULT 'India',
    ADD COLUMN IF NOT EXISTS official_url TEXT,
    ADD COLUMN IF NOT EXISTS domain TEXT,
    ADD COLUMN IF NOT EXISTS enabled_status BOOLEAN DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS discovery_method TEXT DEFAULT 'html',
    ADD COLUMN IF NOT EXISTS last_successful_crawl TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS last_failure TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS crawl_frequency TEXT DEFAULT 'daily',
    ADD COLUMN IF NOT EXISTS rate_limit_seconds NUMERIC(4,2) DEFAULT 2.0,
    ADD COLUMN IF NOT EXISTS notes TEXT;

-- -----------------------------------------------------------------------------
-- 2. ENHANCE public.examinations WITH MASTER OPPORTUNITY FIELDS
-- -----------------------------------------------------------------------------
ALTER TABLE public.examinations
    ADD COLUMN IF NOT EXISTS canonical_id TEXT,
    ADD COLUMN IF NOT EXISTS opportunity_type TEXT DEFAULT 'recruitment_examination',
    ADD COLUMN IF NOT EXISTS sector TEXT,
    ADD COLUMN IF NOT EXISTS sub_sector TEXT,
    ADD COLUMN IF NOT EXISTS qualification_levels TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS advertisement_number TEXT,
    ADD COLUMN IF NOT EXISTS requisition_id TEXT,
    ADD COLUMN IF NOT EXISTS application_status TEXT DEFAULT 'open',
    ADD COLUMN IF NOT EXISTS verification_status TEXT DEFAULT 'discovered',
    ADD COLUMN IF NOT EXISTS published_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS application_open_date TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS application_close_date TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS examination_date DATE,
    ADD COLUMN IF NOT EXISTS minimum_age INT,
    ADD COLUMN IF NOT EXISTS maximum_age INT,
    ADD COLUMN IF NOT EXISTS age_cutoff_date DATE,
    ADD COLUMN IF NOT EXISTS educational_eligibility TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS required_disciplines TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS minimum_percentage NUMERIC(5,2),
    ADD COLUMN IF NOT EXISTS minimum_cgpa NUMERIC(4,2),
    ADD COLUMN IF NOT EXISTS vacancy_count INT,
    ADD COLUMN IF NOT EXISTS category_breakdown JSONB DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS application_fee NUMERIC(10,2),
    ADD COLUMN IF NOT EXISTS salary TEXT,
    ADD COLUMN IF NOT EXISTS stipend TEXT,
    ADD COLUMN IF NOT EXISTS required_documents TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS selection_process TEXT,
    ADD COLUMN IF NOT EXISTS first_seen_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
    ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
    ADD COLUMN IF NOT EXISTS evidence JSONB DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS change_history JSONB DEFAULT '[]'::jsonb;

-- -----------------------------------------------------------------------------
-- 3. TYPED DETAIL TABLES FOR MULTI-ENTITY OPPORTUNITY ARCHITECTURE
-- -----------------------------------------------------------------------------

-- A. Recruitment Posts (Supports notifications with multiple posts/cadres)
CREATE TABLE IF NOT EXISTS public.recruitment_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    examination_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE,
    post_code TEXT,
    post_name TEXT NOT NULL,
    department TEXT,
    pay_scale TEXT,
    pay_level TEXT,
    vacancies INT,
    category_vacancies JSONB DEFAULT '{}'::jsonb,
    min_age INT,
    max_age INT,
    educational_qualification TEXT,
    experience_required TEXT,
    selection_method TEXT,
    evidence JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW())
);

-- B. Examination Cycles (Supports multiple stages, calendars, prelims/mains)
CREATE TABLE IF NOT EXISTS public.examination_cycles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    examination_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE,
    cycle_year INT NOT NULL,
    cycle_name TEXT NOT NULL,
    notification_date DATE,
    application_start_date TIMESTAMPTZ,
    application_end_date TIMESTAMPTZ,
    prelims_date DATE,
    mains_date DATE,
    interview_date DATE,
    admit_card_date DATE,
    result_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW())
);

-- C. Scholarships & Education Funding Details
CREATE TABLE IF NOT EXISTS public.opportunity_scholarships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    examination_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE UNIQUE,
    scheme_code TEXT,
    scholarship_type TEXT NOT NULL DEFAULT 'merit_cum_means', -- merit, post_matric, pre_matric, overseas, means, minority, sc_st_obc, girls, disability
    funding_agency TEXT NOT NULL DEFAULT 'Government of India',
    amount_per_year NUMERIC(12,2),
    financial_benefit_description TEXT NOT NULL DEFAULT '',
    income_ceiling_annual NUMERIC(12,2),
    eligible_courses TEXT[] DEFAULT '{}',
    eligible_categories TEXT[] DEFAULT '{}',
    domicile_state TEXT,
    academic_marks_requirement TEXT,
    minimum_marks_percentage NUMERIC(5,2),
    institution_eligibility TEXT,
    renewal_conditions TEXT,
    guidelines_pdf_url TEXT,
    application_portal_url TEXT,
    disbursement_mode TEXT DEFAULT 'DBT',
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW())
);

-- D. Internships Details (AICTE, ministries, corporate, research labs)
CREATE TABLE IF NOT EXISTS public.opportunity_internships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    examination_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE UNIQUE,
    program_name TEXT NOT NULL,
    internship_type TEXT NOT NULL DEFAULT 'government', -- government, research, corporate, virtual, public_policy
    duration_weeks INT,
    stipend_amount_per_month NUMERIC(10,2),
    stipend_description TEXT,
    eligible_academic_years TEXT[] DEFAULT '{}', -- 2nd year, 3rd year, Final year, Postgrad
    eligible_degrees TEXT[] DEFAULT '{}',
    required_skills TEXT[] DEFAULT '{}',
    work_location_type TEXT DEFAULT 'On-site', -- On-site, Remote, Hybrid
    number_of_openings INT,
    mentor_department TEXT,
    certificate_provided BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW())
);

-- E. Apprenticeships Details (NATS 2.0, NAPS, Railways, PSUs)
CREATE TABLE IF NOT EXISTS public.opportunity_apprenticeships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    examination_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE UNIQUE,
    portal_type TEXT NOT NULL DEFAULT 'NATS', -- NATS, NAPS, Direct PSU, Railway
    apprentice_category TEXT NOT NULL DEFAULT 'Graduate Apprentice', -- Trade Apprentice (ITI), Technician (Diploma), Graduate Apprentice
    designated_trade TEXT NOT NULL,
    stipend_monthly NUMERIC(10,2),
    training_duration_months INT DEFAULT 12,
    qualification_required TEXT,
    establishment_registration_no TEXT,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW())
);

-- F. Fellowships Details (PMRF, JRF, SRF, Postdoctoral, Institute-specific)
CREATE TABLE IF NOT EXISTS public.opportunity_fellowships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    examination_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE UNIQUE,
    fellowship_type TEXT NOT NULL DEFAULT 'JRF', -- JRF, SRF, Postdoctoral, PMRF, Research Associate
    awarding_body TEXT NOT NULL,
    fellowship_amount_monthly NUMERIC(10,2),
    contingency_grant_annual NUMERIC(10,2),
    tenure_years INT DEFAULT 2,
    qualifying_exam TEXT, -- GATE, UGC-NET, CSIR-NET, ICMR-JRF, INSPIRE
    subject_area TEXT,
    host_institution_type TEXT,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW())
);

-- G. Private Job Requisitions (Canonical employer requisitions)
CREATE TABLE IF NOT EXISTS public.private_job_requisitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    examination_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE UNIQUE,
    requisition_id TEXT NOT NULL,
    company_name TEXT NOT NULL,
    industry_sector TEXT NOT NULL,
    role_family TEXT NOT NULL, -- Software & IT, Data & AI, Product & Design, etc.
    work_experience_min_years NUMERIC(3,1) DEFAULT 0.0,
    work_experience_max_years NUMERIC(3,1),
    job_location TEXT NOT NULL DEFAULT 'Pan India',
    employment_type TEXT DEFAULT 'Full-time',
    salary_range_min NUMERIC(12,2),
    salary_range_max NUMERIC(12,2),
    salary_currency TEXT DEFAULT 'INR',
    primary_skills TEXT[] DEFAULT '{}',
    career_page_url TEXT NOT NULL,
    verified_on_employer_site BOOLEAN DEFAULT TRUE,
    employer_domain TEXT,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW())
);

-- H. Admissions & Professional Licensing Qualifications
CREATE TABLE IF NOT EXISTS public.admission_qualifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    examination_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE UNIQUE,
    admission_level TEXT NOT NULL DEFAULT 'Postgraduate', -- Undergraduate, Postgraduate, Doctoral, Professional Certification, Licensing
    conducting_agency TEXT NOT NULL,
    target_courses TEXT[] DEFAULT '{}',
    score_validity_years INT DEFAULT 1,
    leads_to_direct_recruitment BOOLEAN DEFAULT FALSE,
    participating_institutes_count INT,
    counselling_authority TEXT,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW())
);

-- I. Opportunity Change History (Audit trail of date changes, corrigenda, cancellations)
CREATE TABLE IF NOT EXISTS public.opportunity_change_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    examination_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE,
    field_name TEXT NOT NULL,
    old_value TEXT,
    new_value TEXT,
    change_summary TEXT NOT NULL,
    source_document_url TEXT,
    detected_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
    verification_status TEXT DEFAULT 'verified',
    notified_users_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW())
);

-- J. Source Health Logs (Crawl telemetry, error diagnostics & uptime observability)
CREATE TABLE IF NOT EXISTS public.source_health_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_id UUID REFERENCES public.sources(id) ON DELETE SET NULL,
    source_slug TEXT NOT NULL,
    crawl_started_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    crawl_completed_at TIMESTAMPTZ,
    crawl_duration_seconds NUMERIC(8,2),
    http_status INT,
    health_status TEXT NOT NULL, -- successfully_crawled, partially_crawled, blocked, temporarily_unavailable, unsupported, no_new_opportunities
    pages_discovered INT DEFAULT 0,
    documents_downloaded INT DEFAULT 0,
    opportunities_discovered INT DEFAULT 0,
    opportunities_updated INT DEFAULT 0,
    duplicates_skipped INT DEFAULT 0,
    extraction_failures INT DEFAULT 0,
    verification_failures INT DEFAULT 0,
    error_message TEXT,
    details JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW())
);

-- -----------------------------------------------------------------------------
-- 4. PERFORMANCE & LOOKUP INDEXES
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_examinations_opp_type ON public.examinations(opportunity_type);
CREATE INDEX IF NOT EXISTS idx_examinations_verif_status ON public.examinations(verification_status);
CREATE INDEX IF NOT EXISTS idx_examinations_app_status ON public.examinations(application_status);
CREATE INDEX IF NOT EXISTS idx_examinations_state ON public.examinations(state);
CREATE INDEX IF NOT EXISTS idx_examinations_sector ON public.examinations(sector);
CREATE INDEX IF NOT EXISTS idx_examinations_advertisement ON public.examinations(advertisement_number);
CREATE INDEX IF NOT EXISTS idx_examinations_requisition ON public.examinations(requisition_id);
CREATE INDEX IF NOT EXISTS idx_examinations_canonical ON public.examinations(canonical_id);

CREATE INDEX IF NOT EXISTS idx_recruitment_posts_exam ON public.recruitment_posts(examination_id);
CREATE INDEX IF NOT EXISTS idx_recruitment_posts_name ON public.recruitment_posts(post_name);
CREATE INDEX IF NOT EXISTS idx_examination_cycles_exam ON public.examination_cycles(examination_id);
CREATE INDEX IF NOT EXISTS idx_change_history_exam ON public.opportunity_change_history(examination_id);
CREATE INDEX IF NOT EXISTS idx_source_health_slug ON public.source_health_logs(source_slug);
CREATE INDEX IF NOT EXISTS idx_source_health_status ON public.source_health_logs(health_status);
CREATE INDEX IF NOT EXISTS idx_sources_enabled ON public.sources(enabled_status);
CREATE INDEX IF NOT EXISTS idx_sources_category ON public.sources(source_category);

-- -----------------------------------------------------------------------------
-- 5. ROW LEVEL SECURITY (RLS) POLICIES
-- -----------------------------------------------------------------------------
ALTER TABLE public.recruitment_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.examination_cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.opportunity_scholarships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.opportunity_internships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.opportunity_apprenticeships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.opportunity_fellowships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.private_job_requisitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admission_qualifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.opportunity_change_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.source_health_logs ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    -- Public read access to published opportunity details
    DROP POLICY IF EXISTS "Allow public read access to recruitment_posts" ON public.recruitment_posts;
    CREATE POLICY "Allow public read access to recruitment_posts" ON public.recruitment_posts FOR SELECT USING (true);

    DROP POLICY IF EXISTS "Allow public read access to examination_cycles" ON public.examination_cycles;
    CREATE POLICY "Allow public read access to examination_cycles" ON public.examination_cycles FOR SELECT USING (true);

    DROP POLICY IF EXISTS "Allow public read access to opportunity_scholarships" ON public.opportunity_scholarships;
    CREATE POLICY "Allow public read access to opportunity_scholarships" ON public.opportunity_scholarships FOR SELECT USING (true);

    DROP POLICY IF EXISTS "Allow public read access to opportunity_internships" ON public.opportunity_internships;
    CREATE POLICY "Allow public read access to opportunity_internships" ON public.opportunity_internships FOR SELECT USING (true);

    DROP POLICY IF EXISTS "Allow public read access to opportunity_apprenticeships" ON public.opportunity_apprenticeships;
    CREATE POLICY "Allow public read access to opportunity_apprenticeships" ON public.opportunity_apprenticeships FOR SELECT USING (true);

    DROP POLICY IF EXISTS "Allow public read access to opportunity_fellowships" ON public.opportunity_fellowships;
    CREATE POLICY "Allow public read access to opportunity_fellowships" ON public.opportunity_fellowships FOR SELECT USING (true);

    DROP POLICY IF EXISTS "Allow public read access to private_job_requisitions" ON public.private_job_requisitions;
    CREATE POLICY "Allow public read access to private_job_requisitions" ON public.private_job_requisitions FOR SELECT USING (true);

    DROP POLICY IF EXISTS "Allow public read access to admission_qualifications" ON public.admission_qualifications;
    CREATE POLICY "Allow public read access to admission_qualifications" ON public.admission_qualifications FOR SELECT USING (true);

    DROP POLICY IF EXISTS "Allow public read access to opportunity_change_history" ON public.opportunity_change_history;
    CREATE POLICY "Allow public read access to opportunity_change_history" ON public.opportunity_change_history FOR SELECT USING (true);

    DROP POLICY IF EXISTS "Allow public read access to source_health_logs" ON public.source_health_logs;
    CREATE POLICY "Allow public read access to source_health_logs" ON public.source_health_logs FOR SELECT USING (true);

    DROP POLICY IF EXISTS "Allow public read access to sources" ON public.sources;
    CREATE POLICY "Allow public read access to sources" ON public.sources FOR SELECT USING (true);
END $$;

