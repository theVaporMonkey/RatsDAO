# Open Questions — Resolve Before Each Milestone

Each item lists which milestone it blocks. Items not listed here are closed;
see `docs/decisions.md`.

## Before M1 (scaffold)
- [ ] Production domain: is `app.poolduck.app` acceptable, or use a different subdomain so it doesn't shadow the live apex? The live `poolduck.app` stays untouched.
- [ ] Github repo strategy: stay on this `claude/integrate-pool-bra-features-aDMXw` branch of RatsDAO for the whole build, or cut a fresh repo `poolduck-app` once we have M1 scaffold? (Current decision: stay on this branch.)
- [ ] Does the live poolduck.app already have a database with user accounts, customers, or chat history? If yes, plan a one-time data migration at cutover; if no, greenfield data.

## Before M2 (Duck chat + readings)
- [ ] UX brief for live poolduck.app (see `poolduck-ux-audit.md`).
- [ ] Duck voice samples. Without these we'll draft our own, reviewed by user.
- [ ] Anthropic API access + rate-limit tier (see `integrations-credentials.md`).
- [ ] Should Duck chat be per-user (private) or per-customer (shared with all techs servicing that customer)? Affects `duck_threads` RLS.
- [ ] Tool-use allowlist — which of `log_reading`, `draft_work_order`, `suggest_dosing`, `lookup_customer`, `schedule_visit` should the Duck be allowed to execute autonomously vs. requiring human confirm?

## Before M3 (routes + offline)
- [ ] Mapbox account + token (see `integrations-credentials.md`).
- [ ] Route optimization constraints: fixed service windows, skill-matching (pool size / equipment), tech vehicle capacity, home-base start/end? Pool Brain and Skimmer differ here.
- [ ] Offline conflict resolution policy: last-write-wins, server-wins, or per-field merge? Likely last-write-wins for readings, server-wins for schedule changes.

## Before M4 (billing + QBO)
- [ ] Intuit Developer app credentials (see `integrations-credentials.md`).
- [ ] Stripe account + webhook endpoint (see `integrations-credentials.md`).
- [ ] QBO sync direction priority: which side is the source of truth for customer edits? (Recommendation: PoolDuck is source of truth for service data; QBO is source of truth for accounting categories / items.)
- [ ] Tax handling: let QBO handle sales tax, or compute locally via TaxJar/Avalara? US multi-state service companies often have nexus issues.
- [ ] Invoice number scheme: sequential per-tenant or per-QBO-company?

## Before M5 (Skimmer + Pool Brain import/export)
- [ ] Sample CSV exports from both Skimmer and Pool Brain (current format versions). Needed to build schema mappers and golden-file tests. If user has live tenant access at either, a fresh export of each entity type is ideal.
- [ ] Conflict resolution for imports: dedup by email? by address? by external_id? Likely a combination with user-facing merge UI.
- [ ] Round-trip guarantee: if data is imported from Skimmer then re-exported, should it bit-match? (Realistic target: mapped fields match; computed fields like `lsi_computed` are PoolDuck-native.)

## Before M6 (PWA polish + pilot)
- [ ] Push notification provider: Web Push via VAPID (direct) or a service (OneSignal)?
- [ ] Pilot tenant list — 2–3 real pool-service companies willing to run PoolDuck alongside their current tool for a month.
- [ ] Support / SLA: what response time are we promising pilots?

## Ongoing / Legal
- [ ] Terms of Service + Privacy Policy (especially given AI chat transcripts + customer photos + payment data)
- [ ] Data residency: US-only or cross-region? Supabase project region decides this.
- [ ] SOC2 roadmap — required if targeting larger pool-service franchises.
- [ ] Copyright / trademark review of "Ask the Duck" + duck mark (confirm ownership sits with the right entity before we scale marketing).
