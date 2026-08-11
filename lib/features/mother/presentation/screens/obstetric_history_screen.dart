import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons/app_text_button.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/cards/tile_card.dart';
import '../../../../core/widgets/detail_grid.dart';
import '../../../../core/widgets/inputs/app_date_field.dart';
import '../../../../core/widgets/inputs/app_switch_tile.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/widgets/section_heading.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/obstetric_history.dart';
import '../widgets/obstetric_labels.dart';
import '../widgets/past_pregnancy_sheet.dart';

/// The mother's third tab: how many pregnancies there have been, what was
/// screened at booking, the dates this one turns on, and every pregnancy before
/// it.
///
/// Like the history tab and unlike the profile form, there is no Save. Each row
/// commits as it moves and [onChanged] fires with the whole updated record, so
/// nothing here can be half-entered and lost.
///
/// Past pregnancies are rendered, never invented: an empty list says so rather
/// than showing a sample row.
class ObstetricHistoryScreen extends StatefulWidget {
  const ObstetricHistoryScreen({
    super.key,
    this.history = const ObstetricHistory.empty(),
    this.onChanged,
  });

  /// What the screen starts on. Defaults to a record with nothing entered.
  final ObstetricHistory history;

  /// Fired with the full record after every change, including a pregnancy added
  /// through the sheet. Null leaves the rows working but going nowhere, which is
  /// the state until the record layer lands.
  final ValueChanged<ObstetricHistory>? onChanged;

  @override
  State<ObstetricHistoryScreen> createState() => _ObstetricHistoryScreenState();
}

class _ObstetricHistoryScreenState extends State<ObstetricHistoryScreen> {
  late ObstetricHistory _history = widget.history;

  final TextEditingController _gravidity = TextEditingController();
  final TextEditingController _livingChildren = TextEditingController();

  @override
  void initState() {
    super.initState();
    _gravidity.text = _text(_history.gravidity);
    _livingChildren.text = _text(_history.livingChildren);
  }

  @override
  void didUpdateWidget(ObstetricHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new record from above wins — otherwise a reload would leave the rows
    // showing the copy this screen was first built with.
    if (widget.history != oldWidget.history) {
      _history = widget.history;
      _reseed(_gravidity, _history.gravidity);
      _reseed(_livingChildren, _history.livingChildren);
    }
  }

