-- =============================================================================
-- REXAM: COMPLETE SUPABASE DATABASE SETUP SCRIPT
-- =============================================================================
-- Run this script in the Supabase Dashboard SQL Editor:
-- Dashboard -> SQL Editor -> New query -> Paste and click 'Run'
--
-- This script creates:
-- 1. All 18 application tables with indexes and constraints.
-- 2. Strict Row Level Security (RLS) policies for candidate privacy.
-- 3. Automatic candidate profile provisioning trigger on auth sign-up.
-- 4. Initial demonstration records for UPSC, ISRO, DRDO, SBI, PMRF, IOCL.
-- =============================================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- -----------------------------------------------------------------------------
-- 1. PROFILES (Candidate demographics linked to auth.users)
-- -----------------------------------------------------------------------------
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
    social_category TEXT NOT NULL DEFAULT 'General',
    is_pwbd BOOLEAN NOT NULL DEFAULT FALSE,
    pwbd_disability_type TEXT,
    is_ex_serviceman BOOLEAN NOT NULL DEFAULT FALSE,
    additional_relaxations TEXT[] DEFAULT '{}',
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- -----------------------------------------------------------------------------
-- 2. CANDIDATE EDUCATION
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.candidate_education (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    candidate_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    highest_qualification TEXT NOT NULL,
    degree_name TEXT,
    stream TEXT,
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

-- -----------------------------------------------------------------------------
-- 3. CANDIDATE PREFERENCES
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- 4. ORGANISATIONS (Conducting bodies & Ministries)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.organisations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    slug TEXT UNIQUE,
    short_name TEXT,
    organisation_type TEXT NOT NULL,
    parent_ministry TEXT,
    state TEXT,
    website_url TEXT,
    logo_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- -----------------------------------------------------------------------------
-- 5. SOURCES (Official crawler targets)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organisation_id UUID REFERENCES public.organisations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    source_type TEXT NOT NULL DEFAULT 'html',
    base_url TEXT NOT NULL UNIQUE,
    url TEXT,
    crawler_adapter TEXT NOT NULL DEFAULT 'generic',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    scrape_interval_hours INT NOT NULL DEFAULT 24,
    last_scanned_at TIMESTAMPTZ,
    last_status TEXT NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- -----------------------------------------------------------------------------
-- 6. EXAMINATIONS (Core opportunity records)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.examinations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organisation_id UUID REFERENCES public.organisations(id) ON DELETE SET NULL,
    source_id UUID REFERENCES public.sources(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    title TEXT,
    slug TEXT UNIQUE NOT NULL,
    category TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'published',
    overview TEXT NOT NULL DEFAULT '',
    vacancies INT,
    salary_or_pay_scale TEXT,
    location TEXT NOT NULL DEFAULT 'All India',
    official_notification_url TEXT,
    notification_url TEXT,
    official_application_url TEXT NOT NULL DEFAULT '',
    application_url TEXT,
    source_url TEXT NOT NULL DEFAULT '',
    last_verified_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    last_crawled_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
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

-- -----------------------------------------------------------------------------
-- 7. EXAMINATION DATES
-- -----------------------------------------------------------------------------
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
    prelims_date DATE,
    examination_end_date DATE,
    result_date DATE,
    is_tentative BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- -----------------------------------------------------------------------------
-- 8. ELIGIBILITY RULES
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.eligibility_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    examination_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE UNIQUE,
    min_age INT NOT NULL DEFAULT 18,
    max_age INT NOT NULL DEFAULT 35,
    age_cutoff_date DATE,
    category_age_relaxations JSONB NOT NULL DEFAULT '{}'::jsonb,
    educational_qualifications TEXT[] NOT NULL DEFAULT '{}',
    eligible_branches TEXT[] NOT NULL DEFAULT '{}',
    eligible_streams TEXT[] NOT NULL DEFAULT '{}',
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

-- -----------------------------------------------------------------------------
-- 9. EXAMINATION DOCUMENTS
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.examination_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    examination_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE,
    document_type TEXT NOT NULL DEFAULT 'official_notification',
    title TEXT NOT NULL,
    file_url TEXT NOT NULL,
    sha256_hash TEXT NOT NULL,
    file_size_bytes BIGINT,
    extracted_text TEXT,
    published_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- -----------------------------------------------------------------------------
-- 10. EXAMINATION UPDATES (Corrigenda & milestone changes)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.examination_updates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    examination_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE,
    update_type TEXT NOT NULL,
    title TEXT NOT NULL,
    summary TEXT NOT NULL,
    official_source_url TEXT,
    effective_date TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- -----------------------------------------------------------------------------
-- 11. SAVED EXAMINATIONS (Candidate Bookmarks)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.saved_examinations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    candidate_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    examination_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE,
    notes TEXT,
    saved_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    UNIQUE(candidate_id, examination_id)
);

-- -----------------------------------------------------------------------------
-- 12. CANDIDATE FOLLOWED EXAMINATIONS
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.candidate_followed_examinations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    candidate_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    examination_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE,
    receive_email BOOLEAN NOT NULL DEFAULT TRUE,
    receive_push BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    UNIQUE(candidate_id, examination_id)
);

