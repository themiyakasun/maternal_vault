import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maternal_vault/core/l10n/app_locales.dart';
import 'package:maternal_vault/core/theme/app_theme.dart';
import 'package:maternal_vault/features/mother/domain/mother_tab.dart';
import 'package:maternal_vault/features/mother/presentation/screens/mother_shell_screen.dart';
import 'package:maternal_vault/l10n/generated/app_localizations.dart';

void main() {
  /// Mounts the shell on a phone-shaped surface, with a harness that owns the
  /// locale the way `main.dart` does.
  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(412 * 3, 915 * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const _ShellHarness());
    await tester.pumpAndSettle();
  }

  /// Which tab the stack is painting.
  ///
  /// Asserted through the index rather than by hunting for on-screen text:
  /// `IndexedStack` keeps every tab mounted and visible-but-unpainted, so finding
  /// a tab's text proves it exists, not that you are looking at it.
  int shownIndex(WidgetTester tester) =>
      tester.widget<IndexedStack>(find.byType(IndexedStack)).index!;

  /// Taps a destination in the bottom bar. Scoped to the bar because three of the
  /// five labels are also the heading of their own placeholder.
  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opens on Profile with all five destinations', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);

    expect(shownIndex(tester), MotherTab.profile.index);
    expect(find.text('Basic Profile'), findsOneWidget);

    final Finder bar = find.byType(NavigationBar);
    for (final String label in <String>[
      'Profile',
      'History',
      'Obstetric',
      'Clinic',
      'Plan',
    ]) {
      expect(
        find.descendant(of: bar, matching: find.text(label)),
        findsOneWidget,
        reason: 'missing the $label destination',
      );
    }
  });

  testWidgets('the header names the record and stubs the bell', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);

    expect(find.text('Pregnancy Record'), findsOneWidget);
    expect(find.byIcon(Icons.language_rounded), findsOneWidget);

    // The notifications screen does not exist yet, so the bell renders disabled
    // rather than tappable-but-inert.
    final IconButton bell = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.notifications_none_rounded),
    );
    expect(bell.onPressed, isNull);
  });

  testWidgets('each of the other four tabs shows its own placeholder', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);

    final Map<String, MotherTab> tabs = <String, MotherTab>{
      'History': MotherTab.history,
      'Obstetric': MotherTab.obstetric,
      'Clinic': MotherTab.clinic,
      'Plan': MotherTab.plan,
    };

    for (final MapEntry<String, MotherTab> entry in tabs.entries) {
      await tapTab(tester, entry.key);

      expect(shownIndex(tester), entry.value.index);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        entry.value.index,
      );
      // The tab's own name heads its placeholder, so it is obvious which section
      // you landed in — hence two matches for the name, bar plus body.
      expect(find.text(entry.key), findsNWidgets(2));
    }

    // One shared "not yet" across the four, rather than four degrees of empty.
    expect(find.text('Coming soon'), findsNWidgets(4));
  });

  testWidgets('returning to Profile keeps its scroll position', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -320));
    await tester.pumpAndSettle();

    final ScrollableState scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable),
    );
    final double scrolled = scrollable.position.pixels;
    expect(scrolled, greaterThan(0));

    await tapTab(tester, 'History');
    await tapTab(tester, 'Profile');

    expect(shownIndex(tester), MotherTab.profile.index);
    // What IndexedStack buys over swapping the body out: a half-filled form and
    // a scroll offset both survive a trip to another section.
    expect(scrollable.position.pixels, scrolled);
  });

  testWidgets('the globe opens the sheet and switching re-renders the shell', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(find.byIcon(Icons.language_rounded));
    await tester.pumpAndSettle();

    // The same heading and tiles as the welcome step, on purpose.
    expect(find.text('Choose your language'), findsOneWidget);
    expect(find.text('සිංහල'), findsOneWidget);
    expect(find.text('தமிழ்'), findsOneWidget);

    await tester.tap(find.text('සිංහල'));
    await tester.pumpAndSettle();

    expect(find.text('ගැබ්බර වාර්තාව'), findsOneWidget);
    expect(find.text('මූලික පැතිකඩ'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('පැතිකඩ'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('dismissing the sheet leaves the language alone', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(find.byIcon(Icons.language_rounded));
    await tester.pumpAndSettle();

    // Tapping the scrim dismisses without a choice.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Choose your language'), findsNothing);
    expect(find.text('Pregnancy Record'), findsOneWidget);
  });
}

/// Owns the locale so the globe has something real to change, mirroring how
/// `main.dart` holds it above the shell.
class _ShellHarness extends StatefulWidget {
  const _ShellHarness();

  @override
  State<_ShellHarness> createState() => _ShellHarnessState();
}

class _ShellHarnessState extends State<_ShellHarness> {
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
      home: MotherShellScreen(
        onLanguageChanged: (AppLanguage next) =>
            setState(() => _language = next),
      ),
    );
  }
}
