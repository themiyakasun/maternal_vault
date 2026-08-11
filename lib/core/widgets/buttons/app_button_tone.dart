import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

/// Which of the brand's colour identities a button carries.
///
/// [primary] is the rose the app moves forward in. [secondary] is the sage that
/// marks partner-side actions, the same pairing the welcome flow's role cards
/// use to tell the two people apart.
enum AppButtonTone {
  primary(fill: AppColors.primary, onFill: AppColors.onPrimary),
  secondary(fill: AppColors.secondary, onFill: AppColors.onSecondary);

  const AppButtonTone({required this.fill, required this.onFill});

  /// Background for a solid button; label and glyph colour for an outlined one.
  final Color fill;

  /// Label colour on top of [fill].
  final Color onFill;
}

/// The disabled pair every button in the app greys out to.
///
/// Spelled out here rather than left to Material's defaults so a button that
/// overrides its enabled colours does not also lose its disabled ones — which
/// matters because screens waiting on a backend hook ship disabled.
abstract final class AppButtonDisabled {
  static final Color background = AppColors.onSurface.withValues(alpha: 0.12);
  static final Color foreground = AppColors.onSurface.withValues(alpha: 0.38);
}
