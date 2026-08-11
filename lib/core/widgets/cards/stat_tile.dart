import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../theme/app_theme.dart';
import 'app_card.dart';

/// One read-only figure from the record: a tinted glyph, what it is, and what it
/// says.
///
/// A null [value] renders an em-dash rather than a zero or a blank, so a record
/// that has not been filled in yet reads as empty instead of as measured-and-nil
/// — which for a blood group or a BMI is a meaningful difference.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.unit,
  });

  final IconData icon;

  /// What the figure is, e.g. "Blood Group".
  final String label;

  /// The figure itself. Null means the record has no value for it yet.
  final String? value;

  /// Colour identity for the glyph chip.
  final Color accent;

  /// Trailing unit, set smaller than the value, e.g. `cm`. Dropped when [value]
  /// is null — a unit next to an em-dash reads as a measurement that failed.
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final bool empty = value == null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRadii.md),
              ),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Text(
            label,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              style: empty
                  ? AppTextStyles.h2.copyWith(color: AppColors.onSurfaceVariant)
                  : AppTextStyles.h2,
              children: <InlineSpan>[
                TextSpan(text: empty ? '—' : value),
                if (!empty && unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
