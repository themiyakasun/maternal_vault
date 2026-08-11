import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/page_intro.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/user_role.dart';
import '../widgets/role_card.dart';

/// Welcome step 3 — pick a role, which decides the shell the app opens into.
class RoleStep extends StatelessWidget {
  const RoleStep({
    super.key,
    required this.selected,
    required this.onSelected,
    this.compact = false,
  });

  /// Null until the user has committed to a role, which keeps Get Started
  /// disabled.
  final UserRole? selected;
  final ValueChanged<UserRole> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PageIntro(
            title: l10n.roleStepTitle,
            body: l10n.roleStepBody,
            compact: compact,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          RoleCard(
            icon: Icons.pregnant_woman_rounded,
            title: l10n.roleMotherTitle,
            body: l10n.roleMotherBody,
            accent: AppColors.primaryContainer,
            selected: selected == UserRole.expectantMother,
            onTap: () => onSelected(UserRole.expectantMother),
          ),
          const SizedBox(height: AppSpacing.componentGap),
          RoleCard(
            icon: Icons.favorite_outline_rounded,
            title: l10n.rolePartnerTitle,
            body: l10n.rolePartnerBody,
            accent: AppColors.secondaryContainer,
            selected: selected == UserRole.partner,
            onTap: () => onSelected(UserRole.partner),
          ),
        ],
      ),
    );
  }
}
