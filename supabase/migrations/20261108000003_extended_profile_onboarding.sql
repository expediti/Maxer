-- =============================================================================
-- REXAM ADDITIVE MIGRATION: EXTENDED ONBOARDING, PROFILE & QUALIFICATIONS
-- Migration: 20261108000003_extended_profile_onboarding.sql
-- Safe to execute all at once in Supabase SQL Editor.
-- Completely preserves existing user accounts, opportunities, applications & RLS.
-- =============================================================================

-- 1. ADD EXTENDED ONBOARDING & PROFILE ATTRIBUTES TO public.profiles
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS current_status TEXT,
    ADD COLUMN IF NOT EXISTS class_10_year INT,
    ADD COLUMN IF NOT EXISTS class_12_year INT,
    ADD COLUMN IF NOT EXISTS class_12_stream TEXT,
    ADD COLUMN IF NOT EXISTS is_obc_ncl BOOLEAN DEFAULT FALSE;

-- 2. ADD QUALIFICATION STATUS TO public.candidate_education
ALTER TABLE public.candidate_education
    ADD COLUMN IF NOT EXISTS qualification_type TEXT DEFAULT 'Undergraduate',
    ADD COLUMN IF NOT EXISTS is_completed BOOLEAN NOT NULL DEFAULT TRUE;

-- 3. CREATE PERFORMANCE INDEXES FOR CANDIDATE SEARCH & ELIGIBILITY MATCHING
CREATE INDEX IF NOT EXISTS idx_profiles_current_status 
    ON public.profiles(current_status);

CREATE INDEX IF NOT EXISTS idx_candidate_education_cand_qual 
    ON public.candidate_education(candidate_id, highest_qualification);

-- 4. VERIFY ROW LEVEL SECURITY (RLS) POLICIES REMAIN ACTIVE AND ENFORCED
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidate_education ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidate_preferences ENABLE ROW LEVEL SECURITY;

