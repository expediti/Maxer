-- REXAM: Comprehensive Supabase PostgreSQL Schema Migration (01_initial_schema.sql)
-- Target: Indian Examination Discovery, Eligibility & Tracking Architecture
-- Extension Setup

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. PROFILES (Linked directly to Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT NOT NULL,
    date_of_birth DATE,
    gender TEXT,
    nationality TEXT NOT NULL DEFAULT 'Indian',
    state TEXT,
    district TEXT,
    country_of_residence TEXT NOT NULL DEFAULT 'India',
    social_category TEXT NOT NULL DEFAULT 'General', -- General, OBC-NCL, SC, ST, EWS
    is_pwbd BOOLEAN NOT NULL DEFAULT FALSE,
    pwbd_disability_type TEXT,
    is_ex_serviceman BOOLEAN NOT NULL DEFAULT FALSE,
    additional_relaxations TEXT[] DEFAULT '{}',
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- 2. CANDIDATE EDUCATION
CREATE TABLE IF NOT EXISTS public.candidate_education (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    candidate_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    highest_qualification TEXT NOT NULL, -- 10th, 12th, Diploma, B.Tech / B.E., Bachelor's, Master's, Ph.D
    degree_name TEXT,
    stream TEXT, -- Engineering Branch or Academic Specialization
    institution TEXT,
    is_institution_recognized BOOLEAN NOT NULL DEFAULT TRUE,
    graduation_year INT,
    expected_graduation_date DATE,
    cgpa_or_percentage NUMERIC(5,2),
    has_active_backlogs BOOLEAN NOT NULL DEFAULT FALSE,
    gate_score INT,
    gate_year INT,
    has_net_jrf BOOLEAN NOT NULL DEFAULT FALSE,
    net_subject TEXT,
    work_experience_years NUMERIC(4,1) NOT NULL DEFAULT 0.0,
    research_experience_months INT NOT NULL DEFAULT 0,
    certifications TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- 3. CANDIDATE PREFERENCES
CREATE TABLE IF NOT EXISTS public.candidate_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    candidate_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE,
    preferred_categories TEXT[] DEFAULT '{}',
    preferred_states TEXT[] DEFAULT '{}',
    willing_to_relocate BOOLEAN NOT NULL DEFAULT TRUE,
    willing_to_work_anywhere_in_india BOOLEAN NOT NULL DEFAULT TRUE,
    max_application_fee_budget NUMERIC(10,2),
    career_interests TEXT[] DEFAULT '{}',
    notification_preferences JSONB NOT NULL DEFAULT '{"push": true, "deadlines": true, "corrigenda": true, "results": true}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- 4. ORGANISATIONS (Conducting bodies & Ministries)
CREATE TABLE IF NOT EXISTS public.organisations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    short_name TEXT,
    organisation_type TEXT NOT NULL, -- Central Government, State Government, PSU, Defence, Testing Agency, University, Corporate
    parent_ministry TEXT,
    state TEXT,
    website_url TEXT,
    logo_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- 5. SOURCES (Official crawler targets)
CREATE TABLE IF NOT EXISTS public.sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organisation_id UUID REFERENCES public.organisations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    source_type TEXT NOT NULL, -- html, pdf, rss, sitemap
    base_url TEXT NOT NULL UNIQUE,
    crawler_adapter TEXT NOT NULL, -- upsc, ssc, isro, drdo, ibps, nta, rrb, generic
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    scrape_interval_hours INT NOT NULL DEFAULT 24,
    last_scanned_at TIMESTAMPTZ,
    last_status TEXT NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- 6. EXAMINATIONS (Core opportunity records)
CREATE TABLE IF NOT EXISTS public.examinations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organisation_id UUID NOT NULL REFERENCES public.organisations(id) ON DELETE RESTRICT,
    source_id UUID REFERENCES public.sources(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    category TEXT NOT NULL, -- Government Recruitment, PSU Recruitment, Entrance Examinations, University Admissions, Scholarships & Fellowships, Research & Internships, Private Jobs, Professional Certifications
    status TEXT NOT NULL DEFAULT 'published', -- draft, published, updated, expired, under_review
    overview TEXT NOT NULL,
    vacancies INT,
    salary_or_pay_scale TEXT,
    location TEXT NOT NULL DEFAULT 'All India',
    official_notification_url TEXT,
    official_application_url TEXT NOT NULL,
    source_url TEXT NOT NULL,
    last_verified_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    is_official_source BOOLEAN NOT NULL DEFAULT TRUE,
    is_confirmed BOOLEAN NOT NULL DEFAULT TRUE,
    is_central_government BOOLEAN NOT NULL DEFAULT TRUE,
    state TEXT,
    selection_procedure TEXT,
    exam_pattern TEXT,
    application_instructions TEXT,
    uncertain_fields TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- 7. EXAMINATION DATES
CREATE TABLE IF NOT EXISTS public.examination_dates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    examination_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE UNIQUE,
    notification_date DATE,
    application_opening_date TIMESTAMPTZ,
    application_closing_date TIMESTAMPTZ,
    fee_payment_deadline TIMESTAMPTZ,
    correction_window_start TIMESTAMPTZ,
    correction_window_end TIMESTAMPTZ,
    admit_card_release_date DATE,
    examination_start_date DATE,
    examination_end_date DATE,
    result_date DATE,
    is_tentative BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- 8. ELIGIBILITY RULES
CREATE TABLE IF NOT EXISTS public.eligibility_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    examination_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE UNIQUE,
    min_age INT NOT NULL DEFAULT 18,
    max_age INT NOT NULL DEFAULT 35,
    age_cutoff_date DATE,
    category_age_relaxations JSONB NOT NULL DEFAULT '{}'::jsonb,
    educational_qualifications TEXT[] NOT NULL DEFAULT '{}',
    eligible_branches TEXT[] NOT NULL DEFAULT '{}',
    min_percentage NUMERIC(5,2),
    nationality TEXT NOT NULL DEFAULT 'Citizen of India',
    gender_requirements TEXT NOT NULL DEFAULT 'All genders eligible',
    work_experience_requirement TEXT NOT NULL DEFAULT 'None required',
    required_documents TEXT[] NOT NULL DEFAULT '{}',
    fee_general NUMERIC(10,2),
    fee_exemptions TEXT NOT NULL DEFAULT 'SC/ST/PwBD and female candidates exempted',
    evidence_page_number INT,
    extracted_rule_text TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- 9. EXAMINATION DOCUMENTS
CREATE TABLE IF NOT EXISTS public.examination_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    examination_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE,
    document_type TEXT NOT NULL, -- official_notification, corrigendum, syllabus, admit_card_notice, result_pdf
    title TEXT NOT NULL,
    file_url TEXT NOT NULL,
    sha256_hash TEXT NOT NULL,
    file_size_bytes BIGINT,
    extracted_text TEXT,
    published_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- 10. EXAMINATION UPDATES (Corrigenda, changes & announcements)
CREATE TABLE IF NOT EXISTS public.examination_updates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    examination_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE,
    update_type TEXT NOT NULL, -- corrigendum, deadline_extended, admit_card_out, exam_rescheduled, result_declared
    title TEXT NOT NULL,
    summary TEXT NOT NULL,
    official_source_url TEXT,
    effective_date TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- 11. SAVED EXAMINATIONS (Candidate Bookmarks)
CREATE TABLE IF NOT EXISTS public.saved_examinations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    candidate_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    examination_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    UNIQUE(candidate_id, examination_id)
);

-- 12. CANDIDATE FOLLOWED EXAMINATIONS (Direct notification subscriptions)
CREATE TABLE IF NOT EXISTS public.candidate_followed_examinations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    candidate_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    examination_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE,
    receive_email BOOLEAN NOT NULL DEFAULT TRUE,
    receive_push BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    UNIQUE(candidate_id, examination_id)
);

-- 13. CANDIDATE APPLICATIONS (User lifecycle tracker)
CREATE TABLE IF NOT EXISTS public.candidate_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    candidate_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    examination_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'Interested', -- Interested, Preparing Documents, Ready to Apply, Applied, Admit Card Released, Examination Completed, Result Declared, Selected, Rejected, Withdrawn
    application_number TEXT,
    applied_date TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    scheduled_exam_date DATE,
    personal_notes TEXT,
    completed_checklist TEXT[] DEFAULT '{}',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    UNIQUE(candidate_id, examination_id)
);

