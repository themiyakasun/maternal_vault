import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/contact_tile.dart';
import '../../../../core/widgets/labeled_field.dart';
import '../../../../core/widgets/section_heading.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/emergency_plan.dart';

/// The partner's emergency tab: who to call and how to reach the hospital, laid
/// out to be read at a glance under stress.
///
/// Stateless — nothing here is edited, only shown. [plan] supplies the contacts
/// and travel details; the call button reports through [onCall].
class PartnerEmergencyScreen extends StatelessWidget {
  const PartnerEmergencyScreen({
    super.key,
    this.plan = const EmergencyPlan.empty(),
    this.onCall,
  });

  final EmergencyPlan plan;

  /// Places a call to a contact. Null shows a notice rather than pretending it
  /// dialled.
  final void Function(EmergencyContact contact)? onCall;

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
          _intro(l10n),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeading(
            icon: Icons.contact_emergency_rounded,
            accent: AppColors.primary,
            title: l10n.partnerQuickContacts,
          ),
          const SizedBox(height: AppSpacing.stackMd),
          _contacts(context, l10n),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeading(
            icon: Icons.map_rounded,
            accent: AppColors.secondary,
            title: l10n.partnerBirthPlanLogistics,
          ),
          const SizedBox(height: AppSpacing.stackMd),
          _logistics(l10n),
        ],
      ),
    );
  }

  Widget _intro(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.partnerEmergencyTitle,
          style: AppTextStyles.h2.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          l10n.partnerEmergencySubtitle,
          style: AppTextStyles.bodyLg.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _contacts(BuildContext context, AppLocalizations l10n) {
    if (plan.contacts.isEmpty) {
      return AppCard(
        child: Text(l10n.partnerNoContacts, style: AppTextStyles.bodySm),
      );
    }

    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < plan.contacts.length; i++) {
      if (i > 0) rows.add(const SizedBox(height: AppSpacing.componentGap));
      final EmergencyContact contact = plan.contacts[i];
      rows.add(
        ContactTile(
          role: _role(l10n, contact.kind),
          name: contact.name,
          accent: _accent(contact.kind),
          avatarIcon: _avatar(contact.kind),
          emphasized: contact.kind == EmergencyContactKind.emergencyPerson,
          callTooltip: l10n.actionCall,
          onCall: () => _call(context, l10n, contact),
        ),
      );
    }
    return AppCard(child: Column(children: rows));
  }

  Widget _logistics(AppLocalizations l10n) {
    final BirthPlanLogistics? logistics = plan.logistics;
    if (logistics == null) {
      return AppCard(
        child: Text(l10n.partnerLogisticsEmpty, style: AppTextStyles.bodySm),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _map(l10n),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                LabeledField(
                  icon: Icons.apartment_rounded,
                  accent: AppColors.primary,
                  label: l10n.partnerIntendedHospital,
                  value: logistics.hospital,
                ),
                const SizedBox(height: AppSpacing.componentGap),
                LabeledField(
                  icon: Icons.directions_car_rounded,
                  accent: AppColors.tertiary,
                  label: l10n.partnerModeOfTransport,
                  value: logistics.transport,
                ),
                const SizedBox(height: AppSpacing.componentGap),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: LabeledField(
                        icon: Icons.route_rounded,
                        accent: AppColors.secondary,
                        label: l10n.partnerDistance,
                        value: l10n.partnerDistanceValue(logistics.distanceKm),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.componentGap),
                    Expanded(
                      child: LabeledField(
                        icon: Icons.schedule_rounded,
                        accent: AppColors.secondary,
                        label: l10n.partnerEstTime,
                        value: l10n.partnerEstTimeValue(logistics.estMinutes),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A stand-in for the route map — the app ships no map tiles, so rather than
  /// fake one it shows a calm placeholder with the live-traffic note.
  Widget _map(AppLocalizations l10n) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadii.lg),
      ),
      child: SizedBox(
        height: 150,
        child: ColoredBox(
          color: AppColors.tertiary.withValues(alpha: 0.08),
          child: Stack(
            children: <Widget>[
              Center(
                child: Icon(
                  Icons.map_rounded,
                  size: 40,
                  color: AppColors.tertiary.withValues(alpha: 0.5),
                ),
              ),
              PositionedDirectional(
                end: AppSpacing.stackMd,
                bottom: AppSpacing.stackMd,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: AppRadii.pill,
                    boxShadow: AppColors.shadowCard,
                  ),
                  child: Text(
                    l10n.partnerLiveTraffic,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _call(
    BuildContext context,
    AppLocalizations l10n,
    EmergencyContact contact,
  ) {
    final void Function(EmergencyContact)? handler = onCall;
    if (handler != null) {
      handler(contact);
      return;
    }

    // TODO: wire the platform dialer and pass it in as onCall.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.partnerCallNotConnected)),
    );
  }

  String _role(AppLocalizations l10n, EmergencyContactKind kind) {
    switch (kind) {
      case EmergencyContactKind.emergencyPerson:
        return l10n.partnerContactEmergency;
      case EmergencyContactKind.phm:
        return l10n.partnerContactPhm;
      case EmergencyContactKind.moh:
        return l10n.partnerContactMoh;
    }
  }

  Color _accent(EmergencyContactKind kind) {
    switch (kind) {
      case EmergencyContactKind.emergencyPerson:
        return AppColors.primary;
      case EmergencyContactKind.phm:
        return AppColors.secondary;
      case EmergencyContactKind.moh:
        return AppColors.tertiary;
    }
  }

  IconData? _avatar(EmergencyContactKind kind) {
    switch (kind) {
      case EmergencyContactKind.emergencyPerson:
        return Icons.person_rounded;
      case EmergencyContactKind.phm:
        return null;
      case EmergencyContactKind.moh:
        return Icons.local_hospital_rounded;
    }
  }
}
