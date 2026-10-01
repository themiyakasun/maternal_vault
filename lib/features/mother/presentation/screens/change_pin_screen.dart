import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/security/vault_auth_manager.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/brand_backdrop.dart';
import '../../../../core/widgets/pin_code_dots.dart';
import '../../../../core/widgets/pin_keyboard.dart';

enum ChangePinStep {
  enterCurrent,
  enterNew,
  confirmNew,
}

/// A 3-step security screen for safely changing the Mother's 6-digit Vault PIN.
class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  static Route<bool> route() {
    return PageRouteBuilder<bool>(
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (BuildContext context, _, _) => const ChangePinScreen(),
      transitionsBuilder:
          (BuildContext context, Animation<double> animation, _, Widget child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  static const int _pinLength = 6;

  ChangePinStep _step = ChangePinStep.enterCurrent;
  String _newPin = '';
  String _pinBuffer = '';
  bool _hasError = false;
  String? _errorMessage;

  void _onDigit(String digit) {
    if (_pinBuffer.length >= _pinLength) return;

    setState(() {
      _hasError = false;
      _errorMessage = null;
      _pinBuffer += digit;
    });

    if (_pinBuffer.length == _pinLength) {
      _handlePinEntered();
    }
  }

  void _onBackspace() {
    if (_pinBuffer.isEmpty) return;
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _pinBuffer = _pinBuffer.substring(0, _pinBuffer.length - 1);
    });
  }

  Future<void> _handlePinEntered() async {
    switch (_step) {
      case ChangePinStep.enterCurrent:
        final entered = _pinBuffer;
        final isValid = await VaultAuthManager.verifyPin(entered);
        if (!mounted) return;

        if (isValid) {
          HapticFeedback.lightImpact();
          setState(() {
            _pinBuffer = '';
            _step = ChangePinStep.enterNew;
          });
        } else {
          HapticFeedback.heavyImpact();
          setState(() {
            _hasError = true;
            _errorMessage = 'Current PIN is incorrect. Please try again.';
            _pinBuffer = '';
          });
        }
        break;

      case ChangePinStep.enterNew:
        final entered = _pinBuffer;
        await Future.delayed(const Duration(milliseconds: 150));
        if (!mounted) return;

        setState(() {
          _newPin = entered;
          _pinBuffer = '';
          _step = ChangePinStep.confirmNew;
        });
        break;

      case ChangePinStep.confirmNew:
        final entered = _pinBuffer;
        if (entered == _newPin) {
          HapticFeedback.mediumImpact();
          await VaultAuthManager.setupPin(_newPin);
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vault PIN changed successfully!'),
              backgroundColor: AppColors.primary,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          HapticFeedback.heavyImpact();
          setState(() {
            _hasError = true;
            _errorMessage = 'New PINs did not match. Please try again.';
            _pinBuffer = '';
            _newPin = '';
            _step = ChangePinStep.enterNew;
          });
        }
        break;
    }
  }

  String get _stepTitle {
    switch (_step) {
      case ChangePinStep.enterCurrent:
        return 'Enter Current PIN';
      case ChangePinStep.enterNew:
        return 'Create New PIN';
      case ChangePinStep.confirmNew:
        return 'Confirm New PIN';
    }
  }

  String get _stepDescription {
    switch (_step) {
      case ChangePinStep.enterCurrent:
        return 'Verify your identity before setting a new vault PIN.';
      case ChangePinStep.enterNew:
        return 'Choose a new 6-digit access code for your encrypted vault.';
      case ChangePinStep.confirmNew:
        return 'Re-enter your new 6-digit PIN to confirm.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandBackdrop(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              // Top navigation
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.stackSm,
                ),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop(false),
                      tooltip: 'Cancel',
                    ),
                    const SizedBox(width: AppSpacing.stackSm),
                    Text(
                      'Change Vault PIN',
                      style: AppTextStyles.h3,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Step Indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Step ${_step.index + 1} of 3',
                  style: AppTextStyles.labelCaps.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.stackMd),

              Text(
                _stepTitle,
                style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.stackSm),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _stepDescription,
                  style: AppTextStyles.bodySm,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: AppSpacing.sectionGap),

              // PIN dots
              PinCodeDots(
                length: _pinLength,
                currentLength: _pinBuffer.length,
                hasError: _hasError,
              ),

              const SizedBox(height: AppSpacing.stackMd),

              // Error message
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _hasError && _errorMessage != null ? 1.0 : 0.0,
                child: Text(
                  _errorMessage ?? '',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(),

              // Numeric keypad
              PinKeyboard(
                onDigit: _onDigit,
                onBackspace: _onBackspace,
              ),

              const SizedBox(height: AppSpacing.stackLg),
            ],
          ),
        ),
      ),
    );
  }
}
