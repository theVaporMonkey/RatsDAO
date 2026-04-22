# Ask the Duck

Native iOS (SwiftUI) companion app for **Pool Duck** technicians and franchisees.
Sign in, snap a photo or short video of the equipment / water / problem,
speak or type what you're seeing, and get an AI-assisted answer from Claude
— right there on the deck.

## Features

- **Pool Duck branded UI** — teal/green gradient, duck mascot, and on-brand
  typography throughout.
- **Technician & admin sign-in** — pluggable `AuthBackend` (ships with a
  mock; swap for Firebase / Cognito / the franchise portal). Email
  containing `admin` signs in as admin in the mock backend.
- **Problem-type selection** — Equipment, Water Chemistry, Troubleshooting,
  Leak / Structure, Automation & Controls, Other. Each one steers Claude
  with a tailored system prompt.
- **Customer capture** — every service call starts by capturing customer
  name, address, and phone. That info travels with the ticket if it
  escalates.
- **Photo & video capture** — built-in camera for photos or up-to-60-second
  video, plus Photos library picker for existing media. Videos are sent as
  a representative still frame (Claude's vision API accepts images).
- **Speech-to-text** — on-device `SFSpeechRecognizer` so a tech with wet
  hands can just tap the mic and talk.
- **Claude integration** — calls `/v1/messages` with multi-modal content
  blocks. System prompt asks Claude to answer like "a seasoned pool pro
  talking to a teammate on a job site" with a consistent Likely-Cause /
  Check / Fix / Escalate structure.
- **Escalate to office** — if Claude can't crack it, the tech taps
  "Escalate." The summary, troubleshooting steps already tried, full chat
  transcript, every photo/video still, and the customer's contact info
  are bundled into a ticket and dropped in the admin queue.
- **Admin panel** — admins see a list of tickets filterable by Pending /
  Scheduled / Completed, with full detail (customer, photos, chat
  transcript, tech notes) and one-tap scheduling for a repair with
  optional notes back to the tech.

## Project layout

```
AskTheDuck/
├── AskTheDuck.xcodeproj
└── AskTheDuck/
    ├── AskTheDuckApp.swift          # @main entry point + role routing
    ├── Info.plist
    ├── Assets.xcassets/             # Brand colors + DuckLogo image slot
    ├── Theme/PoolDuckTheme.swift
    ├── Models/
    │   ├── ProblemType.swift
    │   ├── Message.swift            # Technician (with role), ChatMessage
    │   ├── CustomerInfo.swift       # Name / address / phone
    │   └── Ticket.swift             # EscalationTicket + TicketMessage
    ├── Services/
    │   ├── ClaudeService.swift      # Anthropic Messages API (vision)
    │   ├── SpeechService.swift      # SFSpeechRecognizer wrapper
    │   ├── MediaService.swift       # Image resize + video thumbnail
    │   ├── AuthService.swift        # Pluggable backend (mock included)
    │   └── TicketStore.swift        # Local JSON + attachment persistence
    ├── ViewModels/
    │   ├── AuthViewModel.swift
    │   ├── ChatViewModel.swift      # Chat + escalate flow
    │   └── AdminViewModel.swift     # Ticket list + scheduling
    └── Views/
        ├── LoginView.swift
        ├── HomeView.swift
        ├── CustomerInfoView.swift   # Captured before every chat
        ├── ChatView.swift
        ├── EscalateView.swift       # "Send to office" sheet
        ├── AdminPanelView.swift     # Ticket inbox
        ├── TicketDetailView.swift   # Photos + transcript + scheduling
        ├── MediaPickers.swift
        └── Components/DuckLogo.swift
```

## Prerequisites

- Xcode 15.3+
- iOS 17.0+ deployment target
- An Anthropic API key (https://console.anthropic.com/)

## Setup

1. Open `AskTheDuck/AskTheDuck.xcodeproj` in Xcode.
2. Select the `AskTheDuck` target, then **Signing & Capabilities** — set your
   team and a unique bundle identifier (default: `com.poolduck.asktheduck`).
3. **Add your Claude API key.** The recommended flow:
   - Copy `AskTheDuck/Secrets.xcconfig.template` to
     `AskTheDuck/Secrets.xcconfig` (gitignored) and fill in your key.
   - In the project editor → **Info** tab → **Configurations** → set
     both Debug and Release to use `Secrets.xcconfig`.
   - `Info.plist` already reads `$(CLAUDE_API_KEY)` at build time.
   - **Production recommendation:** do NOT ship the key in the app binary.
     Stand up a small proxy (Vercel / Cloudflare Worker / Lambda) that
     holds the key server-side and forwards requests, then point
     `CLAUDE_ENDPOINT` at that proxy.
4. **Drop in the brand logo.** Replace
   `AskTheDuck/Assets.xcassets/DuckLogo.imageset/duck-logo.png` (any
   resolution — 1024×1024 PNG is ideal). Until you do, the app renders
   a vector fallback silhouette of the duck.
5. Build & run on an iPhone (camera / mic / speech need a real device or
   a simulator with fake audio).

## Flows

### Technician flow
1. Sign in (any email without `admin` in it → technician role).
2. Tap a problem tile on the home grid.
3. Enter the customer's name, service address, and phone.
4. Chat with Claude — snap photos, record short video clips, speak or type
   your question. Claude responds with a consistent Likely-cause / Check /
   Fix / Escalate-if structure.
5. If you can't resolve it on site, tap **Escalate** in the top-right.
   Describe the issue in one paragraph, note what you already tried
   (there's a "Paste Claude's guidance" shortcut), and submit. Everything
   — customer info, photos, chat transcript, your notes — goes to the
   admin queue.

### Admin flow
1. Sign in with an email that contains `admin` (e.g.
   `dispatch@admin.poolduck.com`).
2. The Admin Panel shows every escalated ticket, filterable by Pending /
   Scheduled / Completed.
3. Tap a ticket to see the customer info (with tap-to-call), the photos
   and video stills, and the full chat transcript between the tech and
   Claude.
4. Hit **Schedule repair** to pick a date/time and add dispatch notes for
   the technician, or **Mark done** once the repair is completed.

### Storage

Tickets and their attachments persist locally under
`~/Library/Application Support/AskTheDuckTickets/<ticket-uuid>/` —
one folder per ticket, containing `ticket.json` and every JPEG from the
session. This is intentionally a drop-in backend: implement
`TicketStoring` against Firebase/Firestore, DynamoDB, or a REST API when
you're ready to sync across devices / franchises.

## Customization pointers

- **Colors:** tweak `PoolDuckTheme.swift` and the matching `.colorset`
  entries in the asset catalog.
- **Problem types:** add cases to `ProblemType` in `Models/ProblemType.swift`
  — the home grid, chat header, and system prompt all pick them up
  automatically.
- **Claude model:** change `CLAUDE_MODEL` in `Info.plist` /
  `Secrets.xcconfig`. Default is `claude-sonnet-4-6`. Bump to
  `claude-opus-4-7` for tougher chemistry questions if latency allows.
- **Auth backend:** implement the `AuthBackend` protocol in
  `Services/AuthService.swift` and inject it into `AuthViewModel`.

## Permissions

`Info.plist` already declares all required strings:
- `NSCameraUsageDescription`
- `NSMicrophoneUsageDescription`
- `NSSpeechRecognitionUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`

## Next steps worth considering

- Per-franchise branding (logo + accent color pulled from a config
  endpoint so each franchisee can customize their own theme).
- Offline queue: photos captured without signal get sent once the truck
  rolls back into range.
- Job tagging: attach the address / customer from the day's route so
  Claude's answers can be pinned to a service record.
- Analytics: anonymized "most common questions" per franchise to feed
  training/ops.
