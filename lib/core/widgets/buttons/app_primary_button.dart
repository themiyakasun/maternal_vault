import 'package:flutter/material.dart';

import '../../constants/app_text_styles.dart';
import '../../theme/app_theme.dart';
import 'app_button_tone.dart';

/// The app's solid call-to-action.
///
/// Wraps [FilledButton] so a screen names what the button *is* — a primary
/// action in a given [tone] — instead of restating how it is painted. Height,
/// radius and type still come from [AppTheme.light]'s `filledButtonTheme`; only
/// the colour pair is applied here.
///
/// Pass [icon] for a leading glyph. A null [onPressed] renders disabled, which
/// is the resting state for actions still waiting on a backend.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
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

  /// Optional leading glyph, sized to sit with the label.
  final IconData? icon;

  /// Whether to stretch to the incoming width. False lets the button size to
  /// its label — for buttons sitting inline rather than pinned to a footer.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = FilledButton.styleFrom(
      backgroundColor: tone.fill,
      foregroundColor: tone.onFill,
      disabledBackgroundColor: AppButtonDisabled.background,
      disabledForegroundColor: AppButtonDisabled.foreground,
      // Overriding minimumSize would drop the theme's height, so only the
      // width half is relaxed when the button should hug its label.
      minimumSize: expand
          ? null
          : const Size(AppSpacing.minTouchTarget, AppTheme.buttonHeight),
    );

    final Text text = Text(label, style: AppTextStyles.button);

    if (icon == null) {
      return FilledButton(onPressed: onPressed, style: style, child: text);
    }
    return FilledButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon, size: 20),
      label: text,
    );
  }
}
