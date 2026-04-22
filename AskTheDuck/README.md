# Ask the Duck

Native iOS (SwiftUI) companion app for **Pool Duck** technicians and
franchisees. Sign in, snap a photo or short video of the equipment /
water / problem, speak or type what you're seeing, and get an
AI-assisted answer from Claude — right there on the deck.

## Features

- **Pool Duck branded UI** — teal/green gradient, duck mascot, and
  on-brand typography throughout.
- **Technician & admin sign-in** — pluggable `AuthBackend` (ships with
  a mock; swap for Firebase / Cognito / the franchise portal). Email
  containing `admin` signs in as admin in the mock backend.
- **Problem-type selection** — Equipment, Water Chemistry,
  Troubleshooting, Leak / Structure, Automation & Controls, Other.
  Each one steers Claude with a tailored system prompt.
- **Pool Duck Way playbook** — one central `playbook.md` (bundled in
  the app) is injected into every Claude call so advice stays
  consistent across techs, franchises, and locations. The playbook
  covers audience (tech, not homeowner), diagnostic order, repair
  process, escalation triggers, and markup / pricing policy. Drop in
  the real FDD / Franchise Operations Manual derivations when they're
  ready (see **Playbook** section below).
- **Customer capture** — every service call starts with name, service
  address, and phone. Prior visits at the same customer surface as
  the tech types.
- **Service history & search** — every chat session is persisted as a
  `ServiceRecord`. From the home screen, tap the clock icon to search
  past sessions by customer, address, phone, or any keyword. Filter by
  "mine" vs. the whole franchise.
