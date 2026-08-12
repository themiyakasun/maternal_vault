import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_progress_bar.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/info_tile.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/partner_summary.dart';

/// The partner's home tab: a warm greeting, the baby's development, the mother's
/// status, then a short stack of tips.
///
/// Read-only — the partner watches a record they do not edit, so nothing here
/// takes input. [summary] carries the numbers; the descriptive copy is localized
/// so a Sinhala or Tamil partner reads it in their own language.
class PartnerHomeScreen extends StatelessWidget {
  const PartnerHomeScreen({
    super.key,
    this.summary = const PartnerSummary.empty(),
  });

  final PartnerSummary summary;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.stackSm,
        AppSpacing.screenPadding,
        AppSpacing.sectionGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _greeting(l10n),
          const SizedBox(height: AppSpacing.sectionGap),
          _babyDevelopment(l10n),
          const SizedBox(height: AppSpacing.componentGap),
          _motherStatus(l10n),
          const SizedBox(height: AppSpacing.componentGap),
          ..._tips(l10n),
        ],
      ),
    );
  }

  Widget _greeting(AppLocalizations l10n) {
    return Column(
      children: <Widget>[
        Text(
          l10n.partnerHomeGreeting(summary.week),
          style: AppTextStyles.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          l10n.partnerHomeGreetingBody,
          style: AppTextStyles.bodyLg.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Blue-tinted with a blue border — the one card that is about the baby, not
  /// the mother.
  Widget _babyDevelopment(AppLocalizations l10n) {
    return AppCard(
      color: AppColors.tertiary.withValues(alpha: 0.06),
      borderColor: AppColors.tertiaryContainer,
      borderWidth: 1.5,
      boxShadow: const <BoxShadow>[],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              StatusChip(
                label: l10n.partnerPoaWeeks(summary.week),
                accent: AppColors.tertiary,
              ),
              const Spacer(),
              const Icon(
                Icons.child_care_rounded,
                color: AppColors.tertiary,
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Text(l10n.partnerBabyDevTitle, style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.stackSm),
          Text(l10n.partnerBabySize, style: AppTextStyles.bodyLg),
          const SizedBox(height: AppSpacing.stackLg),
          AppProgressBar(value: summary.progress, color: AppColors.secondary),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                l10n.partnerHomeProgressWeek(1),
                style: AppTextStyles.labelCaps,
              ),
              Text(
                l10n.partnerHomeProgressWeek(summary.totalWeeks),
                style: AppTextStyles.labelCaps,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// White with a green border, everything centred — a reassurance card, so it
  /// reads calmly rather than as another data block.
  Widget _motherStatus(AppLocalizations l10n) {
    return AppCard(
      borderColor: AppColors.secondaryContainer,
      borderWidth: 1.5,
      boxShadow: const <BoxShadow>[],
      child: Column(
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withValues(alpha: 0.14),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.shield_rounded,
              size: 30,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Text(l10n.partnerMotherStatusTitle, style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            l10n.partnerMotherStatusHeadline,
            style: AppTextStyles.bodyLg.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.partnerMotherStatusBody,
            style: AppTextStyles.bodySm,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// The tip stack, gaps woven between the tiles rather than trailing each.
  List<Widget> _tips(AppLocalizations l10n) {
    final List<InfoTile> tiles = <InfoTile>[
      InfoTile(
        icon: Icons.restaurant_rounded,
        title: l10n.partnerTipNutritionTitle,
        body: l10n.partnerTipNutritionBody,
      ),
      InfoTile(
        icon: Icons.self_improvement_rounded,
        title: l10n.partnerTipSupportTitle,
        body: l10n.partnerTipSupportBody,
      ),
      InfoTile(
        icon: Icons.checklist_rounded,
        title: l10n.partnerTipCheckupTitle,
        body: l10n.partnerTipCheckupBody,
      ),
    ];

    final List<Widget> out = <Widget>[];
    for (int i = 0; i < tiles.length; i++) {
      if (i > 0) out.add(const SizedBox(height: AppSpacing.componentGap));
      out.add(tiles[i]);
    }
    return out;
  }
}
