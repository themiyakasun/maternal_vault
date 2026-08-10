import 'package:flutter/material.dart';

import '../../../../core/l10n/app_locales.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../widgets/language_option_tile.dart';
import '../widgets/welcome_step_intro.dart';

/// Welcome step 1 — pick the app's language.
///
/// Selecting a tile switches the locale immediately rather than on Next, so the
/// rest of this screen re-renders in the chosen language and the user gets to
/// confirm they picked the right one before going further.
class LanguageStep extends StatelessWidget {
  const LanguageStep({
    super.key,
    required this.selected,
    required this.onSelected,
    this.compact = false,
  });

  final AppLanguage selected;
  final ValueChanged<AppLanguage> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    final Map<AppLanguage, (String name, String subtitle)> labels =
        <AppLanguage, (String, String)>{
      AppLanguage.english: (
        l10n.languageNameEnglish,
        l10n.languageSubtitleEnglish,
      ),
      AppLanguage.sinhala: (
        l10n.languageNameSinhala,
        l10n.languageSubtitleSinhala,
      ),
      AppLanguage.tamil: (l10n.languageNameTamil, l10n.languageSubtitleTamil),
    };

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          WelcomeStepIntro(
            title: l10n.languageStepTitle,
            body: l10n.languageStepBody,
            compact: compact,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          for (final AppLanguage language in AppLanguage.values)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.componentGap),
              child: LanguageOptionTile(
                name: labels[language]!.$1,
                subtitle: labels[language]!.$2,
                selected: language == selected,
                selectedSemanticsLabel: l10n.languageSelectedSemantics,
                onTap: () => onSelected(language),
              ),
            ),
        ],
      ),
    );
  }
}
