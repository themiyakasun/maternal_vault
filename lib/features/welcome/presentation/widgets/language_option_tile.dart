import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

/// One row in the language list: the endonym on top, the name in the currently
/// selected language beneath, and a check once chosen.
///
/// [name] deliberately stays in its own script in every locale — someone who
/// only reads Tamil has to be able to find "தமிழ்" while the app is still in
/// English, which is the whole point of this screen.
class LanguageOptionTile extends StatelessWidget {
  const LanguageOptionTile({
    super.key,
    required this.name,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.selectedSemanticsLabel,
  });

  /// The language's own name, in its own script.
  final String name;

  /// The same language named in the app's current language.
  final String subtitle;

  final bool selected;
  final VoidCallback onTap;

  /// Announced by screen readers on the chosen tile.
  final String? selectedSemanticsLabel;

  @override
  Widget build(BuildContext context) {
    final Color border =
        selected ? AppColors.primary : AppColors.outlineVariant;

    return Semantics(
      button: true,
      selected: selected,
      value: selected ? selectedSemanticsLabel : null,
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.cardSurface,
        borderRadius: AppRadii.cardRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.cardRadius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: AppRadii.cardRadius,
              border: Border.all(color: border, width: selected ? 2 : 1),
            ),
            child: Padding(
              // 1px less when unselected so the thinner border does not shift
              // the contents between states.
              padding: EdgeInsets.all(selected ? 15 : 16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          name,
                          style: AppTextStyles.h3.copyWith(
                            color: selected
                                ? AppColors.primary
                                : AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.stackMd),
                  _SelectionMark(selected: selected),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A radio-style ring that fills with a check when its tile is chosen.
class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.outline,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 15, color: AppColors.onPrimary)
          : null,
    );
  }
}
