# STATE — The Refactor Room

**Last updated:** 2026-07-06  
**Status:** ✅ Done — rename complete, Windows + Android builds on shelf

---

## Shipped

| Platform | Artifact | Location |
|----------|----------|----------|
| **Windows** | Portable exe + zip v1.1.0 | `D:\Beta Apps\Refactor-Room\Windows\Refactor-Room-Windows-v1.1.0.zip` |
| **Android** | Debug APK v1.0.5 (pre-rename package) | `D:\Beta Apps\Refactor-Room-LATEST.apk` — rebuild v1.1.0 when JDK fixed |

**Version (code):** 1.1.0  
**On-screen label:** `v1.1.0 · transplants`  
**Backend:** Venice (Llama 3.3 70B), 2 calls per run

### Android rebuild note

`JAVA_HOME` points to a missing JDK on this machine (2026-07-06). Windows build succeeded. To refresh Android APK with new package id `com.aicc.refactor_room`:

1. Install JDK 17 (Eclipse Temurin) or point `JAVA_HOME` at Android Studio's `jbr`
2. `cd refactor_room && flutter build apk --debug && .\copy_to_beta_apps.ps1`

Phone can keep using v1.0.5 LATEST until then — same transplant pipeline, old package id.

---

## Rename complete

| Was | Now |
|-----|-----|
| `D:\dev\Panoptes Lens\panoptes_lens` | `D:\dev\Refactor Room\refactor_room` |
| Package `panoptes_lens` | `refactor_room` |
| Android `com.panoptes.panoptes_lens` | `com.aicc.refactor_room` |
| Windows exe `panoptes_lens.exe` | `refactor_room.exe` |

Old `D:\dev\Panoptes Lens` is a stale copy — safe to delete after smoke test.

---

## How to verify (2 min)

**Windows:** Run `refactor_room.exe` → enter short idea → two stages → 10+5 transplants.  
**Android:** Install LATEST → confirm `v1.1.0 · transplants` top-right.

---

## Not in scope (by design)

- Play Store / Microsoft Store listing
- Think Tank prompt export from Claude (separate task)
- Analysis history / persistence

---

## Cross off list

Refactor Room is **portfolio-complete** as a personal/consulting demo tool. Future work is optional polish only.
