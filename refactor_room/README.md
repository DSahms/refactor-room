# The Refactor Room

**Product:** Business-idea dissector — strip an idea to its skeleton, then rank where else that pattern could live (transplants).  
**Company:** AI Integration and Consulting LLC  
**Stack:** Flutter (Windows + Android), Venice API (default), optional Groq/Anthropic  
**Status:** Shipped as debug/portable builds on the Beta Apps shelf — see `STATE.md`

---

## What it does

1. You type or speak a business idea (optional **Domain Lock** to keep transplants in one industry).
2. **Stage 1 — Skeleton:** AI strips the idea to mechanics — problem archetype, value mechanic, dependencies, hidden constraint.
3. **Stage 2 — Transplants:** AI returns **10 ranked** market applications + **5 bonus** wild-card domains.

No brand lenses (Apple/Tesla/etc.). No stress-test stage. Two API calls per run.

**Think Tank** (Claude project prompt) is a separate, richer tool — not this app.

---

## Install — Windows

### Option A: Pre-built portable (fastest)

1. Open `D:\Beta Apps\Refactor-Room\Windows\`
2. Unzip **`Refactor-Room-Windows-v1.1.0.zip`** (or use the `Refactor-Room-Portable-v1.1.0` folder if present).
3. Run **`refactor_room.exe`**
4. Needs **internet** — the app calls Venice (or whatever backend is in `.env` when you build from source).

### Option B: Build from source

```powershell
cd "D:\dev\Refactor Room\refactor_room"
copy .env.example .env   # add your VENICE_API_KEY
flutter pub get
flutter build windows --release
.\copy_to_windows_release.ps1
```

Output: `build\windows\x64\runner\Release\refactor_room.exe` plus `data\` folder — keep them together.

---

## Install — Android

1. Copy **`D:\Beta Apps\Refactor-Room-LATEST.apk`** to your phone (USB, Drive, etc.).
2. Uninstall any old **Panoptes Lens** or **Refactor Room** install first (different package IDs can coexist — avoid confusion).
3. Allow **Install unknown apps** if Android prompts.
4. Open the app — top-right should show **`v1.1.0 · transplants`**.

### Build from source

```powershell
cd "D:\dev\Refactor Room\refactor_room"
flutter build apk --debug
.\copy_to_beta_apps.ps1
```

---

## How to use it

| Step | What happens |
|------|----------------|
| Home | Enter idea (type, mic, or import `.md` / `.txt`) |
| Domain Lock | Optional — e.g. `construction` keeps transplants in that industry |
| Run | ~45–90 seconds — Skeleton, then Transplants |
| Results | Skeleton summary + 10 ranked cards + 5 bonus — tap for detail |

**Backend (default):** Venice → `llama-3.3-70b`. Set `LLM_BACKEND=groq` or `anthropic` in `.env` before building.

**Cost:** 2 LLM calls per idea — not free. Watch Venice credits.

---

## What to expect

- **Good at:** Cross-industry pattern spotting, “where else could this live?”, fast pitch prep.
- **Not:** A business plan writer, financial model, or Play Store product (debug/personal builds).
- **Parsing is lenient:** If Venice returns odd headings, you may get fewer than 10 cards — re-run or shorten the idea.
- **Mic:** Works on Android; Windows speech depends on OS speech services.

---

## Repo layout

```
Refactor Room/              ← workspace root (open in Cursor)
├── AGENTS.md               ← agent briefing
├── STATE.md                ← ship status
└── refactor_room/          ← Flutter project
    ├── lib/api/prompts.dart   ← the product (do not surface in UI)
    ├── copy_to_beta_apps.ps1
    └── copy_to_windows_release.ps1
```

---

## Legacy names (ignore)

| Old | Now |
|-----|-----|
| Panoptes Lens | Folder/product codename |
| panoptes_lens | Package name → **refactor_room** |
| Think Tank (mobile) | **The Refactor Room** on screen |

Old folder `D:\dev\Panoptes Lens` can be deleted once you confirm this copy works.
