import 'package:flutter/material.dart';

import '../constants/app_text_styles.dart';
import '../theme/app_theme.dart';

/// A small tinted pill stating a record's status — Term, Preterm, Alive.
///
/// A wash of [accent] rather than a solid fill: several of these can appear down
/// a list of cards, and at full strength they would out-shout the data they are
/// labelling.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.accent});

  final String label;

  /// Colour identity — carries the meaning, so pick from the semantic tokens
  /// (`AppColors.health` for a good outcome, `error` for a loss) rather than by
  /// looks.
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: AppRadii.pill,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.stackMd,
          vertical: AppSpacing.unit / 2,
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySm.copyWith(
            color: accent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
