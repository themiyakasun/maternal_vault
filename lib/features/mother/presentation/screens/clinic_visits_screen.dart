import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons/app_text_button.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/cards/section_card.dart';
import '../../../../core/widgets/charts/chart_card.dart';
import '../../../../core/widgets/charts/line_chart.dart';
import '../../../../core/widgets/detail_grid.dart';
import '../../../../core/widgets/section_heading.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/clinic_record.dart';
import '../widgets/clinic_visit_card.dart';
import '../widgets/clinic_visit_sheet.dart';

/// The mother's fourth tab: the routine visits, growth tracking curves,
/// system exams, investigations, tetanus immunizations, dental care, and referrals.
///
/// All data here reflects the mother's official clinic book (MOH Form H 512 A)
/// recorded by clinical officers, presented in read-only form.
class ClinicVisitsScreen extends StatefulWidget {
  const ClinicVisitsScreen({
    super.key,
    this.record = const ClinicRecord.empty(),
    this.onChanged,
    this.onViewAllVisits,
    this.onScanQr,
  });

  final ClinicRecord record;

  /// Called with the whole record after any change.
  final ValueChanged<ClinicRecord>? onChanged;

  /// Opens the full visit history. Null shows a notice rather than a dead button.
  final VoidCallback? onViewAllVisits;

  /// Opens the midwife QR scanner to import records.
  final VoidCallback? onScanQr;

  @override
  State<ClinicVisitsScreen> createState() => _ClinicVisitsScreenState();
}

class _ClinicVisitsScreenState extends State<ClinicVisitsScreen> {
  late ClinicRecord _record = widget.record;

