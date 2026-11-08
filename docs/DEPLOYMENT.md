# Deployment & Operations Guide

This guide covers setting up your live Supabase cloud project, applying version-controlled SQL migrations, configuring environment secrets, and building the Flutter mobile application.

---

## 1. Supabase Project Setup

1. Sign in to [Supabase](https://supabase.com).
2. Click **New Project**:
   - Organization: Select or create your org.
   - Project Name: `rexam`
   - Database Password: Generate a secure password and save it in your password manager.
   - Region: Select **Central India (Mumbai)** (`ap-south-1`) for lowest latency to Indian candidates.
   - Pricing Plan: **Free tier** is 100% supported.

---

## 2. Applying Database Migrations

You can apply the migrations using either the **Supabase CLI** or the **Supabase Dashboard SQL Editor**.

### Method A: Supabase Dashboard (Fastest)
1. Open the **SQL Editor** in your Supabase Dashboard.
2. Open [supabase/migrations/20261108000001_initial_schema.sql](file:///home/amitsharma/Rexam/supabase/migrations/20261108000001_initial_schema.sql), copy all contents, paste into the SQL Editor, and click **Run**.
3. Open [supabase/migrations/20261108000002_row_level_security.sql](file:///home/amitsharma/Rexam/supabase/migrations/20261108000002_row_level_security.sql), copy all contents, paste, and click **Run**.
4. Open [supabase/seed.sql](file:///home/amitsharma/Rexam/supabase/seed.sql), copy all contents, paste, and click **Run**.

### Method B: Supabase CLI
```bash
# Link your local repository to your remote Supabase project
supabase link --project-ref <your-project-ref>

# Push all migrations to remote PostgreSQL database
supabase db push

# Apply seed data
supabase db reset
```

---

## 3. Configuring the Flutter Mobile App (`mobile/`)

1. Copy `.env.example` to `.env` in `mobile/`:
   ```bash
   cd mobile
   cp .env.example .env
   ```
2. Retrieve your project credentials from **Supabase Dashboard > Project Settings > API**:
   - `Project URL` -> `SUPABASE_URL`
   - `Project API keys > anon / public` -> `SUPABASE_PUBLISHABLE_KEY`
3. Edit `mobile/.env`:
   ```ini
   SUPABASE_URL=https://<your-project-ref>.supabase.co
   SUPABASE_PUBLISHABLE_KEY=<your-anon-publishable-key>
   SUPABASE_REDIRECT_URL=io.supabase.rexam://login-callback
   ```

### Building the Mobile Application:
```bash
cd mobile

# Verify static analysis
flutter analyze

# Run unit and widget tests
flutter test

# Build debug APK for testing
flutter build apk --debug

# Build release APK
flutter build apk --release

# Build Android App Bundle (for Google Play Console)
flutter build appbundle --release
```

---

## 4. Configuring GitHub Actions Ingestion

1. In your GitHub repository, go to **Settings** > **Secrets and variables** > **Actions**.
2. Add the two required secrets:
   - `SUPABASE_URL`: `https://<your-project-ref>.supabase.co`
   - `SUPABASE_SERVICE_ROLE_KEY`: `ey...` (from Supabase Dashboard > Project Settings > API > `service_role secret`)
3. Optional secrets for AI parsing:
   - `CLOUDFLARE_ACCOUNT_ID`
   - `CLOUDFLARE_API_TOKEN`
4. Trigger a test scan via **Actions > Manual Opportunity Ingestion Scan > Run workflow**.
5. Check your Supabase database table `examinations` to see the ingested opportunities!

