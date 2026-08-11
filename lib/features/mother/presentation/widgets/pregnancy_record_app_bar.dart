import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/brand_logo_mark.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// The header above every tab of the mother's record: the mark, the section's
/// name, then language and notifications.
///
/// A plain widget rather than an [AppBar]: the shell paints a gradient behind
/// the whole screen, and an app bar would lay its own surface colour over the
/// top of it.
class PregnancyRecordAppBar extends StatelessWidget {
  const PregnancyRecordAppBar({
    super.key,
    required this.title,
    required this.onChangeLanguage,
    this.onOpenNotifications,
  });

  /// What section you are in. Supplied by the shell rather than fixed here, so a
  /// tab that carries its own heading — Medical History — says so in the header
  /// instead of repeating the record's name.
  final String title;

  /// Opens the language sheet.
  final VoidCallback onChangeLanguage;

  /// TODO: build the notifications screen and pass it in. Null until then, which
  /// renders the bell disabled rather than tappable-but-inert.
  final VoidCallback? onOpenNotifications;

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
          const BrandLogoMark(size: 28),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.h3,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _HeaderAction(
            icon: Icons.language_rounded,
            label: l10n.actionChangeLanguage,
            onPressed: onChangeLanguage,
          ),
          _HeaderAction(
            icon: Icons.notifications_none_rounded,
            label: l10n.actionNotifications,
            onPressed: onOpenNotifications,
          ),
        ],
      ),
    );
  }
}

/// One glyph in the header, sized to the minimum touch target.
class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      tooltip: label,
      // Both colours are restated: styleFrom drops the theme's disabled pair as
      // soon as an enabled one is supplied, which would leave the not-yet-built
      // bell looking live.
      style: IconButton.styleFrom(
        foregroundColor: AppColors.onSurfaceVariant,
        disabledForegroundColor: AppColors.onSurfaceVariant.withValues(
          alpha: 0.38,
        ),
        minimumSize: const Size.square(AppSpacing.minTouchTarget),
      ),
    );
  }
}
