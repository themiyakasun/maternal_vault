import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maternal_vault/core/theme/app_theme.dart';
import 'package:maternal_vault/core/widgets/inputs/app_date_field.dart';
import 'package:maternal_vault/core/widgets/inputs/app_dropdown_field.dart';
import 'package:maternal_vault/core/widgets/inputs/app_text_field.dart';

/// Stand-in for the enums the real forms select over, so the dropdown tests
/// assert a typed value came back rather than a translated label.
enum _Fruit { apple, banana }

void main() {
  /// Mounts one field inside a [Form], and hands back the key so a test can run
  /// validation the way the screen's Save button does.
  Future<GlobalKey<FormState>> pumpField(
    WidgetTester tester,
    Widget field,
  ) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Form(key: formKey, child: field),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return formKey;
  }

  group('AppTextField', () {
    testWidgets('renders its label above the field and its hint inside', (
      WidgetTester tester,
    ) async {
      await pumpField(
        tester,
        const AppTextField(
          label: "Mother's Name",
          hint: 'Full name as on your ID',
        ),
      );

      expect(find.text("Mother's Name"), findsOneWidget);
      expect(find.text('Full name as on your ID'), findsOneWidget);
    });

    testWidgets('reports typed text through its controller', (
      WidgetTester tester,
    ) async {
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpField(
        tester,
        AppTextField(label: "Mother's Name", controller: controller),
      );

      await tester.enterText(find.byType(TextFormField), 'Nimali Perera');
      await tester.pump();

      expect(controller.text, 'Nimali Perera');
    });

    testWidgets('surfaces its validator message on a failed validate', (
      WidgetTester tester,
    ) async {
      final GlobalKey<FormState> formKey = await pumpField(
        tester,
        AppTextField(
          label: "Mother's Name",
          validator: (String? value) =>
              (value?.isEmpty ?? true) ? 'This field is required' : null,
        ),
      );

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();

      expect(find.text('This field is required'), findsOneWidget);
    });

    testWidgets('suppresses the character counter under a maxLength', (
      WidgetTester tester,
    ) async {
      await pumpField(tester, const AppTextField(label: 'Age', maxLength: 2));

      // maxLength is there to cap the input, not to invite counting.
      expect(find.text('0/2'), findsNothing);
    });
  });

  group('AppDropdownField', () {
    testWidgets('renders its label and hint while nothing is selected', (
      WidgetTester tester,
    ) async {
      await pumpField(
        tester,
        AppDropdownField<_Fruit>(
          label: 'Education Level',
          hint: 'Choose one',
          value: null,
          onChanged: (_) {},
          items: const <AppDropdownItem<_Fruit>>[
            AppDropdownItem<_Fruit>(value: _Fruit.apple, label: 'Apple'),
            AppDropdownItem<_Fruit>(value: _Fruit.banana, label: 'Banana'),
          ],
        ),
      );

      expect(find.text('Education Level'), findsOneWidget);
      expect(find.text('Choose one'), findsOneWidget);
    });

    testWidgets('reports the selected enum value, not its label', (
      WidgetTester tester,
    ) async {
      _Fruit? selected;

      await pumpField(
        tester,
        AppDropdownField<_Fruit>(
          label: 'Education Level',
          hint: 'Choose one',
          value: null,
          onChanged: (_Fruit? next) => selected = next,
          items: const <AppDropdownItem<_Fruit>>[
            AppDropdownItem<_Fruit>(value: _Fruit.apple, label: 'Apple'),
            AppDropdownItem<_Fruit>(value: _Fruit.banana, label: 'Banana'),
          ],
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<_Fruit>));
      await tester.pumpAndSettle();

      // The closed button keeps every item mounted in a hidden IndexedStack, so
      // the one in the open menu is the last match.
      await tester.tap(find.text('Banana').last);
      await tester.pumpAndSettle();

      expect(selected, _Fruit.banana);
    });

    testWidgets('does not open while disabled', (WidgetTester tester) async {
      await pumpField(
        tester,
        AppDropdownField<_Fruit>(
          label: 'Education Level',
          hint: 'Choose one',
          value: null,
          enabled: false,
          onChanged: (_) {},
          items: const <AppDropdownItem<_Fruit>>[
            AppDropdownItem<_Fruit>(value: _Fruit.apple, label: 'Apple'),
          ],
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<_Fruit>));
      await tester.pumpAndSettle();

      // Still closed with no item selected — no menu opened.
      expect(find.text('Apple'), findsNothing);
    });
  });

  group('AppDateField', () {
    testWidgets('shows its hint until a date is chosen', (
      WidgetTester tester,
    ) async {
      await pumpField(
        tester,
        AppDateField(
          label: 'Date of Registration',
          hint: 'Choose a date',
          value: null,
          onChanged: (_) {},
        ),
      );

      expect(find.text('Date of Registration'), findsOneWidget);
      expect(find.text('Choose a date'), findsOneWidget);
    });

    testWidgets('opens the picker and writes the chosen date back', (
      WidgetTester tester,
    ) async {
      DateTime? chosen;

      await pumpField(
        tester,
        AppDateField(
          label: 'Date of Registration',
          hint: 'Choose a date',
          value: null,
          onChanged: (DateTime? next) => chosen = next,
        ),
      );

      await tester.tap(find.text('Choose a date'));
      await tester.pumpAndSettle();

      // Accepts whatever the picker opened on, which is today.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(chosen, isNotNull);
      expect(chosen, DateUtils.dateOnly(DateTime.now()));
      // The field now reads as a date rather than a placeholder.
      expect(find.text('Choose a date'), findsNothing);
    });

    testWidgets('does not open while disabled', (WidgetTester tester) async {
      DateTime? chosen;

      await pumpField(
        tester,
        AppDateField(
          label: 'Date of Registration',
          hint: 'Choose a date',
          value: null,
          enabled: false,
          onChanged: (DateTime? next) => chosen = next,
        ),
      );

      await tester.tap(find.text('Choose a date'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsNothing);
      expect(chosen, isNull);
    });

    testWidgets('surfaces its validator message on a failed validate', (
      WidgetTester tester,
    ) async {
      final GlobalKey<FormState> formKey = await pumpField(
        tester,
        AppDateField(
          label: 'Date of Registration',
          hint: 'Choose a date',
          value: null,
          onChanged: (_) {},
          validator: (DateTime? value) =>
              value == null ? 'This field is required' : null,
        ),
      );

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();

      expect(find.text('This field is required'), findsOneWidget);
    });
  });
}
