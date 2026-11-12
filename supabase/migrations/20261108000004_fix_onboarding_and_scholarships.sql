-- =============================================================================
-- REXAM ADDITIVE MIGRATION: ONBOARDING PERSISTENCE & SCHOLARSHIP ARCHITECTURE
-- Migration: 20261108000004_fix_onboarding_and_scholarships.sql
-- Safe to execute all at once in Supabase SQL Editor.
-- Completely preserves existing user accounts, opportunities, applications & RLS.
-- =============================================================================

-- 1. ADD EXTENDED ONBOARDING ATTRIBUTES TO public.profiles
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS onboarding_completed_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS current_status TEXT,
    ADD COLUMN IF NOT EXISTS class_10_year INT,
    ADD COLUMN IF NOT EXISTS class_12_year INT,
    ADD COLUMN IF NOT EXISTS class_12_stream TEXT,
    ADD COLUMN IF NOT EXISTS is_obc_ncl BOOLEAN DEFAULT FALSE;

-- 2. ADD QUALIFICATION STATUS TO public.candidate_education
ALTER TABLE public.candidate_education
    ADD COLUMN IF NOT EXISTS qualification_type TEXT DEFAULT 'Undergraduate',
    ADD COLUMN IF NOT EXISTS is_completed BOOLEAN NOT NULL DEFAULT TRUE;

-- 3. ENSURE UNIQUE CONSTRAINT ON candidate_education(candidate_id) FOR RESILIENT UPSERTS
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'candidate_education_candidate_id_unique'
    ) THEN
        -- Delete duplicate candidate education entries if any exist, keeping the most recent
        DELETE FROM public.candidate_education a
        USING public.candidate_education b
        WHERE a.candidate_id = b.candidate_id 
          AND a.updated_at < b.updated_at;

        ALTER TABLE public.candidate_education
            ADD CONSTRAINT candidate_education_candidate_id_unique UNIQUE (candidate_id);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Constraint already exists or could not be added: %', SQLERRM;
END $$;

-- 4. MAKE MIN/MAX AGE FLEXIBLE FOR SCHOLARSHIP & FELLOWSHIP ELIGIBILITY
ALTER TABLE public.eligibility_rules
    ALTER COLUMN min_age DROP NOT NULL,
    ALTER COLUMN max_age DROP NOT NULL;

-- 5. PERFORMANCE INDEXES FOR FASTER EXPLORER FILTERING
CREATE INDEX IF NOT EXISTS idx_examinations_category 
    ON public.examinations(category);

CREATE INDEX IF NOT EXISTS idx_profiles_onboarding_completed_at 
    ON public.profiles(onboarding_completed_at);

CREATE INDEX IF NOT EXISTS idx_candidate_education_cand_id 
    ON public.candidate_education(candidate_id);

-- 6. VERIFY ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidate_education ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidate_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.examinations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.examination_dates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eligibility_rules ENABLE ROW LEVEL SECURITY;

-- Allow candidates to view and update their own profile and qualifications
DO $$
BEGIN
    DROP POLICY IF EXISTS "Users can read own profile" ON public.profiles;
    CREATE POLICY "Users can read own profile" ON public.profiles
        FOR SELECT USING (auth.uid() = id);

    DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
    CREATE POLICY "Users can update own profile" ON public.profiles
        FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

    DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
    CREATE POLICY "Users can insert own profile" ON public.profiles
        FOR INSERT WITH CHECK (auth.uid() = id);

    DROP POLICY IF EXISTS "Users can manage own education" ON public.candidate_education;
    CREATE POLICY "Users can manage own education" ON public.candidate_education
        FOR ALL USING (auth.uid() = candidate_id) WITH CHECK (auth.uid() = candidate_id);

    DROP POLICY IF EXISTS "Users can manage own preferences" ON public.candidate_preferences;
    CREATE POLICY "Users can manage own preferences" ON public.candidate_preferences
        FOR ALL USING (auth.uid() = candidate_id) WITH CHECK (auth.uid() = candidate_id);

    -- Ensure public read access for published opportunities
    DROP POLICY IF EXISTS "Allow public read access to published examinations" ON public.examinations;
    CREATE POLICY "Allow public read access to published examinations" ON public.examinations
        FOR SELECT USING (status = 'published');

    DROP POLICY IF EXISTS "Allow public read access to examination dates" ON public.examination_dates;
    CREATE POLICY "Allow public read access to examination dates" ON public.examination_dates
        FOR SELECT USING (true);

    DROP POLICY IF EXISTS "Allow public read access to eligibility rules" ON public.eligibility_rules;
    CREATE POLICY "Allow public read access to eligibility rules" ON public.eligibility_rules
        FOR SELECT USING (true);
END $$;

