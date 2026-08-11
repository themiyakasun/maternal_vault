import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../theme/app_theme.dart';
import 'input_field_shell.dart';

/// A date field with its label above it: read-only, opening the platform date
/// picker when tapped.
///
/// The value is never typed. Dates in a health record are the kind of thing that
/// gets transposed when typed by hand, and a picker also sidesteps the question
/// of which order the parts go in — which differs by locale.
///
/// The chosen date is rendered with [MaterialLocalizations.formatCompactDate],
/// so it reads the way the current locale writes dates without this widget
/// knowing anything about formats.
class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.validator,
    this.enabled = true,
    this.firstDate,
    this.lastDate,
    this.icon,
  });

  /// Caption shown above the field.
  final String label;

  /// The currently chosen date, or null for nothing chosen yet.
  final DateTime? value;

  final ValueChanged<DateTime?> onChanged;

  /// Placeholder shown while no date is chosen.
  final String? hint;

  final FormFieldValidator<DateTime>? validator;

  /// False greys the field out and stops the picker opening.
  final bool enabled;

  /// Earliest selectable date. Defaults to two years back — wide enough for a
  /// registration or last-period date, narrow enough that the picker opens near
  /// where the answer is.
  final DateTime? firstDate;

  /// Latest selectable date. Defaults to two years ahead, which covers a due
  /// date.
  final DateTime? lastDate;

  /// Optional glyph inside the leading edge of the field. For a screen with
  /// several dates in a row, where the labels alone take a moment to tell apart.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations material = MaterialLocalizations.of(context);

    return LabeledField(
      label: label,
      child: FormField<DateTime>(
        initialValue: value,
        validator: validator,
        builder: (FormFieldState<DateTime> field) {
          final DateTime? chosen = field.value;
          final bool empty = chosen == null;

          return InkWell(
            onTap: enabled ? () => _pick(context, field) : null,
            borderRadius: AppRadii.cardRadius,
            child: InputDecorator(
              decoration: appFieldDecoration(
                prefixIcon: icon == null
                    ? null
                    : Icon(
                        icon,
                        size: 20,
                        color: AppColors.onSurfaceVariant,
                      ),
                suffixIcon: const Icon(
                  Icons.calendar_today_rounded,
                  size: 20,
                  color: AppColors.onSurfaceVariant,
                ),
              ).copyWith(errorText: field.errorText, enabled: enabled),
              // The placeholder is drawn as the child rather than handed over as
              // `hintText`: with no floating label there is nothing for Material
              // to hinge hint visibility on, so this keeps it predictable.
              child: Text(
                empty ? (hint ?? '') : material.formatCompactDate(chosen),
                style: AppTextStyles.bodyLg.copyWith(
                  color: empty
                      ? AppColors.onSurfaceVariant
                      : AppColors.onSurface,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    FormFieldState<DateTime> field,
  ) async {
    final DateTime now = DateTime.now();
    final DateTime first =
        firstDate ?? DateTime(now.year - 2, now.month, now.day);
    final DateTime last =
        lastDate ?? DateTime(now.year + 2, now.month, now.day);

    // showDatePicker asserts on an initial date outside the range, which a
    // caller narrowing the window past today would otherwise trip.
    DateTime initial = field.value ?? now;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );

    if (picked == null) return;
    // Keeps the FormField's own value in step with the caller's — the field
    // repaints from `field.value`, the caller stores what it was given.
    field.didChange(picked);
    onChanged(picked);
  }
}
