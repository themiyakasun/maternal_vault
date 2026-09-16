import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/cards/tile_card.dart';
import '../../../../core/widgets/detail_grid.dart';
import '../../../../core/widgets/section_heading.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/obstetric_history.dart';
import '../widgets/obstetric_labels.dart';

/// The mother's third tab: how many pregnancies there have been, what was
/// screened at booking, the dates this one turns on, and every pregnancy before
/// it.
///
/// All data here reflects the mother's official clinic book (MOH Form H 512 A)
/// recorded by clinical officers at booking, presented in read-only form.
class ObstetricHistoryScreen extends StatefulWidget {
  const ObstetricHistoryScreen({
    super.key,
    this.history = const ObstetricHistory.empty(),
    this.onChanged,
  });

  /// What the screen starts on. Defaults to a record with nothing entered.
  final ObstetricHistory history;

  /// Fired with the full record after every change.
  final ValueChanged<ObstetricHistory>? onChanged;

  @override
  State<ObstetricHistoryScreen> createState() => _ObstetricHistoryScreenState();
}

class _ObstetricHistoryScreenState extends State<ObstetricHistoryScreen> {
  late ObstetricHistory _history = widget.history;

  @override
  void didUpdateWidget(ObstetricHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.history != oldWidget.history) {
      setState(() {
        _history = widget.history;
      });
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
          SectionHeading(title: l10n.sectionCurrentHistory),
          const SizedBox(height: AppSpacing.stackMd),
          _counts(l10n),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeading(title: l10n.fieldRiskConditions),
          const SizedBox(height: AppSpacing.stackMd),
          _riskConditionsSection(l10n),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeading(title: l10n.sectionScreening),
          const SizedBox(height: AppSpacing.stackMd),
          _screening(l10n),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeading(title: l10n.sectionKeyDates),
          const SizedBox(height: AppSpacing.stackMd),
          _keyDates(l10n),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeading(title: l10n.sectionPastObstetric),
          const SizedBox(height: AppSpacing.stackMd),
          _pastPregnancies(l10n),
        ],
      ),
    );
  }

  /// Gravidity, Parity, Living Children, and Youngest Child's Age.
  Widget _counts(AppLocalizations l10n) {
    return AppCard(
      child: DetailGrid(
        items: <DetailPair>[
          DetailPair(
            label: l10n.fieldGravidity,
            value: _history.gravidity?.toString(),
          ),
          DetailPair(
            label: l10n.fieldParity,
            value: _history.parity?.toString(),
          ),
          DetailPair(
            label: l10n.fieldLivingChildren,
            value: _history.livingChildren?.toString(),
          ),
          DetailPair(
            label: l10n.fieldYoungestChildAge,
            value: _history.youngestChildAgeYears == null
                ? null
                : l10n.ageInYears(_history.youngestChildAgeYears!),
          ),
        ],
      ),
    );
  }

  Widget _riskConditionsSection(AppLocalizations l10n) {
    return AppCard(
      leadingAccent: _history.riskConditionsAndMorbidities != null
          ? AppColors.error
          : null,
      child: DetailGrid(
        columns: 1,
        items: <DetailPair>[
          DetailPair(
            label: l10n.fieldRiskConditions,
            value: _history.riskConditionsAndMorbidities,
          ),
        ],
      ),
    );
  }

  Widget _screening(AppLocalizations l10n) {
    return TileCard(
      children: <Widget>[
        for (final ObstetricScreening question in ObstetricScreening.values)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.unit,
              horizontal: AppSpacing.unit,
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  _history.hasScreening(question)
                      ? Icons.check_circle_rounded
                      : Icons.remove_circle_outline_rounded,
                  color: _history.hasScreening(question)
                      ? AppColors.health
                      : AppColors.outline,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.stackMd),
                Expanded(
                  child: Text(
                    screeningLabel(l10n, question),
                    style: AppTextStyles.bodyLg,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String? _formatDate(MaterialLocalizations material, DateTime? date) {
    if (date == null) return null;
    return '${material.formatShortMonthDay(date)}, ${material.formatYear(date)}';
  }

  /// The clinic dates, registration details, and contraceptive history.
  Widget _keyDates(AppLocalizations l10n) {
    final MaterialLocalizations material = MaterialLocalizations.of(context);

    return AppCard(
      child: DetailGrid(
        items: <DetailPair>[
          DetailPair(
            label: l10n.fieldLrmp,
            value: _formatDate(material, _history.lastMenstrualPeriod),
          ),
          DetailPair(
            label: l10n.fieldEdd,
            value: _formatDate(material, _history.expectedDelivery),
          ),
          DetailPair(
            label: l10n.fieldUltrasoundEdd,
            value: _formatDate(material, _history.ultrasoundExpectedDelivery),
          ),
          DetailPair(
            label: l10n.fieldExpectedPeriod,
            value: _history.expectedDeliveryPeriod,
          ),
          DetailPair(
            label: l10n.fieldQuickening,
            value: _formatDate(material, _history.quickening),
          ),
          DetailPair(
            label: l10n.fieldPoaAtRegistration,
            value: _history.poaAtRegistrationWeeks == null
                ? null
                : l10n.weeksShort(_history.poaAtRegistrationWeeks!),
          ),
          DetailPair(
            label: l10n.fieldContraceptiveLastUsed,
            value: _history.contraceptiveMethodLastUsed,
          ),
        ],
      ),
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
              if (pregnancy.placeOfDelivery != null &&
                  pregnancy.placeOfDelivery!.isNotEmpty)
                DetailPair(
                  label: l10n.fieldPlaceOfDelivery,
                  value: pregnancy.placeOfDelivery,
                ),
              if (pregnancy.antenatalComplications != null &&
                  pregnancy.antenatalComplications!.isNotEmpty)
                DetailPair(
                  label: l10n.fieldAntenatalComplications,
                  value: pregnancy.antenatalComplications,
                ),
              if (pregnancy.postnatalComplications != null &&
                  pregnancy.postnatalComplications!.isNotEmpty)
                DetailPair(
                  label: l10n.fieldPostnatalComplications,
                  value: pregnancy.postnatalComplications,
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
