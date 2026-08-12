import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../theme/app_theme.dart';

/// A contact row with a call action: a coloured avatar, a role label over a
/// name, and a phone button.
///
/// [emphasized] turns the row into a filled [accent] block with white text —
/// for the one contact that matters most in a hurry. The rest sit as
/// hairline-outlined rows, [accent] carried only by the avatar, name and phone.
class ContactTile extends StatelessWidget {
  const ContactTile({
    super.key,
    required this.role,
    required this.name,
    required this.accent,
    this.avatarIcon,
    this.onCall,
    this.callTooltip,
    this.emphasized = false,
  });

  final String role;
  final String name;
  final Color accent;

  /// Glyph inside the avatar disc. Null leaves the disc a plain colour.
  final IconData? avatarIcon;

  final VoidCallback? onCall;
  final String? callTooltip;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final Color onFill = emphasized ? Colors.white : accent;
    final Color roleColor = emphasized
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: emphasized ? accent : AppColors.cardSurface,
        borderRadius: AppRadii.cardRadius,
        border: emphasized
            ? null
            : Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Row(
        children: <Widget>[
          _Avatar(accent: accent, icon: avatarIcon, emphasized: emphasized),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  role,
                  style: AppTextStyles.labelCaps.copyWith(color: roleColor),
                ),
                const SizedBox(height: 2),
                Text(name, style: AppTextStyles.h3.copyWith(color: onFill)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          IconButton(
            onPressed: onCall,
            tooltip: callTooltip,
            icon: Icon(Icons.call_rounded, color: onFill),
            style: IconButton.styleFrom(
              minimumSize: const Size.square(AppSpacing.minTouchTarget),
            ),
          ),
        ],
      ),
    );
  }
}

/// The leading disc: a person or glyph on [accent], or a translucent white ring
/// when the row is [emphasized] and already sits on that colour.
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.accent,
    required this.icon,
    required this.emphasized,
  });

  final Color accent;
  final IconData? icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: emphasized ? Colors.white.withValues(alpha: 0.2) : accent,
      ),
      alignment: Alignment.center,
      child: icon == null ? null : Icon(icon, size: 22, color: Colors.white),
    );
  }
}
