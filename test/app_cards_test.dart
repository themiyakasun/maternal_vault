import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maternal_vault/core/constants/app_colors.dart';
import 'package:maternal_vault/core/theme/app_theme.dart';
import 'package:maternal_vault/core/widgets/cards/app_card.dart';
import 'package:maternal_vault/core/widgets/cards/section_card.dart';
import 'package:maternal_vault/core/widgets/cards/stat_tile.dart';
import 'package:maternal_vault/core/widgets/cards/sub_card.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, Widget card) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: card,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The decoration the card itself painted — scoped to the [AppCard] so the
  /// tiles' inner glyph chips, which are also decorated boxes, cannot be picked
  /// up instead.
  BoxDecoration decorationOf(WidgetTester tester) {
    return tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(AppCard),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;
  }

  group('AppCard', () {
    testWidgets('paints the white lifted surface by default', (
      WidgetTester tester,
    ) async {
      await pumpCard(tester, const AppCard(child: Text('Body')));

      final BoxDecoration decoration = decorationOf(tester);
      expect(decoration.color, AppColors.cardSurface);
      expect(decoration.borderRadius, AppRadii.cardRadius);
      expect(decoration.boxShadow, AppColors.shadowCard);
      // A shadowed card wants no outline on top of the shadow.
      expect(decoration.border, isNull);
    });

    testWidgets('draws a hairline only when given a border colour', (
      WidgetTester tester,
    ) async {
      await pumpCard(
        tester,
        const AppCard(
          borderColor: AppColors.outlineVariant,
          child: Text('Body'),
        ),
      );

      expect(decorationOf(tester).border, isNotNull);
    });
  });

  group('StatTile', () {
    testWidgets('shows a value with its unit', (WidgetTester tester) async {
      await pumpCard(
        tester,
        const StatTile(
          icon: Icons.straighten_rounded,
          label: 'Height',
          value: '158',
          unit: 'cm',
          accent: AppColors.tertiary,
        ),
      );

      expect(find.text('Height'), findsOneWidget);
      expect(find.text('158 cm'), findsOneWidget);
    });

    testWidgets('shows an em-dash and drops the unit when there is no value', (
      WidgetTester tester,
    ) async {
      await pumpCard(
        tester,
        const StatTile(
          icon: Icons.straighten_rounded,
          label: 'Height',
          value: null,
          unit: 'cm',
          accent: AppColors.tertiary,
        ),
      );

      // Not "— cm", which would read as a measurement that failed.
      expect(find.text('—'), findsOneWidget);
      expect(find.text('— cm'), findsNothing);
    });
  });

  group('SectionCard', () {
    testWidgets('renders its glyph, title and children', (
      WidgetTester tester,
    ) async {
      await pumpCard(
        tester,
        const SectionCard(
          icon: Icons.badge_outlined,
          title: 'Demographics',
          accent: AppColors.primary,
          children: <Widget>[Text('First'), Text('Second')],
        ),
      );

      expect(find.byIcon(Icons.badge_outlined), findsOneWidget);
      expect(find.text('Demographics'), findsOneWidget);
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
    });
  });

  group('SubCard', () {
    testWidgets('renders its title over a divider, then its children', (
      WidgetTester tester,
    ) async {
      await pumpCard(
        tester,
        const SubCard(
          title: 'Mother (Wife)',
          accent: AppColors.primary,
          children: <Widget>[Text('Age')],
        ),
      );

      expect(find.text('Mother (Wife)'), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
    });

    testWidgets('sits flat — a shadow inside a card reads as a mistake', (
      WidgetTester tester,
    ) async {
      await pumpCard(
        tester,
        const SubCard(
          title: 'Mother (Wife)',
          accent: AppColors.primary,
          children: <Widget>[Text('Age')],
        ),
      );

      final BoxDecoration decoration = decorationOf(tester);
      expect(decoration.boxShadow, isEmpty);
      expect(decoration.border, isNotNull);
    });
  });
}
