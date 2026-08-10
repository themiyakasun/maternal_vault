import 'package:flutter/widgets.dart';

/// The languages Maternal Vault ships, in the order they are offered.
///
/// Kept as an enum rather than a bare `List<Locale>` so the welcome screen can
/// hang the display name, subtitle and flag-free ordering off one value and stay
/// exhaustive — adding a language here forces every switch to be updated.
enum AppLanguage {
  english(Locale('en')),
  sinhala(Locale('si')),
  tamil(Locale('ta'));

  const AppLanguage(this.locale);

  /// The locale handed to [WidgetsApp.locale].
  final Locale locale;

  /// Every locale the app supports, for [WidgetsApp.supportedLocales].
  static List<Locale> get locales =>
      AppLanguage.values.map((AppLanguage l) => l.locale).toList();

  /// Resolves a stored or system locale back to one of ours, matching on the
  /// language subtag only — `si_LK` and plain `si` should both land on Sinhala.
  /// Falls back to [english] for anything we do not translate.
  static AppLanguage fromLocale(Locale? locale) {
    if (locale == null) return AppLanguage.english;
    for (final AppLanguage language in AppLanguage.values) {
      if (language.locale.languageCode == locale.languageCode) return language;
    }
    return AppLanguage.english;
  }
}
