import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_locales.dart';
import '../../../../core/widgets/brand_backdrop.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/basic_profile.dart';
import '../../domain/key_vitals.dart';
import '../../domain/mother_tab.dart';
import '../widgets/language_sheet.dart';
import '../widgets/pregnancy_record_app_bar.dart';
import '../widgets/tab_placeholder.dart';
import 'basic_profile_screen.dart';

/// The mother's app once setup is done: one header, five sections, one bottom
/// bar.
///
/// Only [MotherTab.profile] is built; the rest render [TabPlaceholder] so the
/// bar is fully navigable while those sections are still being designed.
class MotherShellScreen extends StatefulWidget {
  const MotherShellScreen({
    super.key,
    required this.onLanguageChanged,
    this.vitals = const KeyVitals.empty(),
    this.onSubmitProfile,
    this.initialTab = MotherTab.profile,
  });

  /// Asks the app root to switch languages, the same contract the welcome flow
  /// uses. The shell never stores the answer — see [_MotherShellScreenState._changeLanguage].
  final ValueChanged<AppLanguage> onLanguageChanged;

  /// Passed through to [BasicProfileScreen].
  final KeyVitals vitals;

  /// Passed through to [BasicProfileScreen.onSubmit].
  final ValueChanged<BasicProfile>? onSubmitProfile;

  /// Which section to open on. A param so a notification or a deep link can
  /// land somewhere other than Profile later.
  final MotherTab initialTab;

  /// Replaces the setup screen: setup is finished and there is nothing behind
  /// this to go back to.
  static Route<void> route({
    required ValueChanged<AppLanguage> onLanguageChanged,
    KeyVitals vitals = const KeyVitals.empty(),
    ValueChanged<BasicProfile>? onSubmitProfile,
  }) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (BuildContext context, _, _) => MotherShellScreen(
        onLanguageChanged: onLanguageChanged,
        vitals: vitals,
        onSubmitProfile: onSubmitProfile,
      ),
      transitionsBuilder:
          (BuildContext context, Animation<double> animation, _, Widget child) {
            return FadeTransition(opacity: animation, child: child);
          },
    );
  }

  @override
  State<MotherShellScreen> createState() => _MotherShellScreenState();
}

class _MotherShellScreenState extends State<MotherShellScreen> {
  late MotherTab _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    // The shell is the root after setup, so the back gesture is refused rather
    // than popping to a finished setup screen or an empty navigator.
    return PopScope<void>(
      canPop: false,
      child: Scaffold(
        body: BrandBackdrop(
          child: SafeArea(
            // The bar paints its own opaque surface and handles the bottom
            // inset itself, so the body only claims the top one.
            bottom: false,
            child: Column(
              children: <Widget>[
                PregnancyRecordAppBar(onChangeLanguage: _changeLanguage),
                Expanded(
                  // IndexedStack rather than a swap: every tab stays mounted, so
                  // a half-filled form and a scroll position both survive a trip
                  // to another section and back.
                  child: IndexedStack(
                    index: _tab.index,
                    children: <Widget>[
                      for (final MotherTab tab in MotherTab.values)
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
              setState(() => _tab = MotherTab.values[index]),
          destinations: <Widget>[
            for (final MotherTab tab in MotherTab.values)
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

  Widget _body(AppLocalizations l10n, MotherTab tab) {
    switch (tab) {
      case MotherTab.profile:
        return BasicProfileScreen(
          vitals: widget.vitals,
          onSubmit: widget.onSubmitProfile,
        );
      case MotherTab.history:
      case MotherTab.obstetric:
      case MotherTab.clinic:
      case MotherTab.plan:
        return TabPlaceholder(
          icon: _icon(tab),
          title: _label(l10n, tab),
          accent: _accent(tab),
        );
    }
  }

  Future<void> _changeLanguage() async {
    // Read the live locale rather than a stored copy: a field would freeze at
    // whatever was current when the shell was pushed, so the checkmark in the
    // sheet would stop moving after the first change.
    final AppLanguage? picked = await showLanguageSheet(
      context,
      selected: AppLanguage.fromLocale(Localizations.maybeLocaleOf(context)),
    );

    // Null means the sheet was dismissed without a choice.
    if (picked == null) return;
    widget.onLanguageChanged(picked);
  }

  String _label(AppLocalizations l10n, MotherTab tab) {
    switch (tab) {
      case MotherTab.profile:
        return l10n.tabProfile;
      case MotherTab.history:
        return l10n.tabHistory;
      case MotherTab.obstetric:
        return l10n.tabObstetric;
      case MotherTab.clinic:
        return l10n.tabClinic;
      case MotherTab.plan:
        return l10n.tabPlan;
    }
  }

  IconData _icon(MotherTab tab) {
    switch (tab) {
      case MotherTab.profile:
        return Icons.person_outline_rounded;
      case MotherTab.history:
        return Icons.history_rounded;
      case MotherTab.obstetric:
        return Icons.pregnant_woman_rounded;
      case MotherTab.clinic:
        return Icons.local_hospital_outlined;
      case MotherTab.plan:
        return Icons.event_note_outlined;
    }
  }

  /// Colour identity for a placeholder's glyph. Cycles the three brand accents
  /// so consecutive sections do not read as the same one.
  Color _accent(MotherTab tab) {
    switch (tab) {
      case MotherTab.profile:
      case MotherTab.obstetric:
        return AppColors.primary;
      case MotherTab.clinic:
        return AppColors.secondary;
      case MotherTab.history:
      case MotherTab.plan:
        return AppColors.tertiary;
    }
  }
}
