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
    this.leadingAccent,
    this.accentWidth = 4,
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

  /// A stripe down the leading edge, full height. For a card in a list where the
  /// colour carries meaning — a past pregnancy's outcome, say — and a tinted fill
  /// would be too loud to repeat down the page. Null draws no stripe.
  final Color? leadingAccent;

  /// Thickness of the [leadingAccent] stripe.
  final double accentWidth;

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(padding: padding, child: child);

    if (leadingAccent != null) {
      content = ClipRRect(
        // The stripe runs to the card's edge, so it has to be clipped to the
        // same radius or its corners square off the rounded ones.
        borderRadius: borderRadius,
        child: Stack(
          children: <Widget>[
            // The padded content sizes the stack; the stripe is positioned
            // against that height. A Row with CrossAxisAlignment.stretch would
            // read cleaner but hands its children the incoming maxHeight, which
            // is unbounded inside a scroll view.
            content,
            PositionedDirectional(
              start: 0,
              top: 0,
              bottom: 0,
              width: accentWidth,
              child: ColoredBox(color: leadingAccent!),
            ),
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: borderWidth),
        boxShadow: boxShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: borderRadius,
        child: content,
      ),
    );
  }
}
