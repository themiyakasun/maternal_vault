import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/vault_setup_stage.dart';

/// One line of the vault setup checklist: a status indicator and its label.
///
/// The tile — not the decorative dots at the foot of the screen — is what
/// carries progress, so it announces itself to screen readers as it becomes
/// active.
class SetupStageTile extends StatelessWidget {
  const SetupStageTile({
    super.key,
    required this.label,
    required this.status,
    required this.statusLabel,
  });

  final String label;
  final StageStatus status;

  /// Spoken status ("Done", "In progress", "Waiting"). Never drawn — the
  /// indicator carries it visually.
  final String statusLabel;

  static const Duration _settle = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final bool active = status == StageStatus.active;

    // One node per stage, not a label plus a stray progress-bar announcement:
    // the tile speaks its own status, so the subtree is excluded.
    return Semantics(
      label: label,
      value: statusLabel,
      liveRegion: active,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackSm),
        child: Row(
          children: <Widget>[
            _StageIndicator(status: status),
            const SizedBox(width: AppSpacing.stackMd),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: _settle,
                curve: Curves.easeOut,
                style: AppTextStyles.bodyLg.copyWith(
                  color: status == StageStatus.pending
                      ? AppColors.onSurfaceVariant
                      : AppColors.onSurface,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
                child: Text(label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ring → spinner → filled check, as a stage moves through the run.
class _StageIndicator extends StatelessWidget {
  const _StageIndicator({required this.status});

  final StageStatus status;

  static const double _size = 24;

  @override
  Widget build(BuildContext context) {
    if (status == StageStatus.active) {
      return const SizedBox(
        width: _size,
        height: _size,
        child: Padding(
          padding: EdgeInsets.all(3),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.secondary,
          ),
        ),
      );
    }

    final bool done = status == StageStatus.done;

    return AnimatedContainer(
      duration: SetupStageTile._settle,
      curve: Curves.easeOut,
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.secondary : Colors.transparent,
        border: Border.all(
          color: done ? AppColors.secondary : AppColors.outline,
          width: 2,
        ),
      ),
      child: done
          ? const Icon(
              Icons.check_rounded,
              size: 15,
              color: AppColors.onSecondary,
            )
          : null,
    );
  }
}
