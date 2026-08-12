import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons/app_button_tone.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/checklist_tile.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/section_heading.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/partner_agenda.dart';

/// The partner's calendar tab: the next clinic visit, a reminder, and a
/// checklist of things to prepare before it.
///
/// Stateful for the checklist alone — ticking a task is a local, in-session
/// change until a record layer can store it, so the count in the heading and the
/// struck-through rows update at once. [agenda] supplies the visit.
class PartnerCalendarScreen extends StatefulWidget {
  const PartnerCalendarScreen({
    super.key,
    this.agenda = const PartnerAgenda.empty(),
    this.onAddToCalendar,
  });

  final PartnerAgenda agenda;

  /// Adds the visit to the device calendar. Null shows a notice rather than
  /// pretending it worked.
  final VoidCallback? onAddToCalendar;

  @override
  State<PartnerCalendarScreen> createState() => _PartnerCalendarScreenState();
}

class _PartnerCalendarScreenState extends State<PartnerCalendarScreen> {
  /// Which tasks are ticked. Local until there is somewhere to persist it.
  final Set<PartnerPrepTask> _done = <PartnerPrepTask>{};

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final int remaining = PartnerPrepTask.values.length - _done.length;

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
          _intro(l10n),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeading(title: l10n.partnerUpcomingVisit),
          const SizedBox(height: AppSpacing.stackMd),
          _visit(context, l10n),
          const SizedBox(height: AppSpacing.componentGap),
          InfoBanner(message: l10n.partnerVisitReminder),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeading(
            title: l10n.partnerActionChecklist,
            trailing: StatusChip(
              label: remaining == 0
                  ? l10n.partnerAllTasksDone
                  : l10n.partnerTasksRemaining(remaining),
              accent: AppColors.tertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          ..._checklist(l10n),
        ],
      ),
    );
  }

  Widget _intro(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(l10n.partnerCalendarTitle, style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          l10n.partnerCalendarSubtitle,
          style: AppTextStyles.bodyLg.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _visit(BuildContext context, AppLocalizations l10n) {
    final ClinicAppointment? visit = widget.agenda.nextVisit;
    if (visit == null) {
      return AppCard(
        child: Text(l10n.partnerNoUpcomingVisit, style: AppTextStyles.bodySm),
      );
    }

    final MaterialLocalizations material = MaterialLocalizations.of(context);
    final String date =
        '${material.formatShortMonthDay(visit.date)}, ${material.formatYear(visit.date)}';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.partnerNextClinicVisit,
                      style: AppTextStyles.labelCaps.copyWith(
                        color: AppColors.tertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    Text(date, style: AppTextStyles.h2),
                    const SizedBox(height: 4),
                    _iconLine(
                      Icons.access_time_rounded,
                      material.formatTimeOfDay(visit.time),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.outlineVariant,
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.location_on_outlined,
                size: 20,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.stackSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      visit.hospital,
                      style: AppTextStyles.bodyLg.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(visit.ward, style: AppTextStyles.bodySm),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),
          AppPrimaryButton(
            label: l10n.partnerAddToCalendar,
            icon: Icons.calendar_month_rounded,
            tone: AppButtonTone.secondary,
            onPressed: () => _addToCalendar(l10n),
          ),
        ],
      ),
    );
  }

  Widget _iconLine(IconData icon, String text) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
        const SizedBox(width: AppSpacing.stackSm),
        Text(
          text,
          style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurface),
        ),
      ],
    );
  }

  List<Widget> _checklist(AppLocalizations l10n) {
    final List<PartnerPrepTask> tasks = PartnerPrepTask.values;
    final List<Widget> out = <Widget>[];
    for (int i = 0; i < tasks.length; i++) {
      if (i > 0) out.add(const SizedBox(height: AppSpacing.componentGap));
      final PartnerPrepTask task = tasks[i];
      out.add(
        ChecklistTile(
          title: _taskTitle(l10n, task),
          subtitle: _taskBody(l10n, task),
          done: _done.contains(task),
          onToggle: () => setState(() {
            // add() returns false when already present — that is the untick.
            if (!_done.add(task)) _done.remove(task);
          }),
        ),
      );
    }
    return out;
  }

  void _addToCalendar(AppLocalizations l10n) {
    final VoidCallback? handler = widget.onAddToCalendar;
    if (handler != null) {
      handler();
      return;
    }

    // TODO: wire device-calendar insertion and pass it in as onAddToCalendar.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.partnerCalendarAddNotConnected)),
    );
  }

  String _taskTitle(AppLocalizations l10n, PartnerPrepTask task) {
    switch (task) {
      case PartnerPrepTask.hospitalBag:
        return l10n.partnerTaskBagTitle;
      case PartnerPrepTask.birthPlan:
        return l10n.partnerTaskBirthPlanTitle;
      case PartnerPrepTask.folicAcid:
        return l10n.partnerTaskFolicTitle;
    }
  }

  String _taskBody(AppLocalizations l10n, PartnerPrepTask task) {
    switch (task) {
      case PartnerPrepTask.hospitalBag:
        return l10n.partnerTaskBagBody;
      case PartnerPrepTask.birthPlan:
        return l10n.partnerTaskBirthPlanBody;
      case PartnerPrepTask.folicAcid:
        return l10n.partnerTaskFolicBody;
    }
  }
}
