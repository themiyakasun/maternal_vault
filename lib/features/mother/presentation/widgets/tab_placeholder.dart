import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Stands in for a tab whose screen has not been designed yet.
///
/// Shared by all four so they read as one consistent "not yet" rather than four
/// different degrees of emptiness, and so the bottom bar can be fully navigable
/// while the sections behind it are still being built.
class TabPlaceholder extends StatelessWidget {
  const TabPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.accent,
  });

  final IconData icon;

  /// The tab's own name, so it is obvious which section you landed in.
  final String title;

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sectionGap),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.10),
              ),
              child: Icon(icon, size: 32, color: accent),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Text(title, style: AppTextStyles.h3, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(
              l10n.tabComingSoon,
              style: AppTextStyles.labelCaps.copyWith(color: accent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              l10n.tabComingSoonBody,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
