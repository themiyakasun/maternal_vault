import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maternal_vault/core/l10n/app_locales.dart';
import 'package:maternal_vault/core/theme/app_theme.dart';
import 'package:maternal_vault/features/mother/domain/basic_profile.dart';
import 'package:maternal_vault/features/mother/domain/education_level.dart';
import 'package:maternal_vault/features/mother/domain/key_vitals.dart';
import 'package:maternal_vault/features/mother/presentation/screens/basic_profile_screen.dart';
import 'package:maternal_vault/l10n/generated/app_localizations.dart';

void main() {
  /// Mounts the form on a phone-shaped surface.
  ///
  /// The default 800x600 test window is shorter than any phone the app targets,
  /// which would put the Save button so far outside the viewport that
  /// [WidgetTester.ensureVisible] has nothing sensible to scroll to.
  Future<void> pumpProfile(
    WidgetTester tester, {
    KeyVitals vitals = const KeyVitals.empty(),
    ValueChanged<BasicProfile>? onSubmit,
    AppLanguage language = AppLanguage.english,
  }) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(412 * 3, 915 * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: language.locale,
        supportedLocales: AppLanguage.locales,
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: BasicProfileScreen(vitals: vitals, onSubmit: onSubmit),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Scrolls the button into reach, then taps it. Unlike [WidgetTester.enterText],
  /// a tap hit-tests, so the button has to actually be on screen.
  Future<void> tapSave(WidgetTester tester, {String label = 'Save Profile'}) async {
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('renders both sections and all twelve fields', (
    WidgetTester tester,
  ) async {
    await pumpProfile(tester);

    expect(find.text('Basic Profile'), findsOneWidget);

    expect(find.text('Demographics'), findsOneWidget);
    expect(find.text('Registration No.'), findsOneWidget);
    expect(find.text('Date of Registration'), findsOneWidget);
    expect(find.text("Mother's Name"), findsOneWidget);
    expect(find.text('NIC / ID Number'), findsOneWidget);
    expect(find.text('Address'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);

    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('Mother (Wife)'), findsOneWidget);
    expect(find.text('Father (Husband)'), findsOneWidget);
    // The same three questions for either parent.
    expect(find.text('Age'), findsNWidgets(2));
    expect(find.text('Education Level'), findsNWidgets(2));
    expect(find.text('Occupation'), findsNWidgets(2));

    expect(find.text('Save Profile'), findsOneWidget);
  });

  testWidgets('an empty record shows an em-dash in every vitals tile', (
    WidgetTester tester,
  ) async {
    await pumpProfile(tester);

    expect(find.text('KEY VITALS'), findsOneWidget);
    expect(find.text('Blood Group'), findsOneWidget);
    expect(find.text('BMI'), findsOneWidget);
    expect(find.text('Height'), findsOneWidget);
    expect(find.text('Allergies'), findsOneWidget);

    // Nothing measured yet reads as empty, not as zero.
    expect(find.text('—'), findsNWidgets(4));
  });

  testWidgets('renders the vitals it is given, with the height unit', (
    WidgetTester tester,
  ) async {
    await pumpProfile(
      tester,
      vitals: const KeyVitals(
        bloodGroup: 'O+',
        bmi: '22.4',
        heightCm: '158',
        allergies: 'None',
      ),
    );

    expect(find.text('O+'), findsOneWidget);
    expect(find.text('22.4'), findsOneWidget);
    expect(find.text('158 cm'), findsOneWidget);
    expect(find.text('None'), findsOneWidget);
    expect(find.text('—'), findsNothing);
  });

  testWidgets('Save without a mother name blocks and does not submit', (
    WidgetTester tester,
  ) async {
    BasicProfile? submitted;
    await pumpProfile(
      tester,
      onSubmit: (BasicProfile profile) => submitted = profile,
    );

    await tapSave(tester);

    expect(find.text('This field is required'), findsOneWidget);
    expect(submitted, isNull);
  });

  testWidgets('a non-numeric age is rejected', (WidgetTester tester) async {
    BasicProfile? submitted;
    await pumpProfile(
      tester,
      onSubmit: (BasicProfile profile) => submitted = profile,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name as on your ID'),
      'Nimali Perera',
    );
    // maxLength clips this to two characters, which is still not a number.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Years').first,
      'abc',
    );
    await tester.pump();

    await tapSave(tester);

    expect(find.text('Enter an age between 12 and 70'), findsOneWidget);
    expect(submitted, isNull);
  });

  testWidgets('an age below the accepted range is rejected', (
    WidgetTester tester,
  ) async {
    BasicProfile? submitted;
    await pumpProfile(
      tester,
      onSubmit: (BasicProfile profile) => submitted = profile,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name as on your ID'),
      'Nimali Perera',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Years').first,
      '9',
    );
    await tester.pump();

    await tapSave(tester);

    expect(find.text('Enter an age between 12 and 70'), findsOneWidget);
    expect(submitted, isNull);
  });

  testWidgets('a filled form submits the typed values once', (
    WidgetTester tester,
  ) async {
    final List<BasicProfile> submitted = <BasicProfile>[];
    await pumpProfile(
      tester,
      onSubmit: (BasicProfile profile) => submitted.add(profile),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'As printed on your clinic card'),
      'PR-2026-0184',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name as on your ID'),
      '  Nimali Perera  ',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'National identity card number'),
      '199812345678',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'House number, street, city'),
      '14 Temple Road, Kandy',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '07X XXX XXXX').first,
      '0771234567',
    );

    // The mother's field is the first of the pair; once it holds a value its
    // hint is gone, so the remaining match is the father's.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Years').first,
      '27',
    );
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextFormField, 'Years').last, '31');
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'e.g. Teacher').first,
      'Teacher',
    );
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'e.g. Teacher').last,
      'Driver',
    );
    await tester.pump();

    await tapSave(tester);

    expect(submitted, hasLength(1));
    final BasicProfile profile = submitted.single;
    // Surrounding whitespace is trimmed off on the way out.
    expect(profile.motherName, 'Nimali Perera');
    expect(profile.registrationNumber, 'PR-2026-0184');
    expect(profile.nationalId, '199812345678');
    expect(profile.address, '14 Temple Road, Kandy');
    expect(profile.phoneNumber, '0771234567');
    expect(profile.mother.age, 27);
    expect(profile.mother.occupation, 'Teacher');
    expect(profile.father.age, 31);
    expect(profile.father.occupation, 'Driver');
    // Untouched optional fields come through as null, not as blank strings.
    expect(profile.registrationDate, isNull);
    expect(profile.mother.education, isNull);
  });

  testWidgets('the education dropdown submits the enum value', (
    WidgetTester tester,
  ) async {
    final List<BasicProfile> submitted = <BasicProfile>[];
    await pumpProfile(
      tester,
      onSubmit: (BasicProfile profile) => submitted.add(profile),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name as on your ID'),
      'Nimali Perera',
    );
    await tester.pump();

    final Finder dropdown = find
        .byType(DropdownButtonFormField<EducationLevel>)
        .first;
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    // Each closed button keeps every option mounted in a hidden IndexedStack, so
    // the entry in the open menu is the last match.
    await tester.tap(find.text('A/L qualified').last);
    await tester.pumpAndSettle();

    await tapSave(tester);

    expect(submitted.single.mother.education, EducationLevel.aLevel);
  });

  testWidgets('a valid Save with nowhere to store it says so plainly', (
    WidgetTester tester,
  ) async {
    // onSubmit left null — the state main.dart is in until the record layer lands.
    await pumpProfile(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name as on your ID'),
      'Nimali Perera',
    );
    await tester.pump();

    await tapSave(tester);

    // Careful wording: it does not claim the profile was saved.
    expect(
      find.text('Details look good. Saving to your record is not connected yet.'),
      findsOneWidget,
    );
  });

  testWidgets('renders in Sinhala', (WidgetTester tester) async {
    await pumpProfile(tester, language: AppLanguage.sinhala);

    expect(find.text('මූලික පැතිකඩ'), findsOneWidget);
    expect(find.text('ජන විස්තර'), findsOneWidget);
    expect(find.text('පෞද්ගලික තොරතුරු'), findsOneWidget);
    expect(find.text('මව (බිරිඳ)'), findsOneWidget);
    expect(find.text('පියා (සැමියා)'), findsOneWidget);
    expect(find.text('අධ්‍යාපන මට්ටම'), findsNWidgets(2));
    expect(find.text('පැතිකඩ සුරකින්න'), findsOneWidget);
  });

  testWidgets('blocks Save in Sinhala with the translated message', (
    WidgetTester tester,
  ) async {
    await pumpProfile(tester, language: AppLanguage.sinhala);

    await tapSave(tester, label: 'පැතිකඩ සුරකින්න');

    expect(find.text('මෙම ක්ෂේත්‍රය අවශ්‍යයි'), findsOneWidget);
  });
}
