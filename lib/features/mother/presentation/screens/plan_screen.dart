import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/cards/section_card.dart';
import '../../../../core/widgets/inputs/app_date_field.dart';
import '../../../../core/widgets/inputs/app_dropdown_field.dart';
import '../../../../core/widgets/inputs/app_stepper_field.dart';
import '../../../../core/widgets/inputs/app_switch_tile.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/delivery_plan.dart';
import '../../domain/family_planning_method.dart';
import '../../domain/obstetric_history.dart';
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
  late final TextEditingController _birthWeight;
  late final TextEditingController _complications;

  late DateTime? _dateOfBirth = widget.plan.dateOfBirth;
  late TransportMode? _transportMode = widget.plan.transportMode;
  late DeliveryMode? _deliveryMode = widget.plan.deliveryMode;
  late FamilyPlanningMethod? _familyPlanning = widget.plan.familyPlanningMethod;
  late bool _episiotomy = widget.plan.episiotomy;
  late int? _apgarOne = widget.plan.apgarOneMinute;
  late int? _apgarFive = widget.plan.apgarFiveMinutes;

  /// Wide bounds — these catch a slipped digit, not a clinician's judgement.
  static const int _minCost = 0;
  static const int _maxCost = 1000000;
  static const int _minDistance = 0;
  static const int _maxDistance = 1000;
  static const int _minMinutes = 0;
  static const int _maxMinutes = 1440;
  static const int _minWeightKg = 0;
  static const int _maxWeightKg = 10;

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
    _birthWeight = TextEditingController(
      text: plan.birthWeightKg?.toString() ?? '',
    );
    _complications = TextEditingController(text: plan.complications ?? '');
  }

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      _hospital,
      _transportCost,
      _distance,
      _estTime,
      _birthWeight,
      _complications,
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
            _deliverySummary(l10n),
            const SizedBox(height: AppSpacing.componentGap),
            _familyPlanningSection(l10n),
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

  Widget _deliverySummary(AppLocalizations l10n) {
    return SectionCard(
      icon: Icons.child_care_outlined,
      title: l10n.sectionDeliverySummary,
      accent: AppColors.secondary,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: AppTextField(
                label: l10n.fieldBirthWeight,
                controller: _birthWeight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                suffixText: l10n.unitKilograms,
                validator: (String? raw) => _range(
                  l10n,
                  raw,
                  _minWeightKg,
                  _maxWeightKg,
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.componentGap),
            Expanded(
              child: AppDateField(
                label: l10n.fieldDateOfBirth,
                hint: l10n.hintPickDate,
                value: _dateOfBirth,
                // A birth is not in the future; the delivery half is filled on
                // the day, not booked ahead.
                lastDate: DateTime.now(),
                onChanged: (DateTime? next) =>
                    setState(() => _dateOfBirth = next),
              ),
            ),
          ],
        ),
        AppDropdownField<DeliveryMode>(
          label: l10n.fieldModeOfDelivery,
          hint: l10n.hintSelectMode,
          value: _deliveryMode,
          items: <AppDropdownItem<DeliveryMode>>[
            for (final DeliveryMode mode in DeliveryMode.values)
              AppDropdownItem<DeliveryMode>(
                value: mode,
                label: deliveryModeLabel(l10n, mode),
              ),
          ],
          onChanged: (DeliveryMode? next) =>
              setState(() => _deliveryMode = next),
        ),
        AppSwitchTile(
          label: l10n.fieldEpisiotomy,
          value: _episiotomy,
          onChanged: (bool next) => setState(() => _episiotomy = next),
        ),
        AppTextField(
          label: l10n.fieldComplications,
          hint: l10n.fieldComplicationsHint,
          controller: _complications,
          minLines: 3,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
        ),
        _apgar(l10n),
      ],
    );
  }

  /// The two scores under one caption, split by a slash the way the clinic card
  /// writes them.
  Widget _apgar(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.fieldApgarScore,
          style: AppTextStyles.bodySm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Row(
          children: <Widget>[
            Expanded(
              child: AppStepperField(
                hint: l10n.apgarOneMinute,
                value: _apgarOne,
                onChanged: (int? next) => setState(() => _apgarOne = next),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.stackSm,
              ),
              child: Text('/', style: AppTextStyles.bodyLg),
            ),
            Expanded(
              child: AppStepperField(
                hint: l10n.apgarFiveMinutes,
                value: _apgarFive,
                onChanged: (int? next) => setState(() => _apgarFive = next),
              ),
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

  /// Empty is fine — this only judges what was actually typed. Whole numbers
  /// unless [decimal], because the field behind it stores an int.
  String? _range(
    AppLocalizations l10n,
    String? raw,
    int min,
    int max, {
    bool decimal = false,
  }) {
    final String value = raw?.trim() ?? '';
    if (value.isEmpty) return null;

    final num? number = decimal ? double.tryParse(value) : int.tryParse(value);
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

    final DeliveryPlan plan = DeliveryPlan(
      intendedHospital: _trimmedOrNull(_hospital),
      transportMode: _transportMode,
      transportCostEstimate: int.tryParse(_transportCost.text.trim()),
      distanceKm: int.tryParse(_distance.text.trim()),
      estimatedTimeMinutes: int.tryParse(_estTime.text.trim()),
      birthWeightKg: double.tryParse(_birthWeight.text.trim()),
      dateOfBirth: _dateOfBirth,
      deliveryMode: _deliveryMode,
      episiotomy: _episiotomy,
      complications: _trimmedOrNull(_complications),
      apgarOneMinute: _apgarOne,
      apgarFiveMinutes: _apgarFive,
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