  @override
  void didUpdateWidget(ClinicVisitsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.record != oldWidget.record) {
      setState(() {
        _record = widget.record;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      // No horizontal padding on the scroll view itself: the visit strip runs to
      // both edges, so each block pads itself instead.
      padding: const EdgeInsets.only(
        top: AppSpacing.stackSm,
        bottom: AppSpacing.sectionGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (widget.onScanQr != null) ...[
            _padded(_buildSyncCard(context, l10n)),
            const SizedBox(height: AppSpacing.sectionGap),
          ],
          _padded(
            SectionHeading(
              title: l10n.sectionRoutineLogs,
              trailing: AppTextButton(
                label: l10n.actionViewAll,
                caps: true,
                onPressed: () => _openViewAll(context),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          _visits(context, l10n),
          const SizedBox(height: AppSpacing.sectionGap),
          _padded(SectionHeading(title: l10n.sectionGrowthTracking)),
          const SizedBox(height: AppSpacing.stackMd),
          _padded(_weightChart(context, l10n)),
          const SizedBox(height: AppSpacing.componentGap),
          _padded(_fundalHeightChart(context, l10n)),
          const SizedBox(height: AppSpacing.sectionGap),
          _padded(_systemExams(context, l10n)),
          const SizedBox(height: AppSpacing.sectionGap),
          _padded(_investigations(context, l10n)),
          const SizedBox(height: AppSpacing.sectionGap),
          _padded(_tetanus(context, l10n)),
          const SizedBox(height: AppSpacing.sectionGap),
          _padded(_dental(context, l10n)),
          const SizedBox(height: AppSpacing.sectionGap),
          _padded(_referrals(context, l10n)),
        ],
      ),
    );
  }

  Widget _buildSyncCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.midwifeSyncButtonCard,
                  style: AppTextStyles.bodyLg.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.midwifeSyncButtonCardDesc,
                  style: AppTextStyles.bodySm,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            tooltip: l10n.actionScanMidwifeQr,
            onPressed: widget.onScanQr,
          ),
        ],
      ),
    );
  }

  Widget _padded(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      child: child,
    );
  }

  Widget _visits(BuildContext context, AppLocalizations l10n) {
    if (_record.visits.isEmpty) {
      return _padded(
        AppCard(
          child: Text(
            l10n.visitsEmpty,
            style: AppTextStyles.bodySm,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      // IntrinsicHeight so every card in the strip is as tall as the tallest:
      // these are compared side by side, and a short card beside a tall one
      // reads as a card missing a row.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (int i = 0; i < _record.visits.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: AppSpacing.componentGap),
              ClinicVisitCard(
                visit: _record.visits[i],
                onTap: () => showClinicVisitDetailSheet(
                  context,
                  visit: _record.visits[i],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _weightChart(BuildContext context, AppLocalizations l10n) {
    return ChartCard(
      title: l10n.chartWeightGain,
      infoTooltip: l10n.actionWhatIsThis,
      onInfo: () => _showInfo(
        context,
        title: l10n.chartWeightGain,
        body: l10n.chartWeightGainInfo,
      ),
      child: LineChart(
        emptyLabel: l10n.chartEmpty,
        xLabels: _weekLabels(l10n, _record.weightGain),
        series: <ChartSeries>[
          ChartSeries(
            label: l10n.legendYourWeight,
            color: AppColors.chartMother,
            points: _points(_record.weightGain),
          ),
        ],
      ),
    );
  }

  Widget _fundalHeightChart(BuildContext context, AppLocalizations l10n) {
    return ChartCard(
      title: l10n.chartFundalHeight,
      infoTooltip: l10n.actionWhatIsThis,
      onInfo: () => _showInfo(
        context,
        title: l10n.chartFundalHeight,
        body: l10n.chartFundalHeightInfo,
      ),
      child: LineChart(
        emptyLabel: l10n.chartEmpty,
        xLabels: _weekLabels(
          l10n,
          _record.fundalHeight.isEmpty
              ? _record.expectedFundalHeight
              : _record.fundalHeight,
        ),
        series: <ChartSeries>[
          // Reference first, so the measured line draws over it where they meet.
          ChartSeries(
            label: l10n.legendExpected,
            color: AppColors.outlineVariant,
            dashed: true,
            strokeWidth: 2,
            points: _points(_record.expectedFundalHeight),
          ),
          ChartSeries(
            label: l10n.legendYourFundalHeight,
            color: AppColors.chartBaby,
            points: _points(_record.fundalHeight),
          ),
        ],
      ),
    );
  }

  List<Offset> _points(List<GrowthPoint> points) {
    return <Offset>[
      for (final GrowthPoint point in points)
        Offset(point.week.toDouble(), point.value),
    ];
  }

  /// Four evenly spaced week markers across whatever range was measured, so the
  /// axis describes the data rather than a fixed 12-to-40 assumption.
  List<String> _weekLabels(AppLocalizations l10n, List<GrowthPoint> points) {
    if (points.length < 2) return const <String>[];

    const int count = 4;
    final int first = points.first.week;
    final int last = points.last.week;

    return <String>[
      for (int i = 0; i < count; i++)
        l10n.weeksShort(first + ((last - first) * i / (count - 1)).round()),
    ];
  }

  Future<void> _showInfo(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title, style: AppTextStyles.h3),
        content: Text(body, style: AppTextStyles.bodyLg),
        actions: <Widget>[
          AppTextButton(
            label: AppLocalizations.of(context).actionClose,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _openViewAll(BuildContext context) {
    final VoidCallback? onViewAll = widget.onViewAllVisits;
    if (onViewAll != null) {
      onViewAll();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).clinicViewAllNotConnected),
      ),
    );
  }

  String? _formatDate(MaterialLocalizations material, DateTime? date) {
    if (date == null) return null;
    return '${material.formatShortMonthDay(date)}, ${material.formatYear(date)}';
  }

  Widget _systemExams(BuildContext context, AppLocalizations l10n) {
    final TrimesterSystemExams exams = _record.systemExams;

    return SectionCard(
      icon: Icons.monitor_heart_outlined,
      title: l10n.sectionSystemExams,
      accent: AppColors.secondary,
      children: <Widget>[
        DetailGrid(
          items: <DetailPair>[
            DetailPair(
              label: l10n.fieldCvsTrimester1,
              value: exams.cvsTrimester1,
            ),
            DetailPair(
              label: l10n.fieldCvsTrimester2,
              value: exams.cvsTrimester2,
            ),
            DetailPair(
              label: l10n.fieldCvsTrimester3,
              value: exams.cvsTrimester3,
            ),
            DetailPair(
              label: l10n.fieldRespiratory,
              value: exams.respiratory,
            ),
          ],
        ),
        const Divider(),
        DetailGrid(
          columns: 1,
          items: <DetailPair>[
            DetailPair(
              label: l10n.fieldBreastExam,
              value: exams.breastExam,
            ),
          ],
        ),
      ],
    );
  }

  Widget _investigations(BuildContext context, AppLocalizations l10n) {
    final MaterialLocalizations material = MaterialLocalizations.of(context);
    final LabInvestigations inv = _record.investigations;

    return SectionCard(
      icon: Icons.science_outlined,
      title: l10n.sectionInvestigations,
      accent: AppColors.primary,
      children: <Widget>[
        DetailGrid(
          items: <DetailPair>[
            DetailPair(
              label: l10n.fieldBloodSugar,
              value: inv.bloodSugar,
            ),
            DetailPair(
              label: l10n.fieldHaemoglobin,
              value: inv.haemoglobin,
            ),
          ],
        ),
        if (inv.otherInvestigations != null &&
            inv.otherInvestigations!.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.componentGap),
          DetailGrid(
            columns: 1,
            items: <DetailPair>[
              DetailPair(
                label: l10n.fieldOtherInvestigations,
                value: inv.otherInvestigations,
              ),
            ],
          ),
        ],
        const Divider(),
        Text(l10n.fieldSyphilisScreening, style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.stackSm),
        DetailGrid(
          items: <DetailPair>[
            DetailPair(
              label: l10n.fieldSyphilisSamplingDate,
              value: _formatDate(material, inv.syphilis.samplingDate),
            ),
            DetailPair(
              label: l10n.fieldSyphilisResultDate,
              value: _formatDate(material, inv.syphilis.resultDate),
            ),
            DetailPair(
              label: l10n.fieldSyphilisResult,
              value: inv.syphilis.result,
            ),
            if (inv.syphilis.referralDate != null)
              DetailPair(
                label: l10n.fieldSyphilisReferral,
                value: _formatDate(material, inv.syphilis.referralDate),
              ),
          ],
        ),
        const Divider(),
        DetailGrid(
          columns: 1,
          items: <DetailPair>[
            DetailPair(
              label: l10n.fieldAntihelminthic,
              value: _formatDate(material, inv.antihelminthicDate),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tetanus(BuildContext context, AppLocalizations l10n) {
    final MaterialLocalizations material = MaterialLocalizations.of(context);
    final TetanusImmunization tetanus = _record.tetanus;

    return SectionCard(
      icon: Icons.vaccines_outlined,
      title: l10n.sectionTetanus,
      accent: AppColors.primary,
      children: <Widget>[
        DetailGrid(
          items: <DetailPair>[
            DetailPair(
              label: l10n.fieldTtDose('1'),
              value: _formatDate(material, tetanus.dose1Date),
            ),
            DetailPair(
              label: l10n.fieldTtDose('2'),
              value: _formatDate(material, tetanus.dose2Date),
            ),
            DetailPair(
              label: l10n.fieldTtDose('3'),
              value: _formatDate(material, tetanus.dose3Date),
            ),
            DetailPair(
              label: l10n.fieldTtDose('4'),
              value: _formatDate(material, tetanus.dose4Date),
            ),
            DetailPair(
              label: l10n.fieldTtDose('5'),
              value: _formatDate(material, tetanus.dose5Date),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dental(BuildContext context, AppLocalizations l10n) {
    final MaterialLocalizations material = MaterialLocalizations.of(context);
    final DentalCare dental = _record.dental;

    return SectionCard(
      icon: Icons.medical_services_outlined,
      title: l10n.sectionDental,
      accent: AppColors.tertiary,
      children: <Widget>[
        DetailGrid(
          items: <DetailPair>[
            DetailPair(
              label: l10n.fieldDentalReferral,
              value: _formatDate(material, dental.referralDate),
            ),
            DetailPair(
              label: l10n.fieldDentalScreened,
              value: _formatDate(material, dental.screenedDate),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.componentGap),
        DetailGrid(
          columns: 1,
          items: <DetailPair>[
            DetailPair(
              label: l10n.fieldDentalTreatment,
              value: dental.treatmentStatus,
            ),
          ],
        ),
      ],
    );
  }

  Widget _referrals(BuildContext context, AppLocalizations l10n) {
    final ClinicReferral referrals = _record.referrals;

    return SectionCard(
      icon: Icons.assignment_outlined,
      title: l10n.sectionReferrals,
      accent: AppColors.secondary,
      children: <Widget>[
        DetailGrid(
          columns: 1,
          items: <DetailPair>[
            DetailPair(
              label: l10n.fieldReferralNotes,
              value: referrals.notes,
            ),
          ],
        ),
      ],
    );
  }
}
