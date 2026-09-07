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

/// Screen displayed when opening or resuming the app, gating access behind
/// Biometrics or the 6-digit Vault PIN.
class VaultLockScreen extends StatefulWidget {
  const VaultLockScreen({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  static Route<void> route({required VoidCallback onUnlocked}) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (BuildContext context, _, _) => VaultLockScreen(
        onUnlocked: onUnlocked,
      ),
      transitionsBuilder:
          (BuildContext context, Animation<double> animation, _, Widget child) {
            return FadeTransition(opacity: animation, child: child);
          },
    );
  }

  @override
  State<VaultLockScreen> createState() => _VaultLockScreenState();
}

class _VaultLockScreenState extends State<VaultLockScreen> {
  static const int _pinLength = 6;

  String _currentPin = '';
  bool _hasError = false;
  String? _errorMessage;
  bool _hasBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricsAndPrompt();
  }

  Future<void> _checkBiometricsAndPrompt() async {
    final enabled = await VaultAuthManager.isBiometricsEnabled();
    final supported = await VaultAuthManager.isBiometricsSupported();

    if (mounted) {
      setState(() {
        _hasBiometrics = enabled && supported;
      });
    }

    if (_hasBiometrics) {
      // Small pause to allow entrance animation to settle
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      _authenticateWithBiometrics();
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    final success = await VaultAuthManager.authenticateWithBiometrics();
    if (success && mounted) {
      widget.onUnlocked();
    }
  }

  void _onDigit(String digit) {
    if (_currentPin.length >= _pinLength) return;

    setState(() {
      _hasError = false;
      _errorMessage = null;
      _currentPin += digit;
    });

    if (_currentPin.length == _pinLength) {
      _verifyPin();
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

  Future<void> _verifyPin() async {
    final isValid = await VaultAuthManager.verifyPin(_currentPin);

    if (!mounted) return;

    if (isValid) {
      HapticFeedback.lightImpact();
      widget.onUnlocked();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _hasError = true;
        _errorMessage = 'Incorrect PIN. Please try again.';
        _currentPin = '';
      });
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
                    title: 'Unlock Maternal Vault',
                    body: 'Enter your 6-digit PIN to access your records',
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
                    showBiometric: _hasBiometrics,
                    onBiometric: _authenticateWithBiometrics,
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
