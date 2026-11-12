-- =============================================================================
-- REXAM EXPLORE SECTION: INDEXES, STATUSES AND FULL-CATALOGUE SEARCH
-- Migration: 20261110000002_explore_pagination_and_statuses.sql
-- Optimizes query performance for range-based pagination, continuous scrolling,
-- full database filtering (all 36 States/UTs, qualifications, lifecycle statuses).
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gin;

-- 1. Ensure required columns on examinations table
ALTER TABLE public.examinations
    ADD COLUMN IF NOT EXISTS application_status TEXT DEFAULT 'awaiting_notification',
    ADD COLUMN IF NOT EXISTS opportunity_type TEXT DEFAULT 'recruitment_examination',
    ADD COLUMN IF NOT EXISTS state TEXT,
    ADD COLUMN IF NOT EXISTS qualification_levels TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS educational_eligibility TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS required_disciplines TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS application_close_date TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS application_open_date TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS examination_date DATE,
    ADD COLUMN IF NOT EXISTS verification_status TEXT DEFAULT 'verified';

-- 2. Performance & Multi-dimensional Query Indexes
CREATE INDEX IF NOT EXISTS idx_examinations_app_status ON public.examinations(application_status);
CREATE INDEX IF NOT EXISTS idx_examinations_opp_type ON public.examinations(opportunity_type);
CREATE INDEX IF NOT EXISTS idx_examinations_state ON public.examinations(state);
CREATE INDEX IF NOT EXISTS idx_examinations_category ON public.examinations(category);
CREATE INDEX IF NOT EXISTS idx_examinations_last_verified ON public.examinations(last_verified_at DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_examinations_close_date ON public.examinations(application_close_date ASC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_examinations_status_published ON public.examinations(status);

-- 3. Array GIN Indexes for Fast Qualification & Stream Filtering
CREATE INDEX IF NOT EXISTS idx_examinations_qual_levels_gin ON public.examinations USING GIN (qualification_levels);
CREATE INDEX IF NOT EXISTS idx_examinations_edu_elig_gin ON public.examinations USING GIN (educational_eligibility);

-- 4. Text Search Composite Index for Instant Exploratory Search
CREATE INDEX IF NOT EXISTS idx_examinations_title_trgm ON public.examinations USING gin (title gin_trgm_ops);
