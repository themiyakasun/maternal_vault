import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'cards/app_card.dart';

/// A tappable to-do row: a check circle, a title with one line under it, a
/// chevron.
///
/// The whole card toggles [done] via [onToggle], not just the circle, so it is
/// an easy target. When done the circle fills and the title is struck through,
/// so a glance down the list separates finished from not.
class ChecklistTile extends StatelessWidget {
  const ChecklistTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.done,
    this.onToggle,
  });

  final String title;
  final String subtitle;
  final bool done;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onToggle,
          borderRadius: AppRadii.cardRadius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Row(
              children: <Widget>[
                _CheckCircle(done: done),
                const SizedBox(width: AppSpacing.stackMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppTextStyles.bodyLg.copyWith(
                          fontWeight: FontWeight.w600,
                          color: done
                              ? AppColors.onSurfaceVariant
                              : AppColors.onSurface,
                          decoration: done
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTextStyles.bodySm),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.stackSm),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The tick target: an outlined ring until [done], then a filled disc with a
/// check.
class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.secondary : Colors.transparent,
        border: Border.all(
          color: done ? AppColors.secondary : AppColors.outline,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: done
          ? const Icon(
              Icons.check_rounded,
              size: 16,
              color: AppColors.onSecondary,
            )
          : null,
    );
  }
}
