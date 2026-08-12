import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons/app_outline_button.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/inputs/app_date_field.dart';
import '../../../../core/widgets/inputs/app_dropdown_field.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/clinic_record.dart';
import 'clinic_labels.dart';

/// Collects one routine visit, in the order it is written on the clinic card.
///
/// Resolves to the visit, or to null if the sheet was dismissed — the caller adds
/// only on a non-null answer, so a swipe-away leaves the record alone.
Future<ClinicVisit?> showClinicVisitSheet(BuildContext context) {
  return showModalBottomSheet<ClinicVisit>(
    context: context,
    // A form, not a menu: without this the sheet caps at half the screen and the
    // keyboard covers the field being typed into.
    isScrollControlled: true,
    builder: (BuildContext context) => const _ClinicVisitSheet(),
  );
}

class _ClinicVisitSheet extends StatefulWidget {
  const _ClinicVisitSheet();

  @override
  State<_ClinicVisitSheet> createState() => _ClinicVisitSheetState();
}

class _ClinicVisitSheetState extends State<_ClinicVisitSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _week = TextEditingController();
  final TextEditingController _systolic = TextEditingController();
  final TextEditingController _diastolic = TextEditingController();
  final TextEditingController _weight = TextEditingController();
  final TextEditingController _fundalHeight = TextEditingController();
  final TextEditingController _fetalHeartRate = TextEditingController();

  /// Prefilled with today: a visit is nearly always logged on the day it
  /// happened, and the picker is still one tap away when it was not.
  late DateTime? _date = _today();

  VisitStatus _status = VisitStatus.normal;
  UrineReading? _urineSugar;
  UrineReading? _urineAlbumin;

  /// Only the week and the date are required — a card that skipped a row should
  /// be enterable as it stands, not padded with guesses to get past the form.
  ///
  /// The ranges are wide on purpose: they exist to catch a slipped digit, not to
  /// second-guess a midwife.
  static const int _minWeek = 4;
  static const int _maxWeek = 44;
  static const int _minSystolic = 60;
  static const int _maxSystolic = 250;
  static const int _minDiastolic = 30;
  static const int _maxDiastolic = 160;
  static const int _minWeightKg = 30;
  static const int _maxWeightKg = 200;
  static const int _minFundalHeightCm = 5;
  static const int _maxFundalHeightCm = 50;
  static const int _minHeartRate = 60;
  static const int _maxHeartRate = 220;

  @override
  void dispose() {
    _week.dispose();
    _systolic.dispose();
    _diastolic.dispose();
    _weight.dispose();
    _fundalHeight.dispose();
    _fetalHeartRate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          0,
          AppSpacing.screenPadding,
          // The keyboard's height, so the Save button clears it rather than
          // sitting behind it.
          AppSpacing.sectionGap + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(l10n.actionLogVisit, style: AppTextStyles.h3),
              Text(
                l10n.visitAddSubtitle,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: AppTextField(
                      label: l10n.fieldVisitWeek,
                      controller: _week,
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      validator: _validateWeek,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.componentGap),
                  Expanded(
                    child: AppDateField(
                      label: l10n.fieldVisitDate,
                      hint: l10n.hintPickDate,
                      value: _date,
                      // No future visits: this records what happened, not what is
                      // booked.
                      lastDate: _today(),
                      validator: _validateDate,
                      onChanged: (DateTime? next) =>
                          setState(() => _date = next),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.componentGap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: AppTextField(
                      label: l10n.fieldSystolic,
                      controller: _systolic,
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                      validator: (String? raw) =>
                          _validateRange(raw, _minSystolic, _maxSystolic),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.componentGap),
                  Expanded(
                    child: AppTextField(
                      label: l10n.fieldDiastolic,
                      controller: _diastolic,
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                      validator: (String? raw) =>
                          _validateRange(raw, _minDiastolic, _maxDiastolic),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.componentGap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: AppTextField(
                      label: l10n.fieldWeight,
                      controller: _weight,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      suffixText: l10n.unitKilograms,
                      validator: (String? raw) => _validateRange(
                        raw,
                        _minWeightKg,
                        _maxWeightKg,
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.componentGap),
                  Expanded(
                    child: AppTextField(
                      label: l10n.fieldFundalHeight,
                      controller: _fundalHeight,
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      suffixText: l10n.unitCentimetres,
                      validator: (String? raw) => _validateRange(
                        raw,
                        _minFundalHeightCm,
                        _maxFundalHeightCm,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.componentGap),
              AppTextField(
                label: l10n.fieldFhs,
                controller: _fetalHeartRate,
                keyboardType: TextInputType.number,
                maxLength: 3,
                suffixText: l10n.unitBpm,
                validator: (String? raw) =>
                    _validateRange(raw, _minHeartRate, _maxHeartRate),
              ),
              const SizedBox(height: AppSpacing.componentGap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: AppDropdownField<UrineReading>(
                      label: l10n.fieldUrineSugar,
                      hint: l10n.hintChooseOne,
                      value: _urineSugar,
                      items: _urineItems(l10n),
                      onChanged: (UrineReading? next) =>
                          setState(() => _urineSugar = next),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.componentGap),
                  Expanded(
                    child: AppDropdownField<UrineReading>(
                      label: l10n.fieldUrineAlbumin,
                      hint: l10n.hintChooseOne,
                      value: _urineAlbumin,
                      items: _urineItems(l10n),
                      onChanged: (UrineReading? next) =>
                          setState(() => _urineAlbumin = next),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.componentGap),
              AppDropdownField<VisitStatus>(
                label: l10n.fieldVisitStatus,
                value: _status,
                items: <AppDropdownItem<VisitStatus>>[
                  for (final VisitStatus status in VisitStatus.values)
                    AppDropdownItem<VisitStatus>(
                      value: status,
                      label: visitStatusLabel(l10n, status),
                    ),
                ],
                // Never cleared to null: every visit read some way, and Normal is
                // the honest default for one nobody flagged.
                onChanged: (VisitStatus? next) =>
                    setState(() => _status = next ?? VisitStatus.normal),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppOutlineButton(
                      label: l10n.actionCancel,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.componentGap),
                  Expanded(
                    child: AppPrimaryButton(
                      label: l10n.actionSave,
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<AppDropdownItem<UrineReading>> _urineItems(AppLocalizations l10n) {
    return <AppDropdownItem<UrineReading>>[
      for (final UrineReading reading in UrineReading.values)
        AppDropdownItem<UrineReading>(
          value: reading,
          label: urineLabel(l10n, reading),
        ),
    ];
  }

  /// Midnight today, so a prefilled date compares equal to one the picker
  /// returns rather than differing by the time of day.
  DateTime _today() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String? _validateWeek(String? raw) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String value = raw?.trim() ?? '';
    if (value.isEmpty) return l10n.validationRequired;

    final int? week = int.tryParse(value);
    if (week == null || week < _minWeek || week > _maxWeek) {
      return l10n.validationNumberRange(_minWeek, _maxWeek);
    }
    return null;
  }

  String? _validateDate(DateTime? value) {
    if (value == null) return AppLocalizations.of(context).validationRequired;
    return null;
  }

  /// Empty is fine — this only judges what was actually typed.
  ///
  /// Whole numbers unless [decimal], because the field behind it stores an int:
  /// silently dropping a typed "24.5" would be worse than asking again.
  String? _validateRange(
    String? raw,
    int min,
    int max, {
    bool decimal = false,
  }) {
    final String value = raw?.trim() ?? '';
    if (value.isEmpty) return null;

    final num? number = decimal ? double.tryParse(value) : int.tryParse(value);
    if (number == null || number < min || number > max) {
      return AppLocalizations.of(context).validationNumberRange(min, max);
    }
    return null;
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final int? week = int.tryParse(_week.text.trim());
    final DateTime? date = _date;
    // The validators already blocked both; this is what makes them non-null
    // rather than a `!`.
    if (week == null || date == null) return;

    Navigator.pop(
      context,
      ClinicVisit(
        week: week,
        date: date,
        status: _status,
        systolic: int.tryParse(_systolic.text.trim()),
        diastolic: int.tryParse(_diastolic.text.trim()),
        weightKg: double.tryParse(_weight.text.trim()),
        fundalHeightCm: int.tryParse(_fundalHeight.text.trim()),
        fetalHeartRate: int.tryParse(_fetalHeartRate.text.trim()),
        urineSugar: _urineSugar,
        urineAlbumin: _urineAlbumin,
      ),
    );
  }
}
