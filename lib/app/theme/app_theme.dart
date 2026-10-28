import 'package:flutter/material.dart';

/// Brand palette taken from the AS Media icon: deep navy with an electric
/// blue → cyan gradient.
abstract final class AppColors {
  static const navy0 = Color(0xFF030716);
  static const navy1 = Color(0xFF071233);
  static const surface = Color(0xFF0C1638);
  static const surfaceHigh = Color(0xFF132050);
  static const surfaceHighest = Color(0xFF1A2A63);
  static const blueDeep = Color(0xFF2443FF);
  static const blue = Color(0xFF2E7BFF);
  static const cyan = Color(0xFF3CE1FF);
  static const text = Color(0xFFEAF0FF);
  static const textMuted = Color(0xFF9AA8D6);
  static const outline = Color(0x1FFFFFFF);

  static const brand = LinearGradient(
    colors: [blueDeep, blue, cyan],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  /// Accent pairs for icon badges and generated artwork.
  static const accents = <List<Color>>[
    [Color(0xFF2443FF), Color(0xFF3CE1FF)],
    [Color(0xFF7B2FFF), Color(0xFF2E7BFF)],
    [Color(0xFFFF3D8B), Color(0xFF7B2FFF)],
    [Color(0xFF00C2A8), Color(0xFF3CE1FF)],
    [Color(0xFFFF8A3D), Color(0xFFFF3D8B)],
    [Color(0xFF2E7BFF), Color(0xFF00C2A8)],
  ];
}

/// Small design-token layer (spec 12): spacing, radii and player sizing.
abstract final class AppTokens {
  static const seed = AppColors.blue;

  static const spaceXs = 4.0;
  static const spaceS = 8.0;
  static const spaceM = 16.0;
  static const spaceL = 24.0;

  static const radiusS = 12.0;
  static const radiusM = 18.0;
  static const radiusL = 24.0;

  /// Minimum touch target for icon controls (spec 12: at least 48 dp).
  static const minTouchTarget = 48.0;
  static const thumbnailWidth = 112.0;
  static const miniPlayerHeight = 68.0;
}

abstract final class AppTheme {
  static const fontFamily = 'Poppins';

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.blue,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF173A99),
      onPrimaryContainer: AppColors.text,
      secondary: AppColors.cyan,
      onSecondary: Color(0xFF002630),
      secondaryContainer: Color(0xFF103C55),
      onSecondaryContainer: AppColors.text,
      tertiary: AppColors.cyan,
      onTertiary: Color(0xFF002630),
      error: Color(0xFFFF6B7A),
      onError: Colors.white,
      errorContainer: Color(0xFF5A1622),
      onErrorContainer: Color(0xFFFFDADF),
      surface: AppColors.surface,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.textMuted,
      surfaceContainerLowest: AppColors.navy0,
      surfaceContainerLow: AppColors.navy1,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surfaceHigh,
      surfaceContainerHighest: AppColors.surfaceHighest,
      outline: Color(0x40FFFFFF),
      outlineVariant: AppColors.outline,
      inverseSurface: AppColors.text,
      onInverseSurface: AppColors.navy1,
      inversePrimary: AppColors.blueDeep,
      shadow: Colors.black,
      scrim: Colors.black,
    );
    return _build(scheme);
  }

  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.blue,
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF1F5BFF),
          tertiary: const Color(0xFF0098C7),
          surface: const Color(0xFFFFFFFF),
          surfaceContainerHigh: const Color(0xFFEDF2FF),
          surfaceContainerHighest: const Color(0xFFE2E9FF),
        );
    return _build(scheme);
  }

  static TextStyle _style(double size, FontWeight weight, Color? color) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: weight,
        color: color,
      );

  static ThemeData _build(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    final base = ThemeData(
      colorScheme: scheme,
      fontFamily: fontFamily,
      useMaterial3: true,
    );
    final text = base.textTheme.copyWith(
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusM),
      side: BorderSide(color: scheme.outlineVariant),
    );
    return base.copyWith(
      textTheme: text,
      // Pages are transparent over the app backdrop (see AppBackdrop).
      scaffoldBackgroundColor: Colors.transparent,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        // Theme text styles have no sizes until localized, so styles captured
        // here set them explicitly.
        titleTextStyle: _style(24, FontWeight.w700, scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface.withValues(alpha: dark ? 0.72 : 0.95),
        elevation: 0,
        shape: cardShape,
        margin: EdgeInsets.zero,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceM,
        ),
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: _style(15, FontWeight.w500, scheme.onSurface),
        subtitleTextStyle: _style(
          12.5,
          FontWeight.w400,
          scheme.onSurfaceVariant,
        ).copyWith(height: 1.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusS),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: dark ? AppColors.navy1 : scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.primary.withValues(alpha: dark ? 0.28 : 0.16),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusS),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => _style(
            12,
            s.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            s.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusS),
          ),
          textStyle: _style(15, FontWeight.w600, null),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusS),
          ),
          textStyle: _style(15, FontWeight.w600, null),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: scheme.primary.withValues(alpha: 0.25),
          selectedForegroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusS),
          ),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outlineVariant)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusM),
          ),
        ),
        hintStyle: WidgetStatePropertyAll(
          _style(15, FontWeight.w400, scheme.onSurfaceVariant),
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.onSurface.withValues(alpha: 0.15),
        thumbColor: dark ? Colors.white : scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.2),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.onSurface.withValues(alpha: 0.12),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.primary : null,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusS),
        ),
        labelStyle: _style(14, FontWeight.w600, null),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusS),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        textStyle: _style(14, FontWeight.w400, scheme.onSurface),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: dark ? AppColors.surface : scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusL),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? AppColors.surface : scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusL),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? AppColors.surfaceHighest : null,
        contentTextStyle: _style(
          14,
          FontWeight.w400,
          dark ? AppColors.text : null,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusS),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
