import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/brand_logo_mark.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../splash/presentation/widgets/brand_wordmark.dart';

/// The lockup shared by all three welcome steps: logo, eyebrow, wordmark, and
/// the three value pills.
///
/// Reuses [BrandWordmark] from the splash so the brand reads identically across
/// the hand-off — the wordmark the user watched fade in is the same one that
/// greets them here, now under the same mark.
class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({super.key, this.compact = false});

  /// Tightens the type and spacing for short viewports.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        BrandLogoMark(size: compact ? 56 : 72),
        SizedBox(height: compact ? AppSpacing.stackSm : AppSpacing.stackMd),
        Text(
          l10n.welcomeEyebrow,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelCaps.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        BrandWordmark(fontSize: compact ? 30 : 36),
        SizedBox(height: compact ? AppSpacing.stackMd : AppSpacing.stackLg),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.stackSm,
          runSpacing: AppSpacing.stackSm,
          children: <Widget>[
            _ValueBadge(
              icon: Icons.lock_outline_rounded,
              label: l10n.badgeSecure,
              color: AppColors.primary,
            ),
            _ValueBadge(
              icon: Icons.favorite_outline_rounded,
              label: l10n.badgePersonal,
              color: AppColors.secondary,
            ),
            _ValueBadge(
              // A baby's face, not the stroller (`child_friendly`) — the pill is
              // about who the app is for, not about gear.
              icon: Icons.child_care_rounded,
              label: l10n.badgeMadeForYou,
              color: AppColors.tertiary,
            ),
          ],
        ),
      ],
    );
  }
}

class _ValueBadge extends StatelessWidget {
  const _ValueBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadii.pill,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelCaps.copyWith(
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
