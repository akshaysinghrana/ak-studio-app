import 'package:drift/drift.dart';
import 'package:flutter/material.dart' show ThemeMode;

import '../../../shared/data/app_database.dart';
import '../../player/domain/subtitles.dart';

/// Typed access to `user_preferences` (spec 4.6, ADR 0002).
class PreferencesRepository {
  PreferencesRepository(this._db);

  final AppDatabase _db;

  static const continueVideoAudioKey =
      'playback.continueVideoAudioInBackground';
  static const themeModeKey = 'appearance.themeMode';
  static const brightnessGestureKey = 'player.brightnessGesture';
  static const volumeGestureKey = 'player.volumeGesture';
  static const subtitleSizeKey = 'player.subtitleSize';
  static const youtubeApiKeyKey = 'online.youtubeApiKey';
  static const jamendoClientIdKey = 'online.jamendoClientId';
  static const downloadWifiOnlyKey = 'downloads.wifiOnly';
  static const downloadConcurrencyKey = 'downloads.concurrency';
  static const downloadAddToPlaylistKey = 'downloads.addToPlaylist';
  static const jamendoQualityKey = 'downloads.jamendoQuality';

  Stream<String?> _watch(String key) =>
      (_db.select(_db.userPreferences)..where((t) => t.key.equals(key)))
          .watchSingleOrNull()
          .map((row) => row?.value);

  Future<String?> _get(String key) async => (await (_db.select(
    _db.userPreferences,
  )..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> _set(String key, String value, {required bool syncEligible}) =>
      _db
          .into(_db.userPreferences)
          .insertOnConflictUpdate(
            UserPreferencesCompanion.insert(
              key: key,
              value: value,
              updatedAt: DateTime.now(),
              syncEligible: Value(syncEligible),
            ),
          );

  /// Spec 8.1: default off.
  Future<bool> continueVideoAudioInBackground() async =>
      await _get(continueVideoAudioKey) == 'true';

  Future<void> setContinueVideoAudioInBackground(bool value) =>
      _set(continueVideoAudioKey, '$value', syncEligible: true);

  /// Spec 12: dark theme by default.
  Stream<ThemeMode> watchThemeMode() =>
      _watch(themeModeKey)
          .map((v) => ThemeMode.values.asNameMap()[v] ?? ThemeMode.dark);

  Future<void> setThemeMode(ThemeMode mode) =>
      _set(themeModeKey, mode.name, syncEligible: true);

  /// Swipe gestures are off until the user enables them (spec 5.4). They
  /// are device-specific, so they never sync.
  Stream<bool> watchBrightnessGesture() =>
      _watch(brightnessGestureKey).map((v) => v == 'true');

  Future<void> setBrightnessGesture(bool on) =>
      _set(brightnessGestureKey, '$on', syncEligible: false);

  Stream<bool> watchVolumeGesture() =>
      _watch(volumeGestureKey).map((v) => v == 'true');

  Future<void> setVolumeGesture(bool on) =>
      _set(volumeGestureKey, '$on', syncEligible: false);

  Stream<SubtitleSize> watchSubtitleSize() => _watch(subtitleSizeKey)
      .map((v) => SubtitleSize.values.asNameMap()[v] ?? SubtitleSize.medium);

  Future<void> setSubtitleSize(SubtitleSize size) =>
      _set(subtitleSizeKey, size.name, syncEligible: true);

  /// Library view per tab: folders or all items (device-only).
  Stream<bool> watchFolderView(String tab) =>
      _watch('library.$tab.folderView').map((v) => v != 'false');

  Future<void> setFolderView(String tab, bool folders) =>
      _set('library.$tab.folderView', '$folders', syncEligible: false);

  /// Video list layout: grid (default) or list.
  Stream<bool> watchGridLayout() =>
      _watch('library.gridLayout').map((v) => v != 'false');

  Future<void> setGridLayout(bool grid) =>
      _set('library.gridLayout', '$grid', syncEligible: false);

  /// Remembered sort orders per library tab (device-only).
  Stream<String?> watchSort(String key) => _watch('library.sort.$key');

  Future<void> setSort(String key, String value) =>
      _set('library.sort.$key', value, syncEligible: false);

  // Online sources (ADR 0004). Credentials are device-only and never synced.

  Stream<String?> watchYoutubeApiKey() => _watch(youtubeApiKeyKey);

  Future<void> setYoutubeApiKey(String key) =>
      _set(youtubeApiKeyKey, key.trim(), syncEligible: false);

  Stream<String?> watchJamendoClientId() => _watch(jamendoClientIdKey);

  Future<void> setJamendoClientId(String id) =>
      _set(jamendoClientIdKey, id.trim(), syncEligible: false);

  // Downloads (ADR 0004): device-only.

  Stream<bool> watchDownloadWifiOnly() =>
      _watch(downloadWifiOnlyKey).map((v) => v == 'true');

  Future<bool> downloadWifiOnly() async =>
      await _get(downloadWifiOnlyKey) == 'true';

  Future<void> setDownloadWifiOnly(bool on) =>
      _set(downloadWifiOnlyKey, '$on', syncEligible: false);

  /// Simultaneous downloads, 1–3 (default 2).
  Stream<int> watchDownloadConcurrency() =>
      _watch(downloadConcurrencyKey)
          .map((v) => (int.tryParse(v ?? '') ?? 2).clamp(1, 3));

  Future<int> downloadConcurrency() async =>
      (int.tryParse(await _get(downloadConcurrencyKey) ?? '') ?? 2).clamp(1, 3);

  Future<void> setDownloadConcurrency(int n) =>
      _set(downloadConcurrencyKey, '${n.clamp(1, 3)}', syncEligible: false);

  /// Adds finished downloads to the "Downloads" playlist (default on).
  Stream<bool> watchDownloadAddToPlaylist() =>
      _watch(downloadAddToPlaylistKey).map((v) => v != 'false');

  Future<bool> downloadAddToPlaylist() async =>
      await _get(downloadAddToPlaylistKey) != 'false';

  Future<void> setDownloadAddToPlaylist(bool on) =>
      _set(downloadAddToPlaylistKey, '$on', syncEligible: false);

  /// Jamendo download format: `mp32` (VBR high, default) or `mp31` (96 kbps).
  Stream<String> watchJamendoQuality() =>
      _watch(jamendoQualityKey).map((v) => v == 'mp31' ? 'mp31' : 'mp32');

  Future<String> jamendoQuality() async =>
      await _get(jamendoQualityKey) == 'mp31' ? 'mp31' : 'mp32';

  Future<void> setJamendoQuality(String format) =>
      _set(jamendoQualityKey, format, syncEligible: false);
}
