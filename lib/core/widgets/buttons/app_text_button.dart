import 'package:flutter/material.dart';

import '../../constants/app_text_styles.dart';
import '../../theme/app_theme.dart';
import 'app_button_tone.dart';

/// The app's lightest action — a label, no fill and no border.
///
/// The third of the three buttons, for something offered beside content rather
/// than at the foot of a form: Add next to a heading, Edit on a card. Where
/// [AppPrimaryButton] and [AppOutlineButton] stand a full 52pt tall, this one
/// keeps to the minimum touch target so it can sit on a heading row without
/// setting that row's height.
class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = AppButtonTone.primary,
    this.icon,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;

  final AppButtonTone tone;

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = TextButton.styleFrom(
      foregroundColor: tone.fill,
      disabledForegroundColor: AppButtonDisabled.foreground,
      minimumSize: const Size(
        AppSpacing.minTouchTarget,
        AppSpacing.minTouchTarget,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackSm),
    );

    final Text text = Text(label, style: AppTextStyles.button);

    if (icon == null) {
      return TextButton(onPressed: onPressed, style: style, child: text);
    }
    return TextButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon, size: 20),
      label: text,
    );
  }
}
