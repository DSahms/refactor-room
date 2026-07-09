# HANDOFF — The Refactor Room

> Start with **`AGENTS.md`** and **`STATE.md`**.

## Current (2026-07-06)

- Renamed from Panoptes Lens → **Refactor Room** / package **refactor_room**
- Two-stage pipeline: skeleton → transplants (10 ranked + 5 bonus)
- **Windows release** build + portable zip script
- **Android debug** APK copy script
- Full install/usage docs in `refactor_room/README.md`

## Run from source

```powershell
cd "D:\dev\Refactor Room\refactor_room"
flutter pub get
flutter run -d windows   # or -d <android-device>
```

Requires `.env` with `VENICE_API_KEY` (or set `LLM_BACKEND`).

## Shelf paths

- Android: `D:\Beta Apps\Refactor-Room-LATEST.apk`
- Windows: `D:\Beta Apps\Refactor-Room\Windows\Refactor-Room-Windows-v1.1.0.zip`

## Resolved

- ~~Three-stage lens pipeline~~ → removed
- ~~Folder named Panoptes Lens~~ → Refactor Room
- ~~Windows build~~ → release + copy script
