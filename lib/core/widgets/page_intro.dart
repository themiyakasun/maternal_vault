import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../theme/app_theme.dart';

/// Title + supporting copy, styled the same way on every screen that opens with
/// one.
///
/// Started life as the welcome flow's step header and now leads the screens
/// onboarding hands off to as well, so the first thing after the flow reads in
/// the same voice as the flow itself.
class PageIntro extends StatelessWidget {
  const PageIntro({
    super.key,
    required this.title,
    required this.body,
    this.compact = false,
    this.titleColor,
    this.align = TextAlign.center,
  });

  final String title;
  final String body;

  /// Drops the title a size. Set on short screens, where the full heading eats
  /// room the content needs more.
  final bool compact;

  /// Overrides the title colour. Null keeps the theme's default ink, which is
  /// what every welcome step uses.
  final Color? titleColor;

  /// How the two lines sit. Centred for the standalone, one-thing-at-a-time
  /// screens; [TextAlign.start] for the ones that lead into a form, where a
  /// centred heading over left-aligned fields reads as a stray element.
  final TextAlign align;

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
          textAlign: align,
          style: titleColor == null
              ? titleStyle
              : titleStyle.copyWith(color: titleColor),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          body,
          textAlign: align,
          style: AppTextStyles.bodySm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
