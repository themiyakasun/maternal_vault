import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/buttons/app_text_button.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/charts/chart_card.dart';
import '../../../../core/widgets/charts/line_chart.dart';
import '../../../../core/widgets/section_heading.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/clinic_record.dart';
import '../widgets/clinic_visit_card.dart';
import '../widgets/clinic_visit_sheet.dart';

/// The mother's fourth tab: the routine visits, the button that adds one, and
/// the two curves those visits draw.
///
/// Holds the record it was given so a visit logged here appears immediately —
/// both as a card and as a point on the charts — and reports the whole record
/// through [onChanged] for whoever will persist it.
class ClinicVisitsScreen extends StatefulWidget {
  const ClinicVisitsScreen({
    super.key,
    this.record = const ClinicRecord.empty(),
    this.onChanged,
    this.onViewAllVisits,
  });

  final ClinicRecord record;

  /// Called with the whole record after a visit is added. Null is fine — the tab
  /// still works, the addition just does not outlive the session.
  final ValueChanged<ClinicRecord>? onChanged;

  /// Opens the full visit history. Null shows a notice rather than a dead button.
  final VoidCallback? onViewAllVisits;

  @override
  State<ClinicVisitsScreen> createState() => _ClinicVisitsScreenState();
}

class _ClinicVisitsScreenState extends State<ClinicVisitsScreen> {
  late ClinicRecord _record = widget.record;

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
          _padded(
            AppPrimaryButton(
              label: l10n.actionLogVisit,
              icon: Icons.add_rounded,
              onPressed: _logVisit,
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          _padded(SectionHeading(title: l10n.sectionGrowthTracking)),
          const SizedBox(height: AppSpacing.stackMd),
          _padded(_weightChart(context, l10n)),
          const SizedBox(height: AppSpacing.componentGap),
          _padded(_fundalHeightChart(context, l10n)),
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
              ClinicVisitCard(visit: _record.visits[i]),
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

  Future<void> _logVisit() async {
    final ClinicVisit? added = await showClinicVisitSheet(context);

    // Null means the sheet was dismissed without saving.
    if (added == null) return;

    setState(() => _record = _record.withVisit(added));
    widget.onChanged?.call(_record);
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

    // TODO: remove once the full visit list exists.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).clinicViewAllNotConnected),
      ),
    );
  }
}
