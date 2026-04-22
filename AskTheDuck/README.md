# Ask the Duck

Native iOS (SwiftUI) companion app for **Pool Duck** technicians and franchisees.
Sign in, snap a photo or short video of the equipment / water / problem,
speak or type what you're seeing, and get an AI-assisted answer from Claude
— right there on the deck.

## Features

- **Pool Duck branded UI** — teal/green gradient, duck mascot, and on-brand
  typography throughout.
- **Technician sign-in** — pluggable `AuthBackend` (ships with a mock; swap
  for Firebase / Cognito / the franchise portal).
- **Problem-type selection** — Equipment, Water Chemistry, Troubleshooting,
  Leak / Structure, Automation & Controls, Other. Each one steers Claude
  with a tailored system prompt.
- **Photo & video capture** — built-in camera for photos or up-to-60-second
  video, plus Photos library picker for existing media. Videos are sent as
  a representative still frame (Claude's vision API accepts images).
- **Speech-to-text** — on-device `SFSpeechRecognizer` so a tech with wet
  hands can just tap the mic and talk.
- **Claude integration** — calls `/v1/messages` with multi-modal content
  blocks. System prompt asks Claude to answer like "a seasoned pool pro
  talking to a teammate on a job site" with a consistent Likely-Cause /
  Check / Fix / Escalate structure.

## Project layout

```
AskTheDuck/
├── AskTheDuck.xcodeproj
└── AskTheDuck/
    ├── AskTheDuckApp.swift          # @main entry point
    ├── Info.plist
    ├── Assets.xcassets/             # Brand colors + DuckLogo image slot
    ├── Theme/PoolDuckTheme.swift
    ├── Models/
    │   ├── ProblemType.swift
    │   └── Message.swift
    ├── Services/
    │   ├── ClaudeService.swift      # Anthropic Messages API (vision)
    │   ├── SpeechService.swift      # SFSpeechRecognizer wrapper
    │   ├── MediaService.swift       # Image resize + video thumbnail
    │   └── AuthService.swift        # Pluggable backend (mock included)
    ├── ViewModels/
    │   ├── AuthViewModel.swift
    │   └── ChatViewModel.swift
    └── Views/
        ├── LoginView.swift
        ├── HomeView.swift
        ├── ChatView.swift
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
