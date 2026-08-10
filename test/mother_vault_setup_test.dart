import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maternal_vault/core/l10n/app_locales.dart';
import 'package:maternal_vault/core/theme/app_theme.dart';
import 'package:maternal_vault/features/mother/domain/vault_setup_stage.dart';
import 'package:maternal_vault/features/mother/presentation/screens/vault_setup_screen.dart';
import 'package:maternal_vault/features/mother/presentation/widgets/setup_stage_tile.dart';
import 'package:maternal_vault/l10n/generated/app_localizations.dart';

void main() {
  /// Each stage holds for this long, short enough to keep the suite quick.
  const Duration stageDuration = Duration(milliseconds: 20);

  /// Mounts the setup screen on a phone-shaped surface — see the note in
  /// welcome_screen_test.dart for why the default 800x600 window is no good.
  ///
  /// Deliberately pumps a single frame instead of settling: the screen runs a
  /// looping dots animation that never finishes, so `pumpAndSettle` would time
  /// out.
  Future<void> pumpSetup(
    WidgetTester tester, {
    VoidCallback? onComplete,
    Future<void> Function(VaultSetupStage stage)? runStage,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(412 * 3, 915 * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _VaultSetupHarness(
        locale: locale,
        onComplete: onComplete,
        runStage: runStage,
        stageDuration: stageDuration,
      ),
    );
    await tester.pump();
  }

  /// Runs out whatever stages are still queued.
  ///
  /// The binding asserts that no timer outlives the widget tree, and each stage
  /// arms the next one's delay only once it finishes — so the remaining stages
  /// need a pump each rather than one long jump.
  Future<void> drainStages(WidgetTester tester) async {
    for (int i = 0; i < VaultSetupStage.values.length; i++) {
      await tester.pump(stageDuration);
    }
  }

  testWidgets('opens with the first stage running and the rest waiting', (
    WidgetTester tester,
  ) async {
    await pumpSetup(tester);

    expect(find.text('Preparing your vault'), findsOneWidget);
    expect(_statusOf(tester, 'Creating your secure record'), StageStatus.active);
    expect(_statusOf(tester, 'Encrypting your data'), StageStatus.pending);
    expect(_statusOf(tester, 'Getting everything ready'), StageStatus.pending);

    await drainStages(tester);
  });

  testWidgets('the checklist advances one stage at a time', (
    WidgetTester tester,
  ) async {
    await pumpSetup(tester);

    await tester.pump(stageDuration);
    expect(_statusOf(tester, 'Creating your secure record'), StageStatus.done);
    expect(_statusOf(tester, 'Encrypting your data'), StageStatus.active);
    expect(_statusOf(tester, 'Getting everything ready'), StageStatus.pending);

    await tester.pump(stageDuration);
    expect(_statusOf(tester, 'Encrypting your data'), StageStatus.done);
    expect(_statusOf(tester, 'Getting everything ready'), StageStatus.active);

    await drainStages(tester);
  });

  testWidgets('onComplete fires exactly once, after the last stage', (
    WidgetTester tester,
  ) async {
    int completions = 0;
    await pumpSetup(tester, onComplete: () => completions++);

    await tester.pump(stageDuration);
    await tester.pump(stageDuration);
    expect(completions, 0, reason: 'still on the last stage');

    await tester.pump(stageDuration);
    expect(completions, 1);

    // Nothing left running should call it again.
    await tester.pump(stageDuration * 3);
    expect(completions, 1);
  });

  testWidgets('runs each stage through the injected hook, in order', (
    WidgetTester tester,
  ) async {
    final List<VaultSetupStage> ran = <VaultSetupStage>[];
    await pumpSetup(
      tester,
      runStage: (VaultSetupStage stage) async => ran.add(stage),
    );

    await tester.pump(stageDuration);
    await tester.pump(stageDuration);
    await tester.pump(stageDuration);

    expect(ran, VaultSetupStage.values);
  });

  testWidgets('a slow stage holds the screen past the minimum duration', (
    WidgetTester tester,
  ) async {
    // The first stage's work outlasts the floor, so the checklist must wait on
    // the work rather than the clock.
    await pumpSetup(
      tester,
      runStage: (VaultSetupStage stage) async {
        if (stage == VaultSetupStage.creatingRecord) {
          await Future<void>.delayed(stageDuration * 5);
        }
      },
    );

    await tester.pump(stageDuration * 2);
    expect(_statusOf(tester, 'Creating your secure record'), StageStatus.active);

    await tester.pump(stageDuration * 4);
    expect(_statusOf(tester, 'Creating your secure record'), StageStatus.done);

    await drainStages(tester);
  });

  testWidgets('translates into Tamil', (WidgetTester tester) async {
    await pumpSetup(tester, locale: const Locale('ta'));

    expect(find.text('உங்கள் வால்ட் தயாராகிறது'), findsOneWidget);
    expect(find.text('உங்கள் தரவைக் குறியாக்கம் செய்கிறோம்'), findsOneWidget);
    expect(find.text('Preparing your vault'), findsNothing);

    await drainStages(tester);
  });
}

/// The status the tile for [label] is rendering.
StageStatus _statusOf(WidgetTester tester, String label) {
  final Finder tile = find.byWidgetPredicate(
    (Widget widget) => widget is SetupStageTile && widget.label == label,
  );
  expect(tile, findsOneWidget, reason: 'no setup stage tile labelled "$label"');
  return tester.widget<SetupStageTile>(tile).status;
}

class _VaultSetupHarness extends StatelessWidget {
  const _VaultSetupHarness({
    required this.locale,
    required this.stageDuration,
    this.onComplete,
    this.runStage,
  });

  final Locale locale;
  final Duration stageDuration;
  final VoidCallback? onComplete;
  final Future<void> Function(VaultSetupStage stage)? runStage;

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
      home: VaultSetupScreen(
        onComplete: onComplete,
        runStage: runStage,
        minimumStageDuration: stageDuration,
      ),
    );
  }
}
