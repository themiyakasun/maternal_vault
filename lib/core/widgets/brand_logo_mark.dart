import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// The Maternal Vault mark on its white disc, static.
///
/// The disc is clipped rather than merely shaped: the source PNG ships with an
/// opaque white background, and `BoxShape.circle` only shapes a container's own
/// fill — without the clip the image's square corners paint over the disc edge.
///
/// The splash's [AnimatedLogo] keeps its own copy of this arrangement because it
/// rebuilds every frame and holds the image subtree constant across rebuilds.
class BrandLogoMark extends StatelessWidget {
  const BrandLogoMark({
    super.key,
    this.size = 64,
    this.boxShadow = AppColors.shadowCard,
  });

  /// Diameter of the disc.
  final double size;

  final List<BoxShadow> boxShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.cardSurface,
        boxShadow: boxShadow,
      ),
      padding: EdgeInsets.all(size * 0.08),
      child: Image.asset(
        'assets/images/splash_logo.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
      ),
    );
  }
}
