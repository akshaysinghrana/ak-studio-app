import 'package:drift/drift.dart';
import 'package:flutter/material.dart' show ThemeMode;

import '../../../shared/data/app_database.dart';

/// Typed access to `user_preferences` (spec 4.6, ADR 0002).
class PreferencesRepository {
  PreferencesRepository(this._db);

  final AppDatabase _db;

  static const continueVideoAudioKey =
      'playback.continueVideoAudioInBackground';
  static const themeModeKey = 'appearance.themeMode';

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
}
