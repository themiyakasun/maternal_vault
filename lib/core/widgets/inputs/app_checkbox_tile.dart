import 'package:flutter/material.dart';

/// A labelled checkbox whose whole row is the target, not just the 18pt box.
///
/// Built on [CheckboxListTile] rather than a hand-rolled [Row] + [InkWell] so the
/// row reports to a screen reader as one checkbox instead of as a button sitting
/// next to an unrelated checkbox, and so the fill, tick colour and corner radius
/// keep coming from `AppTheme.light`'s `checkboxTheme`.
///
/// Holds no state: [value] comes down and [onChanged] goes up, leaving the screen
/// the single source of truth for what the record says.
class AppCheckboxTile extends StatelessWidget {
  const AppCheckboxTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
  });

  final String label;

  final bool value;

  /// Handed the state the row should move to.
  final ValueChanged<bool> onChanged;

  /// Optional second line, for a condition whose name needs qualifying.
  final String? subtitle;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: enabled ? (bool? next) => onChanged(next ?? false) : null,
      title: Text(label),
      subtitle: subtitle == null ? null : Text(subtitle!),
      // The box leads, so a column of these lines up down the left edge.
      controlAffinity: ListTileControlAffinity.leading,
      // The card around this is already padded; the theme's own 16pt would indent
      // the row a second time.
      contentPadding: EdgeInsets.zero,
      // Tightens the row without going under the 44pt touch target.
      visualDensity: VisualDensity.compact,
    );
  }
}