-- 14. NOTIFICATIONS (Candidate in-app notification center)
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    candidate_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    examination_id UUID REFERENCES public.examinations(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    notification_type TEXT NOT NULL, -- upcoming_deadline, corrigendum, admit_card, result, recommendation
    official_source_url TEXT,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    delivered_via_fcm BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- 15. DEVICE TOKENS (FCM Push tokens per device)
CREATE TABLE IF NOT EXISTS public.device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    candidate_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL UNIQUE,
    platform TEXT NOT NULL DEFAULT 'android',
    device_model TEXT,
    last_active_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- 16. CRAWLER RUNS (Ingestion telemetry & scan logs)
CREATE TABLE IF NOT EXISTS public.crawler_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_id UUID REFERENCES public.sources(id) ON DELETE SET NULL,
    source_name TEXT NOT NULL,
    started_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    completed_at TIMESTAMPTZ,
    status TEXT NOT NULL, -- RUNNING, COMPLETED, FAILED
    items_discovered INT NOT NULL DEFAULT 0,
    items_processed INT NOT NULL DEFAULT 0,
    errors JSONB DEFAULT '[]'::jsonb
);

-- 17. PROCESSED DOCUMENTS (Deduplication ledger with SHA-256)
CREATE TABLE IF NOT EXISTS public.processed_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_id UUID REFERENCES public.sources(id) ON DELETE SET NULL,
    url TEXT NOT NULL UNIQUE,
    sha256_hash TEXT NOT NULL,
    document_title TEXT,
    status TEXT NOT NULL DEFAULT 'PROCESSED', -- PENDING, PROCESSED, FAILED, MANUAL_REVIEW
    processing_error TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- 18. CANDIDATE MATCHES (Pre-evaluated match cache for instant feeds)
