import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons/app_outline_button.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/services/midwife_sync_service.dart';

/// Full-screen QR code scanner to import and encrypt clinical records
/// from the Public Health Midwife's desktop/tablet dashboard.
class MidwifeSyncScannerScreen extends StatefulWidget {
  const MidwifeSyncScannerScreen({
    super.key,
    this.syncService = const MidwifeSyncService(),
  });

  final MidwifeSyncService syncService;

  @override
  State<MidwifeSyncScannerScreen> createState() =>
      _MidwifeSyncScannerScreenState();
}

class _MidwifeSyncScannerScreenState extends State<MidwifeSyncScannerScreen> {
  late final MobileScannerController _scannerController;
  bool _isProcessing = false;
  bool _hasDetected = false;
  SyncResult? _lastSuccessfulResult;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: const [BarcodeFormat.qrCode],
      returnImage: false,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_hasDetected || _isProcessing) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        _hasDetected = true;
        await _processPayload(rawValue);
        break;
      }
    }
  }

  Future<void> _processPayload(String rawPayload) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final result = await widget.syncService.processQrPayload(rawPayload);
      if (!mounted) return;

      if (result.isSuccess) {
        _lastSuccessfulResult = result;
        await _showSuccessDialog(result);
      } else {
        _showErrorDialog(result.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _simulateSync() async {
    final samplePayload = MidwifeSyncService.generateSamplePayload();
    await _processPayload(samplePayload);
  }

  Future<void> _showSuccessDialog(SyncResult result) async {
    final l10n = AppLocalizations.of(context);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, dynamic _) {
            if (didPop) return;
            Navigator.of(dialogContext).pop();
            if (mounted) {
              Navigator.of(context).pop(result);
            }
          },
          child: AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.cardRadius,
          ),
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          title: Text(
            l10n.midwifeSyncSuccess,
            style: AppTextStyles.h3,
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l10n.midwifeSyncSuccessBody(result.motherName ?? 'Mother'),
                style: AppTextStyles.bodyLg,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Container(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (result.clinicName != null) ...[
                      Text(
                        result.clinicName!,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    if (result.midwifeName != null) ...[
                      Text(
                        result.midwifeName!,
                        style: AppTextStyles.labelCaps.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.stackSm),
                    ],
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.midwifeSyncVisitsFound(result.visitsCount),
                          style: AppTextStyles.labelCaps.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      l10n.midwifeSyncSecurityNotice,
                      style: AppTextStyles.labelCaps.copyWith(
                        fontSize: 10,
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            AppPrimaryButton(
              label: l10n.actionDone,
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  Navigator.of(context).pop(result);
                }
              },
            ),
          ],
        ),
      );
    },
  );
  }

  void _showErrorDialog(String message) {
    final l10n = AppLocalizations.of(context);

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.cardRadius,
          ),
          icon: const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 36,
          ),
          title: Text(
            l10n.midwifeSyncError,
            style: AppTextStyles.h3,
          ),
          content: Text(
            message,
            style: AppTextStyles.bodySm,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                setState(() => _hasDetected = false);
              },
              child: Text(l10n.actionDone),
            ),
          ],
        );
      },
    );
  }

  void _showSampleQrDialog() {
    final samplePayload =
        MidwifeSyncService.generateSamplePayload(compressed: true);
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
          ),
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                Text(
                  'Midwife Clinic QR Code',
                  style: AppTextStyles.h3.copyWith(color: AppColors.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Kumari Sandamali Perera (#6720) • 7 Visits • Low Risk',
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.stackMd),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: samplePayload,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                Text(
                  'Point another device camera at this QR code, or tap below to directly sync this record into the application.',
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.stackLg),
                AppPrimaryButton(
                  label: 'Sync This Record Directly',
                  icon: Icons.sync_rounded,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _simulateSync();
                  },
                ),
                const SizedBox(height: AppSpacing.stackSm),
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(l10n.actionDone),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope<SyncResult?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic _) {
        if (didPop) return;
        Navigator.of(context).pop(_lastSuccessfulResult);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(_lastSuccessfulResult),
          ),
          title: Text(
            l10n.midwifeSyncTitle,
            style: AppTextStyles.h3.copyWith(color: Colors.white),
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.qr_code_2_rounded),
              tooltip: 'View Clinic QR Code',
              onPressed: _showSampleQrDialog,
            ),
            IconButton(
              icon: const Icon(Icons.flash_on_rounded),
              tooltip: 'Flashlight',
              onPressed: () => _scannerController.toggleTorch(),
            ),
            IconButton(
              icon: const Icon(Icons.cameraswitch_rounded),
              tooltip: 'Flip Camera',
              onPressed: () => _scannerController.switchCamera(),
            ),
          ],
        ),
        body: Stack(
          children: <Widget>[
            // 1. Live Camera Stream
            MobileScanner(
              controller: _scannerController,
              onDetect: _handleBarcode,
              errorBuilder: (context, error) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    child: AppCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.videocam_off_rounded,
                            size: 48,
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(height: AppSpacing.stackMd),
                          const Text(
                            'Camera unavailable on this device or emulator.',
                            style: AppTextStyles.bodySm,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.stackLg),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: AppPrimaryButton(
                                  label: l10n.midwifeSyncSimulate,
                                  icon: Icons.sync_rounded,
                                  onPressed: _simulateSync,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.componentGap),
                              Expanded(
                                child: AppOutlineButton(
                                  label: 'View QR',
                                  icon: Icons.qr_code_2_rounded,
                                  onPressed: _showSampleQrDialog,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // 2. Viewfinder Overlay Reticle
            Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.8),
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  color: Colors.transparent,
                ),
                child: const Stack(
                  children: <Widget>[
                    Positioned(
                      top: -2,
                      left: -2,
                      child: _CornerAccent(isTop: true, isLeft: true),
                    ),
                    Positioned(
                      top: -2,
                      right: -2,
                      child: _CornerAccent(isTop: true, isLeft: false),
                    ),
                    Positioned(
                      bottom: -2,
                      left: -2,
                      child: _CornerAccent(isTop: false, isLeft: true),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: _CornerAccent(isTop: false, isLeft: false),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Instructions & Actions at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: <Color>[
                      Colors.black.withValues(alpha: 0.9),
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        l10n.midwifeSyncPrompt,
                        style: AppTextStyles.bodySm.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: AppOutlineButton(
                              label: l10n.midwifeSyncSimulate,
                              icon: Icons.sync_rounded,
                              onPressed: _simulateSync,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.componentGap),
                          Expanded(
                            child: AppOutlineButton(
                              label: 'View QR Code',
                              icon: Icons.qr_code_2_rounded,
                              onPressed: _showSampleQrDialog,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.stackSm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(
                            Icons.shield_outlined,
                            size: 14,
                            color: Colors.white54,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              l10n.midwifeSyncSecurityNotice,
                              style: AppTextStyles.labelCaps.copyWith(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 4. Loading Overlay
            if (_isProcessing)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CornerAccent extends StatelessWidget {
  const _CornerAccent({required this.isTop, required this.isLeft});

  final bool isTop;
  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: isTop && isLeft
              ? const Radius.circular(AppRadii.lg)
              : Radius.zero,
          topRight: isTop && !isLeft
              ? const Radius.circular(AppRadii.lg)
              : Radius.zero,
          bottomLeft: !isTop && isLeft
              ? const Radius.circular(AppRadii.lg)
              : Radius.zero,
          bottomRight: !isTop && !isLeft
              ? const Radius.circular(AppRadii.lg)
              : Radius.zero,
        ),
      ),
    );
  }
}
