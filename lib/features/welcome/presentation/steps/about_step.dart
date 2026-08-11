import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/page_intro.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../widgets/feature_highlight.dart';

/// Welcome step 2 — what the app is and why it exists.
class AboutStep extends StatelessWidget {
  const AboutStep({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PageIntro(
            title: l10n.aboutStepTitle,
            body: l10n.aboutStepBody,
            compact: compact,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          FeatureHighlight(
            icon: Icons.cloud_off_outlined,
            title: l10n.aboutFeatureOfflineTitle,
            body: l10n.aboutFeatureOfflineBody,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.stackLg),
          FeatureHighlight(
            icon: Icons.lock_outline_rounded,
            title: l10n.aboutFeaturePrivateTitle,
            body: l10n.aboutFeaturePrivateBody,
            color: AppColors.secondary,
          ),
          const SizedBox(height: AppSpacing.stackLg),
          FeatureHighlight(
            icon: Icons.qr_code_2_outlined,
            title: l10n.aboutFeatureShareTitle,
            body: l10n.aboutFeatureShareBody,
            color: AppColors.tertiary,
          ),
        ],
      ),
    );
  }
}
