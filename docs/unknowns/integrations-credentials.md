# Integration Credentials Checklist

Every third-party integration PoolDuck v1 depends on. None of these block the
plan, but all of them block M3+ execution. Gather in parallel with M1 scaffold.

## 1. Supabase (M1 — blocks everything)
- [ ] Create Supabase project (prod) + a second project (staging)
- [ ] Record `SUPABASE_URL` and `SUPABASE_ANON_KEY` (public)
- [ ] Record `SUPABASE_SERVICE_ROLE_KEY` (server only — never ship to browser)
- [ ] Configure auth providers: email + magic link; Apple SSO (requires Apple Developer program)
- [ ] Set up Storage buckets: `visit-photos`, `signatures`, `invoice-pdfs`, `import-staging`
- [ ] Enable Realtime on `routes`, `stops`, `visits` tables once migrated
- Reference: https://supabase.com/docs

## 2. Claude API — Ask-the-Duck (M2)
- [ ] Anthropic Console account + org
- [ ] Generate API key → `ANTHROPIC_API_KEY`
- [ ] Model: `claude-sonnet-4-6` (primary). Keep `claude-haiku-4-5-20251001` wired as the cheap fallback for short tool-use turns.
- [ ] Turn on prompt caching for the Duck system prompt (duck persona + pool-ops reference) and tool schemas — these are large and stable, big cache-hit-rate win.
- [ ] Usage budget / rate-limit tier appropriate for chat streaming (SSE)
- Reference: https://docs.anthropic.com

## 3. QuickBooks Online — Intuit (M4)
- [ ] Intuit Developer account: https://developer.intuit.com
- [ ] Create an app in the developer portal
- [ ] Capture **sandbox** and **production** keys separately:
  - `QBO_CLIENT_ID`
  - `QBO_CLIENT_SECRET`
- [ ] Redirect URIs to register:
  - `https://<staging-domain>/api/qbo/callback`
  - `https://<prod-domain>/api/qbo/callback`
  - `http://localhost:3000/api/qbo/callback` (dev)
- [ ] Scopes requested: `com.intuit.quickbooks.accounting` (+ `payment` if we take Intuit payments later)
- [ ] Subscribe to QBO webhooks (invoice/customer/payment events) → `/api/qbo/webhook`; capture verifier token → `QBO_WEBHOOK_VERIFIER_TOKEN`
- [ ] Create a sandbox company with seed customers/items for contract tests
- SDK: `node-quickbooks` or raw `intuit-oauth`
- Reference: https://developer.intuit.com/app/developer/qbo/docs/develop

## 4. Stripe — Customer Payments (M4)
- [ ] Stripe account (activate live mode when ready)
- [ ] API keys:
  - `STRIPE_SECRET_KEY` (server)
  - `STRIPE_PUBLISHABLE_KEY` (browser)
- [ ] Restricted key for server-side webhook signing verification
- [ ] Webhook endpoint: `/api/stripe/webhook` → `STRIPE_WEBHOOK_SECRET`
- [ ] Products & Prices:
  - Customer invoice line items are created dynamically, so no upfront Products needed
  - (Deferred) PoolDuck SaaS subscription Prices — wait until billing model is decided
- [ ] Enable ACH (US Bank Account) + Card; optional Apple Pay / Google Pay
- [ ] Branding: logo + colors once brand refresh is final
- Reference: https://docs.stripe.com

## 5. Mapbox — Route Optimization (M3)
- [ ] Mapbox account
- [ ] Access token → `MAPBOX_ACCESS_TOKEN` (URL-restricted to PoolDuck domains)
- [ ] Pick tier based on monthly Optimization API calls (rough v1 budget: ~5k calls/mo for 50 tenants × 2 optimizations/week)
- [ ] Fallback already in plan: `@turf/turf` + OSRM if we blow budget
- Reference: https://docs.mapbox.com/api/navigation/optimization/

## 6. Apple Developer (optional M1, required for SSO + iOS install polish)
- [ ] Apple Developer Program membership (if we want Sign in with Apple)
- [ ] Service ID + key for Supabase Apple provider
- [ ] Associated domains for iOS PWA install banner polish (optional)

## 7. Vercel (deploy — M1)
- [ ] Vercel project connected to GitHub repo
- [ ] Env vars mirrored from above per environment (preview / staging / prod)
- [ ] Custom domains: `app.poolduck.app` (or similar; NOT touching the live `poolduck.app` apex)

## 8. Secrets Storage
- `.env.local` for dev (git-ignored — add to `.gitignore` in M1)
- Vercel encrypted env for staging/prod
- Supabase Vault for anything an Edge Function needs server-side
- **Never** commit any of these keys. CI check (gitleaks) added in M1.

## Required Env Vars (consolidated)
```
# Supabase
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=

# Anthropic
ANTHROPIC_API_KEY=

# QuickBooks Online
QBO_CLIENT_ID=
QBO_CLIENT_SECRET=
QBO_ENVIRONMENT=sandbox        # or production
QBO_REDIRECT_URI=
QBO_WEBHOOK_VERIFIER_TOKEN=

# Stripe
STRIPE_SECRET_KEY=
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=
STRIPE_WEBHOOK_SECRET=

# Mapbox
NEXT_PUBLIC_MAPBOX_ACCESS_TOKEN=
```