CREATE TABLE IF NOT EXISTS public.candidate_matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    candidate_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    examination_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE,
    match_status TEXT NOT NULL, -- Eligible, Potentially Eligible, Not Eligible
    match_score NUMERIC(5,2),
    reasons JSONB DEFAULT '[]'::jsonb,
    evaluated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    UNIQUE(candidate_id, examination_id)
);

-- PERFORMANCE INDEXES
CREATE INDEX IF NOT EXISTS idx_examinations_status ON public.examinations(status);
CREATE INDEX IF NOT EXISTS idx_examinations_category ON public.examinations(category);
CREATE INDEX IF NOT EXISTS idx_examinations_org ON public.examinations(organisation_id);
CREATE INDEX IF NOT EXISTS idx_examinations_slug ON public.examinations(slug);
CREATE INDEX IF NOT EXISTS idx_examinations_name_gin ON public.examinations USING gin (to_tsvector('english', name));

CREATE INDEX IF NOT EXISTS idx_examination_dates_closing ON public.examination_dates(application_closing_date);
CREATE INDEX IF NOT EXISTS idx_examination_dates_exam ON public.examination_dates(examination_start_date);

CREATE INDEX IF NOT EXISTS idx_candidate_education_cand ON public.candidate_education(candidate_id);
CREATE INDEX IF NOT EXISTS idx_saved_examinations_cand ON public.saved_examinations(candidate_id);
CREATE INDEX IF NOT EXISTS idx_candidate_applications_cand ON public.candidate_applications(candidate_id);
CREATE INDEX IF NOT EXISTS idx_notifications_cand_read ON public.notifications(candidate_id, is_read);
CREATE INDEX IF NOT EXISTS idx_processed_docs_hash ON public.processed_documents(sha256_hash);

