import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cards/section_card.dart';
import '../../../../core/widgets/inputs/app_checkbox_tile.dart';
import '../../../../core/widgets/inputs/app_switch_tile.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/medical_history.dart';

/// The mother's second tab: what runs in her family, and what she has been
/// treated for herself.
///
/// No Save button, unlike the profile form. Every row here commits the moment it
/// moves — a switch that needed confirming would look like it had already taken
/// effect when it had not. [onChanged] fires on each tap with the whole updated
/// record.
class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({
    super.key,
    this.history = const MedicalHistory.empty(),
    this.onChanged,
  });

  /// What the rows start on. Defaults to nothing reported.
  final MedicalHistory history;

  /// Fired with the full record after every change. Null leaves the rows working
  /// but going nowhere, which is the state until the record layer lands.
  final ValueChanged<MedicalHistory>? onChanged;

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  late MedicalHistory _history = widget.history;

  @override
  void didUpdateWidget(MedicalHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new record from above wins — otherwise a reload would leave the rows
    // showing the copy this screen was first built with.
    if (widget.history != oldWidget.history) {
      _history = widget.history;
    }
  }

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
          _familyHistory(l10n),
          const SizedBox(height: AppSpacing.componentGap),
          _personalHistory(l10n),
        ],
      ),
    );
  }

  /// Checkboxes, because this is a list of things to tick off about other people.
  Widget _familyHistory(AppLocalizations l10n) {
    return SectionCard(
      icon: Icons.account_tree_outlined,
      title: l10n.sectionFamilyHistory,
      accent: AppColors.secondary,
      // Tighter than the form default: these rows carry their own touch padding,
      // so a full 16pt on top of it reads as a gap rather than a list.
      gap: AppSpacing.stackSm,
      children: <Widget>[
        for (final FamilyCondition condition in FamilyCondition.values)
          AppCheckboxTile(
            label: _familyLabel(l10n, condition),
            value: _history.hasFamily(condition),
            onChanged: (bool present) =>
                _update(_history.withFamily(condition, present: present)),
          ),
      ],
    );
  }

  /// Switches, because each of these is a standing fact about her own health
  /// rather than an item on a checklist.
  Widget _personalHistory(AppLocalizations l10n) {
    return SectionCard(
      icon: Icons.medical_services_outlined,
      title: l10n.sectionMedicalSurgicalHistory,
      accent: AppColors.secondary,
      // Six near-identical rows are hard to scan unbroken, so they get rules.
      divided: true,
      children: <Widget>[
        for (final PersonalCondition condition in PersonalCondition.values)
          AppSwitchTile(
            label: _personalLabel(l10n, condition),
            value: _history.hasPersonal(condition),
            onChanged: (bool present) =>
                _update(_history.withPersonal(condition, present: present)),
          ),
      ],
    );
  }

  void _update(MedicalHistory next) {
    setState(() => _history = next);
    widget.onChanged?.call(next);
  }

  String _familyLabel(AppLocalizations l10n, FamilyCondition condition) {
    switch (condition) {
      case FamilyCondition.diabetesMellitus:
        return l10n.familyDiabetesMellitus;
      case FamilyCondition.hypertension:
        return l10n.familyHypertension;
      case FamilyCondition.haematological:
        return l10n.familyHaematological;
    }
  }

  String _personalLabel(AppLocalizations l10n, PersonalCondition condition) {
    switch (condition) {
      case PersonalCondition.diabetes:
        return l10n.conditionDiabetes;
      case PersonalCondition.hypertension:
        return l10n.conditionHypertension;
      case PersonalCondition.cardiac:
        return l10n.conditionCardiac;
      case PersonalCondition.renal:
        return l10n.conditionRenal;
      case PersonalCondition.hepatic:
        return l10n.conditionHepatic;
      case PersonalCondition.surgeries:
        return l10n.conditionSurgeries;
    }
  }
}
