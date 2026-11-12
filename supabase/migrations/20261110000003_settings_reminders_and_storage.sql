-- ============================================================================
-- REXAM MIGRATION: 20261110000003_settings_reminders_and_storage.sql
-- PURPOSE: Frontend functional completion, theme preference synchronization,
--          user-controlled reminders, device notification token registration,
--          and Supabase Storage bucket policies for candidate avatars.
-- ============================================================================

-- 1. CANDIDATE PREFERENCES: Theme Mode and Notification Toggles
ALTER TABLE public.candidate_preferences
    ADD COLUMN IF NOT EXISTS theme_mode VARCHAR(20) DEFAULT 'system',
    ADD COLUMN IF NOT EXISTS push_notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS deadline_reminders_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS corrigenda_alerts_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS result_alerts_enabled BOOLEAN NOT NULL DEFAULT TRUE;

-- Ensure RLS on candidate_preferences
ALTER TABLE public.candidate_preferences ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'candidate_preferences' AND policyname = 'Users can manage own preferences'
    ) THEN
        CREATE POLICY "Users can manage own preferences"
            ON public.candidate_preferences FOR ALL
            USING (auth.uid() = candidate_id)
            WITH CHECK (auth.uid() = candidate_id);
    END IF;
END $$;

-- 2. CANDIDATE FOLLOWED EXAMINATIONS: User-Controlled Reminders
ALTER TABLE public.candidate_followed_examinations
    ADD COLUMN IF NOT EXISTS reminders_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS scheduled_reminder_dates TIMESTAMPTZ[] DEFAULT '{}';

ALTER TABLE public.candidate_followed_examinations ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    DROP POLICY IF EXISTS "Candidates can manage own followed examinations" ON public.candidate_followed_examinations;
    CREATE POLICY "Candidates can manage own followed examinations"
        ON public.candidate_followed_examinations FOR ALL
        USING (auth.uid() = candidate_id)
        WITH CHECK (auth.uid() = candidate_id);
END $$;

-- 3. CANDIDATE PROFILES: Avatar Support
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- 4. DEVICE TOKENS TABLE (For FCM and background dispatches)
CREATE TABLE IF NOT EXISTS public.device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    candidate_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL UNIQUE,
    platform TEXT NOT NULL DEFAULT 'android',
    last_active_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_candidate ON public.device_tokens(candidate_id);

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    DROP POLICY IF EXISTS "Candidates can manage own device tokens" ON public.device_tokens;
    CREATE POLICY "Candidates can manage own device tokens"
        ON public.device_tokens FOR ALL
        USING (auth.uid() = candidate_id)
        WITH CHECK (auth.uid() = candidate_id);
END $$;

-- 5. STORAGE BUCKET: profile-avatars
-- Insert the public profile-avatars bucket if it does not already exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'profile-avatars',
    'profile-avatars',
    true,
    5242880, -- 5 MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg'];

-- 6. STORAGE POLICIES: Allow authenticated users to upload and view avatars
DO $$
BEGIN
    -- Public read policy for avatars
    DROP POLICY IF EXISTS "Public can view candidate profile avatars" ON storage.objects;
    CREATE POLICY "Public can view candidate profile avatars"
        ON storage.objects FOR SELECT
        USING (bucket_id = 'profile-avatars');

    -- Authenticated upload policy: Scoped to user's folder
    DROP POLICY IF EXISTS "Authenticated candidates can upload profile avatar" ON storage.objects;
    CREATE POLICY "Authenticated candidates can upload profile avatar"
        ON storage.objects FOR INSERT
        TO authenticated
        WITH CHECK (
            bucket_id = 'profile-avatars' AND
            (storage.foldername(name))[1] = auth.uid()::text
        );

    -- Authenticated update policy
    DROP POLICY IF EXISTS "Authenticated candidates can update own profile avatar" ON storage.objects;
    CREATE POLICY "Authenticated candidates can update own profile avatar"
        ON storage.objects FOR UPDATE
        TO authenticated
        USING (
            bucket_id = 'profile-avatars' AND
            (storage.foldername(name))[1] = auth.uid()::text
        )
        WITH CHECK (
            bucket_id = 'profile-avatars' AND
            (storage.foldername(name))[1] = auth.uid()::text
        );

    -- Authenticated delete policy
    DROP POLICY IF EXISTS "Authenticated candidates can delete own profile avatar" ON storage.objects;
    CREATE POLICY "Authenticated candidates can delete own profile avatar"
        ON storage.objects FOR DELETE
        TO authenticated
        USING (
            bucket_id = 'profile-avatars' AND
            (storage.foldername(name))[1] = auth.uid()::text
        );
END $$;

