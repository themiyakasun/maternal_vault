import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// A rounded fill against a rounded track — one number from 0 to 1.
///
/// For a "how far along" bar where the framework's [LinearProgressIndicator]
/// would force the theme's rose fill; here [color] is the caller's, so the
/// baby-development bar can read in sage while [value] stays clamped to the
/// track rather than overflowing it.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.primary,
    this.trackColor,
    this.height = 8,
  });

  /// Fraction filled. Values outside 0..1 are clamped.
  final double value;

  final Color color;

  /// The unfilled remainder. Defaults to a hairline-grey track.
  final Color? trackColor;

  final double height;

  @override
  Widget build(BuildContext context) {
    final double fraction = value.clamp(0.0, 1.0);
    final BorderRadius radius = BorderRadius.circular(height);

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: height,
        color: trackColor ?? AppColors.outlineVariant.withValues(alpha: 0.5),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: fraction,
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, borderRadius: radius),
          ),
        ),
      ),
    );
  }
}
