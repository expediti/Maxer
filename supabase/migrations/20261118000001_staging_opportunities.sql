-- =============================================================================
-- Migration: 20261118000001_staging_opportunities.sql
-- Description: Introduces staging_opportunities table for pre-production 
--              data verification, Gemini API structured outputs, and
--              deterministic guardrails before reflecting to user-facing examinations.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.staging_opportunities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug TEXT NOT NULL UNIQUE,
    source_id UUID REFERENCES public.sources(id) ON DELETE SET NULL,
    organisation_id UUID REFERENCES public.organisations(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    organisation_name TEXT,
    application_url TEXT,
    official_notification_url TEXT,
    source_url TEXT,
    raw_text_snippet TEXT,
    
    -- Normalized Dates
    notification_date DATE,
    start_date DATE,
    closing_date DATE,
    correction_start_date DATE,
    correction_end_date DATE,
    admit_card_date DATE,
    exam_date DATE,
    exam_end_date DATE,
    result_date DATE,

    -- Provenance & AI Audit Fields
    date_evidence JSONB DEFAULT '{}'::jsonb,
    extracted_data JSONB DEFAULT '{}'::jsonb,
    validation_errors JSONB DEFAULT '[]'::jsonb,
    is_verified BOOLEAN DEFAULT FALSE,
    verification_status TEXT NOT NULL DEFAULT 'PENDING', -- PENDING, VERIFIED, NEEDS_REVIEW, REJECTED, PROMOTED
    
    -- Promotion to Production State
    promoted_to_production BOOLEAN DEFAULT FALSE,
    promoted_at TIMESTAMPTZ,
    production_examination_id UUID REFERENCES public.examinations(id) ON DELETE SET NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- Performance & Lookup Indexes
CREATE INDEX IF NOT EXISTS idx_staging_opp_slug ON public.staging_opportunities(slug);
CREATE INDEX IF NOT EXISTS idx_staging_opp_source ON public.staging_opportunities(source_id);
CREATE INDEX IF NOT EXISTS idx_staging_opp_org ON public.staging_opportunities(organisation_id);
CREATE INDEX IF NOT EXISTS idx_staging_opp_status ON public.staging_opportunities(verification_status);
CREATE INDEX IF NOT EXISTS idx_staging_opp_verified ON public.staging_opportunities(is_verified);
CREATE INDEX IF NOT EXISTS idx_staging_opp_promoted ON public.staging_opportunities(promoted_to_production);

-- Enable RLS
ALTER TABLE public.staging_opportunities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read access to staging opportunities" ON public.staging_opportunities;
CREATE POLICY "Allow public read access to staging opportunities"
    ON public.staging_opportunities FOR SELECT
    USING (true);
