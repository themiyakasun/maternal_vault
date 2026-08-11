import 'package:flutter/material.dart';

/// A yes/no question with a switch for an answer: label on the left, control on
/// the right, whole row tappable.
///
/// The counterpart to [AppCheckboxTile] — same contract, different affordance. A
/// switch is for a setting that takes effect the moment it moves; a checkbox is
/// for ticking items off a list. Built on [SwitchListTile] for the same reasons:
/// merged semantics, and the thumb and track colours stay with
/// `AppTheme.light`'s `switchTheme`.
class AppSwitchTile extends StatelessWidget {
  const AppSwitchTile({
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

  /// Optional second line, for a question whose wording needs qualifying.
  final String? subtitle;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: enabled ? onChanged : null,
      title: Text(label),
      subtitle: subtitle == null ? null : Text(subtitle!),
      // The switch trails: it is the answer to the label's question, so it reads
      // left to right as question then state.
      controlAffinity: ListTileControlAffinity.trailing,
      // The card around this is already padded; the theme's own 16pt would indent
      // the row a second time.
      contentPadding: EdgeInsets.zero,
      // Tightens the row without going under the 44pt touch target.
      visualDensity: VisualDensity.compact,
    );
  }
}
