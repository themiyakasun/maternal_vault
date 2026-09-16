import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cards/section_card.dart';
import '../../../../core/widgets/inputs/app_checkbox_tile.dart';
import '../../../../core/widgets/inputs/app_switch_tile.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/medical_history.dart';

/// The mother's second tab: what runs in her family, and what she has been
/// treated for herself.
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
  late final TextEditingController _familyOtherController;
  late final TextEditingController _personalOtherController;

  @override
  void initState() {
    super.initState();
    _familyOtherController = TextEditingController(
      text: widget.history.familyOtherDetails ?? '',
    );
    _personalOtherController = TextEditingController(
      text: widget.history.personalOtherDetails ?? '',
    );
  }

  @override
  void didUpdateWidget(MedicalHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.history != oldWidget.history) {
      setState(() {
        _history = widget.history;
        if (_familyOtherController.text !=
            (widget.history.familyOtherDetails ?? '')) {
          _familyOtherController.text =
              widget.history.familyOtherDetails ?? '';
        }
        if (_personalOtherController.text !=
            (widget.history.personalOtherDetails ?? '')) {
          _personalOtherController.text =
              widget.history.personalOtherDetails ?? '';
        }
      });
    }
  }

  @override
  void dispose() {
    _familyOtherController.dispose();
    _personalOtherController.dispose();
    super.dispose();
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
      gap: AppSpacing.stackSm,
      children: <Widget>[
        for (final FamilyCondition condition in FamilyCondition.values) ...<Widget>[
          AppCheckboxTile(
            label: _familyLabel(l10n, condition),
            value: _history.hasFamily(condition),
            onChanged: (bool present) =>
                _update(_history.withFamily(condition, present: present)),
          ),
          if (condition == FamilyCondition.other && _history.hasFamily(FamilyCondition.other))
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.stackMd,
                right: AppSpacing.stackMd,
                bottom: AppSpacing.stackSm,
              ),
              child: AppTextField(
                label: l10n.familyOther,
                hint: l10n.fieldSpecifyOther,
                controller: _familyOtherController,
                onChanged: (String val) => _update(
                  _history.copyWith(familyOtherDetails: val.trim().isEmpty ? null : val.trim()),
                ),
              ),
            ),
        ],
      ],
    );
  }

  /// Switches, because each of these is a standing fact about her own health.
  Widget _personalHistory(AppLocalizations l10n) {
    return SectionCard(
      icon: Icons.medical_services_outlined,
      title: l10n.sectionMedicalSurgicalHistory,
      accent: AppColors.secondary,
      divided: true,
      children: <Widget>[
        for (final PersonalCondition condition in PersonalCondition.values) ...<Widget>[
          AppSwitchTile(
            label: _personalLabel(l10n, condition),
            value: _history.hasPersonal(condition),
            onChanged: (bool present) =>
                _update(_history.withPersonal(condition, present: present)),
          ),
          if (condition == PersonalCondition.other && _history.hasPersonal(PersonalCondition.other))
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.stackMd,
                vertical: AppSpacing.stackSm,
              ),
              child: AppTextField(
                label: l10n.conditionOther,
                hint: l10n.fieldSpecifyOther,
                controller: _personalOtherController,
                onChanged: (String val) => _update(
                  _history.copyWith(personalOtherDetails: val.trim().isEmpty ? null : val.trim()),
                ),
              ),
            ),
        ],
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
      case FamilyCondition.other:
        return l10n.familyOther;
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
      case PersonalCondition.psychiatric:
        return l10n.conditionPsychiatric;
      case PersonalCondition.epilepsy:
        return l10n.conditionEpilepsy;
      case PersonalCondition.malignancies:
        return l10n.conditionMalignancies;
      case PersonalCondition.haematological:
        return l10n.conditionHaematological;
      case PersonalCondition.tuberculosis:
        return l10n.conditionTuberculosis;
      case PersonalCondition.thyroid:
        return l10n.conditionThyroid;
      case PersonalCondition.bronchialAsthma:
        return l10n.conditionBronchialAsthma;
      case PersonalCondition.previousDvt:
        return l10n.conditionPreviousDvt;
      case PersonalCondition.surgeries:
        return l10n.conditionSurgeriesOther;
      case PersonalCondition.socialRiskFactors:
        return l10n.conditionSocialRisk;
      case PersonalCondition.other:
        return l10n.conditionOther;
    }
  }
}

