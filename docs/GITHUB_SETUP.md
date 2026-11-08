# GitHub Setup & Automation Guide

Rexam uses **GitHub Actions** as its serverless scheduling harness, eliminating the need to maintain or pay for permanently running virtual machines.

---

## 1. Repository Secrets Configuration

To enable automated data ingestion and candidate reminder dispatch, add the following secrets to your GitHub repository:

1. In your GitHub repository, navigate to **Settings** > **Secrets and variables** > **Actions**.
2. Click **New repository secret** and define the following:

| Secret Name | Required? | Source / Description |
| :--- | :--- | :--- |
| `SUPABASE_URL` | **Yes** | Your Supabase project URL (e.g., `https://xyzproject.supabase.co`). |
| `SUPABASE_SERVICE_ROLE_KEY` | **Yes** | Supabase Service Role Secret (found in Project Settings > API). **Never commit to source code or pass to Flutter.** |
| `CLOUDFLARE_ACCOUNT_ID` | Optional | Your Cloudflare Account ID from Cloudflare Dashboard URL or Workers AI page. |
| `CLOUDFLARE_API_TOKEN` | Optional | API token with `Workers AI: Read` permission. |
| `CLOUDFLARE_AI_MODEL` | Optional | Model identifier (defaults to `@cf/meta/llama-3.1-8b-instruct`). |

---

## 2. Configured Workflows

The repository contains three GitHub Actions workflows in `.github/workflows/`:

### A. Scheduled Discovery Pipeline (`discovery.yml`)
- **Schedule**: `0 1 * * *` (01:00 UTC = **06:30 AM IST** every morning).
- **Function**: Crawls UPSC, SSC, ISRO, DRDO, IBPS, and PMRF portals.
- **Deduplication**: Computes SHA-256 hashes of notices. If a notice PDF is already recorded in the `processed_documents` table, it skips redownload and AI extraction.
- **Verification**: Validates dates and sanity bounds before setting status to `published` or `under_review`.
- **Artifacts**: Uploads failure diagnostics and download logs if any step fails.

### B. Scheduled Milestone Reminders (`reminder-check.yml`)
- **Schedule**:
  - `0 3 * * *` (03:00 UTC = **08:30 AM IST** daily).
  - `30 11 * * *` (11:30 UTC = **05:00 PM IST** daily for final closing hours).
- **Function**: Scans candidate followed/saved examinations and generates in-app notifications for 7-day, 3-day, and 24-hour application closing windows.

### C. Manual Opportunity Scan (`manual-scan.yml`)
- **Trigger**: Manual dispatch (`workflow_dispatch`) from the GitHub Actions tab.
- **Inputs**:
  - `source`: Dropdown selection (`upsc`, `ssc`, `isro`, `drdo`, `ibps`, `pmrf`).
  - `url`: Optional direct URL to crawl a specific newly released notice PDF or webpage.

---

## 3. Running Workflows Manually

1. Go to your repository on GitHub.
2. Click on the **Actions** tab.
3. Select **Manual Opportunity Ingestion Scan** in the left sidebar.
4. Click **Run workflow**, choose the recruiting body (e.g. `isro`), and click the green **Run workflow** button.
5. Watch live logs as notices are crawled, extracted, and upserted into your Supabase database.

