# Start this project in Claude Code

1. Copy `MEDIA_PLAYER_SPEC.md` and `CLAUDE.md` into the root of the Flutter repository.
2. Open Claude Code from that repository root.
3. Paste this prompt:

> Read `CLAUDE.md` and `MEDIA_PLAYER_SPEC.md` completely. First inspect this repository, current Git changes, Flutter/Dart toolchain, dependencies and Android/iOS configuration. Do not edit or delete existing user work. Report the current baseline (`flutter doctor -v`, `flutter pub get`, `flutter analyze`, existing tests/build where possible), then propose a phased implementation plan mapped to the acceptance criteria in the spec. Start with Phase 1's smallest media-engine proof of concept: MP3 playback plus MP4 playback, 10-second seek, video zoom feasibility, true frame screenshot feasibility, and especially MP4 audio continuing when the phone is locked with the setting enabled on a physical Android device and iPhone when available. Compare viable player-stack options, verify current package compatibility/licenses, and write ADR 0001 before choosing. Do not build all screens first or claim background playback works without device evidence. Implement only the next phase, run tests and analyze, and summarize exact files changed, results, blockers, and the next phase.

4. If Firebase is selected, create/configure the Firebase project and FlutterFire settings when prompted. Never paste service-account private keys into source code.
5. Keep the spec in the repository and update it only when a deliberate product decision changes. Record technical decisions in `docs/adr/`.
