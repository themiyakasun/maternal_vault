import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/l10n/app_locales.dart';
import 'core/l10n/locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/mother/presentation/screens/mother_shell_screen.dart';
import 'features/mother/presentation/screens/vault_setup_screen.dart';
import 'features/partner/presentation/screens/connect_mother_record_screen.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'features/welcome/domain/user_role.dart';
import 'features/welcome/presentation/screens/welcome_screen.dart';
import 'l10n/generated/app_localizations.dart';

void main() {
  runApp(const MaternalVaultApp());
}

class MaternalVaultApp extends StatefulWidget {
  const MaternalVaultApp({super.key});

  @override
  State<MaternalVaultApp> createState() => _MaternalVaultAppState();
}

class _MaternalVaultAppState extends State<MaternalVaultApp> {
  /// Owned here because [MaterialApp.locale] lives here — the welcome flow only
  /// asks for a change, it never applies one itself.
  final LocaleController _locale = LocaleController();

  /// Routing is driven from here too, and the callbacks that drive it outlive
  /// the routes that trigger them: [_onOnboardingComplete] runs from the
  /// welcome flow, which a replacement then unmounts. A context taken from
  /// inside the tree would already be dead by the time the next push lands, so
  /// the navigator is reached by key instead.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void dispose() {
    _locale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: _locale,
      builder: (BuildContext context, AppLanguage language, _) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          onGenerateTitle: (BuildContext context) =>
              AppLocalizations.of(context).appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: language.locale,
          supportedLocales: AppLanguage.locales,
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: SplashScreen(
            // TODO: hand real startup work (session restore, cache warm-up) to
            // `initialization`.
            onComplete: _openWelcome,
          ),
        );
      },
    );
  }

  NavigatorState get _navigator => _navigatorKey.currentState!;

  void _openWelcome() {
    _navigator.pushReplacement(
      WelcomeScreen.route(
        onLanguageChanged: (AppLanguage next) => _locale.language = next,
        onCompleted: _onOnboardingComplete,
      ),
    );
  }

  /// The two roles want different histories, so they get different pushes.
  void _onOnboardingComplete(UserRole role) {
    // TODO: persist the role and the chosen language before routing.
    switch (role) {
      case UserRole.expectantMother:
        // Replaces the flow: setup is not resumable and the screen offers no
        // way back into it.
        _navigator.pushReplacement(
          VaultSetupScreen.route(
            // TODO: pass `runStage` once the record and crypto layers land.
            onComplete: _openMotherShell,
          ),
        );
      case UserRole.partner:
        // Pushed: the connect screen has a back chip, and someone who picked
        // the wrong role should land back on the role step.
        _navigator.push(ConnectMotherRecordScreen.route());
    }
  }

  /// Replaces setup rather than stacking on it — the vault is built by now and
  /// there is nothing to return to.
  void _openMotherShell() {
    _navigator.pushReplacement(
      MotherShellScreen.route(
        onLanguageChanged: (AppLanguage next) => _locale.language = next,
        // TODO: read `vitals` from the record and pass `onSubmitProfile` once
        // there is somewhere to store the profile.
      ),
    );
  }
}
