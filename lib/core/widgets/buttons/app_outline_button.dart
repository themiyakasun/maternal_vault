import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../theme/app_theme.dart';
import 'app_button_tone.dart';

/// The app's secondary action — an outline, not a fill.
///
/// The sibling of [AppPrimaryButton]: same height and radius, but it reads as a
/// choice offered rather than the one being urged. [tone] tints the label and
/// border together, so a sage outline can sit under a sage fill without the two
/// disagreeing.
class AppOutlineButton extends StatelessWidget {
  const AppOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = AppButtonTone.primary,
    this.icon,
    this.expand = true,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;

  final AppButtonTone tone;

  final IconData? icon;

  /// Whether to stretch to the incoming width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = OutlinedButton.styleFrom(
      foregroundColor: tone.fill,
      disabledForegroundColor: AppButtonDisabled.foreground,
      // The border stays the neutral outline token rather than a tint of the
      // tone: at 1pt a coloured hairline reads as a stray line, and the label
      // already carries the tone.
      side: const BorderSide(color: AppColors.outlineVariant),
      minimumSize: expand
          ? null
          : const Size(AppSpacing.minTouchTarget, AppTheme.buttonHeight),
    );

    final Text text = Text(label, style: AppTextStyles.button);

    if (icon == null) {
      return OutlinedButton(onPressed: onPressed, style: style, child: text);
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon, size: 20),
      label: text,
    );
  }
}
