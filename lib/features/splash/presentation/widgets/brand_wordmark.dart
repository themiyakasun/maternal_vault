import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';

/// "Maternal Vault" set in two tones — rose for the first word, sage for the
/// second — matching the brand lockup.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.fontSize = 40});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = AppTextStyles.h1.copyWith(
      fontSize: fontSize,
      height: 1.15,
    );

    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: AppStrings.brandFirstWord,
            style: base.copyWith(color: AppColors.primaryContainer),
          ),
          const TextSpan(text: ' '),
          TextSpan(
            text: AppStrings.brandSecondWord,
            style: base.copyWith(color: AppColors.secondaryFixedDim),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      semanticsLabel: AppStrings.appName,
    );
  }
}
