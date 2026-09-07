import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/security/vault_auth_manager.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/brand_backdrop.dart';
import '../../../../core/widgets/brand_logo_mark.dart';
import '../../../../core/widgets/page_intro.dart';
import '../../../../core/widgets/pin_code_dots.dart';
import '../../../../core/widgets/pin_keyboard.dart';

/// Screen where the expectant mother sets up her 6-digit Vault PIN and
/// optionally enables Biometric unlock.
class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key, required this.onCompleted});

  final VoidCallback onCompleted;

  static Route<void> route({required VoidCallback onCompleted}) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (BuildContext context, _, _) => CreatePinScreen(
        onCompleted: onCompleted,
      ),
      transitionsBuilder:
          (BuildContext context, Animation<double> animation, _, Widget child) {
            return FadeTransition(opacity: animation, child: child);
          },
    );
  }

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  static const int _pinLength = 6;

  String _firstPin = '';
  String _currentPin = '';
  bool _isConfirming = false;
  bool _hasError = false;
  String? _errorMessage;

  void _onDigit(String digit) {
    if (_currentPin.length >= _pinLength) return;

    setState(() {
      _hasError = false;
      _errorMessage = null;
      _currentPin += digit;
    });

    if (_currentPin.length == _pinLength) {
      _handlePinEntered();
    }
  }

  void _onBackspace() {
    if (_currentPin.isEmpty) return;
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _currentPin = _currentPin.substring(0, _currentPin.length - 1);
    });
  }

  Future<void> _handlePinEntered() async {
    if (!_isConfirming) {
      // Transition to Confirming step
      await Future.delayed(const Duration(milliseconds: 180));
      setState(() {
        _firstPin = _currentPin;
        _currentPin = '';
        _isConfirming = true;
      });
    } else {
      // Verify match
      if (_currentPin == _firstPin) {
        // Success
        await VaultAuthManager.setupPin(_currentPin);
        _promptBiometricsOption();
      } else {
        // Mismatch
        HapticFeedback.heavyImpact();
        setState(() {
          _hasError = true;
          _errorMessage = 'PINs did not match. Please try again.';
          _currentPin = '';
          _firstPin = '';
          _isConfirming = false;
        });
      }
    }
  }

  Future<void> _promptBiometricsOption() async {
    final isSupported = await VaultAuthManager.isBiometricsSupported();

    if (!mounted) return;

    if (isSupported) {
      // Ask user to enable Biometrics
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 28),
                SizedBox(width: 10),
                Text('Enable Biometrics?'),
              ],
            ),
            content: Text(
              'Would you like to use Fingerprint or Face ID for faster, secure access to your Maternal Vault?',
              style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceVariant),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await VaultAuthManager.setBiometricsEnabled(false);
                  if (context.mounted) Navigator.of(context).pop();
                  widget.onCompleted();
                },
                child: const Text('Maybe Later', style: TextStyle(color: AppColors.outline)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await VaultAuthManager.setBiometricsEnabled(true);
                  if (context.mounted) Navigator.of(context).pop();
                  widget.onCompleted();
                },
                child: const Text('Enable'),
              ),
            ],
          );
        },
      );
    } else {
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).height < 700;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: BrandBackdrop(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.stackLg),
                  Center(child: BrandLogoMark(size: compact ? 48 : 56)),
                  const SizedBox(height: AppSpacing.stackMd),
                  PageIntro(
                    title: _isConfirming ? 'Confirm your Vault PIN' : 'Create your Vault PIN',
                    body: _isConfirming
                        ? 'Re-enter your 6-digit PIN to confirm'
                        : 'Choose a 6-digit PIN to secure your health records',
                    compact: compact,
                    titleColor: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                  PinCodeDots(
                    length: _pinLength,
                    currentLength: _currentPin.length,
                    hasError: _hasError,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const Spacer(),
                  PinKeyboard(
                    onDigit: _onDigit,
                    onBackspace: _onBackspace,
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
