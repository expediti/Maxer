-- =============================================================================
-- REXAM ADDITIVE MIGRATION: ACADEMIC STAGES, GRADING SYSTEMS & VERIFIED CONVERSION
-- Migration: 20261108000005_academic_eligibility_and_stages.sql
-- Safe to execute all at once in Supabase SQL Editor.
-- Completely preserves existing user accounts, opportunities, applications & RLS.
-- =============================================================================

-- 1. EXTEND candidate_education WITH GRANULAR UNDERGRADUATE PROGRESS & GRADING SYSTEMS
ALTER TABLE public.candidate_education
    ADD COLUMN IF NOT EXISTS university TEXT,
    ADD COLUMN IF NOT EXISTS college_name TEXT,
    ADD COLUMN IF NOT EXISTS current_year_of_study INT,
    ADD COLUMN IF NOT EXISTS current_semester INT,
    ADD COLUMN IF NOT EXISTS degree_duration_years INT DEFAULT 4,
    ADD COLUMN IF NOT EXISTS academic_status TEXT DEFAULT 'pursuing', -- pursuing, completed, discontinued
    ADD COLUMN IF NOT EXISTS grading_system TEXT DEFAULT 'cgpa', -- cgpa, percentage, gpa
    ADD COLUMN IF NOT EXISTS grading_scale_max NUMERIC(5,2) DEFAULT 10.0,
    ADD COLUMN IF NOT EXISTS cgpa NUMERIC(4,2),
    ADD COLUMN IF NOT EXISTS percentage NUMERIC(5,2),
    ADD COLUMN IF NOT EXISTS year_wise_performance JSONB DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS semester_wise_performance JSONB DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS conversion_formula TEXT,
    ADD COLUMN IF NOT EXISTS conversion_source TEXT;

-- 2. EXTEND eligibility_rules WITH ACADEMIC-STAGE & GRADING REQUIREMENTS
ALTER TABLE public.eligibility_rules
    ADD COLUMN IF NOT EXISTS min_cgpa NUMERIC(4,2),
    ADD COLUMN IF NOT EXISTS grading_type TEXT DEFAULT 'percentage', -- percentage, cgpa, any
    ADD COLUMN IF NOT EXISTS accepted_grading_systems TEXT[] DEFAULT '{"percentage", "cgpa"}',
    ADD COLUMN IF NOT EXISTS accepts_final_year_students BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS accepts_appearing_candidates BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS min_academic_year_required INT, -- e.g. 3 for GATE / CDS pre-final year
    ADD COLUMN IF NOT EXISTS degree_completion_cutoff_date DATE,
    ADD COLUMN IF NOT EXISTS requires_conversion_certificate BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS institution_conversion_requirements TEXT;

-- 3. INSTITUTIONAL GRADING & VERIFIED CONVERSION REGISTRY TABLE
CREATE TABLE IF NOT EXISTS public.institution_grading_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_slug TEXT UNIQUE NOT NULL,
    institution_name TEXT NOT NULL,
    state TEXT,
    standard_grading_system TEXT NOT NULL DEFAULT 'cgpa',
    scale_max NUMERIC(5,2) NOT NULL DEFAULT 10.0,
    conversion_formula_expression TEXT NOT NULL, -- e.g. "percentage = (cgpa - 0.75) * 10"
    formula_description TEXT NOT NULL,
    official_source_reference TEXT NOT NULL,
    requires_official_certificate BOOLEAN NOT NULL DEFAULT FALSE,
    is_verified BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- Seed Verified Standard Indian University Conversion Formulas
INSERT INTO public.institution_grading_rules 
    (institution_slug, institution_name, state, standard_grading_system, scale_max, conversion_formula_expression, formula_description, official_source_reference)
VALUES
    ('aicte_norm', 'AICTE Standard Norm', 'All India', 'cgpa', 10.0, '(cgpa - 0.75) * 10', 'Percentage = (CGPA - 0.75) × 10', 'AICTE Approval Process Handbook & Gazette Notification'),
    ('delhi_university', 'University of Delhi (DU)', 'Delhi (NCT)', 'cgpa', 10.0, 'cgpa * 9.5', 'Percentage = CGPA × 9.5', 'DU Notification No. Exam.VII/2019/338'),
    ('cbse', 'Central Board of Secondary Education (CBSE)', 'All India', 'cgpa', 10.0, 'cgpa * 9.5', 'Percentage = CGPA × 9.5', 'CBSE Examination Bye-Laws Circular No. Coord/SO(EC-RO)/2017'),
    ('vtu', 'Visvesvaraya Technological University (VTU)', 'Karnataka', 'cgpa', 10.0, '(cgpa - 0.75) * 10', 'Percentage = (CGPA - 0.75) × 10', 'VTU Academic Regulations for B.E./B.Tech'),
    ('anna_university', 'Anna University', 'Tamil Nadu', 'cgpa', 10.0, 'cgpa * 10', 'Percentage = CGPA × 10', 'Anna University Regulations 2021 Clause 12.4'),
    ('mumbai_university', 'University of Mumbai', 'Maharashtra', 'cgpa', 10.0, '7.25 * cgpa + 11.0', 'Percentage = 7.25 × CGPA + 11', 'University of Mumbai UG CBCS Ordinance'),
    ('jntu_hyderabad', 'JNTU Hyderabad', 'Telangana', 'cgpa', 10.0, '(cgpa - 0.5) * 10', 'Percentage = (CGPA - 0.5) × 10', 'JNTUH Academic Regulations R18/R22'),
    ('ugc_linear', 'UGC 10-Point Linear Scale', 'All India', 'cgpa', 10.0, 'cgpa * 10', 'Percentage = CGPA × 10', 'UGC Guidelines on Adoption of Choice Based Credit System')
ON CONFLICT (institution_slug) DO UPDATE SET
    conversion_formula_expression = EXCLUDED.conversion_formula_expression,
    formula_description = EXCLUDED.formula_description,
    official_source_reference = EXCLUDED.official_source_reference,
    updated_at = TIMEZONE('utc', NOW());

-- 4. PERFORMANCE INDEXES
CREATE INDEX IF NOT EXISTS idx_candidate_education_academic_status 
    ON public.candidate_education(academic_status);

CREATE INDEX IF NOT EXISTS idx_candidate_education_grading_system 
    ON public.candidate_education(grading_system);

CREATE INDEX IF NOT EXISTS idx_eligibility_rules_final_year 
    ON public.eligibility_rules(accepts_final_year_students);

CREATE INDEX IF NOT EXISTS idx_eligibility_rules_min_academic_year 
    ON public.eligibility_rules(min_academic_year_required);

CREATE INDEX IF NOT EXISTS idx_institution_rules_slug 
    ON public.institution_grading_rules(institution_slug);

-- 5. ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.institution_grading_rules ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    DROP POLICY IF EXISTS "Allow public read access to institution grading rules" ON public.institution_grading_rules;
    CREATE POLICY "Allow public read access to institution grading rules" ON public.institution_grading_rules
        FOR SELECT USING (true);
END $$;

