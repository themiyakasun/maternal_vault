import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

/// Title + supporting copy, styled identically on every welcome step.
///
/// Also used by the screens onboarding hands off to, so the first thing after
/// the flow reads in the same voice as the flow itself.
class WelcomeStepIntro extends StatelessWidget {
  const WelcomeStepIntro({
    super.key,
    required this.title,
    required this.body,
    this.compact = false,
    this.titleColor,
  });

  final String title;
  final String body;
  final bool compact;

  /// Overrides the title colour. Null keeps the theme's default ink, which is
  /// what every welcome step uses.
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = compact
        ? AppTextStyles.h2
        : AppTextStyles.h1Mobile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          title,
          textAlign: TextAlign.center,
          style: titleColor == null
              ? titleStyle
              : titleStyle.copyWith(color: titleColor),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          body,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
