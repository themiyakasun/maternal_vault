import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons/app_button_tone.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../data/services/partner_sync_service.dart';
import '../widgets/partner_connect_sheet.dart';

/// Full-screen camera scanner for partners to scan the QR code from the mother's phone.
class PartnerQrScannerScreen extends StatefulWidget {
  const PartnerQrScannerScreen({super.key});

  static Route<PartnerConnectionData?> route() {
    return MaterialPageRoute<PartnerConnectionData?>(
      builder: (BuildContext context) => const PartnerQrScannerScreen(),
    );
  }

  @override
  State<PartnerQrScannerScreen> createState() => _PartnerQrScannerScreenState();
}

class _PartnerQrScannerScreenState extends State<PartnerQrScannerScreen> {
  late final MobileScannerController _controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      formats: const [BarcodeFormat.qrCode],
      returnImage: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        final parsed = PartnerSyncService.parsePartnerPayload(rawValue);
        if (parsed != null) {
          _isProcessing = true;
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop(parsed);
          return;
        }
      }
    }
  }

  void _openManualSheet() async {
    final result = await PartnerConnectSheet.show(context);
    if (result != null && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.videocam_off_rounded,
                        color: Colors.white70,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Camera unavailable or permission denied.',
                        style: AppTextStyles.bodyLg.copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      AppPrimaryButton(
                        label: 'Enter Code Manually',
                        onPressed: _openManualSheet,
                        tone: AppButtonTone.secondary,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Viewfinder Overlay
          SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                    vertical: AppSpacing.stackSm,
                  ),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Close',
                      ),
                      const SizedBox(width: AppSpacing.stackSm),
                      Text(
                        'Scan Mother\'s QR Code',
                        style: AppTextStyles.h3.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Frame
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.secondary,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Point camera at the QR code on mother\'s phone',
                    style: AppTextStyles.bodyLg.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: AppPrimaryButton(
                    label: 'Enter Code Manually',
                    onPressed: _openManualSheet,
                    tone: AppButtonTone.secondary,
                    icon: Icons.keyboard_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
