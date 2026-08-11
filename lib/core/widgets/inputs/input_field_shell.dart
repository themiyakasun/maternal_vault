import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../theme/app_theme.dart';

/// The label-above-field arrangement every input in this folder shares.
///
/// The label sits outside the field rather than inside it as a Material
/// floating label: the forms in this app are long and read as a checklist, and
/// a caption that never moves is easier to scan than one that animates away as
/// soon as there is a value.
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTextStyles.bodySm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        child,
      ],
    );
  }
}

/// The decoration every input in this folder hands to its Material field.
///
/// Radius, padding, and the five border states all come from the theme
/// ([AppTheme.light]'s `inputDecorationTheme`). Only two things are restated
/// here:
///
/// * **fill** — the theme fills fields with `cardSurface`, pure white, which
///   vanishes on the white cards these sit inside. The off-white `surface`
///   token keeps a field looking like a field.
/// * **counter** — [maxLength] is used to cap input, not to invite counting, so
///   the character counter Material would otherwise add is suppressed.
InputDecoration appFieldDecoration({
  String? hint,
  String? suffixText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    suffixText: suffixText,
    suffixIcon: suffixIcon,
    fillColor: AppColors.surface,
    counterText: '',
  );
}
