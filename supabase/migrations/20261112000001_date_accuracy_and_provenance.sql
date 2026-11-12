-- =============================================================================
-- Migration: 20261112000001_date_accuracy_and_provenance.sql
-- Description: Establishes 10 independent date fields on public.examinations,
--              creates public.opportunity_date_evidence table for immutable
--              source provenance, removes unique constraints that block multiple
--              independent date sources/corrigenda, and configures synchronization.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. ADD 10 INDEPENDENT DATE FIELDS TO public.examinations
-- -----------------------------------------------------------------------------
ALTER TABLE public.examinations
    ADD COLUMN IF NOT EXISTS notification_date DATE,
    ADD COLUMN IF NOT EXISTS application_start_date TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS application_end_date TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS correction_start_date TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS correction_end_date TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS admit_card_date DATE,
    ADD COLUMN IF NOT EXISTS exam_start_date DATE,
    ADD COLUMN IF NOT EXISTS exam_end_date DATE,
    ADD COLUMN IF NOT EXISTS result_date DATE;

-- age_cutoff_date already exists from previous migration; ensure it exists
ALTER TABLE public.examinations
    ADD COLUMN IF NOT EXISTS age_cutoff_date DATE;

-- -----------------------------------------------------------------------------
-- 2. CREATE public.opportunity_date_evidence TABLE
-- Stores immutable evidence quotes, page numbers, and source URLs per date field.
-- Multiple evidence records allowed per opportunity and date field (no restrictive uniqueness).
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.opportunity_date_evidence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    opportunity_id UUID NOT NULL REFERENCES public.examinations(id) ON DELETE CASCADE,
    date_field TEXT NOT NULL, -- notification_date, application_start_date, application_end_date, etc.
    extracted_value TEXT, -- ISO string or date
    original_text TEXT NOT NULL, -- verbatim snippet / quote from notification
    source_url TEXT NOT NULL,
    source_document_title TEXT,
    page_number INT,
    extraction_method TEXT NOT NULL DEFAULT 'deterministic_regex', -- deterministic_regex, ocr_tesseract, pdf_table_parse, official_web_html, corrigendum_parser
    verification_status TEXT NOT NULL DEFAULT 'VERIFIED', -- VERIFIED, UNDER_REVIEW, SUPERSEDED, UNSUPPORTED
    is_corrigendum BOOLEAN NOT NULL DEFAULT FALSE,
    supersedes_evidence_id UUID REFERENCES public.opportunity_date_evidence(id) ON DELETE SET NULL,
    verified_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- Indices for performance
CREATE INDEX IF NOT EXISTS idx_date_evidence_opp ON public.opportunity_date_evidence(opportunity_id);
CREATE INDEX IF NOT EXISTS idx_date_evidence_field ON public.opportunity_date_evidence(date_field);
CREATE INDEX IF NOT EXISTS idx_date_evidence_status ON public.opportunity_date_evidence(verification_status);

-- Enable RLS
ALTER TABLE public.opportunity_date_evidence ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read access to date evidence" ON public.opportunity_date_evidence;
CREATE POLICY "Allow public read access to date evidence"
    ON public.opportunity_date_evidence FOR SELECT
    USING (true);

-- -----------------------------------------------------------------------------
-- 3. REMOVE RESTRICTIVE UNIQUE CONSTRAINT ON examination_field_evidence
-- Allows multiple independent source notices & corrigenda for the same field.
-- -----------------------------------------------------------------------------
ALTER TABLE public.examination_field_evidence
    DROP CONSTRAINT IF EXISTS uq_exam_field_evidence;

-- -----------------------------------------------------------------------------
-- 4. BACKWARD COMPATIBILITY & BIDIRECTIONAL SYNCHRONIZATION TRIGGER
-- Keeps examinations and examination_dates in sync automatically.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.sync_examination_dates_trigger()
RETURNS TRIGGER AS $$
BEGIN
    -- Synchronize legacy columns on examinations
    IF NEW.application_start_date IS NOT NULL THEN
        NEW.application_open_date := NEW.application_start_date;
    END IF;
    IF NEW.application_end_date IS NOT NULL THEN
        NEW.application_close_date := NEW.application_end_date;
    END IF;
    IF NEW.exam_start_date IS NOT NULL THEN
        NEW.examination_date := NEW.exam_start_date;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_examination_dates ON public.examinations;
CREATE TRIGGER trg_sync_examination_dates
    BEFORE INSERT OR UPDATE ON public.examinations
    FOR EACH ROW
    EXECUTE FUNCTION public.sync_examination_dates_trigger();

