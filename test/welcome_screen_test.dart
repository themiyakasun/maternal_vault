import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maternal_vault/core/l10n/app_locales.dart';
import 'package:maternal_vault/core/theme/app_theme.dart';
import 'package:maternal_vault/features/welcome/domain/user_role.dart';
import 'package:maternal_vault/features/welcome/presentation/screens/welcome_screen.dart';
import 'package:maternal_vault/features/welcome/presentation/widgets/language_option_tile.dart';
import 'package:maternal_vault/l10n/generated/app_localizations.dart';

void main() {
  /// Mounts the flow on a phone-shaped surface.
  ///
  /// The default 800x600 test window is shorter than any phone the app targets,
  /// which pushes the second role card outside the visible scroll area and makes
  /// taps miss. Sizing the surface here keeps the tests honest about the layout
  /// users actually get.
  Future<void> pumpWelcome(
    WidgetTester tester, {
    ValueChanged<UserRole>? onCompleted,
  }) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(412 * 3, 915 * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_WelcomeHarness(onCompleted: onCompleted));
    await tester.pumpAndSettle();
  }

  testWidgets('starts on the language step with English preselected', (
    WidgetTester tester,
  ) async {
    await pumpWelcome(tester);

    expect(find.text('Choose your language'), findsOneWidget);
    // All three languages are offered in their own script.
    expect(find.text('English'), findsWidgets);
    expect(find.text('සිංහල'), findsOneWidget);
    expect(find.text('தமிழ்'), findsOneWidget);

    // No Back button on the first step.
    expect(find.text('Back'), findsNothing);
  });

  testWidgets('picking Sinhala re-renders the step in Sinhala', (
    WidgetTester tester,
  ) async {
    await pumpWelcome(tester);

    await tester.tap(find.text('සිංහල'));
    await tester.pumpAndSettle();

    expect(find.text('ඔබේ භාෂාව තෝරන්න'), findsOneWidget);
    expect(find.text('Choose your language'), findsNothing);
    // The primary action follows the locale too.
    expect(find.text('ඊළඟ'), findsOneWidget);
  });

  testWidgets('the checkmark follows the picked language', (
    WidgetTester tester,
  ) async {
    await pumpWelcome(tester);

    // English starts selected.
    expect(_isSelected(tester, 'English'), isTrue);
    expect(_isSelected(tester, 'සිංහල'), isFalse);

    await tester.tap(find.text('සිංහල'));
    await tester.pumpAndSettle();

    // Regression guard: the flow used to receive the language as a field
    // captured when the route was pushed, so the copy translated but the check
    // stayed on English forever.
    expect(_isSelected(tester, 'English'), isFalse);
    expect(_isSelected(tester, 'සිංහල'), isTrue);
  });

  testWidgets('Next and Back walk through all three steps', (
    WidgetTester tester,
  ) async {
    await pumpWelcome(tester);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Your pregnancy, safely in hand'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('How will you be using Maternal Vault?'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Your pregnancy, safely in hand'), findsOneWidget);
  });

  testWidgets('Get Started stays disabled until a role is picked', (
    WidgetTester tester,
  ) async {
    UserRole? completedWith;
    await pumpWelcome(
      tester,
      onCompleted: (UserRole role) => completedWith = role,
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    final Finder getStarted = find.widgetWithText(FilledButton, 'Get Started');
    expect(tester.widget<FilledButton>(getStarted).onPressed, isNull);

    final Finder partnerCard = find.text('I am the Partner / Support');
    await tester.ensureVisible(partnerCard);
    await tester.pumpAndSettle();
    await tester.tap(partnerCard);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(getStarted).onPressed, isNotNull);

    await tester.tap(getStarted);
    await tester.pumpAndSettle();
    expect(completedWith, UserRole.partner);
  });

  testWidgets('Get Started reports the mother role too', (
    WidgetTester tester,
  ) async {
    // The other branch of the routing switch in main.dart — partner is covered
    // above, and each role goes somewhere different.
    UserRole? completedWith;
    await pumpWelcome(
      tester,
      onCompleted: (UserRole role) => completedWith = role,
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    final Finder motherCard = find.text('I am the Expectant Mother');
    await tester.ensureVisible(motherCard);
    await tester.pumpAndSettle();
    await tester.tap(motherCard);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Get Started'));
    await tester.pumpAndSettle();
    expect(completedWith, UserRole.expectantMother);
  });
}

/// Hosts the flow with the same localization setup the real app uses, holding
/// the locale in state so a tile tap really does re-render the subtree — which
/// is the behaviour the selection tests depend on.
class _WelcomeHarness extends StatefulWidget {
  const _WelcomeHarness({this.onCompleted});

  final ValueChanged<UserRole>? onCompleted;

  @override
  State<_WelcomeHarness> createState() => _WelcomeHarnessState();
}

class _WelcomeHarnessState extends State<_WelcomeHarness> {
  AppLanguage _language = AppLanguage.english;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      locale: _language.locale,
      supportedLocales: AppLanguage.locales,
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: WelcomeScreen(
        onLanguageChanged: (AppLanguage next) =>
            setState(() => _language = next),
        onCompleted: widget.onCompleted,
      ),
    );
  }
}

/// Whether the tile for the language named [name] renders as selected.
///
/// Matches on the tile's own `name` rather than searching for descendant text:
/// in the English locale a tile's name and subtitle are both "English", so a
/// text-based ancestor lookup finds the same tile twice.
///
/// Reads the rendered semantics rather than any private field, so this asserts
/// what a user — or a screen reader — actually perceives.
bool _isSelected(WidgetTester tester, String name) {
  final Finder tile = find.byWidgetPredicate(
    (Widget widget) => widget is LanguageOptionTile && widget.name == name,
  );
  expect(tile, findsOneWidget, reason: 'no language tile named "$name"');
  return tester.getSemantics(tile).flagsCollection.isSelected ==
      Tristate.isTrue;
}
