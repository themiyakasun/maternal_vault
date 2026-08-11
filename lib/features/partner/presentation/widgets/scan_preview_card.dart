import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cards/app_card.dart';

/// The viewfinder placeholder on the partner's connect screen: a sage-framed
/// square with corner brackets and a QR glyph, plus a status chip straddling
/// its bottom edge.
///
/// Drawn entirely in code rather than shipped as an image, so it recolours with
/// the tokens and stays crisp at any size. When the camera lands, the centre
/// becomes the preview texture and the brackets stay exactly where they are.
class ScanPreviewCard extends StatelessWidget {
  const ScanPreviewCard({super.key, required this.statusLabel});

  /// Copy for the chip on the bottom edge, e.g. "Ready to scan".
  final String statusLabel;

  /// How far the chip hangs below the frame. The parent must leave this much
  /// room underneath, since the [Stack] does not clip it.
  static const double chipOverhang = 20;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: chipOverhang),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1.05,
            child: AppCard(
              color: AppColors.secondary.withValues(alpha: 0.06),
              borderColor: AppColors.secondaryContainer,
              borderWidth: 2,
              // Flat and edge-to-edge: this is a viewfinder, not a card lifted
              // off the page, and the brackets have to reach the corners.
              boxShadow: const <BoxShadow>[],
              padding: EdgeInsets.zero,
              child: Stack(
                children: <Widget>[
                  const Center(
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: 88,
                      color: AppColors.secondary,
                    ),
                  ),
                  for (final Alignment corner in <Alignment>[
                    Alignment.topLeft,
                    Alignment.topRight,
                    Alignment.bottomLeft,
                    Alignment.bottomRight,
                  ])
                    Align(
                      alignment: corner,
                      child: _CornerBracket(corner: corner),
                    ),
                ],
              ),
            ),
          ),
          // Sits half off the bottom edge, so the frame reads as the subject
          // and the chip as a label attached to it.
          Positioned(
            bottom: -chipOverhang,
            child: _StatusChip(label: statusLabel),
          ),
        ],
      ),
    );
  }
}

/// One L-shaped viewfinder corner, built from the two [Border] sides that meet
/// at [corner] plus a matching rounded corner — cheaper and sharper than a
/// [CustomPaint] for four static marks.
class _CornerBracket extends StatelessWidget {
  const _CornerBracket({required this.corner});

  final Alignment corner;

  static const double _size = 30;
  static const double _thickness = 3;
  static const double _inset = 14;
  static const Radius _radius = Radius.circular(AppRadii.base);

  @override
  Widget build(BuildContext context) {
    final bool top = corner.y < 0;
    final bool left = corner.x < 0;
    const BorderSide side = BorderSide(
      color: AppColors.secondary,
      width: _thickness,
    );

    return Padding(
      padding: const EdgeInsets.all(_inset),
      child: SizedBox(
        width: _size,
        height: _size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: top ? side : BorderSide.none,
              bottom: top ? BorderSide.none : side,
              left: left ? side : BorderSide.none,
              right: left ? BorderSide.none : side,
            ),
            borderRadius: BorderRadius.only(
              topLeft: top && left ? _radius : Radius.zero,
              topRight: top && !left ? _radius : Radius.zero,
              bottomLeft: !top && left ? _radius : Radius.zero,
              bottomRight: !top && !left ? _radius : Radius.zero,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderRadius: AppRadii.pill,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Text(
            label,
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.onSurface,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
