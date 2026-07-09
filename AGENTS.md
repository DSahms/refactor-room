# The Refactor Room — Agent Briefing

Read at session start. **Product name on screen:** The Refactor Room. **Package:** `refactor_room`.

## What this app is

Flutter app (Windows + Android) that runs a **two-stage LLM pipeline** on a business idea:

1. **Skeleton** — strip to structural pattern
2. **Transplants** — 10 ranked + 5 bonus market applications

**No lenses. No stress stage.** Prompts live in `refactor_room/lib/api/prompts.dart`.

**Think Tank** = separate Claude project prompt (not this repo).

## Repo layout

```
Refactor Room/
├── AGENTS.md          ← you are here
├── STATE.md           ← ship status
└── refactor_room/     ← Flutter project
    ├── lib/api/       prompts, pipeline, clients ★
    ├── lib/screens/   input → processing → results → detail
    └── .env           API keys (never commit)
```

## Sacred files

| File | Why |
|------|-----|
| `lib/api/prompts.dart` | The product — never shorten or expose in UI |
| `lib/api/pipeline.dart` | Two-stage orchestration |
| `lib/models/analysis.dart` | Lenient parsers |

## Backend

Default: **Venice** (`LLM_BACKEND=venice`). Alternatives: `groq`, `anthropic`. See `lib/core/env_config.dart`.

## Build & ship

```powershell
cd refactor_room
flutter pub get
flutter analyze
flutter test

# Windows
flutter build windows --release
.\copy_to_windows_release.ps1

# Android
flutter build apk --debug
.\copy_to_beta_apps.ps1
```

Shelf: `D:\Beta Apps\Refactor-Room\` and `Refactor-Room-LATEST.apk`.

## Design PDF policy

Style reference only — skin via `lib/theme/tokens.dart`. **Code wins for behavior; PDF wins for appearance.** Never rewrite pipeline logic to match mockups.

## Do not confuse with

- **Think Tank** (Claude prompt)
- **Panoptes Lens** (legacy folder name — retired)
- **Ledger / NURA / Arden** (different products)
