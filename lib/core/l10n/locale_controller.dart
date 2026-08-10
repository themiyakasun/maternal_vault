import 'package:flutter/widgets.dart';

import 'app_locales.dart';

/// Holds the language the app is currently rendered in.
///
/// Deliberately a plain [ValueNotifier] rather than a state-management package:
/// the locale is a single value, read by one widget (the [WidgetsApp] at the
/// root) and written from one screen (the welcome flow's language step).
///
/// TODO: persist the choice — read it back on launch instead of always starting
/// at [AppLanguage.english], and write it whenever [language] changes.
class LocaleController extends ValueNotifier<AppLanguage> {
  LocaleController({AppLanguage initial = AppLanguage.english}) : super(initial);

  AppLanguage get language => value;

  set language(AppLanguage next) => value = next;

  /// The value handed to [WidgetsApp.locale].
  Locale get locale => value.locale;
}
