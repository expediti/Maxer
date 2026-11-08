# REXAM — Indian Examination & Opportunity Discovery Platform

**Rexam** is a career intelligence and opportunity discovery platform tailored for Indian public service commissions (UPSC, SSC, State PSCs), PSU recruitment (ISRO, DRDO, IOCL, BARC), banking recruitment (IBPS, SBI), university entrance exams, and premier research fellowships (PMRF, CSIR-JRF).

The platform deterministically evaluates candidate eligibility conditions (age cutoffs, statutory category relaxations for OBC-NCL, SC, ST, PwBD, Ex-Servicemen, required degree streams, aggregate percentages, and GATE/NET scores) to ensure candidates never miss a verified opportunity or waste non-refundable application fees.

---

## 1. System Architecture

```
rexam/
│
├── mobile/                     # Production Flutter Mobile Application (Material 3)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app/                # App initialization
│   │   ├── core/               # Theme, constants, typography, GoRouter, Supabase client
│   │   ├── models/             # Examination, CandidateProfile, ApplicationTracker, Reports
│   │   ├── services/           # SupabaseAuthService (Google OAuth PKCE), FCM Notifications
│   │   ├── repositories/       # Direct Supabase PostgreSQL repositories with RLS
│   │   ├── features/           # Discover, Explorer, Details, Saved, Tracker, Alerts, Profile
│   │   └── shared/             # Reusable UI widgets
│   ├── android/                # Android config with deep link intent filter
│   ├── test/                   # Widget tests and deterministic eligibility tests
│   ├── pubspec.yaml
│   └── .env.example
│
├── engine/                     # Python 3.12+ Ingestion, AI Extraction & Matching Data Engine
│   ├── app/
│   │   ├── config/             # Pydantic Settings
│   │   ├── database/           # Supabase Python Service-Role client
│   │   ├── discovery/          # Official source registry & URL normalizer
│   │   ├── crawlers/           # Dedicated crawler adapters (UPSC, SSC, ISRO, DRDO, Generic)
│   │   ├── downloading/        # Rate-limited HTTPX async file downloader
│   │   ├── extraction/         # PyMuPDF PDF extractor & BeautifulSoup HTML parser
│   │   ├── ai/                 # Cloudflare Workers AI client & Pydantic schema validation
│   │   ├── verification/       # Provenance, date validation & sanity checks
│   │   ├── deduplication/      # SHA-256 document hashing
│   │   ├── matching/           # Deterministic Python candidate eligibility evaluation
│   │   ├── notifications/      # Milestone & deadline reminder generator
│   │   └── jobs/               # Discovery pipeline, reminder check, manual scan
│   ├── tests/                  # Pytest unit & integration test suite (14 passing tests)
│   ├── requirements.txt
│   ├── .env.example
│   └── README.md
│
├── supabase/                   # Database Architecture & Infrastructure-as-Code
│   ├── migrations/             # 18 PostgreSQL tables + complete Row Level Security (RLS)
│   ├── seed.sql                # Demonstration opportunities (UPSC, ISRO, DRDO, SBI, PMRF)
│   └── config.toml             # Local development configuration & OAuth settings
│
├── .github/
│   └── workflows/
│       ├── discovery.yml       # Scheduled crawler execution (06:30 IST daily)
│       ├── reminder-check.yml  # Scheduled deadline alerts (08:30 & 17:00 IST daily)
│       └── manual-scan.yml     # On-demand manual scan via workflow dispatch
│
├── docs/                       # Comprehensive System Documentation
│   ├── ARCHITECTURE.md         # Zero-VPS design, direct-to-database security & data flow
│   ├── DATABASE.md             # Complete data dictionary for all 18 tables & RLS policies
│   ├── GOOGLE_AUTH_SETUP.md    # Step-by-step Google Cloud OAuth 2.0 & deep link configuration
│   ├── GITHUB_SETUP.md         # Repository secrets, scheduled jobs & manual trigger guide
│   ├── CLOUDFLARE_AI_SETUP.md  # Cloudflare Workers AI token, model selection & fallback
│   └── DEPLOYMENT.md           # Production deployment & migration guide
│
├── LICENSE                     # Apache 2.0 Open Source License
└── README.md
```

---

## 2. Key Technical Highlights

1. **Zero-VPS Operational Model**: No permanently running server instances. All heavy crawling and parsing runs serverlessly on GitHub Actions runners, writing directly to Supabase with service-role security.
2. **PostgreSQL Row Level Security (RLS)**: Candidate data is isolated at the database kernel level (`auth.uid() = candidate_id`). Published opportunities are safely queryable by mobile clients using client-safe anon keys.
3. **Deterministic Eligibility Engine**: Strict Indian recruitment criteria (OBC-NCL +3 years, SC/ST +5 years, PwBD +10 years, stream matching, and backlog checks) are evaluated deterministically in compiled Dart and Python without non-deterministic AI hallucinations.
4. **Cloudflare Workers AI Document Extraction**: Unstructured PDF notifications are parsed into structured JSON via Cloudflare Workers AI (`@cf/meta/llama-3.1-8b-instruct`), with 100% reliable regex heuristic fallback if AI is offline or unconfigured.
5. **Authentic Offline Graceful Fallback**: Both Flutter and Python test fixtures work reliably out-of-the-box with demonstration data when remote credentials are not yet configured.

---

## 3. Visual Design System

- **Brand:** REXAM
- **Style:** Premium minimalism, editorial density without clutter, restrained green highlights.
- **Palette:**
  - Main Background: `#090D0B`
  - Secondary Background: `#111713`
  - Surface: `#171F19`
  - Primary Green: `#65D68A`
  - Secondary Green: `#328653`
  - Main Text: `#F2F5F2`
  - Muted Text: `#89938C`
  - Border: `#27332B`
  - Warning: `#E5B65B`
  - Error: `#E16B6B`
- **Typography:** Inter sans-serif with high contrast and restrained weights.
- **Grid:** Strict 4px increments; corner radii limited to 8–12px. No emojis, glassmorphism, or neon effects.

---

## 4. Quick Start

### Mobile Client (Flutter)
```bash
cd mobile
flutter pub get
flutter analyze  # 0 errors
flutter test     # All tests pass
flutter run -d chrome  # or -d android
```

### Python Data Engine
```bash
cd engine
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pytest           # 14 tests pass
python -m engine.app.jobs.manual_scan_job --source isro
```

### Supabase Migrations
See [docs/DEPLOYMENT.md](file:///home/amitsharma/Rexam/docs/DEPLOYMENT.md) for applying migrations in `supabase/migrations/` and loading `supabase/seed.sql`.

---

## 5. Documentation Directory

- [Architecture Overview](file:///home/amitsharma/Rexam/docs/ARCHITECTURE.md)
- [Database Schema & RLS Policies](file:///home/amitsharma/Rexam/docs/DATABASE.md)
- [Google OAuth 2.0 & Deep Linking Setup](file:///home/amitsharma/Rexam/docs/GOOGLE_AUTH_SETUP.md)
- [GitHub Actions Workflows & Secrets](file:///home/amitsharma/Rexam/docs/GITHUB_SETUP.md)
- [Cloudflare Workers AI Configuration](file:///home/amitsharma/Rexam/docs/CLOUDFLARE_AI_SETUP.md)
- [Deployment & Operations Guide](file:///home/amitsharma/Rexam/docs/DEPLOYMENT.md)
