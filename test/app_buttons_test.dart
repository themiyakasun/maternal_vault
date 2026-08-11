import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maternal_vault/core/constants/app_colors.dart';
import 'package:maternal_vault/core/theme/app_theme.dart';
import 'package:maternal_vault/core/widgets/buttons/app_button_tone.dart';
import 'package:maternal_vault/core/widgets/buttons/app_outline_button.dart';
import 'package:maternal_vault/core/widgets/buttons/app_primary_button.dart';

void main() {
  Future<void> pumpButton(WidgetTester tester, Widget button) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: button,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AppPrimaryButton', () {
    testWidgets('paints the primary tone by default', (
      WidgetTester tester,
    ) async {
      await pumpButton(
        tester,
        AppPrimaryButton(label: 'Continue', onPressed: () {}),
      );

      final ButtonStyle style = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .style!;
      expect(
        style.backgroundColor?.resolve(<WidgetState>{}),
        AppColors.primary,
      );
      expect(
        style.foregroundColor?.resolve(<WidgetState>{}),
        AppColors.onPrimary,
      );
    });

    testWidgets('paints the secondary tone in sage', (
      WidgetTester tester,
    ) async {
      await pumpButton(
        tester,
        AppPrimaryButton(
          label: 'Scan Now',
          onPressed: () {},
          tone: AppButtonTone.secondary,
        ),
      );

      final ButtonStyle style = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .style!;
      expect(
        style.backgroundColor?.resolve(<WidgetState>{}),
        AppColors.secondary,
      );
      expect(
        style.foregroundColor?.resolve(<WidgetState>{}),
        AppColors.onSecondary,
      );
    });

    testWidgets('keeps its disabled colours when the tone overrides enabled '
        'ones', (WidgetTester tester) async {
      // The regression this guards: styleFrom drops the theme's disabled pair
      // as soon as a caller supplies its own background, so a toned button
      // would otherwise stay fully sage while unusable.
      await pumpButton(
        tester,
        const AppPrimaryButton(
          label: 'Scan Now',
          onPressed: null,
          tone: AppButtonTone.secondary,
        ),
      );

      final ButtonStyle style = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .style!;
      const Set<WidgetState> disabled = <WidgetState>{WidgetState.disabled};
      expect(
        style.backgroundColor?.resolve(disabled),
        AppButtonDisabled.background,
      );
      expect(
        style.foregroundColor?.resolve(disabled),
        AppButtonDisabled.foreground,
      );
    });

    testWidgets('renders a leading glyph only when asked', (
      WidgetTester tester,
    ) async {
      await pumpButton(
        tester,
        AppPrimaryButton(label: 'Plain', onPressed: () {}),
      );
      expect(find.byType(Icon), findsNothing);

      await pumpButton(
        tester,
        AppPrimaryButton(
          label: 'Scan Now',
          onPressed: () {},
          icon: Icons.qr_code_scanner_rounded,
        ),
      );
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
    });

    testWidgets('fills the width by default and hugs its label when not', (
      WidgetTester tester,
    ) async {
      await pumpButton(
        tester,
        AppPrimaryButton(label: 'Continue', onPressed: () {}),
      );
      final double full = tester.getSize(find.byType(FilledButton)).width;

      await pumpButton(
        tester,
        AppPrimaryButton(
          label: 'Continue',
          onPressed: () {},
          expand: false,
        ),
      );
      final Size hugged = tester.getSize(find.byType(FilledButton));

      expect(hugged.width, lessThan(full));
      // Relaxing the width must not cost the theme's height.
      expect(hugged.height, AppTheme.buttonHeight);
    });

    testWidgets('fires its callback once per tap', (WidgetTester tester) async {
      int taps = 0;
      await pumpButton(
        tester,
        AppPrimaryButton(label: 'Continue', onPressed: () => taps++),
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });
  });

  group('AppOutlineButton', () {
    testWidgets('tints the label with the tone but keeps a neutral border', (
      WidgetTester tester,
    ) async {
      await pumpButton(
        tester,
        AppOutlineButton(
          label: 'Enter Code Manually',
          onPressed: () {},
          tone: AppButtonTone.secondary,
        ),
      );

      final ButtonStyle style = tester
          .widget<OutlinedButton>(find.byType(OutlinedButton))
          .style!;
      expect(
        style.foregroundColor?.resolve(<WidgetState>{}),
        AppColors.secondary,
      );
      expect(
        style.side?.resolve(<WidgetState>{})?.color,
        AppColors.outlineVariant,
      );
    });

    testWidgets('greys its label out when disabled', (
      WidgetTester tester,
    ) async {
      await pumpButton(
        tester,
        const AppOutlineButton(label: 'Back', onPressed: null),
      );

      final ButtonStyle style = tester
          .widget<OutlinedButton>(find.byType(OutlinedButton))
          .style!;
      expect(
        style.foregroundColor?.resolve(<WidgetState>{WidgetState.disabled}),
        AppButtonDisabled.foreground,
      );
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );
    });

    testWidgets('fires its callback once per tap', (WidgetTester tester) async {
      int taps = 0;
      await pumpButton(
        tester,
        AppOutlineButton(label: 'Back', onPressed: () => taps++),
      );

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });
  });
}