- **Photo & video capture** — built-in camera for photos or
  up-to-60-second video, plus Photos library picker. Videos are
  encouraged — a prominent banner in the composer nudges the tech to
  shoot a 10-second clip with the equipment running. A **Low signal**
  toggle (in the chat's `…` menu) suppresses the nudge when cellular
  is weak.
- **Speech-to-text** — on-device `SFSpeechRecognizer` so a tech with
  wet hands can just tap the mic and talk.
- **Claude integration** — calls `/v1/messages` with multi-modal
  content blocks, governed by the playbook system prompt. Response
  format is always Likely cause / Check / Fix / Escalate.
- **Repair quoting** — tech can generate a repair quote from the chat
  (Claude extracts line items + labor) or start a quote from the
  problem-selection screen. Pool Duck's default is **100% markup** on
  parts; the tech can pull that down with a local-market note
  explaining why. Full quote editor with parts / labor / markup slider
  / totals.
- **Escalate to office** — if Claude can't crack it, the tech taps
  Escalate. Summary, steps already tried, chat transcript, every
  photo/video still, and customer contact info bundle into a ticket
  for the admin queue.
- **Admin panel** — admins see a filterable inbox (Pending / Scheduled
  / Completed) with ticket detail (customer with tap-to-call, all
  photos, full transcript, tech notes) and one-tap scheduling with
  notes back to the tech.

## Playbook — where the "Pool Duck way" lives

`AskTheDuck/Resources/playbook.md` is the single source of truth for
how Claude is told to behave. Every Claude call injects this file into
the system prompt, so advice stays aligned franchise-wide.

**The committed `playbook.md` is a placeholder** — reasonable pool-
industry convention written in the Pool Duck voice. Before shipping:

1. Drop the real FDD / FOM PDFs into `docs/source/` (gitignored —
   raw documents never hit the repo).
2. Ask Claude Code to extract the tech-relevant sections (repair
   process, audience, escalation triggers, safety, markup policy) and
   rewrite `playbook.md`.
3. Legal / ops reviews the derived playbook before cutting a build.

See `docs/README.md` for the ingestion workflow.

## Project layout

```
AskTheDuck/
├── AskTheDuck.xcodeproj
└── AskTheDuck/
    ├── AskTheDuckApp.swift          # @main entry point + role routing
    ├── Info.plist
    ├── Assets.xcassets/             # Brand colors + DuckLogo image slot
    ├── Resources/
    │   └── playbook.md              # Pool Duck Way (injected into Claude)
    ├── Theme/PoolDuckTheme.swift
    ├── Models/
    │   ├── ProblemType.swift
    │   ├── Message.swift            # Technician (with role), ChatMessage
    │   ├── CustomerInfo.swift
    │   ├── Ticket.swift             # EscalationTicket + TicketMessage
    │   ├── ServiceRecord.swift      # Auto-saved chat history
    │   └── Quote.swift              # Parts + labor + markup
    ├── Services/
    │   ├── ClaudeService.swift      # Messages API (vision)
    │   ├── SpeechService.swift
    │   ├── MediaService.swift
    │   ├── AuthService.swift
    │   ├── TicketStore.swift        # Escalation tickets
    │   ├── HistoryStore.swift       # All service records
    │   ├── QuoteStore.swift
    │   ├── QuoteService.swift       # Claude-powered quote drafting
    │   ├── PoolDuckPlaybook.swift   # Loads + injects playbook.md
    │   └── Integrations/
    │       ├── PoolBrainSync.swift       # Stub — next release
    │       └── CustomerNotifier.swift    # Stub — next release
    ├── ViewModels/
    │   ├── AuthViewModel.swift
    │   ├── ChatViewModel.swift
    │   ├── AdminViewModel.swift
    │   └── HistoryViewModel.swift
    └── Views/
        ├── LoginView.swift
        ├── HomeView.swift           # Troubleshoot vs. Quote mode
        ├── CustomerInfoView.swift   # Prior-visit matches live
        ├── ChatView.swift           # Quote button, video nudge, signal toggle
        ├── EscalateView.swift
        ├── AdminPanelView.swift
        ├── TicketDetailView.swift
        ├── HistoryView.swift        # Search past sessions
        ├── QuoteView.swift          # Full quote editor
        ├── MediaPickers.swift
        └── Components/DuckLogo.swift
```

## Prerequisites

- Xcode 15.3+
- iOS 17.0+
- Anthropic API key (https://console.anthropic.com/)

## Setup

1. Open `AskTheDuck/AskTheDuck.xcodeproj` in Xcode.
2. Select the `AskTheDuck` target → **Signing & Capabilities** → set
   your team and a unique bundle identifier (default:
   `com.poolduck.asktheduck`).
3. Copy `AskTheDuck/Secrets.xcconfig.template` →
   `AskTheDuck/Secrets.xcconfig` (gitignored) and fill in your key.
   Wire it via Project → Info → Configurations (Debug + Release).
   **Production:** put the key behind a proxy instead of shipping in
   the binary.
4. Drop your real logo at
   `AskTheDuck/Assets.xcassets/DuckLogo.imageset/duck-logo.png`.
5. When you're ready to swap in the real playbook, follow
   `docs/README.md`.
6. Build & run on a device (camera / mic / speech need real hardware).

## Flows

### Technician flow
1. Sign in (any email without `admin` → technician role).
2. Pick **Troubleshoot** or **Start a Quote** at the top of the home
   screen.
3. Tap a problem tile. Enter customer name, address, phone. If the tech
   has been to this customer before, prior visits appear inline — tap
   one to pre-fill.
4. Chat with Claude. Capture video (preferred) or photos, speak or
   type. Claude responds in the Likely cause / Check / Fix / Escalate
   format governed by the playbook.
5. **Quote**: tap `…` → "Generate repair quote." Claude drafts line
   items + labor from the transcript, applies 100% markup by default.
   Edit parts, pull markup down per local market with a required note,
   save.
6. **Can't resolve?** Tap `…` → "Escalate to office." The whole
   session (customer, transcript, photos, your notes) lands in the
   admin queue.
7. **Looking up past work?** Tap the clock icon on the home screen to
   search history by customer / address / keyword.

### Admin flow
1. Sign in with `admin` in the email.
2. Filterable inbox of escalated tickets.
3. Ticket detail has tap-to-call customer phone, all photos, full
   transcript, tech notes. Hit **Schedule repair** with date/time +
   notes back to the tech, or **Mark done**.

## Storage

Everything persists locally under `~/Library/Application Support/`:

- `AskTheDuckHistory/<record-uuid>/` — one folder per session
  (record.json + attachment JPEGs).
- `AskTheDuckTickets/<ticket-uuid>/` — escalated tickets.
- `AskTheDuckQuotes/*.json` — saved quotes.

Every store implements a protocol (`HistoryStoring`, `TicketStoring`,
`QuoteStoring`) — swap for Firebase / Firestore / REST when syncing
across the franchise.

## Roadmap (future releases)

These are stubbed out in code so the call sites are already in place:

- **Pool Brain two-way sync** (`Services/Integrations/PoolBrainSync.swift`) —
  push service records + tickets into Pool Brain as work orders, pull
  tech reassignments / reschedules back in.
- **Customer email + SMS notifications** (`CustomerNotifier.swift`) —
  once admin schedules a repair, automatically email / text the
  customer. Post-visit, send a homeowner-friendly summary generated by
  a separate Claude call that translates the tech-facing transcript
  into plain language. TCPA / CAN-SPAM compliance reminders are in the
  stub file.
- **Per-franchise playbook overrides** — layer a franchise-specific
  overlay on top of the master `playbook.md` for local markup,
  pricing, and state rules.
- **Remote playbook config** — fetch playbook updates without a
  TestFlight push.
