import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// The partner app's header: who they are, the app's name, a way into settings.
///
/// A plain widget rather than an [AppBar], for the same reason the mother's
/// header is — the shell paints a gradient the whole way up, and an app bar
/// would drop its own surface colour over it. The brand sits in rose to echo the
/// welcome flow.
class PartnerAppBar extends StatelessWidget {
  const PartnerAppBar({super.key, this.onOpenSettings});

  /// Opens settings when tapped. The shell always supplies one (falling back to
  /// a notice), so the gear reads as live rather than disabled.
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.stackSm,
      ),
      child: Row(
        children: <Widget>[
          const AppAvatar(size: 32),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Text(
              l10n.partnerBrand,
              style: AppTextStyles.h3.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings_outlined, size: 22),
            tooltip: l10n.actionSettings,
            style: IconButton.styleFrom(
              foregroundColor: AppColors.onSurfaceVariant,
              disabledForegroundColor: AppColors.onSurfaceVariant.withValues(
                alpha: 0.38,
              ),
              minimumSize: const Size.square(AppSpacing.minTouchTarget),
            ),
          ),
        ],
      ),
    );
  }
}
