-- REXAM: Supabase PostgreSQL Row Level Security (RLS) & Auth Triggers
-- Migration: 02_row_level_security.sql

-- Enable RLS across all tables
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

-- 1. PROFILES POLICIES
CREATE POLICY "Candidates can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Candidates can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Candidates can insert own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- 2. CANDIDATE EDUCATION POLICIES
CREATE POLICY "Candidates can manage own education"
    ON public.candidate_education FOR ALL
    USING (auth.uid() = candidate_id)
    WITH CHECK (auth.uid() = candidate_id);

-- 3. CANDIDATE PREFERENCES POLICIES
CREATE POLICY "Candidates can manage own preferences"
    ON public.candidate_preferences FOR ALL
    USING (auth.uid() = candidate_id)
    WITH CHECK (auth.uid() = candidate_id);

-- 4. ORGANISATIONS POLICIES (Public read, service-role write)
CREATE POLICY "Anyone can view organisations"
    ON public.organisations FOR SELECT
    USING (true);

-- 5. SOURCES POLICIES (Service role only for configuration)
CREATE POLICY "Authenticated users can view active sources"
    ON public.sources FOR SELECT
    USING (auth.role() = 'authenticated' AND is_active = true);

-- 6. EXAMINATIONS POLICIES (Public read for published records)
CREATE POLICY "Anyone can view published examinations"
    ON public.examinations FOR SELECT
    USING (status = 'published');

-- 7. EXAMINATION DATES POLICIES
CREATE POLICY "Anyone can view dates for published examinations"
    ON public.examination_dates FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.examinations e
            WHERE e.id = examination_dates.examination_id AND e.status = 'published'
        )
    );

-- 8. ELIGIBILITY RULES POLICIES
CREATE POLICY "Anyone can view eligibility rules for published examinations"
    ON public.eligibility_rules FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.examinations e
            WHERE e.id = eligibility_rules.examination_id AND e.status = 'published'
        )
    );

-- 9. EXAMINATION DOCUMENTS POLICIES
CREATE POLICY "Anyone can view documents for published examinations"
    ON public.examination_documents FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.examinations e
            WHERE e.id = examination_documents.examination_id AND e.status = 'published'
        )
    );

-- 10. EXAMINATION UPDATES POLICIES
CREATE POLICY "Anyone can view updates for published examinations"
    ON public.examination_updates FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.examinations e
            WHERE e.id = examination_updates.examination_id AND e.status = 'published'
        )
    );

-- 11. SAVED EXAMINATIONS POLICIES
CREATE POLICY "Candidates can manage own saved examinations"
    ON public.saved_examinations FOR ALL
    USING (auth.uid() = candidate_id)
    WITH CHECK (auth.uid() = candidate_id);

-- 12. CANDIDATE FOLLOWED EXAMINATIONS POLICIES
CREATE POLICY "Candidates can manage own follows"
    ON public.candidate_followed_examinations FOR ALL
    USING (auth.uid() = candidate_id)
    WITH CHECK (auth.uid() = candidate_id);

-- 13. CANDIDATE APPLICATIONS POLICIES
CREATE POLICY "Candidates can manage own application tracking"
    ON public.candidate_applications FOR ALL
    USING (auth.uid() = candidate_id)
    WITH CHECK (auth.uid() = candidate_id);

-- 14. NOTIFICATIONS POLICIES
CREATE POLICY "Candidates can view own notifications"
    ON public.notifications FOR SELECT
    USING (auth.uid() = candidate_id);

CREATE POLICY "Candidates can update own notification read state"
    ON public.notifications FOR UPDATE
    USING (auth.uid() = candidate_id)
    WITH CHECK (auth.uid() = candidate_id);

CREATE POLICY "Candidates can delete own notifications"
    ON public.notifications FOR DELETE
    USING (auth.uid() = candidate_id);

-- 15. DEVICE TOKENS POLICIES
CREATE POLICY "Candidates can manage own device tokens"
    ON public.device_tokens FOR ALL
    USING (auth.uid() = candidate_id)
    WITH CHECK (auth.uid() = candidate_id);

-- 16. CANDIDATE MATCHES POLICIES
CREATE POLICY "Candidates can view own pre-evaluated matches"
    ON public.candidate_matches FOR SELECT
    USING (auth.uid() = candidate_id);

-- 17. AUTOMATIC PROFILE PROVISIONING TRIGGER ON AUTH SIGN-UP
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

-- Drop trigger if exists to ensure idempotency
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

