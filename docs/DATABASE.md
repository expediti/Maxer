# Rexam — Database Architecture & Data Dictionary

## 1. Overview

Rexam uses **Supabase PostgreSQL** as its unified data platform. The database schema is designed for high reliability, strict multi-tenant candidate data isolation via **Row Level Security (RLS)**, and comprehensive auditing of web ingestion activities.

All migrations are located in `supabase/migrations/`:
- `20261108000001_initial_schema.sql`: Table definitions, indexes, constraints, and audit columns.
- `20261108000002_row_level_security.sql`: RLS policies and `handle_new_user()` trigger for automated user onboarding.

---

## 2. Table Catalog (18 Tables)

### Group A: Identity & Candidate Profile
| Table Name | Primary Key | Description |
| :--- | :--- | :--- |
| `profiles` | `id` (UUID references `auth.users`) | Core candidate demographic info: name, DOB, social category (General, OBC-NCL, SC, ST, EWS), PwBD status, Ex-Serviceman status. |
| `candidate_education` | `id` (UUID) | Academic qualification details: degree, stream, institution, graduation year, CGPA/percentage, backlog status, GATE score, NET/JRF. |
| `candidate_preferences` | `id` (UUID) | Career preferences: target categories, preferred states, fee budget, relocation willingness, career interest tags. |

### Group B: Organizations & Provenance
| Table Name | Primary Key | Description |
| :--- | :--- | :--- |
| `organisations` | `id` (UUID) | Public recruiting bodies (e.g. UPSC, SSC, ISRO, DRDO, IBPS, IITs, State PSCs) with slug, website URL, and category type. |
| `sources` | `id` (UUID) | Registered crawling endpoints (portal notice URLs, RSS feeds, API endpoints) with crawler adapter mapping. |

### Group C: Opportunities & Eligibility
| Table Name | Primary Key | Description |
| :--- | :--- | :--- |
| `examinations` | `id` (UUID) | Core examination records: title, slug, category, status (`published`, `under_review`, `expired`), vacancies, salary scale, overview. |
| `examination_dates` | `id` (UUID) | Crucial timeline milestones: notification date, application opening date, application closing date, fee deadline, correction window, prelims date, mains date, result date. |
| `eligibility_rules` | `id` (UUID) | Deterministic statutory eligibility criteria: min age, max age, category age relaxations (JSONB), eligible degree streams (text[]), min percentage, fee exemptions. |
| `examination_documents` | `id` (UUID) | PDF notices, syllabi, and official corrigenda linked to an examination. |
| `examination_updates` | `id` (UUID) | Chronological log of post-notification announcements (admit card releases, date revisions, result declarations). |

### Group D: Candidate Interactions & Tracking
| Table Name | Primary Key | Description |
| :--- | :--- | :--- |
| `saved_examinations` | `id` (UUID) | Bookmarked examinations saved by candidates for quick access. |
| `candidate_followed_examinations`| `id` (UUID) | Opportunities explicitly followed for push/in-app milestone notifications. |
| `candidate_applications` | `id` (UUID) | Personal application tracker: stage (`interested`, `applied`, `admit_card_released`, etc.), application number, notes, checklist (JSONB). |
| `notifications` | `id` (UUID) | In-app alerts: deadline warnings, corrigenda, exam date announcements. |
| `device_tokens` | `id` (UUID) | FCM push notification tokens registered by mobile devices. |
| `candidate_matches` | `id` (UUID) | Cached deterministic eligibility matching scores and breakdown reasons. |

### Group E: Data Engine Ingestion & Audit
| Table Name | Primary Key | Description |
| :--- | :--- | :--- |
| `crawler_runs` | `id` (UUID) | Execution audit logs for each crawler run: status, examinations found, examinations updated, error messages. |
| `processed_documents` | `id` (UUID) | Cryptographic SHA-256 hashes of downloaded PDFs to guarantee deduplication and prevent duplicate AI processing. |

---

## 3. Row Level Security (RLS) Policies

All 18 tables have `ALTER TABLE <table> ENABLE ROW LEVEL SECURITY;` enforced.

### Key RLS Principles:
1. **Candidate Isolation**:
   - `profiles`: `auth.uid() = id` (Candidates can select and update only their own profile).
   - `candidate_education`, `candidate_preferences`, `candidate_applications`, `saved_examinations`, `candidate_followed_examinations`, `notifications`, `device_tokens`:
     `auth.uid() = candidate_id` (Candidates have full CRUD permissions over their own records only).
2. **Public / Candidate Read for Opportunities**:
   - `examinations`: `status = 'published'` is readable by all authenticated candidates (`TO authenticated USING (status = 'published')`) and anonymous candidates (`TO anon USING (status = 'published')`).
   - `organisations`, `examination_dates`, `eligibility_rules`, `examination_documents`, `examination_updates`: Readable if the parent examination is published.
3. **Data Engine Administration**:
   - Service Role Key bypasses RLS directly at the PostgreSQL layer, allowing GitHub Actions crawlers to insert and update examinations, dates, and crawler runs without exposing write permissions to the mobile client.

---

## 4. Automatic User Provisioning Trigger

When a candidate registers via Email or Google OAuth, a PostgreSQL trigger automatically provisions their profile and preferences:

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    NOW(),
    NOW()
  ) ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.candidate_preferences (candidate_id, preferred_categories, created_at, updated_at)
  VALUES (
    NEW.id,
    ARRAY['govt_recruitment', 'psu'],
    NOW(),
    NOW()
  ) ON CONFLICT (candidate_id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

