import 'package:flutter/material.dart';

import '../../constants/app_text_styles.dart';
import 'input_field_shell.dart';

/// A single-line text field with its label above it.
///
/// The app's default text input. Wraps [TextFormField] so it validates inside a
/// [Form] like any other field, and leans on the theme for everything but the
/// fill (see [appFieldDecoration]).
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.enabled = true,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.sentences,
    this.maxLength,
    this.suffixText,
    this.textInputAction,
    this.onChanged,
  });

  /// Caption shown above the field.
  final String label;

  /// Placeholder shown while the field is empty.
  final String? hint;

  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;

  /// False greys the field out and stops it taking focus.
  final bool enabled;

  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  /// Caps how much can be typed. The character counter is suppressed — see
  /// [appFieldDecoration].
  final int? maxLength;

  /// Trailing unit, e.g. `cm` on a height field.
  final String? suffixText;

  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: label,
      child: TextFormField(
        controller: controller,
        validator: validator,
        enabled: enabled,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        maxLength: maxLength,
        textInputAction: textInputAction,
        onChanged: onChanged,
        style: AppTextStyles.bodyLg,
        decoration: appFieldDecoration(hint: hint, suffixText: suffixText),
      ),
    );
  }
}
