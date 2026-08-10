import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maternal_vault/core/l10n/app_locales.dart';
import 'package:maternal_vault/core/theme/app_theme.dart';
import 'package:maternal_vault/features/partner/presentation/screens/connect_mother_record_screen.dart';
import 'package:maternal_vault/l10n/generated/app_localizations.dart';

void main() {
  /// Mounts the connect screen on a phone-shaped surface — see the note in
  /// welcome_screen_test.dart for why the default 800x600 window is no good.
  Future<void> pumpConnect(
    WidgetTester tester, {
    VoidCallback? onScanNow,
    VoidCallback? onEnterCode,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(412 * 3, 915 * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _ConnectHarness(
        locale: locale,
        onScanNow: onScanNow,
        onEnterCode: onEnterCode,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the title, copy, scan status and both actions', (
    WidgetTester tester,
  ) async {
    await pumpConnect(tester);

    expect(find.text("Connect to Mother's Record"), findsOneWidget);
    expect(
      find.textContaining('Scan the secure code on your partner'),
      findsOneWidget,
    );
    expect(find.text('Ready to scan'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Scan Now'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Enter Code Manually'),
      findsOneWidget,
    );
  });

  testWidgets('both actions are disabled until the sync backend supplies them',
      (WidgetTester tester) async {
    await pumpConnect(tester);

    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Scan Now'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Enter Code Manually'),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('the actions fire the callbacks they are handed', (
    WidgetTester tester,
  ) async {
    int scans = 0;
    int manualEntries = 0;
    await pumpConnect(
      tester,
      onScanNow: () => scans++,
      onEnterCode: () => manualEntries++,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Scan Now'));
    await tester.pumpAndSettle();
    expect(scans, 1);
    expect(manualEntries, 0);

    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Enter Code Manually'),
    );
    await tester.pumpAndSettle();
    expect(manualEntries, 1);
  });

  testWidgets('the back chip pops the route', (WidgetTester tester) async {
    await pumpConnect(tester);

    // Reached through the route the harness pushed, so popping should reveal
    // the placeholder underneath.
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text("Connect to Mother's Record"), findsNothing);
    expect(find.text('beneath'), findsOneWidget);
  });

  testWidgets('translates into Sinhala', (WidgetTester tester) async {
    await pumpConnect(tester, locale: const Locale('si'));

    expect(find.text('මවගේ වාර්තාවට සම්බන්ධ වන්න'), findsOneWidget);
    expect(find.text('දැන් ස්කෑන් කරන්න'), findsOneWidget);
    expect(find.text("Connect to Mother's Record"), findsNothing);
  });
}

/// Pushes the screen onto a route stack rather than using it as `home`, so the
/// back chip has something to pop back to — which is how the app reaches it.
class _ConnectHarness extends StatelessWidget {
  const _ConnectHarness({
    required this.locale,
    this.onScanNow,
    this.onEnterCode,
  });

  final Locale locale;
  final VoidCallback? onScanNow;
  final VoidCallback? onEnterCode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppLanguage.locales,
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            // Pushed in a post-frame callback so the first pump already shows
            // the screen under test.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).push(
                ConnectMotherRecordScreen.route(
                  onScanNow: onScanNow,
                  onEnterCode: onEnterCode,
                ),
              );
            });
            return const Center(child: Text('beneath'));
          },
        ),
      ),
    );
  }
}
