import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/brand_backdrop.dart';
import '../../../../core/widgets/buttons/app_button_tone.dart';
import '../../../../core/widgets/buttons/app_outline_button.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/page_intro.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../widgets/scan_preview_card.dart';

/// Where the partner lands after onboarding: pair this phone with the mother's
/// vault by reading the secure code her app shows.
///
/// The pairing itself is not built yet, so both actions are injectable hooks
/// that default to null — the buttons render disabled until a caller supplies
/// them, rather than the screen faking success.
class ConnectMotherRecordScreen extends StatelessWidget {
  const ConnectMotherRecordScreen({
    super.key,
    this.onScanNow,
    this.onEnterCode,
  });

  /// TODO: open the camera and hand the decoded payload to the sync backend.
  final VoidCallback? onScanNow;

  /// TODO: push the manual code-entry sheet once the sync backend exists.
  final VoidCallback? onEnterCode;

  /// Pushed rather than replacing the welcome flow — the back chip is part of
  /// the design, and a partner who picked the wrong role should land back on
  /// the role step.
  static Route<void> route({
    VoidCallback? onScanNow,
    VoidCallback? onEnterCode,
  }) {
    return MaterialPageRoute<void>(
      builder: (BuildContext context) => ConnectMotherRecordScreen(
        onScanNow: onScanNow,
        onEnterCode: onEnterCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool compact = MediaQuery.sizeOf(context).height < 700;

    return Scaffold(
      body: BrandBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: AppSpacing.stackMd),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _BackChip(label: l10n.actionBack),
                ),
                const SizedBox(height: AppSpacing.stackLg),
                // The actions stay pinned to the bottom while the frame and
                // copy scroll, the same split the welcome flow uses for its
                // nav bar.
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        PageIntro(
                          title: l10n.partnerConnectTitle,
                          body: l10n.partnerConnectBody,
                          compact: compact,
                          titleColor: AppColors.primary,
                        ),
                        const SizedBox(height: AppSpacing.sectionGap),
                        ScanPreviewCard(statusLabel: l10n.partnerScanReady),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                AppPrimaryButton(
                  label: l10n.partnerActionScanNow,
                  onPressed: onScanNow,
                  tone: AppButtonTone.secondary,
                  icon: Icons.qr_code_scanner_rounded,
                ),
                const SizedBox(height: AppSpacing.componentGap),
                AppOutlineButton(
                  label: l10n.partnerActionEnterCode,
                  onPressed: onEnterCode,
                  tone: AppButtonTone.secondary,
                ),
                const SizedBox(height: AppSpacing.sectionGap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The circular back affordance from the design — a floating chip rather than
/// an app bar, so the gradient runs unbroken to the top of the screen.
class _BackChip extends StatelessWidget {
  const _BackChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    // The shadow lives on a DecoratedBox rather than Material.elevation so it
    // matches the card token the rest of the app lifts surfaces with.
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: AppColors.shadowCard,
      ),
      child: Material(
        color: AppColors.cardSurface,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: Tooltip(
          message: label,
          child: InkWell(
            onTap: () => Navigator.maybePop(context),
            child: Semantics(
              button: true,
              label: label,
              child: const SizedBox(
                width: AppSpacing.minTouchTarget,
                height: AppSpacing.minTouchTarget,
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
