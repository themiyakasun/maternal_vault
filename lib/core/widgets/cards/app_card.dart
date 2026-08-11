import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../theme/app_theme.dart';

/// A white surface lifted off the page — the app's one card primitive.
///
/// Everything else in this folder is an [AppCard] with a particular header or
/// body arrangement, so the radius, fill and shadow are decided once here rather
/// than re-derived per screen.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.color = AppColors.cardSurface,
    this.borderColor,
    this.borderWidth = 1,
    this.boxShadow = AppColors.shadowCard,
    this.borderRadius = AppRadii.cardRadius,
  });

  final Widget child;

  final EdgeInsetsGeometry padding;

  final Color color;

  /// Null draws no border at all, which is what a shadowed card wants; pass a
  /// colour for the flatter, hairline-outlined surfaces that sit inside one.
  final Color? borderColor;

  final double borderWidth;

  final List<BoxShadow> boxShadow;

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: borderWidth),
        boxShadow: boxShadow,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
