import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/cards/section_card.dart';
import '../../../../core/widgets/detail_grid.dart';
import '../../../../core/widgets/inputs/app_dropdown_field.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/delivery_plan.dart';
import '../../domain/family_planning_method.dart';
import '../../domain/transport_mode.dart';
import '../widgets/obstetric_labels.dart';
import '../widgets/plan_labels.dart';

/// The mother's fifth tab: how she will reach hospital, what happened at the
/// birth, and what comes after.
///
/// Two of its three sections are filled before labour and one after, so nothing
/// is required — a plan with the emergency half done and the delivery half blank
/// is the normal state for most of the pregnancy. [onSave] is the seam the record
/// layer drops into; the numeric fields are range-checked regardless.
class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key, this.plan = const DeliveryPlan.empty(), this.onSave});

  /// The plan to edit. Defaults to an empty one — a fresh form.
  final DeliveryPlan plan;

  /// Handed a [DeliveryPlan] when Save is tapped. Null shows a notice rather than
  /// pretending to have saved.
  final ValueChanged<DeliveryPlan>? onSave;

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _hospital;
  late final TextEditingController _transportCost;
  late final TextEditingController _distance;
  late final TextEditingController _estTime;

  late TransportMode? _transportMode = widget.plan.transportMode;
  late FamilyPlanningMethod? _familyPlanning = widget.plan.familyPlanningMethod;

  /// Wide bounds — these catch a slipped digit, not a clinician's judgement.
  static const int _minCost = 0;
  static const int _maxCost = 1000000;
  static const int _minDistance = 0;
  static const int _maxDistance = 1000;
  static const int _minMinutes = 0;
  static const int _maxMinutes = 1440;

  @override
  void initState() {
    super.initState();
    final DeliveryPlan plan = widget.plan;
    _hospital = TextEditingController(text: plan.intendedHospital ?? '');
    _transportCost = TextEditingController(
      text: plan.transportCostEstimate?.toString() ?? '',
    );
    _distance = TextEditingController(text: plan.distanceKm?.toString() ?? '');
    _estTime = TextEditingController(
      text: plan.estimatedTimeMinutes?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(PlanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.plan != oldWidget.plan) {
      setState(() {
        final DeliveryPlan plan = widget.plan;
        _hospital.text = plan.intendedHospital ?? '';
        _transportCost.text = plan.transportCostEstimate?.toString() ?? '';
        _distance.text = plan.distanceKm?.toString() ?? '';
        _estTime.text = plan.estimatedTimeMinutes?.toString() ?? '';
        _transportMode = plan.transportMode;
        _familyPlanning = plan.familyPlanningMethod;
      });
    }
  }

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      _hospital,
      _transportCost,
      _distance,
      _estTime,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.stackSm,
          AppSpacing.screenPadding,
          AppSpacing.sectionGap,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _emergencyPlan(l10n),
            const SizedBox(height: AppSpacing.componentGap),
            _deliverySummary(context, l10n),
            const SizedBox(height: AppSpacing.componentGap),
            _dischargeChecklistSection(context, l10n),
            const SizedBox(height: AppSpacing.componentGap),
            _postpartumFieldCareSection(context, l10n),
            const SizedBox(height: AppSpacing.componentGap),
            _postpartumClinicCareSection(l10n),
            const SizedBox(height: AppSpacing.componentGap),
            _familyPlanningSection(l10n),
            const SizedBox(height: AppSpacing.componentGap),
            _antenatalClassesSection(l10n),
            const SizedBox(height: AppSpacing.componentGap),
            _breastfeedingDirectivesCard(l10n),
            const SizedBox(height: AppSpacing.sectionGap),
            AppPrimaryButton(
              label: l10n.actionSavePlan,
              icon: Icons.save_outlined,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  String? _formatDate(MaterialLocalizations material, DateTime? date) {
    if (date == null) return null;
    return '${material.formatShortMonthDay(date)}, ${material.formatYear(date)}';
  }

  Widget _checklistRow({required String label, required bool checked}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.unit / 2),
      child: Row(
        children: <Widget>[
          Icon(
            checked
                ? Icons.check_circle_rounded
                : Icons.remove_circle_outline_rounded,
            color: checked ? AppColors.health : AppColors.outline,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyLg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emergencyPlan(AppLocalizations l10n) {
    return SectionCard(
      // Red, for the one section that matters when everything is going wrong.
      icon: Icons.emergency_outlined,
      title: l10n.sectionEmergencyPlan,
      accent: AppColors.error,
      children: <Widget>[
        AppTextField(
          label: l10n.fieldIntendedHospital,
          hint: l10n.fieldIntendedHospitalHint,
          controller: _hospital,
          textCapitalization: TextCapitalization.words,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: AppDropdownField<TransportMode>(
                label: l10n.fieldTransportMode,
                hint: l10n.hintSelectMode,
                value: _transportMode,
                items: <AppDropdownItem<TransportMode>>[
                  for (final TransportMode mode in TransportMode.values)
                    AppDropdownItem<TransportMode>(
                      value: mode,
                      label: transportModeLabel(l10n, mode),
                    ),
                ],
                onChanged: (TransportMode? next) =>
                    setState(() => _transportMode = next),
              ),
            ),
            const SizedBox(width: AppSpacing.componentGap),
            Expanded(
              child: AppTextField(
                label: l10n.fieldTransportCost,
                hint: l10n.fieldTransportCostHint,
                controller: _transportCost,
                keyboardType: TextInputType.number,
                validator: (String? raw) =>
                    _range(l10n, raw, _minCost, _maxCost),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: AppTextField(
                label: l10n.fieldDistanceKm,
                controller: _distance,
                keyboardType: TextInputType.number,
                validator: (String? raw) =>
                    _range(l10n, raw, _minDistance, _maxDistance),
              ),
            ),
            const SizedBox(width: AppSpacing.componentGap),
            Expanded(
              child: AppTextField(
                label: l10n.fieldEstTimeMinutes,
                controller: _estTime,
                keyboardType: TextInputType.number,
                validator: (String? raw) =>
                    _range(l10n, raw, _minMinutes, _maxMinutes),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _deliverySummary(BuildContext context, AppLocalizations l10n) {
    final MaterialLocalizations material = MaterialLocalizations.of(context);
    final DeliveryPlan plan = widget.plan;

    return SectionCard(
      icon: Icons.child_care_outlined,
      title: l10n.sectionDeliverySummary,
      accent: AppColors.secondary,
      children: <Widget>[
        DetailGrid(
          items: <DetailPair>[
            DetailPair(
              label: l10n.fieldDeliveryHospital,
              value: plan.deliveryHospital,
            ),
            DetailPair(
              label: l10n.fieldPoaAtDelivery,
              value: plan.poaAtDeliveryWeeks != null
                  ? l10n.weeksShort(plan.poaAtDeliveryWeeks!)
                  : null,
            ),
            DetailPair(
              label: l10n.fieldBirthWeight,
              value: plan.birthWeightKg != null
                  ? '${plan.birthWeightKg} ${l10n.unitKilograms}'
                  : null,
            ),
            DetailPair(
              label: l10n.fieldDateOfBirth,
              value: _formatDate(material, plan.dateOfBirth),
            ),
            DetailPair(
              label: l10n.fieldModeOfDelivery,
              value: plan.deliveryMode != null
                  ? deliveryModeLabel(l10n, plan.deliveryMode!)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.unit),
        _checklistRow(
          label: l10n.fieldEpisiotomy,
          checked: plan.episiotomy,
        ),
        if (plan.complications != null && plan.complications!.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.componentGap),
          DetailGrid(
            columns: 1,
            items: <DetailPair>[
              DetailPair(
                label: l10n.fieldComplications,
                value: plan.complications,
              ),
            ],
          ),
        ],
        const Divider(),
        DetailGrid(
          items: <DetailPair>[
            DetailPair(
              label: 'Apgar (${l10n.apgarOneMinute})',
              value: plan.apgarOneMinute?.toString(),
            ),
            DetailPair(
              label: 'Apgar (${l10n.apgarFiveMinutes})',
              value: plan.apgarFiveMinutes?.toString(),
            ),
            DetailPair(
              label: 'Apgar (${l10n.apgarTenMinutes})',
              value: plan.apgarTenMinutes?.toString(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dischargeChecklistSection(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final MaterialLocalizations material = MaterialLocalizations.of(context);
    final DischargeChecklist checklist = widget.plan.dischargeChecklist;

    final List<(String, bool)> items = <(String, bool)>[
      (l10n.fieldTempNormal48h, checklist.tempNormal48h),
      (l10n.fieldPacksChecked, checklist.packsChecked),
      (l10n.fieldInfectionFree, checklist.infectionFree),
      (l10n.fieldFpDiscussed, checklist.fpDiscussed),
      (l10n.fieldDangerSignalsExplained, checklist.dangerSignalsExplained),
      (l10n.fieldBreastfeedingEstablished, checklist.breastfeedingEstablished),
      (l10n.fieldVitAGiven, checklist.vitAGiven),
      (l10n.fieldRubellaGiven, checklist.rubellaGiven),
      (l10n.fieldAntiDGiven, checklist.antiDGiven),
      (l10n.fieldDiagnosisCardIssued, checklist.diagnosisCardIssued),
      (l10n.fieldChdrHandedOver, checklist.chdrHandedOver),
      (l10n.fieldPrescriptionIssued, checklist.prescriptionIssued),
      (l10n.fieldReferredToPhm, checklist.referredToPhm),
    ];

    return SectionCard(
      icon: Icons.checklist_rtl_outlined,
      title: l10n.sectionDischargeChecklist,
      accent: AppColors.health,
      children: <Widget>[
        for (final (String label, bool checked) in items)
          _checklistRow(label: label, checked: checked),
        const Divider(),
        DetailGrid(
          columns: 1,
          items: <DetailPair>[
            DetailPair(
              label: l10n.fieldDischargeDate,
              value: _formatDate(material, checklist.dischargeDate),
            ),
          ],
        ),
      ],
    );
  }

  Widget _postpartumFieldCareSection(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final MaterialLocalizations material = MaterialLocalizations.of(context);
    final PostpartumCare care = widget.plan.postpartumCare;

    return SectionCard(
      icon: Icons.home_work_outlined,
      title: l10n.sectionPostpartumFieldCare,
      accent: AppColors.primary,
      children: <Widget>[
        DetailGrid(
          items: <DetailPair>[
            DetailPair(
              label: l10n.fieldPhmVisitDate,
              value: _formatDate(material, care.phmVisitDate),
            ),
            DetailPair(
              label: l10n.fieldMicronutrientsDate,
              value: _formatDate(material, care.micronutrientsDate),
            ),
          ],
        ),
        if (care.postpartumClinicSchedule != null &&
            care.postpartumClinicSchedule!.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.componentGap),
          DetailGrid(
            columns: 1,
            items: <DetailPair>[
              DetailPair(
                label: l10n.fieldPostpartumClinicSchedule,
                value: care.postpartumClinicSchedule,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _postpartumClinicCareSection(AppLocalizations l10n) {
    final PostpartumCare care = widget.plan.postpartumCare;

    return SectionCard(
      icon: Icons.local_hospital_outlined,
      title: l10n.sectionPostpartumClinicCare,
      accent: AppColors.secondary,
      children: <Widget>[
        DetailGrid(
          columns: 1,
          items: <DetailPair>[
            DetailPair(
              label: l10n.fieldPostpartumMorbidities,
              value: care.postpartumMorbidities,
            ),
          ],
        ),
      ],
    );
  }

  Widget _familyPlanningSection(AppLocalizations l10n) {
    return SectionCard(
      icon: Icons.favorite_outline_rounded,
      title: l10n.sectionFamilyPlanning,
      accent: AppColors.tertiary,
      children: <Widget>[
        AppDropdownField<FamilyPlanningMethod>(
          label: l10n.fieldPostPartumMethod,
          hint: l10n.hintSelectMethod,
          value: _familyPlanning,
          items: <AppDropdownItem<FamilyPlanningMethod>>[
            for (final FamilyPlanningMethod method
                in FamilyPlanningMethod.values)
              AppDropdownItem<FamilyPlanningMethod>(
                value: method,
                label: familyPlanningLabel(l10n, method),
              ),
          ],
          onChanged: (FamilyPlanningMethod? next) =>
              setState(() => _familyPlanning = next),
        ),
      ],
    );
  }

  Widget _antenatalClassesSection(AppLocalizations l10n) {
    final AntenatalEducation edu = widget.plan.antenatalEducation;

    return SectionCard(
      icon: Icons.menu_book_outlined,
      title: l10n.sectionAntenatalClasses,
      accent: AppColors.tertiary,
      children: <Widget>[
        _checklistRow(
          label: l10n.fieldAntenatalClassTrimester(1),
          checked: edu.classTrimester1,
        ),
        _checklistRow(
          label: l10n.fieldAntenatalClassTrimester(2),
          checked: edu.classTrimester2,
        ),
        _checklistRow(
          label: l10n.fieldAntenatalClassTrimester(3),
          checked: edu.classTrimester3,
        ),
        const Divider(),
        _checklistRow(
          label: l10n.fieldIecBookAntenatal,
          checked: edu.bookAntenatal,
        ),
        _checklistRow(
          label: l10n.fieldIecBookBreastfeeding,
          checked: edu.bookBreastfeeding,
        ),
        _checklistRow(
          label: l10n.fieldIecBookEccd,
          checked: edu.bookEccd,
        ),
        _checklistRow(
          label: l10n.fieldIecLeafletFp,
          checked: edu.leafletFp,
        ),
      ],
    );
  }

  Widget _breastfeedingDirectivesCard(AppLocalizations l10n) {
    return SectionCard(
      icon: Icons.verified_user_outlined,
      title: l10n.guidanceBreastfeedingTitle,
      accent: AppColors.primary,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(
              Icons.check_circle_outline,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.stackSm),
            Expanded(
              child: Text(
                l10n.guidanceBreastfeeding1,
                style: AppTextStyles.bodyLg,
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(
              Icons.check_circle_outline,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.stackSm),
            Expanded(
              child: Text(
                l10n.guidanceBreastfeeding2,
                style: AppTextStyles.bodyLg,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Empty is fine — this only judges what was actually typed.
  String? _range(
    AppLocalizations l10n,
    String? raw,
    int min,
    int max,
  ) {
    final String value = raw?.trim() ?? '';
    if (value.isEmpty) return null;

    final int? number = int.tryParse(value);
    if (number == null || number < min || number > max) {
      return l10n.validationNumberRange(min, max);
    }
    return null;
  }

  void _save() {
    // Dismissing the keyboard first stops the error text appearing behind it on
    // a field near the bottom of the form.
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final DeliveryPlan plan = widget.plan.copyWith(
      intendedHospital: _trimmedOrNull(_hospital),
      transportMode: _transportMode,
      transportCostEstimate: int.tryParse(_transportCost.text.trim()),
      distanceKm: int.tryParse(_distance.text.trim()),
      estimatedTimeMinutes: int.tryParse(_estTime.text.trim()),
      familyPlanningMethod: _familyPlanning,
    );

    final ValueChanged<DeliveryPlan>? onSave = widget.onSave;
    if (onSave != null) {
      onSave(plan);
      return;
    }

    // TODO: remove once a caller supplies onSave and owns the confirmation.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).planSaveNotConnected)),
    );
  }

  /// Empty text means "not answered", stored as null rather than a blank string.
  String? _trimmedOrNull(TextEditingController controller) {
    final String text = controller.text.trim();
    return text.isEmpty ? null : text;
  }
}
