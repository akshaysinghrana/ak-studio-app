import 'package:flutter/material.dart';

/// Small design-token layer (spec 12): colour seed, spacing, radii and player
/// control sizing live here so screens stay consistent.
abstract final class AppTokens {
  static const seed = Color(0xFF3D7BFD);

  static const spaceXs = 4.0;
  static const spaceS = 8.0;
  static const spaceM = 16.0;
  static const spaceL = 24.0;

  static const radiusM = 12.0;

  /// Minimum touch target for icon controls (spec 12: at least 48 dp).
  static const minTouchTarget = 48.0;
  static const thumbnailWidth = 112.0;
  static const miniPlayerHeight = 64.0;
}

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppTokens.seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppTokens.spaceM),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusM),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
