import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// The Maternal Vault mark on its white disc, with the splash's entrance and
/// idle motion.
///
/// Two layers of motion combine:
///  * an entrance — the disc scales up from 82% with a soft overshoot and fades
///    in, driven by [entrance];
///  * an idle pulse — a halo ring behind the disc expands and fades on a loop,
///    giving the mark a slow heartbeat, driven by [pulse].
class AnimatedLogo extends StatelessWidget {
  const AnimatedLogo({
    super.key,
    required this.entrance,
    required this.pulse,
    this.size = 200,
  });

  /// Entrance progress, 0 → 1. Expected to already carry its own curve.
  final Animation<double> entrance;

  /// Idle halo progress, repeating 0 → 1.
  final Animation<double> pulse;

  /// Diameter of the white disc.
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[entrance, pulse]),
      builder: (BuildContext context, Widget? child) {
        final double enter = entrance.value.clamp(0.0, 1.0);
        final double halo = pulse.value.clamp(0.0, 1.0);

        return Opacity(
          opacity: enter,
          child: Transform.scale(
            // 0.82 → 1.0, tracking the entrance curve's overshoot.
            scale: 0.82 + 0.18 * entrance.value,
            child: SizedBox.square(
              // Room for the halo to breathe outside the disc.
              dimension: size * 1.5,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  // Halo — expands outward and fades as it grows.
                  Opacity(
                    opacity: (1 - halo) * 0.45 * enter,
                    child: Container(
                      width: size * (1 + 0.34 * halo),
                      height: size * (1 + 0.34 * halo),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryFixedDim,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  // A second, tighter glow that fills rather than outlines.
                  Container(
                    width: size * 1.12,
                    height: size * 1.12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryFixed
                          .withValues(alpha: 0.28 * (1 - halo) * enter),
                    ),
                  ),
                  // The disc itself. Clipped to its circle because the source
                  // logo ships with an opaque white background — without this
                  // its square corners paint over the disc's edge.
                  Container(
                    width: size,
                    height: size,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cardSurface,
                      boxShadow: AppColors.shadowInteractive,
                    ),
                    padding: EdgeInsets.all(size * 0.08),
                    child: child,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      // Built once and reused across every frame — the image never rebuilds.
      child: Image.asset(
        'assets/images/splash_logo.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
      ),
    );
  }
}
