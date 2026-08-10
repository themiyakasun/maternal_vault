import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

/// Title + supporting copy, styled identically on every welcome step.
class WelcomeStepIntro extends StatelessWidget {
  const WelcomeStepIntro({
    super.key,
    required this.title,
    required this.body,
    this.compact = false,
  });

  final String title;
  final String body;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          title,
          textAlign: TextAlign.center,
          style: compact ? AppTextStyles.h2 : AppTextStyles.h1Mobile,
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
