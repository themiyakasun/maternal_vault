import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/brand_backdrop.dart';
import '../../../../core/widgets/buttons/app_button_tone.dart';
import '../../../../core/widgets/buttons/app_outline_button.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../partner/data/services/partner_sync_service.dart';
import '../../data/services/midwife_sync_service.dart';
import '../../domain/basic_profile.dart';
import '../../domain/clinic_record.dart';
import '../../domain/delivery_plan.dart';
import '../../domain/key_vitals.dart';
import '../../domain/transport_mode.dart';

/// Screen that generates and displays a secure QR code for transferring
/// vital pregnancy updates, emergency plans, and clinic schedules to the partner's phone.
class PartnerShareQrScreen extends StatefulWidget {
  const PartnerShareQrScreen({
    super.key,
    required this.profile,
    required this.vitals,
    required this.deliveryPlan,
    required this.clinicRecord,
  });

  final BasicProfile profile;
  final KeyVitals vitals;
  final DeliveryPlan deliveryPlan;
  final ClinicRecord clinicRecord;

  static Route<void> route({
    required BasicProfile profile,
    required KeyVitals vitals,
    required DeliveryPlan deliveryPlan,
    required ClinicRecord clinicRecord,
  }) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (BuildContext context, _, _) => PartnerShareQrScreen(
        profile: profile,
        vitals: vitals,
        deliveryPlan: deliveryPlan,
        clinicRecord: clinicRecord,
      ),
      transitionsBuilder:
          (BuildContext context, Animation<double> animation, _, Widget child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  @override
  State<PartnerShareQrScreen> createState() => _PartnerShareQrScreenState();
}

class _PartnerShareQrScreenState extends State<PartnerShareQrScreen> {
  QrTransferMode _selectedMode = QrTransferMode.gzipCompressed;