-- -----------------------------------------------------------------------------
-- 13. CANDIDATE APPLICATIONS (Application stage tracker)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.candidate_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    candidate_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    examination_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE,
    stage TEXT NOT NULL DEFAULT 'interested',
    status TEXT NOT NULL DEFAULT 'Interested',
    application_number TEXT,
    roll_number TEXT,
    applied_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
    applied_date TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
    scheduled_exam_date DATE,
    notes TEXT,
    personal_notes TEXT,
    checklist_completed JSONB DEFAULT '[]'::jsonb,
    completed_checklist TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    UNIQUE(candidate_id, examination_id)
);

-- -----------------------------------------------------------------------------
-- 14. NOTIFICATIONS
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    candidate_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    examination_id UUID REFERENCES public.examinations(id) ON DELETE SET NULL,
    type TEXT NOT NULL DEFAULT 'official',
    notification_type TEXT NOT NULL DEFAULT 'official',
    title TEXT NOT NULL,
    body TEXT,
    message TEXT NOT NULL DEFAULT '',
    official_source_url TEXT,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
    data JSONB DEFAULT '{}'::jsonb,
    delivered_via_fcm BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- -----------------------------------------------------------------------------
-- 15. DEVICE TOKENS (Push Notification device registry)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    candidate_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL UNIQUE,
    platform TEXT NOT NULL DEFAULT 'android',
    device_model TEXT,
    last_active_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- -----------------------------------------------------------------------------
-- 16. CRAWLER RUNS
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.crawler_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_id UUID REFERENCES public.sources(id) ON DELETE SET NULL,
    crawler_name TEXT,
    source_name TEXT NOT NULL DEFAULT '',
    started_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    completed_at TIMESTAMPTZ,
    status TEXT NOT NULL,
    examinations_found INT NOT NULL DEFAULT 0,
    examinations_updated INT NOT NULL DEFAULT 0,
    items_discovered INT NOT NULL DEFAULT 0,
    items_processed INT NOT NULL DEFAULT 0,
    error_message TEXT,
    errors JSONB DEFAULT '[]'::jsonb
);

-- -----------------------------------------------------------------------------
-- 17. PROCESSED DOCUMENTS (SHA-256 Deduplication)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.processed_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_id UUID REFERENCES public.sources(id) ON DELETE SET NULL,
    examination_id UUID REFERENCES public.examinations(id) ON DELETE SET NULL,
    url TEXT,
    sha256_hash TEXT NOT NULL UNIQUE,
    document_title TEXT,
    extracted_fields JSONB DEFAULT '{}'::jsonb,
    status TEXT NOT NULL DEFAULT 'PROCESSED',
    processing_error TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- -----------------------------------------------------------------------------
-- 18. CANDIDATE MATCHES (Matching engine cache)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.candidate_matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    candidate_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    examination_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE,
    match_status TEXT NOT NULL DEFAULT 'Eligible',
    status TEXT NOT NULL DEFAULT 'eligible',
    is_eligible BOOLEAN NOT NULL DEFAULT TRUE,
    match_score NUMERIC(5,2),
    reasons JSONB DEFAULT '[]'::jsonb,
    evaluated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    UNIQUE(candidate_id, examination_id)
);

