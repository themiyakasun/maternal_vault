import 'package:flutter/material.dart';

import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'welcome_step_dots.dart';

/// The shared footer for every welcome step: progress dots over a Back/Next
/// pair.
///
/// Back is omitted rather than disabled on the first step, so the primary action
/// takes the full width and nothing looks broken. The dots sit *above* the
/// buttons instead of between them because "Get Started" runs long once
/// translated — Sinhala and Tamil both need the extra room.
class WelcomeNavBar extends StatelessWidget {
  const WelcomeNavBar({
    super.key,
    required this.stepCount,
    required this.currentIndex,
    required this.onNext,
    required this.onBack,
  });

  final int stepCount;
  final int currentIndex;

  /// Null disables the primary button — used on the final step until a role has
  /// been chosen.
  final VoidCallback? onNext;

  /// Null hides the Back button entirely.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool isLastStep = currentIndex == stepCount - 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        WelcomeStepDots(count: stepCount, currentIndex: currentIndex),
        const SizedBox(height: AppSpacing.stackLg),
        Row(
          children: <Widget>[
            if (onBack != null) ...<Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  child: Text(l10n.actionBack, style: AppTextStyles.button),
                ),
              ),
              const SizedBox(width: AppSpacing.componentGap),
            ],
            Expanded(
              // Give the primary action twice the room when Back is present, so
              // the hierarchy stays obvious.
              flex: onBack != null ? 2 : 1,
              child: FilledButton(
                onPressed: onNext,
                child: Text(
                  isLastStep ? l10n.actionGetStarted : l10n.actionNext,
                  style: AppTextStyles.button,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
