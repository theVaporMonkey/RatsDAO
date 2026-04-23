# poolduck.app — Live UX Audit (PENDING)

## Why this file is empty
The live poolduck.app is off-limits for edits and also returns **HTTP 403** to
programmatic fetches (Cloudflare / WAF bot protection). All of these were tried
on 2026-04-23 and failed:

- `https://poolduck.app/` → 403
- `https://www.poolduck.app/` → 403
- `https://poolduck.app/sitemap.xml` → 403
- `https://poolduck.app/robots.txt` → 403
- `https://poolduck.app/manifest.json` → 403
- `https://web.archive.org/web/2026/https://poolduck.app` → blocked at fetcher level
- Web search for `"poolduck.app"` returned no hits for the real site (only an
  unrelated `poolduck.com` pool-service business and the `PoolDial` competitor)

Without a snapshot of the live site, we can't lock design tokens, nav IA, or
duck-voice copy samples.

## What we need from the user (paste into this file)

Please paste or drop into `/home/user/RatsDAO/docs/unknowns/poolduck-ux-raw/`:

1. **Home page copy** — hero headline, sub-headline, feature blurbs, CTAs,
   footer text. Exact copy, so we can mirror the duck voice.
2. **Sitemap / nav** — every top-level page and major section the live site has.
3. **Screenshots** — at minimum: home, Ask-the-Duck chat, any settings or
   onboarding screen, any existing pool/reading/customer screen. Desktop and
   mobile breakpoints.
4. **Brand assets** — logo SVG (or highest-res PNG), color palette hex values,
   primary / secondary typefaces. If a Figma or brand-guidelines PDF exists,
   link it.
5. **Duck voice samples** — 5–10 example sentences of how the Duck currently
   talks. Empty states, error messages, welcome copy are ideal.
6. **PWA manifest** — if you can view-source and copy the manifest JSON, drop
   it here so we replicate the install experience.
7. **Tech hints** — anything you already know about the current stack (is it
   Next.js? SvelteKit? Bubble? Webflow?). Affects how much we can port vs.
   rebuild.

## Where it goes once we have it

- Raw pastes / screenshots → `docs/unknowns/poolduck-ux-raw/`
- Distilled findings → this file, replacing the placeholder
- Design tokens derived from palette/typography → `lib/theme/tokens.ts` during M1
- Duck voice guidelines → `docs/voice.md` during M2

## Fallback if user can't provide

If no UX brief is feasible, we proceed with the **Refresh for pro UX** brand
decision from `docs/decisions.md` using a fresh palette and typography, and
we keep duck-forward voice in our own words. The risk is drift from the
live poolduck.app identity; we flag this as a followup for pre-launch review.