  String get _qrPayload {
    switch (_selectedMode) {
      case QrTransferMode.gzipCompressed:
        return PartnerSyncService.generatePartnerQrString(
          profile: widget.profile,
          vitals: widget.vitals,
          deliveryPlan: widget.deliveryPlan,
          clinicRecord: widget.clinicRecord,
          compress: true,
          useGzip: true,
        );
      case QrTransferMode.cameraLink:
        final regId =
            widget.profile.registrationNumber?.replaceAll('#', '') ?? '6720';
        return 'https://maternavault.gov.lk/partner/view?id=$regId';
      case QrTransferMode.fullJson:
        return PartnerSyncService.generatePartnerQrString(
          profile: widget.profile,
          vitals: widget.vitals,
          deliveryPlan: widget.deliveryPlan,
          clinicRecord: widget.clinicRecord,
          compress: false,
        );
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _qrPayload));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Partner transfer code copied to clipboard!'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showEnlargedQr() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  widget.profile.motherName.isNotEmpty
                      ? widget.profile.motherName
                      : 'Partner Transfer Code',
                  style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Scan using Partner Phone',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                QrImageView(
                  data: _qrPayload,
                  version: QrVersions.auto,
                  size: 280.0,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.primary,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 20),
                AppPrimaryButton(
                  label: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  tone: AppButtonTone.secondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getTransportLabel(TransportMode? mode) {
    switch (mode) {
      case TransportMode.ambulance:
        return 'Ambulance (1990)';
      case TransportMode.ownVehicle:
        return 'Personal Vehicle';
      case TransportMode.threeWheeler:
        return 'Three-Wheeler';
      case TransportMode.publicTransport:
        return 'Public Transport';
      case TransportMode.neighbourVehicle:
        return "Neighbour's Vehicle";
      case TransportMode.other:
      case null:
        return 'Ambulance (1990)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final weeks = widget.clinicRecord.visits.isNotEmpty
        ? widget.clinicRecord.visits.first.week
        : 38;

    final hospital = (widget.deliveryPlan.intendedHospital != null &&
            widget.deliveryPlan.intendedHospital!.isNotEmpty)
        ? widget.deliveryPlan.intendedHospital!
        : ((widget.deliveryPlan.deliveryHospital != null &&
                widget.deliveryPlan.deliveryHospital!.isNotEmpty)
            ? widget.deliveryPlan.deliveryHospital!
            : 'Base Hospital Rampur');

    final emergencyContact = (widget.profile.emergencyContactPerson != null &&
            widget.profile.emergencyContactPerson!.isNotEmpty)
        ? widget.profile.emergencyContactPerson!
        : ((widget.profile.father.occupation != null &&
                widget.profile.father.occupation!.isNotEmpty)
            ? widget.profile.father.occupation!
            : 'Partner');

    return Scaffold(
      body: BrandBackdrop(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.stackSm,
                ),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: AppSpacing.stackSm),
                    Expanded(
                      child: Text(
                        'Transfer to Partner',
                        style: AppTextStyles.h3,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: _copyToClipboard,
                      tooltip: 'Copy Code',
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const SizedBox(height: AppSpacing.stackSm),

                      // Intro notice
                      const InfoBanner(
                        message:
                            'Your partner will receive offline access to your emergency plan, hospital details, and clinic schedule.',
                      ),

                      const SizedBox(height: AppSpacing.sectionGap),

                      // 3 Dedicated QR Code Transfer Modes Segmented Selector
                      Center(
                        child: SegmentedButton<QrTransferMode>(
                          segments: const <ButtonSegment<QrTransferMode>>[
                            ButtonSegment<QrTransferMode>(
                              value: QrTransferMode.gzipCompressed,
                              label: Text('⚡ Gzip Fast',
                                  style: TextStyle(fontSize: 12)),
                            ),
                            ButtonSegment<QrTransferMode>(
                              value: QrTransferMode.cameraLink,
                              label: Text('📱 Camera Pass',
                                  style: TextStyle(fontSize: 12)),
                            ),
                            ButtonSegment<QrTransferMode>(
                              value: QrTransferMode.fullJson,
                              label: Text('💾 JSON Vault',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ],
                          selected: <QrTransferMode>{_selectedMode},
                          onSelectionChanged:
                              (Set<QrTransferMode> newSelection) {
                            setState(() {
                              _selectedMode = newSelection.first;
                            });
                          },
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.stackSm),

                      // Mode description & badge
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: Text(
                            _selectedMode == QrTransferMode.gzipCompressed
                                ? '⚡ ~70.9% smaller • Ultra-Fast Gzip QR'
                                : (_selectedMode == QrTransferMode.cameraLink
                                    ? '📱 Phone Camera Pass (Web URL Link)'
                                    : '💾 JSON Vault (Raw Uncompressed Backup)'),
                            style: AppTextStyles.labelCaps.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.stackMd),

                      // QR Code Card
                      Center(
                        child: GestureDetector(
                          onTap: _showEnlargedQr,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: AppColors.shadowCard,
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                QrImageView(
                                  data: _qrPayload,
                                  version: QrVersions.auto,
                                  size: 220.0,
                                  backgroundColor: Colors.white,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: AppColors.primary,
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.zoom_in_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Tap to enlarge',
                                      style: AppTextStyles.labelCaps.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sectionGap),

                      // Shared Data Summary
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: [
                                const Icon(
                                  Icons.lock_person_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Shared With Partner',
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _DataRow(
                              label: 'Mother',
                              value: widget.profile.motherName.isNotEmpty
                                  ? widget.profile.motherName
                                  : 'Kumari Sandamali Perera',
                            ),
                            _DataRow(
                              label: 'Gestational Progress',
                              value: '$weeks Weeks',
                            ),
                            _DataRow(
                              label: 'Delivery Hospital',
                              value: hospital,
                            ),
                            _DataRow(
                              label: 'Emergency Transport',
                              value: _getTransportLabel(widget.deliveryPlan.transportMode),
                            ),
                            _DataRow(
                              label: 'Emergency Contact',
                              value: emergencyContact,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.stackMd),

                      // Privacy Badge
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.verified_user_outlined,
                              color: AppColors.onSurfaceVariant,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Personal clinical notes and confidential lab tests stay private on this device.',
                                style: AppTextStyles.bodySm.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sectionGap),

                      // Actions
                      AppPrimaryButton(
                        label: 'Copy Transfer Code',
                        onPressed: _copyToClipboard,
                        icon: Icons.copy_rounded,
                      ),
                      const SizedBox(height: AppSpacing.componentGap),
                      AppOutlineButton(
                        label: 'Done',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: AppTextStyles.bodySm,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
