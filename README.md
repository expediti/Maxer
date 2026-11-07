# REXAM — Indian Examination & Opportunity Discovery Platform

**Rexam** is a career intelligence and opportunity discovery platform tailored for Indian examinations, central/state recruitment, PSU executive roles, university admissions, and premier research fellowships.

The platform deterministically evaluates candidate eligibility conditions (age cutoffs, statutory category relaxations, educational streams, aggregate percentages, and GATE/NET scores) to ensure candidates never miss a verified opportunity or waste non-refundable application fees.

---

## Architecture Overview

```
Rexam/
├── frontend/               # Production Flutter Mobile Application
│   ├── lib/
│   │   ├── core/           # Brand theme, constants, typography, router, utilities
│   │   └── features/
│   │       ├── auth/       # Splash, Onboarding, Authentication (Email, Google, Guest)
│   │       ├── profile/    # Multi-step Profile Setup Wizard & Management
│   │       ├── opportunities/ # Discover Dashboard, Explorer, 24-point Detail View
│   │       ├── saved/      # Bookmarked opportunities & deadline sorting
│   │       ├── applications/ # 10-stage application tracker with personal notes
│   │       ├── alerts/     # Corrigenda, deadlines, admit cards, and exam alerts
│   │       ├── eligibility/# Deterministic criterion-by-criterion assessment report
│   │       ├── settings/   # Appearance, language, notifications, privacy, legal
│   │       └── navigation/ # Custom restrained 5-tab bottom navigation shell
│   └── test/               # Flutter widget and unit test suites
│
└── backend/                # FastAPI Asynchronous Service Foundation
    ├── app/
    │   ├── api/routes/     # Opportunity, Candidate, Application, Notification, Admin API
    │   ├── core/           # Configuration (Pydantic Settings), Security, Logging
    │   ├── models/         # SQLAlchemy 2.0 ORM base & mixins
    │   ├── schemas/        # Pydantic v2 schemas for REST contracts
    │   ├── services/       # Discovery, Crawling, Extraction, Verification, Matching
    │   └── main.py         # FastAPI application entrypoint & OpenAPI doc generator
    ├── tests/              # Contract tests with pytest & TestClient
    ├── Dockerfile          # Free-tier & production container deployment
    └── requirements.txt    # Python dependencies
```

---

## Visual Design System

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
- **Grid:** Strict 4px increments; corner radii limited to 8–12px.

---

## Implemented Screens (Screens 1 to 13)

1. **Splash Screen (`/splash`):** REXAM wordmark, minimal green brand symbol, session check.
2. **Onboarding (`/onboarding`):** 3 concise editorial slides with step indicators and skip option.
3. **Authentication (`/auth`):** Email signup, login, password reset modal, Google sign-in trigger, and Guest browsing mode.
4. **Profile Setup Wizard (`/profile/wizard`):** 5-step wizard covering Personal, Reservation Category, Education, GATE/NET, and Career Preferences with live completion tracking.
5. **Discover Dashboard (`/discover`):** Real-time search, profile greeting, completion badge, Recommended feed, Closing Soon section, and All Opportunities preview.
6. **Opportunity Explorer (`/explorer`):** Multi-factor filtering (Sector, Category, Closing Soon, State, Age, Max Fee) and sorting (Relevance, Deadline, Latest, Fee).
7. **Opportunity Details (`/opportunities/:id`):** 24-point structured specification (vacancies, age relaxations, educational eligibility, fees, important dates roadmap, selection procedure, official PDF and portal links).
8. **My Saved Opportunities (`/saved`):** Bookmarked opportunities with in-list search, deadline sorting, and one-tap bookmark removal.
9. **My Applications (`/applications`):** 10-stage status tracker (Interested, Preparing Documents, Applied, Admit Card, Selected, etc.) with custom roll numbers and personal notes.
10. **Notifications & Alerts (`/alerts`):** Corrigenda, deadline extensions, admit card releases, and exam announcements with category filter chips and mark-all-read.
11. **Eligibility Report (`/eligibility/:id`):** Rule-by-rule evaluation for Age cutoff, Qualification degree, Stream, and Reservation relaxations with statutory evidence citations.
12. **Profile Management (`/profile`):** Comprehensive view of candidate attributes, completion bar, edit wizard shortcut, and RLS privacy controls.
13. **Settings (`/settings`):** Theme, language selector, push notification toggles, Privacy Policy, Terms of Service, Support intake, and secure sign-out.

---

## Running the Application

### 1. Frontend (Flutter)
```bash
cd frontend
flutter pub get
flutter test
flutter run -d chrome  # or -d linux / android
```

### 2. Backend (FastAPI)
```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pytest tests/test_api_contracts.py -v
uvicorn app.main:app --reload --port 8000
```
Interactive OpenAPI documentation will be accessible at: `http://localhost:8000/docs`.
