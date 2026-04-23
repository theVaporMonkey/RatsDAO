# PoolDuck — Locked Decisions

Captured 2026-04-23. Supersedes any conflicting notes in the original plan at
`/root/.claude/plans/i-would-like-to-scalable-toast.md`.

## Scope
- **V1 ambition**: Feature-complete across all four domains — Ask-the-Duck chat, Routes & scheduling, Water chemistry & readings, Customers/pools/billing + QBO — with full import/export interoperability. Stage-gated into M1–M6 (see plan file).
- **Starting point**: Greenfield build in this repo. The live poolduck.app is reference-only (hands off).
- **Repo**: Reuse the current repo; develop on branch `claude/integrate-pool-bra-features-aDMXw`. The RatsDAO README stays at root for now.

## Stack
- **Next.js 15** App Router + TypeScript + React 19
- **Supabase** — Postgres + RLS, Auth, Storage, Realtime, Edge Functions
- **Stripe** — ACH + card payments and (future) PoolDuck SaaS subscription
- **Claude API** — `claude-sonnet-4-6` with prompt caching on Duck persona + tool schemas
- **QuickBooks Online** — Intuit OAuth2 + REST v3 (two-way sync) plus IIF export fallback
- **PWA** — Serwist service worker, Dexie IndexedDB, background sync queue
- **PDF** — `@react-pdf/renderer` rendered in a Supabase Edge Function
- **CSV** — `papaparse`
- **Routing optimization** — Mapbox Optimization API (fallback: `@turf/turf` + OSRM)
- **Forms** — `react-hook-form` + `zod`
- **Deploy** — Vercel (web) + Supabase (data/functions)

## Exports / Imports
All four formats are v1 scope:
1. **QuickBooks Online** — live REST two-way sync + IIF export + CSV fallback
2. **Skimmer CSV** — import and export against Skimmer's current CSV schema
3. **Pool Brain CSV** — import and export against Pool Brain's current CSV schema
4. **Generic CSV + PDF** — RFC-4180 CSV per first-class entity; PDF service reports, invoices, statements

## Billing Model (PoolDuck's own SaaS)
- **Decision**: Deferred. V1 ships with a single hardcoded plan; full Stripe Billing tiers (per-tech seats vs. flat vs. add-ons) are revisited after pilot feedback.
- Stripe integration for **payments to pool-service customers** is still in v1 scope — only the tenant-facing subscription billing is deferred.

## Brand & Voice
- **Visual design**: Refresh for pro UX. Keep the duck identity; rebuild palette/type for a denser, operator-facing app (route boards, invoice tables, QBO settings). Design tokens live in `lib/theme/tokens.ts` once we port them.
- **Duck voice**: Duck-forward **everywhere** — CTAs, empty states, error messages, push notifications, transactional email copy. Ask-the-Duck is the product, not a feature. Operational UI still reads clearly, but the voice is the throughline.
  - Practical implication: write copy guidelines in `docs/voice.md` during M2; share a `<DuckCopy>` primitive for microcopy so tone is consistent.

## Out of Scope for V1
- Native iOS/Android wrappers (PWA-only for v1; Expo port deferred)
- Multi-language / i18n (English-only v1)
- Marketplace / parts catalog sourcing
- Route auto-dispatch beyond Mapbox Optimization
- PoolDuck SaaS subscription tiers (deferred, see above)

## Open (see `docs/unknowns/`)
- Intuit / Mapbox / Stripe / Claude API / Supabase credentials
- Live poolduck.app UX snapshot (blocked by 403; user will paste)
- Final brand tokens (palette, type, duck mark assets)
