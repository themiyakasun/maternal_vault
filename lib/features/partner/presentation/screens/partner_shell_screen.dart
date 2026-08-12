import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/brand_backdrop.dart';
import '../../../../core/widgets/tab_placeholder.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/partner_summary.dart';
import '../../domain/partner_tab.dart';
import '../widgets/partner_app_bar.dart';
import 'partner_home_screen.dart';

/// The partner's app once they have connected to a record: one header, three
/// sections, one bottom bar — the same shape as the mother's shell.
///
/// Every section is built; the bar switches between them over an [IndexedStack]
/// so each keeps its scroll offset while another is on screen. Only [PartnerTab.home]
/// has a screen yet — the other two stand in with a placeholder.
class PartnerShellScreen extends StatefulWidget {
  const PartnerShellScreen({
    super.key,
    this.summary = const PartnerSummary.empty(),
    this.onOpenSettings,
    this.initialTab = PartnerTab.home,
  });

  /// Passed through to [PartnerHomeScreen].
  final PartnerSummary summary;

  /// Opens settings. Null shows a notice rather than pretending to have a
  /// settings screen — see [_openSettings].
  final VoidCallback? onOpenSettings;

  /// Which section to open on. A param so a notification or deep link can land
  /// somewhere other than Home later.
  final PartnerTab initialTab;

  /// Replaces the connect screen: pairing is done and there is nothing behind
  /// this to go back to.
  static Route<void> route({
    PartnerSummary summary = const PartnerSummary.empty(),
    VoidCallback? onOpenSettings,
  }) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (BuildContext context, _, _) => PartnerShellScreen(
        summary: summary,
        onOpenSettings: onOpenSettings,
      ),
      transitionsBuilder:
          (BuildContext context, Animation<double> animation, _, Widget child) {
            return FadeTransition(opacity: animation, child: child);
          },
    );
  }

  @override
  State<PartnerShellScreen> createState() => _PartnerShellScreenState();
}

class _PartnerShellScreenState extends State<PartnerShellScreen> {
  late PartnerTab _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    // The shell is the root after connecting, so the back gesture is refused
    // rather than popping to a finished connect screen.
    return PopScope<void>(
      canPop: false,
      child: Scaffold(
        body: BrandBackdrop(
          child: SafeArea(
            // The bar paints its own opaque surface and owns the bottom inset,
            // so the body only claims the top one.
            bottom: false,
            child: Column(
              children: <Widget>[
                PartnerAppBar(onOpenSettings: () => _openSettings(l10n)),
                Expanded(
                  child: IndexedStack(
                    index: _tab.index,
                    children: <Widget>[
                      for (final PartnerTab tab in PartnerTab.values)
                        _body(l10n, tab),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab.index,
          onDestinationSelected: (int index) =>
              setState(() => _tab = PartnerTab.values[index]),
          destinations: <Widget>[
            for (final PartnerTab tab in PartnerTab.values)
              NavigationDestination(
                icon: Icon(_icon(tab)),
                label: _label(l10n, tab),
                tooltip: _label(l10n, tab),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n, PartnerTab tab) {
    switch (tab) {
      case PartnerTab.home:
        return PartnerHomeScreen(summary: widget.summary);
      case PartnerTab.calendar:
        return TabPlaceholder(
          icon: Icons.calendar_month_rounded,
          title: l10n.tabCalendar,
          accent: AppColors.tertiary,
        );
      case PartnerTab.emergency:
        return TabPlaceholder(
          icon: Icons.emergency_outlined,
          title: l10n.tabEmergency,
          accent: AppColors.error,
        );
    }
  }

  void _openSettings(AppLocalizations l10n) {
    final VoidCallback? handler = widget.onOpenSettings;
    if (handler != null) {
      handler();
      return;
    }

    // TODO: build the settings screen and pass it in as onOpenSettings.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.partnerSettingsNotConnected)),
    );
  }

  String _label(AppLocalizations l10n, PartnerTab tab) {
    switch (tab) {
      case PartnerTab.home:
        return l10n.tabHome;
      case PartnerTab.calendar:
        return l10n.tabCalendar;
      case PartnerTab.emergency:
        return l10n.tabEmergency;
    }
  }

  IconData _icon(PartnerTab tab) {
    switch (tab) {
      case PartnerTab.home:
        return Icons.home_rounded;
      case PartnerTab.calendar:
        return Icons.calendar_month_rounded;
      case PartnerTab.emergency:
        return Icons.emergency_outlined;
    }
  }
}
