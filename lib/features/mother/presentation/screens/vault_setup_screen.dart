import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/brand_backdrop.dart';
import '../../../../core/widgets/brand_logo_mark.dart';
import '../../../../core/widgets/loading_dots.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../welcome/presentation/widgets/welcome_step_intro.dart';
import '../../domain/vault_setup_stage.dart';
import '../widgets/setup_stage_tile.dart';

/// Where the expectant mother lands after onboarding: her vault being created
/// and encrypted on this device, one stage at a time.
///
/// The record and crypto layers do not exist yet, so [runStage] is the seam
/// they drop into. Left null, each stage simply holds for
/// [minimumStageDuration] — the screen is honest about being a placeholder in
/// its wiring rather than in its pixels.
class VaultSetupScreen extends StatefulWidget {
  const VaultSetupScreen({
    super.key,
    this.onComplete,
    this.runStage,
    this.minimumStageDuration = const Duration(milliseconds: 1100),
  });

  /// Fired once, after the last stage lands. Typically navigates onward.
  final VoidCallback? onComplete;

  /// The real work for a stage. A stage ends when both this future and
  /// [minimumStageDuration] have elapsed, so fast work still reads as a step
  /// instead of a flicker.
  final Future<void> Function(VaultSetupStage stage)? runStage;

  /// Floor on how long each stage stays on screen.
  final Duration minimumStageDuration;

  static Route<void> route({
    VoidCallback? onComplete,
    Future<void> Function(VaultSetupStage stage)? runStage,
  }) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (BuildContext context, _, _) => VaultSetupScreen(
        onComplete: onComplete,
        runStage: runStage,
      ),
      transitionsBuilder:
          (BuildContext context, Animation<double> animation, _, Widget child) {
            return FadeTransition(opacity: animation, child: child);
          },
    );
  }

  @override
  State<VaultSetupScreen> createState() => _VaultSetupScreenState();
}

class _VaultSetupScreenState extends State<VaultSetupScreen> {
  /// How many stages have finished. Everything before it is done, the one at
  /// it is running, everything after is waiting.
  int _completedStages = 0;

  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _runStages();
  }

  Future<void> _runStages() async {
    for (final VaultSetupStage stage in VaultSetupStage.values) {
      await Future.wait<void>(<Future<void>>[
        Future<void>.delayed(widget.minimumStageDuration),
        if (widget.runStage != null) widget.runStage!(stage),
      ]);

      if (!mounted) return;
      setState(() => _completedStages++);
    }

    if (!mounted || _finished) return;
    _finished = true;
    widget.onComplete?.call();
  }

  StageStatus _statusOf(int index) {
    if (index < _completedStages) return StageStatus.done;
    if (index == _completedStages) return StageStatus.active;
    return StageStatus.pending;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool compact = MediaQuery.sizeOf(context).height < 700;

    // Setup is not resumable and there is nothing behind this route to go back
    // to, so the gesture is refused rather than left to unwind a half-written
    // vault.
    return PopScope<void>(
      canPop: false,
      child: Scaffold(
        body: BrandBackdrop(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Spacer(flex: 2),
                  Center(child: BrandLogoMark(size: compact ? 64 : 80)),
                  const SizedBox(height: AppSpacing.stackLg),
                  WelcomeStepIntro(
                    title: l10n.vaultSetupTitle,
                    body: l10n.vaultSetupBody,
                    compact: compact,
                    titleColor: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  for (final VaultSetupStage stage in VaultSetupStage.values)
                    SetupStageTile(
                      label: _stageLabel(l10n, stage),
                      status: _statusOf(stage.index),
                      statusLabel: _statusLabel(l10n, _statusOf(stage.index)),
                    ),
                  const Spacer(flex: 3),
                  const Center(
                    child: LoadingDots(color: AppColors.primaryContainer),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _stageLabel(AppLocalizations l10n, VaultSetupStage stage) {
    switch (stage) {
      case VaultSetupStage.creatingRecord:
        return l10n.vaultStageCreatingRecord;
      case VaultSetupStage.encrypting:
        return l10n.vaultStageEncrypting;
      case VaultSetupStage.finishing:
        return l10n.vaultStageFinishing;
    }
  }

  String _statusLabel(AppLocalizations l10n, StageStatus status) {
    switch (status) {
      case StageStatus.done:
        return l10n.vaultStageStatusDone;
      case StageStatus.active:
        return l10n.vaultStageStatusActive;
      case StageStatus.pending:
        return l10n.vaultStageStatusPending;
    }
  }
}
