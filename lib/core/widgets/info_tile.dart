import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'cards/app_card.dart';

/// A card carrying one short piece of advice: a glyph, a heading, a line or two
/// beneath it.
///
/// The tip list on the partner's home — nutrition, a support suggestion, an
/// upcoming appointment — is a stack of these. The glyph sits in a neutral
/// rounded square so several in a row read as one calm list rather than a row of
/// competing colours; [accent] tints only the glyph.
class InfoTile extends StatelessWidget {
  const InfoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.accent = AppColors.primary,
  });

  final IconData icon;
  final String title;
  final String body;

  /// Colour of the glyph. The chip behind it stays neutral.
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTextStyles.bodyLg.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(body, style: AppTextStyles.bodySm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
