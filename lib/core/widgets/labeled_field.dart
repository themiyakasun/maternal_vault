import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../theme/app_theme.dart';

/// A read-only labelled value: a small captioned icon over a boxed value.
///
/// Shows a stored field the way the form that set it did, but not editable — the
/// box mirrors an input's outline so it reads as "this was filled in".
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.accent = AppColors.primary,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 6),
            Expanded(child: Text(label, style: AppTextStyles.labelCaps)),
          ],
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.04),
            borderRadius: const BorderRadius.all(Radius.circular(AppRadii.md)),
            border: Border.all(color: AppColors.outlineVariant, width: 1),
          ),
          child: Text(
            value,
            style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurface),
          ),
        ),
      ],
    );
  }
}
