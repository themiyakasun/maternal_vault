import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import 'input_field_shell.dart';

/// One option in an [AppDropdownField].
///
/// Pairs the value the form actually carries with the string the user reads, so
/// the translated label never becomes the thing being stored.
@immutable
class AppDropdownItem<T> {
  const AppDropdownItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// A select field with its label above it, generic over what it selects.
///
/// Generic on purpose: the forms in this app choose enum values — education
/// level, blood group — and typing the field means a switch over the result
/// stays exhaustive instead of comparing translated strings.
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.hint,
    this.validator,
    this.enabled = true,
  });

  /// Caption shown above the field.
  final String label;

  final List<AppDropdownItem<T>> items;

  /// The currently selected value, or null for nothing chosen yet.
  final T? value;

  final ValueChanged<T?> onChanged;

  /// Placeholder shown while nothing is selected.
  final String? hint;

  final FormFieldValidator<T>? validator;

  /// False greys the field out and stops it opening.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: label,
      child: DropdownButtonFormField<T>(
        // Controlled from the caller: DropdownButtonFormField re-reads this on
        // update, so a parent holding the value in state stays in charge.
        initialValue: value,
        validator: validator,
        onChanged: enabled ? onChanged : null,
        // Long translated labels — the education levels in Sinhala and Tamil
        // especially — would overflow the menu's intrinsic width otherwise.
        isExpanded: true,
        style: AppTextStyles.bodyLg,
        icon: const Icon(
          Icons.expand_more_rounded,
          color: AppColors.onSurfaceVariant,
        ),
        hint: hint == null
            ? null
            : Text(
                hint!,
                style: AppTextStyles.bodyLg.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
        decoration: appFieldDecoration(),
        items: <DropdownMenuItem<T>>[
          for (final AppDropdownItem<T> item in items)
            DropdownMenuItem<T>(
              value: item.value,
              child: Text(item.label, overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
    );
  }
}
