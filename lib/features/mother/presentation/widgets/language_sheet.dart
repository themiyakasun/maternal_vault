import 'package:flutter/material.dart';

import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/l10n/app_locales.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../welcome/presentation/widgets/language_option_tile.dart';

/// Offers the three languages, same tiles as the welcome step.
///
/// Deliberately the same widget and the same heading as onboarding: someone
/// changing their mind later should meet the screen they already know rather
/// than a second, differently-worded language picker.
///
/// Returns once a language has been chosen, or null if the sheet was dismissed.
Future<AppLanguage?> showLanguageSheet(
  BuildContext context, {
  required AppLanguage selected,
}) {
  return showModalBottomSheet<AppLanguage>(
    context: context,
    // The three tiles plus a heading fit comfortably, so the sheet sizes itself
    // rather than taking a fixed fraction of the screen.
    builder: (BuildContext context) => _LanguageSheet(selected: selected),
  );
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.selected});

  final AppLanguage selected;

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
          AppLanguage.tamil: (
            l10n.languageNameTamil,
            l10n.languageSubtitleTamil,
          ),
        };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          0,
          AppSpacing.screenPadding,
          AppSpacing.sectionGap,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(l10n.languageStepTitle, style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.componentGap),
            for (final AppLanguage language in AppLanguage.values)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.stackSm),
                child: LanguageOptionTile(
                  name: labels[language]!.$1,
                  subtitle: labels[language]!.$2,
                  selected: language == selected,
                  selectedSemanticsLabel: l10n.languageSelectedSemantics,
                  onTap: () => Navigator.pop(context, language),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
