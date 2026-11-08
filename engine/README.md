# Rexam Python Data Engine

Automated crawling, PDF parsing, Cloudflare Workers AI document extraction, and deterministic candidate eligibility matching engine for Indian government examinations and opportunities.

## Key Architecture

- **Zero-VPS Design**: Runs on scheduled cron via GitHub Actions or on-demand locally, writing directly to Supabase PostgreSQL using service-role credentials.
- **Ethical Crawling**: Custom User-Agent, respectful rate-limiting (2s default delays), official source provenance verification, and SHA-256 PDF deduplication.
- **Configurable AI Provider**: Optional Cloudflare Workers AI integration for parsing complex unformatted PDF notices. The system operates 100% reliably with deterministic regex fallbacks when AI is offline or unconfigured.
- **Deterministic Eligibility Logic**: Age, category relaxations (OBC-NCL, SC/ST, PwBD, Ex-Serviceman), stream compatibility, and active backlog checks are evaluated deterministically in Python without relying on non-deterministic LLMs.

## Directory Structure

```
engine/
├── app/
│   ├── config/             # Pydantic Settings & environment loader
│   ├── database/           # Supabase Python client & data access layer
│   ├── discovery/          # Source registry and URL normalizer
│   ├── crawlers/           # Dedicated crawler adapters (UPSC, SSC, ISRO, DRDO)
│   ├── downloading/        # Rate-limited HTTPX async file downloader
│   ├── extraction/         # PyMuPDF PDF extractor & BeautifulSoup HTML parser
│   ├── ai/                 # Cloudflare Workers AI client & Pydantic schema validation
│   ├── verification/       # Official provenance, date coherence & sanity checks
│   ├── deduplication/      # SHA-256 document hashing
│   ├── matching/           # Deterministic candidate eligibility evaluation
│   ├── notifications/      # Milestone & deadline reminder generator
│   └── jobs/               # Entrypoints for scheduled and manual runs
├── tests/                  # Pytest unit and integration test suite
├── requirements.txt        # Python 3.12+ dependencies
├── .env.example            # Sample environment variables
└── README.md
```

## Running Locally

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Copy environment variables:
   ```bash
   cp .env.example .env
   # Edit .env with your Supabase URL & Service Role key
   ```

3. Run discovery pipeline:
   ```bash
   python -m engine.app.jobs.discovery_job
   ```

4. Run deadline reminder scanner:
   ```bash
   python -m engine.app.jobs.reminder_job
   ```

5. Run manual scan for a specific recruiting commission:
   ```bash
   python -m engine.app.jobs.manual_scan_job --source isro
   ```

6. Run test suite:
   ```bash
   pytest
   ```

