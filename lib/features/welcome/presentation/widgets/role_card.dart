import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

/// A tappable role option: a coloured spine down the left edge, a circular icon,
/// the role's name and what picking it sets up.
class RoleCard extends StatelessWidget {
  const RoleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;

  /// The card's colour identity — rose for the mother, sage for the partner.
  final Color accent;

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: AppRadii.cardRadius,
          // Lifts off the page only once chosen, so the two cards read as equal
          // choices until the user commits to one.
          boxShadow:
              selected ? AppColors.shadowInteractive : AppColors.shadowCard,
        ),
        child: Material(
          color: AppColors.cardSurface,
          borderRadius: AppRadii.cardRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: AppRadii.cardRadius,
                border: Border.all(
                  color: selected ? accent : AppColors.outlineVariant,
                  width: selected ? 2 : 1,
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // The spine. `stretch` above makes it run the card's full
                    // height without us having to measure anything.
                    Container(width: 6, color: accent),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.cardPadding),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accent.withValues(alpha: 0.12),
                              ),
                              child: Icon(icon, size: 23, color: accent),
                            ),
                            const SizedBox(width: AppSpacing.componentGap),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(title, style: AppTextStyles.h3),
                                  const SizedBox(height: 4),
                                  Text(
                                    body,
                                    style: AppTextStyles.bodySm.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.stackSm),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 22,
                              color: selected
                                  ? accent
                                  : AppColors.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
