import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Nurture Core type scale.
///
/// Inter throughout, with heavy weight contrast between headings (600–700) and
/// body copy (400). Line heights are expressed as multipliers of the font size
/// so they scale with the user's text-size preference; the comment on each
/// style records the design spec in pixels.
abstract final class AppTextStyles {
  /// The single family used across the app.
  static const String fontFamily = 'Inter';

  /// Screen titles. 32/40, -0.02em.
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
    letterSpacing: -0.64,
    color: AppColors.onSurface,
  );

  /// Screen titles on compact widths. 28/36.
  static const TextStyle h1Mobile = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 36 / 28,
    color: AppColors.onSurface,
  );

  /// Card titles and vitals values. 24/32, -0.01em.
  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
    letterSpacing: -0.24,
    color: AppColors.onSurface,
  );

  /// Section headers. 20/28.
  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    color: AppColors.onSurface,
  );

  /// Primary reading size. 16/24.
  static const TextStyle bodyLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColors.onSurface,
  );

  /// Supporting copy and field labels. 14/20.
  static const TextStyle bodySm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AppColors.onSurfaceVariant,
  );

  /// Button labels. 16/24, SemiBold.
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
  );

  /// Metadata and in-card secondary headers. 12/16, +0.05em, uppercased at the
  /// call site (or via `TextTheme.labelSmall`).
  static const TextStyle labelCaps = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 0.6,
    color: AppColors.onSurfaceVariant,
  );

  /// Maps the design scale onto Material's [TextTheme] slots so framework
  /// widgets inherit it. Colours are left to [ThemeData] to resolve.
  static const TextTheme textTheme = TextTheme(
    displayLarge: h1,
    displayMedium: h1,
    displaySmall: h2,
    headlineLarge: h1,
    headlineMedium: h1Mobile,
    headlineSmall: h2,
    titleLarge: h2,
    titleMedium: h3,
    titleSmall: bodyLg,
    bodyLarge: bodyLg,
    bodyMedium: bodyLg,
    bodySmall: bodySm,
    labelLarge: button,
    labelMedium: bodySm,
    labelSmall: labelCaps,
  );
}
