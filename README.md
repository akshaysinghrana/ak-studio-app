# Unified Media Player

Local-first Flutter player for MP4 and MP3 files. The product and engineering source of truth is [MEDIA_PLAYER_SPEC.md](MEDIA_PLAYER_SPEC.md). Working rules are in [CLAUDE.md](CLAUDE.md).

**Current state:** Phase 1 media-engine proof of concept, Android only. Engine decision: [docs/adr/0001-media-engine.md](docs/adr/0001-media-engine.md).

```sh
flutter pub get
flutter analyze && flutter test
flutter run          # physical Android device recommended (see docs/testing/phase1-device-checklist.md)
```
