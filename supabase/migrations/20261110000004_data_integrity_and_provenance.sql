-- =============================================================================
-- REXAM DATA INTEGRITY, PROVENANCE AND MULTI-LAYER FACT VERIFICATION MIGRATION
-- Migration: 20261110000004_data_integrity_and_provenance.sql
-- Purpose: Field-level evidence & provenance tracking (28 critical fields),
--          authoritative URL validation status & redirect history,
--          corrigendum precedence & examination change audit trail,
--          and multi-tier verification (VERIFIED, PARTIALLY_VERIFIED, UNDER_REVIEW).
-- Safe to execute idempotently in the Supabase Dashboard SQL Editor.
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- -----------------------------------------------------------------------------
-- 1. ENHANCE public.sources WITH DOMAIN & RELIABILITY ATTRIBUTES
-- -----------------------------------------------------------------------------
ALTER TABLE public.sources
    ADD COLUMN IF NOT EXISTS official_domain TEXT,
    ADD COLUMN IF NOT EXISTS is_primary_source BOOLEAN DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS reliability_score NUMERIC(3,2) DEFAULT 1.0,
    ADD COLUMN IF NOT EXISTS availability_status TEXT DEFAULT 'ACTIVE';

-- -----------------------------------------------------------------------------
-- 2. ENHANCE public.examinations WITH VERIFICATION TIER & VALIDATED URL FIELDS
-- -----------------------------------------------------------------------------
ALTER TABLE public.examinations
    ADD COLUMN IF NOT EXISTS verification_tier TEXT DEFAULT 'PARTIALLY_VERIFIED',
    ADD COLUMN IF NOT EXISTS is_application_url_verified BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS application_url_status TEXT DEFAULT 'NEEDS_REVIEW',
    ADD COLUMN IF NOT EXISTS verified_application_url TEXT,
    ADD COLUMN IF NOT EXISTS verified_notification_url TEXT,
    ADD COLUMN IF NOT EXISTS field_evidence_summary JSONB DEFAULT '{}'::jsonb;

-- -----------------------------------------------------------------------------
-- 3. FIELD-LEVEL EVIDENCE & PROVENANCE TRACKING TABLE
-- Tracks atomic evidence for 28 critical fields extracted from gazettes/portals
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.examination_field_evidence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    examination_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE,
    field_name TEXT NOT NULL,
    field_value TEXT,
    source_url TEXT NOT NULL,
    document_url TEXT,
    snippet_or_quote TEXT,
    page_or_paragraph TEXT,
    confidence_score NUMERIC(4,3) DEFAULT 1.0,
    verified_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
    verified_by TEXT DEFAULT 'automated_verifier_v2',
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
    CONSTRAINT uq_exam_field_evidence UNIQUE (examination_id, field_name)
);

-- -----------------------------------------------------------------------------
-- 4. OFFICIAL URL VALIDATION & REDIRECT CHAIN TRACKING TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.url_validations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    url TEXT NOT NULL UNIQUE,
    normalized_url TEXT NOT NULL,
    domain TEXT NOT NULL,
    status_code INT,
    validation_status TEXT NOT NULL, -- VERIFIED, REDIRECTED_VERIFIED, TEMPORARILY_UNAVAILABLE, INVALID_DNS, INVALID_URL, DOMAIN_MISMATCH, NEEDS_REVIEW
    redirect_chain TEXT[] DEFAULT '{}',
    final_url TEXT,
    is_https BOOLEAN DEFAULT TRUE,
    last_checked_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW())
);

-- -----------------------------------------------------------------------------
-- 5. CANONICAL EXAMINATION CHANGE HISTORY TABLE
-- Full audit trail of corrigenda, date extensions, vacancy revisions, cancellations
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.examination_change_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    examination_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE,
    field_name TEXT NOT NULL,
    old_value TEXT,
    new_value TEXT,
    change_type TEXT NOT NULL DEFAULT 'corrigendum', -- corrigendum, extension, revision, cancellation, announcement
    change_summary TEXT NOT NULL,
    source_document_url TEXT,
    effective_date TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
    detected_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
    verification_status TEXT DEFAULT 'verified',
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW())
);

-- -----------------------------------------------------------------------------
-- 6. PERFORMANCE & LOOKUP INDEXES
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_field_evidence_exam ON public.examination_field_evidence(examination_id);
CREATE INDEX IF NOT EXISTS idx_field_evidence_field ON public.examination_field_evidence(field_name);
CREATE INDEX IF NOT EXISTS idx_field_evidence_conf ON public.examination_field_evidence(confidence_score);

CREATE INDEX IF NOT EXISTS idx_url_validations_domain ON public.url_validations(domain);
CREATE INDEX IF NOT EXISTS idx_url_validations_status ON public.url_validations(validation_status);
CREATE INDEX IF NOT EXISTS idx_url_validations_last_chk ON public.url_validations(last_checked_at);

CREATE INDEX IF NOT EXISTS idx_exam_change_history_exam ON public.examination_change_history(examination_id);
CREATE INDEX IF NOT EXISTS idx_exam_change_history_type ON public.examination_change_history(change_type);
CREATE INDEX IF NOT EXISTS idx_exam_change_history_dt ON public.examination_change_history(detected_at DESC);

CREATE INDEX IF NOT EXISTS idx_examinations_verif_tier ON public.examinations(verification_tier);
CREATE INDEX IF NOT EXISTS idx_examinations_app_url_stat ON public.examinations(application_url_status);

-- -----------------------------------------------------------------------------
-- 7. ROW LEVEL SECURITY (RLS) POLICIES
-- Read access for candidates, write access restricted to service role
-- -----------------------------------------------------------------------------
ALTER TABLE public.examination_field_evidence ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.url_validations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.examination_change_history ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    -- Public read access to verified field evidence
    DROP POLICY IF EXISTS "Allow public read access to examination_field_evidence" ON public.examination_field_evidence;
    CREATE POLICY "Allow public read access to examination_field_evidence"
        ON public.examination_field_evidence FOR SELECT
        USING (true);

    -- Public read access to url validations
    DROP POLICY IF EXISTS "Allow public read access to url_validations" ON public.url_validations;
    CREATE POLICY "Allow public read access to url_validations"
        ON public.url_validations FOR SELECT
        USING (true);

    -- Public read access to examination change history
    DROP POLICY IF EXISTS "Allow public read access to examination_change_history" ON public.examination_change_history;
    CREATE POLICY "Allow public read access to examination_change_history"
        ON public.examination_change_history FOR SELECT
        USING (true);
END $$;

