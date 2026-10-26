# AS Media

Local-first Flutter player for MP4 and MP3 files. Android only for now. The product and engineering source of truth is [MEDIA_PLAYER_SPEC.md](MEDIA_PLAYER_SPEC.md). Working rules are in [CLAUDE.md](CLAUDE.md).

**Status:** Phases 0–8 implemented (Android). The final on-device pass is pending; see [docs/testing/final-device-test-plan.md](docs/testing/final-device-test-plan.md). Decisions: ADRs [0001](docs/adr/0001-media-engine.md) (engine), [0002](docs/adr/0002-local-storage-and-media-access.md) (storage and media access), [0003](docs/adr/0003-auth-and-sync.md) (accounts and sync).

**Media engine:** [docs/adr/0001-media-engine.md](docs/adr/0001-media-engine.md). Device evidence: [docs/testing/phase1-device-results.md](docs/testing/phase1-device-results.md).

## Develop

```sh
flutter pub get
flutter analyze && flutter test
flutter run   # on a physical Android device
```

## Device tests (physical Android, ffmpeg on the host)

```sh
# On-device engine and zoom tests (generates and pushes synthetic media)
scripts/run_device_engine_tests.sh <device-id>

# Library against the real MediaStore (adds then removes Movies/Music/UMP_Test)
scripts/run_device_library_test.sh <device-id>

# OS lifecycle checks: lock, Home, media keys, PiP, battery saver, ...
D=/storage/emulated/0/Android/data/com.akshayrana.video_music_app/files/test_media
flutter build apk --debug --dart-define="UMP_DEBUG_AUTOLOAD=$D/ump_long.mp4;$D/ump_tone.mp3;$D/ump_portrait.mp4"
adb install -r build/app/outputs/flutter-apk/app-debug.apk
scripts/device_test_media.sh <device-id>
python3 -I scripts/device_lifecycle_checks.py <device-id> [check ...]
```

`UMP_DEBUG_AUTOLOAD` only works in debug builds.

## Release

Publish an App Bundle: `flutter build appbundle`. Play then delivers a per-ABI APK, so the 50 MB fat APK never reaches users.

Release signing reads `android/key.properties`, which is git-ignored and never committed:

```properties
storeFile=/absolute/path/to/upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

Without that file, release builds are signed with the debug key. Those builds are fine for local testing but must not be published.

## Release checklist

- [ ] Final device test plan passed
- [ ] Release keystore in `android/key.properties`
- [ ] Firebase configured (`flutterfire configure`), `firestore.rules` deployed, or accounts left unconfigured on purpose
- [ ] `docs/PRIVACY.md` completed and published; Play Data safety form filled in from it
- [ ] `flutter build appbundle` (per-device download is about 23–27 MB)

## Third-party patches

`third_party/audio_service` is a patched copy of `audio_service` 0.18.19 (MIT). Explicit PLAY/PAUSE media keys are made idempotent; see [UMP_PATCH.md](third_party/audio_service/UMP_PATCH.md).
