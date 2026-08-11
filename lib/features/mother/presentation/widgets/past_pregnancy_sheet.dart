import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons/app_outline_button.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/inputs/app_dropdown_field.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/obstetric_history.dart';
import 'obstetric_labels.dart';

/// Collects one earlier pregnancy.
///
/// Resolves to the entry, or to null if the sheet was dismissed — the caller
/// appends only on a non-null answer, so a swipe-away leaves the record alone.
///
/// [order] is the G number the new entry takes, which the caller knows and the
/// sheet does not: it is one past the pregnancies already recorded.
Future<PastPregnancy?> showPastPregnancySheet(
  BuildContext context, {
  required int order,
}) {
  return showModalBottomSheet<PastPregnancy>(
    context: context,
    // A form, not a menu: without this the sheet caps at half the screen and the
    // keyboard covers the field being typed into.
    isScrollControlled: true,
    builder: (BuildContext context) => _PastPregnancySheet(order: order),
  );
}

class _PastPregnancySheet extends StatefulWidget {
  const _PastPregnancySheet({required this.order});

  final int order;

  @override
  State<_PastPregnancySheet> createState() => _PastPregnancySheetState();
}

class _PastPregnancySheetState extends State<_PastPregnancySheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _year = TextEditingController();
  final TextEditingController _weight = TextEditingController();
  final TextEditingController _age = TextEditingController();

  PregnancyTerm? _term;
  DeliveryMode? _deliveryMode;
  PregnancyOutcome? _outcome;
  BabySex? _sex;

  /// Nothing is required. These are recalled years after the fact, and a sheet
  /// that refuses to close without a birth weight gets a guessed one.
  static const int _earliestYear = 1950;
  static const double _minWeightKg = 0.3;
  static const double _maxWeightKg = 7;

  @override
  void dispose() {
    _year.dispose();
    _weight.dispose();
    _age.dispose();
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
              Text(l10n.pastPregnancyAddTitle, style: AppTextStyles.h3),
              Text(
                l10n.pregnancyOrder(widget.order),
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
                      label: l10n.fieldYear,
                      hint: l10n.fieldYearHint,
                      controller: _year,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      validator: _validateYear,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.componentGap),
                  Expanded(
                    child: AppTextField(
                      label: l10n.fieldBirthWeight,
                      hint: l10n.fieldBirthWeightHint,
                      controller: _weight,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      suffixText: l10n.unitKilograms,
                      validator: _validateWeight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.componentGap),
              AppDropdownField<PregnancyTerm>(
                label: l10n.fieldTerm,
                hint: l10n.hintChooseOne,
                value: _term,
                items: <AppDropdownItem<PregnancyTerm>>[
                  for (final PregnancyTerm term in PregnancyTerm.values)
                    AppDropdownItem<PregnancyTerm>(
                      value: term,
                      label: termLabel(l10n, term),
                    ),
                ],
                onChanged: (PregnancyTerm? next) => setState(() => _term = next),
              ),
              const SizedBox(height: AppSpacing.componentGap),
              AppDropdownField<DeliveryMode>(
                label: l10n.fieldDeliveryMode,
                hint: l10n.hintChooseOne,
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
              const SizedBox(height: AppSpacing.componentGap),
              AppDropdownField<PregnancyOutcome>(
                label: l10n.fieldOutcome,
                hint: l10n.hintChooseOne,
                value: _outcome,
                items: <AppDropdownItem<PregnancyOutcome>>[
                  for (final PregnancyOutcome outcome
                      in PregnancyOutcome.values)
                    AppDropdownItem<PregnancyOutcome>(
                      value: outcome,
                      label: outcomeLabel(l10n, outcome),
                    ),
                ],
                onChanged: (PregnancyOutcome? next) =>
                    setState(() => _outcome = next),
              ),
              const SizedBox(height: AppSpacing.componentGap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: AppDropdownField<BabySex>(
                      label: l10n.fieldSex,
                      hint: l10n.hintChooseOne,
                      value: _sex,
                      items: <AppDropdownItem<BabySex>>[
                        for (final BabySex sex in BabySex.values)
                          AppDropdownItem<BabySex>(
                            value: sex,
                            label: sexLabel(l10n, sex),
                          ),
                      ],
                      onChanged: (BabySex? next) => setState(() => _sex = next),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.componentGap),
                  Expanded(
                    child: AppTextField(
                      label: l10n.fieldChildAge,
                      hint: l10n.fieldAgeHint,
                      controller: _age,
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                    ),
                  ),
                ],
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

  /// Empty is fine; a year that cannot have happened is not.
  String? _validateYear(String? raw) {
    final String value = raw?.trim() ?? '';
    if (value.isEmpty) return null;

    final AppLocalizations l10n = AppLocalizations.of(context);
    final int thisYear = DateTime.now().year;
    final int? year = int.tryParse(value);
    if (year == null || year < _earliestYear || year > thisYear) {
      return l10n.validationYearRange(_earliestYear, thisYear);
    }
    return null;
  }

  String? _validateWeight(String? raw) {
    final String value = raw?.trim() ?? '';
    if (value.isEmpty) return null;

    final double? weight = double.tryParse(value);
    if (weight == null || weight < _minWeightKg || weight > _maxWeightKg) {
      return AppLocalizations.of(context).validationWeightRange;
    }
    return null;
  }

  void _save() {
    // Nothing is required, so this only catches a year or weight that was typed
    // and is impossible.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.pop(
      context,
      PastPregnancy(
        order: widget.order,
        year: int.tryParse(_year.text.trim()),
        term: _term,
        deliveryMode: _deliveryMode,
        outcome: _outcome,
        birthWeightKg: double.tryParse(_weight.text.trim()),
        sex: _sex,
        ageYears: int.tryParse(_age.text.trim()),
      ),
    );
  }
}