-- -----------------------------------------------------------------------------
-- INDEXES
-- -----------------------------------------------------------------------------
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

-- =============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidate_education ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidate_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organisations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.examinations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.examination_dates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eligibility_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.examination_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.examination_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_examinations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidate_followed_examinations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidate_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crawler_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.processed_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidate_matches ENABLE ROW LEVEL SECURITY;

-- 1. Profiles
DROP POLICY IF EXISTS "Candidates can view own profile" ON public.profiles;
CREATE POLICY "Candidates can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Candidates can update own profile" ON public.profiles;
CREATE POLICY "Candidates can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Candidates can insert own profile" ON public.profiles;
CREATE POLICY "Candidates can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- 2. Candidate Education
DROP POLICY IF EXISTS "Candidates can manage own education" ON public.candidate_education;
CREATE POLICY "Candidates can manage own education" ON public.candidate_education FOR ALL
    USING (auth.uid() = candidate_id) WITH CHECK (auth.uid() = candidate_id);

-- 3. Candidate Preferences
DROP POLICY IF EXISTS "Candidates can manage own preferences" ON public.candidate_preferences;
CREATE POLICY "Candidates can manage own preferences" ON public.candidate_preferences FOR ALL
    USING (auth.uid() = candidate_id) WITH CHECK (auth.uid() = candidate_id);

-- 4. Organisations
DROP POLICY IF EXISTS "Anyone can view organisations" ON public.organisations;
CREATE POLICY "Anyone can view organisations" ON public.organisations FOR SELECT USING (true);

-- 5. Sources
DROP POLICY IF EXISTS "Authenticated users can view active sources" ON public.sources;
CREATE POLICY "Authenticated users can view active sources" ON public.sources FOR SELECT
    USING (auth.role() = 'authenticated' AND is_active = true);

-- 6. Examinations (Public read for published records)
DROP POLICY IF EXISTS "Anyone can view published examinations" ON public.examinations;
CREATE POLICY "Anyone can view published examinations" ON public.examinations FOR SELECT
    USING (status = 'published');

-- 7. Examination Dates
DROP POLICY IF EXISTS "Anyone can view dates for published examinations" ON public.examination_dates;
CREATE POLICY "Anyone can view dates for published examinations" ON public.examination_dates FOR SELECT
    USING (EXISTS (SELECT 1 FROM public.examinations e WHERE e.id = examination_dates.examination_id AND e.status = 'published'));

-- 8. Eligibility Rules
DROP POLICY IF EXISTS "Anyone can view eligibility rules for published examinations" ON public.eligibility_rules;
CREATE POLICY "Anyone can view eligibility rules for published examinations" ON public.eligibility_rules FOR SELECT
    USING (EXISTS (SELECT 1 FROM public.examinations e WHERE e.id = eligibility_rules.examination_id AND e.status = 'published'));

-- 9. Examination Documents
DROP POLICY IF EXISTS "Anyone can view documents for published examinations" ON public.examination_documents;
CREATE POLICY "Anyone can view documents for published examinations" ON public.examination_documents FOR SELECT
    USING (EXISTS (SELECT 1 FROM public.examinations e WHERE e.id = examination_documents.examination_id AND e.status = 'published'));

-- 10. Examination Updates
DROP POLICY IF EXISTS "Anyone can view updates for published examinations" ON public.examination_updates;
CREATE POLICY "Anyone can view updates for published examinations" ON public.examination_updates FOR SELECT
    USING (EXISTS (SELECT 1 FROM public.examinations e WHERE e.id = examination_updates.examination_id AND e.status = 'published'));

-- 11. Saved Examinations
DROP POLICY IF EXISTS "Candidates can manage own saved examinations" ON public.saved_examinations;
CREATE POLICY "Candidates can manage own saved examinations" ON public.saved_examinations FOR ALL
    USING (auth.uid() = candidate_id) WITH CHECK (auth.uid() = candidate_id);