  @override
  void dispose() {
    _gravidity.dispose();
    _livingChildren.dispose();
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
          SectionHeading(title: l10n.sectionCurrentHistory),
          const SizedBox(height: AppSpacing.stackMd),
          _counts(l10n),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeading(title: l10n.sectionScreening),
          const SizedBox(height: AppSpacing.stackMd),
          _screening(l10n),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeading(title: l10n.sectionKeyDates),
          const SizedBox(height: AppSpacing.stackMd),
          _keyDates(l10n),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeading(
            title: l10n.sectionPastObstetric,
            trailing: AppTextButton(
              label: l10n.actionAdd,
              icon: Icons.add_rounded,
              onPressed: _addPregnancy,
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          _pastPregnancies(l10n),
        ],
      ),
    );
  }

  /// Gravidity beside living children: the two are read as a pair, and putting
  /// them on one line keeps that obvious.
  Widget _counts(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: AppTextField(
            label: l10n.fieldGravidity,
            controller: _gravidity,
            keyboardType: TextInputType.number,
            // Two digits covers every real answer, and refusing the rest at the
            // keyboard beats explaining it in an error.
            maxLength: 2,
            onChanged: (String value) => _update(
              _history.copyWith(gravidity: int.tryParse(value.trim())),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.componentGap),
        Expanded(
          child: AppTextField(
            label: l10n.fieldLivingChildren,
            controller: _livingChildren,
            keyboardType: TextInputType.number,
            maxLength: 2,
            onChanged: (String value) => _update(
              _history.copyWith(livingChildren: int.tryParse(value.trim())),
            ),
          ),
        ),
      ],
    );
  }

  Widget _screening(AppLocalizations l10n) {
    return TileCard(
      children: <Widget>[
        for (final ObstetricScreening question in ObstetricScreening.values)
          AppSwitchTile(
            label: screeningLabel(l10n, question),
            value: _history.hasScreening(question),
            onChanged: (bool present) =>
                _update(_history.withScreening(question, present: present)),
          ),
      ],
    );
  }

  /// The four dates, uncarded.
  ///
  /// No card around them: a card groups things that are read together, and these
  /// are looked up one at a time. Each field's own outline is enough.
  Widget _keyDates(AppLocalizations l10n) {
    // Dates already passed for the two that can only be in the past; the two
    // expected dates are the only ones allowed ahead of today.
    final DateTime today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppDateField(
          label: l10n.fieldLrmp,
          hint: l10n.hintPickDate,
          icon: Icons.calendar_month_outlined,
          value: _history.lastMenstrualPeriod,
          lastDate: today,
          onChanged: (DateTime? next) =>
              _update(_history.copyWith(lastMenstrualPeriod: next)),
        ),
        const SizedBox(height: AppSpacing.componentGap),
        AppDateField(
          label: l10n.fieldEdd,
          hint: l10n.hintPickDate,
          icon: Icons.event_available_outlined,
          value: _history.expectedDelivery,
          onChanged: (DateTime? next) =>
              _update(_history.copyWith(expectedDelivery: next)),
        ),
        const SizedBox(height: AppSpacing.componentGap),
        AppDateField(
          label: l10n.fieldUltrasoundEdd,
          hint: l10n.hintPickDate,
          icon: Icons.monitor_heart_outlined,
          value: _history.ultrasoundExpectedDelivery,
          onChanged: (DateTime? next) =>
              _update(_history.copyWith(ultrasoundExpectedDelivery: next)),
        ),
        const SizedBox(height: AppSpacing.componentGap),
        AppDateField(
          label: l10n.fieldQuickening,
          hint: l10n.hintPickDate,
          icon: Icons.child_care_outlined,
          value: _history.quickening,
          lastDate: today,
          onChanged: (DateTime? next) =>
              _update(_history.copyWith(quickening: next)),
        ),
      ],
    );
  }

  Widget _pastPregnancies(AppLocalizations l10n) {
    if (_history.pregnancies.isEmpty) {
      return AppCard(
        child: Text(
          l10n.pastPregnancyEmpty,
          style: AppTextStyles.bodySm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < _history.pregnancies.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: AppSpacing.componentGap),
          _PastPregnancyCard(pregnancy: _history.pregnancies[i]),
        ],
      ],
    );
  }

  /// Opens the sheet and appends whatever it returns.
  ///
  /// The new entry takes the next G number, so the list keeps reading in the
  /// order the pregnancies happened.
  Future<void> _addPregnancy() async {
    final PastPregnancy? added = await showPastPregnancySheet(
      context,
      order: _history.pregnancies.length + 1,
    );

    // Null means the sheet was dismissed without saving.
    if (added == null) return;
    _update(
      _history.copyWith(
        pregnancies: <PastPregnancy>[..._history.pregnancies, added],
      ),
    );
  }

  void _update(ObstetricHistory next) {
    setState(() => _history = next);
    widget.onChanged?.call(next);
  }

  /// Writes [value] into [controller] only when it actually differs, so a record
  /// arriving from above while the field has focus does not move the caret.
  void _reseed(TextEditingController controller, int? value) {
    final String next = _text(value);
    if (controller.text != next) controller.text = next;
  }

  String _text(int? value) => value?.toString() ?? '';
}

/// One earlier pregnancy: which it was, how it ended, and the four facts the
/// clinic asks about it.
///
/// The stripe down its leading edge carries the outcome, so a loss is visible
/// while scrolling past rather than only on reading the Outcome line.
class _PastPregnancyCard extends StatelessWidget {
  const _PastPregnancyCard({required this.pregnancy});

  final PastPregnancy pregnancy;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PregnancyTerm? term = pregnancy.term;

    return AppCard(
      leadingAccent: outcomeAccent(pregnancy.outcome),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.pregnancyOrder(pregnancy.order),
                      style: AppTextStyles.h3,
                    ),
                    if (pregnancy.year != null)
                      Text(
                        pregnancy.year!.toString(),
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (term != null)
                StatusChip(
                  label: termLabel(l10n, term),
                  accent: termAccent(term),
                ),
            ],
          ),
          const Divider(),
          DetailGrid(
            items: <DetailPair>[
              DetailPair(
                label: l10n.fieldDeliveryMode,
                value: pregnancy.deliveryMode == null
                    ? null
                    : deliveryModeLabel(l10n, pregnancy.deliveryMode!),
              ),
              DetailPair(
                label: l10n.fieldOutcome,
                value: pregnancy.outcome == null
                    ? null
                    : outcomeLabel(l10n, pregnancy.outcome!),
              ),
              DetailPair(
                label: l10n.fieldBirthWeight,
                value: pregnancy.birthWeightKg == null
                    ? null
                    : '${pregnancy.birthWeightKg!.toStringAsFixed(1)} '
                          '${l10n.unitKilograms}',
              ),
              DetailPair(
                label: l10n.fieldSexAge,
                value: _sexAndAge(l10n),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// "Male, 4 yrs" — or whichever half is known, or null for neither.
  String? _sexAndAge(AppLocalizations l10n) {
    final String? sex = pregnancy.sex == null
        ? null
        : sexLabel(l10n, pregnancy.sex!);
    final String? age = pregnancy.ageYears == null
        ? null
        : l10n.ageInYears(pregnancy.ageYears!);

    if (sex != null && age != null) return '$sex, $age';
    return sex ?? age;
  }
}
