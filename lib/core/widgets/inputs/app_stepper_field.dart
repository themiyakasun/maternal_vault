import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../theme/app_theme.dart';
import 'input_field_shell.dart';

/// A small whole number chosen with a plus and minus, its label above it.
///
/// For a bounded count that is quicker to nudge than to type — an Apgar score,
/// a parity, a dose. The value is [min]..[max] and never leaves it, so the form
/// cannot carry a score of 12. Null renders [hint] and means "not entered yet";
/// either arrow enters the range at [min].
class AppStepperField extends StatelessWidget {
  const AppStepperField({
    super.key,
    this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.min = 0,
    this.max = 10,
    this.enabled = true,
  });

  /// Caption shown above the field. Null omits it — for a pair of steppers under
  /// one shared heading, where a caption on each would repeat it.
  final String? label;

  /// The current value, or null for nothing entered yet.
  final int? value;

  final ValueChanged<int?> onChanged;

  /// Placeholder shown while [value] is null.
  final String? hint;

  final int min;
  final int max;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final int? current = value;
    final bool empty = current == null;

    final Widget field = InputDecorator(
      decoration: appFieldDecoration().copyWith(enabled: enabled),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              empty ? (hint ?? '') : '$current',
              style: AppTextStyles.bodyLg.copyWith(
                color: empty
                    ? AppColors.onSurfaceVariant
                    : AppColors.onSurface,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.remove_rounded,
            // Nothing below the floor, and disabled outright once there.
            onTap: enabled && !(current != null && current <= min)
                ? () => _step(-1)
                : null,
          ),
          const SizedBox(width: AppSpacing.stackSm),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: enabled && !(current != null && current >= max)
                ? () => _step(1)
                : null,
          ),
        ],
      ),
    );

    final String? caption = label;
    if (caption == null) return field;
    return LabeledField(label: caption, child: field);
  }

  void _step(int delta) {
    // From empty, either arrow enters the range at the floor.
    final int base = value ?? (min - 1);
    onChanged((base + delta).clamp(min, max));
  }
}

/// One 32pt round tap target holding a plus or a minus.
class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;

  /// Null greys the glyph and swallows the tap — the floor and ceiling of the
  /// range read as spent buttons rather than silent no-ops.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 20,
            color: enabled
                ? AppColors.primary
                : AppColors.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