-- 12. Candidate Followed Examinations
DROP POLICY IF EXISTS "Candidates can manage own follows" ON public.candidate_followed_examinations;
CREATE POLICY "Candidates can manage own follows" ON public.candidate_followed_examinations FOR ALL
    USING (auth.uid() = candidate_id) WITH CHECK (auth.uid() = candidate_id);

-- 13. Candidate Applications
DROP POLICY IF EXISTS "Candidates can manage own application tracking" ON public.candidate_applications;
CREATE POLICY "Candidates can manage own application tracking" ON public.candidate_applications FOR ALL
    USING (auth.uid() = candidate_id) WITH CHECK (auth.uid() = candidate_id);

-- 14. Notifications
DROP POLICY IF EXISTS "Candidates can view own notifications" ON public.notifications;
CREATE POLICY "Candidates can view own notifications" ON public.notifications FOR SELECT
    USING (auth.uid() = candidate_id);

DROP POLICY IF EXISTS "Candidates can update own notification read state" ON public.notifications;
CREATE POLICY "Candidates can update own notification read state" ON public.notifications FOR UPDATE
    USING (auth.uid() = candidate_id) WITH CHECK (auth.uid() = candidate_id);

DROP POLICY IF EXISTS "Candidates can delete own notifications" ON public.notifications;
CREATE POLICY "Candidates can delete own notifications" ON public.notifications FOR DELETE
    USING (auth.uid() = candidate_id);

-- 15. Device Tokens
DROP POLICY IF EXISTS "Candidates can manage own device tokens" ON public.device_tokens;
CREATE POLICY "Candidates can manage own device tokens" ON public.device_tokens FOR ALL
    USING (auth.uid() = candidate_id) WITH CHECK (auth.uid() = candidate_id);

-- 16. Candidate Matches
DROP POLICY IF EXISTS "Candidates can view own pre-evaluated matches" ON public.candidate_matches;
CREATE POLICY "Candidates can view own pre-evaluated matches" ON public.candidate_matches FOR SELECT
    USING (auth.uid() = candidate_id);

-- =============================================================================
-- AUTOMATIC CANDIDATE PROFILE PROVISIONING TRIGGER ON AUTH SIGN-UP
-- =============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (
        id,
        email,
        full_name,
        avatar_url
    )
    VALUES (
        new.id,
        new.email,
        COALESCE(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
        new.raw_user_meta_data->>'avatar_url'
    )
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.candidate_preferences (
        candidate_id,
        preferred_categories
    )
    VALUES (
        new.id,
        ARRAY['Government Recruitment', 'PSU Recruitment', 'Entrance Examinations']
    )
    ON CONFLICT (candidate_id) DO NOTHING;

    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================================================
-- INITIAL DEMONSTRATION OPPORTUNITIES SEED DATA
-- =============================================================================
INSERT INTO public.organisations (id, name, slug, short_name, organisation_type, parent_ministry, website_url)
VALUES
    ('a0000000-0000-0000-0000-000000000001', 'Union Public Service Commission', 'upsc', 'UPSC', 'Central Government', 'Department of Personnel and Training (DoPT)', 'https://upsc.gov.in'),
    ('a0000000-0000-0000-0000-000000000002', 'Indian Space Research Organisation', 'isro', 'ISRO', 'PSU', 'Department of Space', 'https://isro.gov.in'),
    ('a0000000-0000-0000-0000-000000000003', 'Defence Research and Development Organisation', 'drdo', 'DRDO', 'Defence', 'Ministry of Defence', 'https://drdo.gov.in'),
    ('a0000000-0000-0000-0000-000000000004', 'State Bank of India', 'sbi', 'SBI', 'PSU', 'Ministry of Finance', 'https://sbi.co.in'),
    ('a0000000-0000-0000-0000-000000000005', 'National PMRF Coordination Committee', 'pmrf', 'PMRF', 'University', 'Ministry of Education', 'https://pmrf.in'),
    ('a0000000-0000-0000-0000-000000000006', 'Indian Oil Corporation Limited', 'iocl', 'IOCL', 'PSU', 'Ministry of Petroleum and Natural Gas', 'https://iocl.com')
ON CONFLICT (name) DO UPDATE SET slug = EXCLUDED.slug;

INSERT INTO public.sources (id, organisation_id, name, source_type, base_url, url, crawler_adapter, is_active, scrape_interval_hours)
VALUES
    ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'UPSC Active Examinations Portal', 'html', 'https://upsc.gov.in/examinations/active-examinations', 'https://upsc.gov.in/examinations/active-examinations', 'upsc', true, 12),
    ('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000002', 'ISRO ICRB Recruitment Notice Board', 'html', 'https://apps.isac.gov.in/icrb-2026', 'https://apps.isac.gov.in/icrb-2026', 'isro', true, 24),
    ('b0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000003', 'DRDO RAC Recruitment Notice Portal', 'html', 'https://rac.gov.in', 'https://rac.gov.in', 'drdo', true, 24)
