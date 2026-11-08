# Cloudflare Workers AI Integration Guide

Rexam integrates with **Cloudflare Workers AI** REST API as an optional, high-throughput document extraction provider.

---

## 1. Why Cloudflare Workers AI?

1. **Free Tier Generosity**: Provides generous daily neuronic quotas on models like Llama 3.1 8B Instruct without requiring GPU provisioning.
2. **Serverless REST Interface**: Accessible directly via simple HTTPS JSON calls without SDK bloat or complex daemon setups.
3. **No Model Lock-In**: Model name is completely parameterized via `CLOUDFLARE_AI_MODEL`. You can switch models anytime by changing an environment variable.

---

## 2. Generating Cloudflare Credentials

1. Log in to the [Cloudflare Dashboard](https://dash.cloudflare.com/).
2. Select your account.
3. Your **Account ID** is visible in the right sidebar of the Dashboard overview, or directly in the URL: `https://dash.cloudflare.com/<ACCOUNT_ID>`.
4. Navigate to **My Profile** > **API Tokens**.
5. Click **Create Token**.
6. Select the **Workers AI** template (or create custom token with **Workers AI: Read** permission).
7. Copy the generated API Token.

---

## 3. Configuring Rexam Data Engine

Set the environment variables in `engine/.env` or GitHub Repository Secrets:

```ini
CLOUDFLARE_ACCOUNT_ID=your-account-id-here
CLOUDFLARE_API_TOKEN=your-token-here
CLOUDFLARE_AI_MODEL=@cf/meta/llama-3.1-8b-instruct
```

### Supported & Tested Models:
- `@cf/meta/llama-3.1-8b-instruct` (Default — fastest and most cost-effective for structured JSON parsing)
- `@cf/mistral/mistral-7b-instruct-v0.2`
- `@cf/qwen/qwen1.5-14b-chat-awq`

---

## 4. Graceful Fallback Behavior

Rexam is **never dependent on AI availability**:
- If `CLOUDFLARE_ACCOUNT_ID` or `CLOUDFLARE_API_TOKEN` are empty or invalid, the ingestion pipeline will **not fail**.
- The pipeline invokes `_heuristic_fallback()` in `engine/app/ai/cloudflare_ai.py`, which parses dates, vacancy counts, fees, and eligibility bounds using deterministic regex.
- Documents extracted via heuristic fallback are flagged with:
  - `status: "under_review"`
  - `requires_human_review: true`
  - `confidence_score: 0.70`
- Once human review confirms or corrects the record in the Supabase Dashboard, its status is updated to `published`.

