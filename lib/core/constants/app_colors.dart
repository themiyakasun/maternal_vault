import 'package:flutter/material.dart';

/// Nurture Core colour tokens.
///
/// Values mirror the design system frontmatter verbatim. Prefer reading colours
/// from `Theme.of(context).colorScheme`; use these constants directly only for
/// tokens the [ColorScheme] has no slot for.
abstract final class AppColors {
  // Surfaces
  static const Color surface = Color(0xFFF9F9FF);
  static const Color surfaceDim = Color(0xFFD0DAEF);
  static const Color surfaceBright = Color(0xFFF9F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF3FF);
  static const Color surfaceContainer = Color(0xFFE6EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDEE9FD);
  static const Color surfaceContainerHighest = Color(0xFFD9E3F7);
  static const Color onSurface = Color(0xFF121C2A);
  static const Color onSurfaceVariant = Color(0xFF524346);
  static const Color inverseSurface = Color(0xFF273140);
  static const Color inverseOnSurface = Color(0xFFEBF1FF);

  /// Retained for reference; superseded by [surface] in Material 3.
  static const Color background = Color(0xFFF9F9FF);
  static const Color onBackground = Color(0xFF121C2A);
  static const Color surfaceVariant = Color(0xFFD9E3F7);

  // Outlines
  static const Color outline = Color(0xFF847376);
  static const Color outlineVariant = Color(0xFFD6C1C5);

  // Primary — Soft Rose
  static const Color surfaceTint = Color(0xFF8B4B5D);
  static const Color primary = Color(0xFF8B4B5D);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFE89AAE);
  static const Color onPrimaryContainer = Color(0xFF6A3042);
  static const Color inversePrimary = Color(0xFFFFB1C4);

  // Secondary — Sage Green
  static const Color secondary = Color(0xFF446647);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFC5EDC4);
  static const Color onSecondaryContainer = Color(0xFF496D4C);

  // Tertiary — Sky Blue
  static const Color tertiary = Color(0xFF21648B);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF7BB6E1);
  static const Color onTertiaryContainer = Color(0xFF004769);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Fixed accents — tonal pairs that stay constant across light and dark.
  static const Color primaryFixed = Color(0xFFFFD9E1);
  static const Color primaryFixedDim = Color(0xFFFFB1C4);
  static const Color onPrimaryFixed = Color(0xFF39081B);
  static const Color onPrimaryFixedVariant = Color(0xFF6F3445);
  static const Color secondaryFixed = Color(0xFFC5EDC4);
  static const Color secondaryFixedDim = Color(0xFFA9D0A9);
  static const Color onSecondaryFixed = Color(0xFF002108);
  static const Color onSecondaryFixedVariant = Color(0xFF2C4E30);
  static const Color tertiaryFixed = Color(0xFFC9E6FF);
  static const Color tertiaryFixedDim = Color(0xFF92CDF9);
  static const Color onTertiaryFixed = Color(0xFF001E2F);
  static const Color onTertiaryFixedVariant = Color(0xFF004B6F);

  // Semantic aliases — role names used across the app.
  /// Health-positive data: wellness trends, toggles and checkboxes when on.
  static const Color health = secondary;

  /// Baby / health target series in charts.
  static const Color chartBaby = secondary;

  /// Mother data series in charts.
  static const Color chartMother = primary;

  /// Information architecture: nav icons and active navigation states.
  static const Color accentInfo = tertiary;

  /// Elevated card surface — pure white, lifted off the tinted background.
  static const Color cardSurface = surfaceContainerLowest;

  // Elevation shadows
  /// Level 1 — content cards. Blur 12, Y 4, 4% black.
  static const List<BoxShadow> shadowCard = <BoxShadow>[
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// Level 2 — FABs and active modals. Blur 20, Y 8, 8% primary.
  static const List<BoxShadow> shadowInteractive = <BoxShadow>[
    BoxShadow(
      color: Color(0x148B4B5D),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  /// The standard page backdrop — a barely-there rose wash, warmer at the top
  /// and bottom than in the middle. Apply it through `BrandBackdrop` rather
  /// than hand-rolling a [DecoratedBox] per screen.
  ///
  /// The splash keeps its own gradient: it carries the illustration behind the
  /// mark and needs different stops to clear it.
  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Color(0xFFFDF4F6),
      Color(0xFFFCFAFE),
      Color(0xFFFBF5F7),
    ],
    stops: <double>[0.0, 0.5, 1.0],
  );
}