ON CONFLICT (base_url) DO NOTHING;

INSERT INTO public.examinations (
    id, organisation_id, source_id, name, title, slug, category, status,
    overview, vacancies, salary_or_pay_scale, location,
    official_notification_url, notification_url, official_application_url, application_url, source_url,
    last_verified_at, is_official_source, is_confirmed, is_central_government
)
VALUES
    (
        'c0000000-0000-0000-0000-000000000001',
        'a0000000-0000-0000-0000-000000000001',
        'b0000000-0000-0000-0000-000000000001',
        'Civil Services Examination (Preliminary) 2026',
        'Civil Services Examination (Preliminary) 2026',
        'upsc-cse-prelims-2026',
        'Government Recruitment',
        'published',
        'Annual premier competitive examination conducted by UPSC to recruit officers into IAS, IPS, IFS and Central Services Group A & B.',
        1056,
        'Level 10 of 7th CPC (₹56,100 to ₹1,77,500 base pay)',
        'All India Cadre Allocation',
        'https://upsc.gov.in/sites/default/files/ExamNotice_CSE_2026.pdf',
        'https://upsc.gov.in/sites/default/files/ExamNotice_CSE_2026.pdf',
        'https://upsconline.nic.in',
        'https://upsconline.nic.in',
        'https://upsc.gov.in',
        TIMEZONE('utc', NOW()),
        true, true, true
    ),
    (
        'c0000000-0000-0000-0000-000000000002',
        'a0000000-0000-0000-0000-000000000002',
        'b0000000-0000-0000-0000-000000000002',
        'Recruitment of Scientist/Engineer "SC" (CS / Mechanical / Electronics)',
        'Recruitment of Scientist/Engineer "SC" (CS / Mechanical / Electronics)',
        'isro-scientist-engineer-sc-2026',
        'PSU Recruitment',
        'published',
        'ISRO Centralised Recruitment Board invites applications for Group A Gazetted Scientist posts in Bengaluru, VSSC, and URSC.',
        320,
        'Level 10 (Gross Emoluments ~₹92,000/month)',
        'Bengaluru, Thiruvananthapuram, Sriharikota',
        'https://isro.gov.in/media_isro/pdf/ICRB_SC_2026.pdf',
        'https://isro.gov.in/media_isro/pdf/ICRB_SC_2026.pdf',
        'https://apps.isac.gov.in/icrb-2026',
        'https://apps.isac.gov.in/icrb-2026',
        'https://isro.gov.in',
        TIMEZONE('utc', NOW()),
        true, true, true
    ),
    (
        'c0000000-0000-0000-0000-000000000003',
        'a0000000-0000-0000-0000-000000000003',
        'b0000000-0000-0000-0000-000000000003',
        'Recruitment of Scientist "B" via Valid GATE Score (RAC Advt 148)',
        'Recruitment of Scientist "B" via Valid GATE Score (RAC Advt 148)',
        'drdo-scientist-b-gate-2026',
        'Government Recruitment',
        'published',
        'DRDO RAC invites applications for 204 Scientist "B" positions in strategic aerospace, defense electronic, and computing divisions.',
        204,
        'Level 10 (Basic ₹56,100, gross ~₹95,000/month)',
        'Pan-India DRDO Laboratories',
        'https://rac.gov.in/download/advt_148_scientist_b.pdf',
        'https://rac.gov.in/download/advt_148_scientist_b.pdf',
        'https://rac.gov.in',
        'https://rac.gov.in',
        'https://rac.gov.in',
        TIMEZONE('utc', NOW()),
        true, true, true
    )
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.examination_dates (
    examination_id, notification_date, application_opening_date,
    application_closing_date, fee_payment_deadline, examination_start_date, prelims_date, is_tentative
)
VALUES
    (
        'c0000000-0000-0000-0000-000000000001',
        '2026-02-14',
        '2026-02-14 10:00:00+00',
        '2026-03-06 18:00:00+00',
        '2026-03-06 18:00:00+00',
        '2026-05-25',
        '2026-05-25',
        false
    ),
    (
        'c0000000-0000-0000-0000-000000000002',
        '2026-02-01',
        '2026-02-01 10:00:00+00',
        '2026-02-28 17:00:00+00',
        '2026-03-01 23:59:00+00',
        '2026-06-14',
        '2026-06-14',
        false
    ),
    (
        'c0000000-0000-0000-0000-000000000003',
        '2026-02-28',
        '2026-02-28 00:00:00+00',
        '2026-03-29 11:30:00+00',
        '2026-03-29 11:30:00+00',
        '2026-04-30',
        '2026-04-30',
        true
    )
