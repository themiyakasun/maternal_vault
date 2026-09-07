import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Numeric dialer keypad for entering PIN codes.
class PinKeyboard extends StatelessWidget {
  const PinKeyboard({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.onBiometric,
    this.showBiometric = false,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;
  final bool showBiometric;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 16),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 16),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 16),
        _buildBottomRow(),
      ],
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildKey(d)).toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Biometric or empty slot
        SizedBox(
          width: 72,
          height: 72,
          child: showBiometric && onBiometric != null
              ? IconButton(
                  icon: const Icon(
                    Icons.fingerprint_rounded,
                    size: 36,
                    color: AppColors.primary,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onBiometric?.call();
                  },
                )
              : const SizedBox.shrink(),
        ),
        _buildKey('0'),
        // Backspace
        SizedBox(
          width: 72,
          height: 72,
          child: IconButton(
            icon: const Icon(
              Icons.backspace_outlined,
              size: 26,
              color: AppColors.onSurface,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              onBackspace();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildKey(String digit) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onDigit(digit);
        },
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceContainerLow.withValues(alpha: 0.65),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            digit,
            style: AppTextStyles.h1Mobile.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
