import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/l10n/app_locales.dart';
import 'core/l10n/locale_controller.dart';
import 'core/theme/app_theme.dart';
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
          // Builder so the callback below sits *under* the Navigator and can
          // push onto it.
          home: Builder(
            builder: (BuildContext context) {
              return SplashScreen(
                // TODO: hand real startup work (session restore, cache
                // warm-up) to `initialization`.
                onComplete: () => _openWelcome(context),
              );
            },
          ),
        );
      },
    );
  }

  void _openWelcome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      WelcomeScreen.route(
        onLanguageChanged: (AppLanguage next) => _locale.language = next,
        onCompleted: _onOnboardingComplete,
      ),
    );
  }

  void _onOnboardingComplete(UserRole role) {
    // TODO: persist the role and the chosen language, then route into the
    // matching shell — the mother's vault or the partner's synced mirror.
  }
}