ON CONFLICT (examination_id) DO NOTHING;

INSERT INTO public.eligibility_rules (
    examination_id, min_age, max_age, age_cutoff_date,
    category_age_relaxations, educational_qualifications, eligible_branches, eligible_streams,
    nationality, fee_general, fee_exemptions
)
VALUES
    (
        'c0000000-0000-0000-0000-000000000001',
        21, 32, '2026-08-01',
        '{"General": "32 years, 6 attempts", "OBC-NCL": "35 years (3 yr relaxation), 9 attempts", "SC/ST": "37 years (5 yr relaxation), unlimited attempts", "PwBD": "42 years (10 yr relaxation)"}'::jsonb,
        ARRAY['Bachelor degree in any discipline from a recognized University'],
        ARRAY['All Disciplines'],
        ARRAY['All Disciplines'],
        'Citizen of India',
        100.00,
        'Female candidates, SC, ST, and PwBD are fully exempted from fee payment.'
    ),
    (
        'c0000000-0000-0000-0000-000000000002',
        18, 28, '2026-02-28',
        '{"General": "28 years", "OBC-NCL": "31 years (3 yr relaxation)", "SC/ST": "33 years (5 yr relaxation)", "PwBD": "38 years (10 yr relaxation)"}'::jsonb,
        ARRAY['B.E. / B.Tech or equivalent in CS / Mechanical / Electronics with minimum 65% aggregate or 6.84 CGPA'],
        ARRAY['Computer Science & Engineering', 'Mechanical Engineering', 'Electronics & Communication Engineering'],
        ARRAY['Computer Science & Engineering', 'Mechanical Engineering', 'Electronics & Communication Engineering'],
        'Citizen of India',
        250.00,
        'All Women candidates, SC/ST, and PwBD candidates are exempted from payment of fee.'
    ),
    (
        'c0000000-0000-0000-0000-000000000003',
        21, 28, '2026-03-29',
        '{"General/EWS": "28 years", "OBC-NCL": "31 years", "SC/ST": "33 years", "PwBD": "38 years"}'::jsonb,
        ARRAY['First Class Bachelor’s Degree in Engineering with Valid GATE Score'],
        ARRAY['Computer Science & Engineering', 'Mechanical Engineering', 'Electronics & Communication', 'Electrical Engineering'],
        ARRAY['Computer Science & Engineering', 'Mechanical Engineering', 'Electronics & Communication', 'Electrical Engineering'],
        'Citizen of India',
        100.00,
        'SC/ST/PwBD and Women candidates exempted from payment of fee.'
    )
ON CONFLICT (examination_id) DO NOTHING;

