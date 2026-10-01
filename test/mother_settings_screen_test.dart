import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maternal_vault/core/l10n/app_locales.dart';
import 'package:maternal_vault/core/theme/app_theme.dart';
import 'package:maternal_vault/features/mother/domain/basic_profile.dart';
import 'package:maternal_vault/features/mother/domain/clinic_record.dart';
import 'package:maternal_vault/features/mother/domain/delivery_plan.dart';
import 'package:maternal_vault/features/mother/domain/key_vitals.dart';
import 'package:maternal_vault/features/mother/presentation/screens/mother_settings_screen.dart';
import 'package:maternal_vault/features/mother/presentation/screens/partner_share_qr_screen.dart';
import 'package:maternal_vault/l10n/generated/app_localizations.dart';

void main() {
  const profile = BasicProfile(
    motherName: 'Kumari Sandamali Perera',
    registrationNumber: '#6720',
    emergencyContactPerson: 'Sunil Shantha',
  );

  const vitals = KeyVitals(
    bloodGroup: 'B +ve',
    bmi: '27.4',
    heightCm: '158',
  );

  const plan = DeliveryPlan(
    intendedHospital: 'Base Hospital Rampur',
    distanceKm: 12,
    estimatedTimeMinutes: 25,
  );

  final clinic = ClinicRecord(
    visits: [
      ClinicVisit(
        week: 38,
        date: DateTime(2025, 1, 1),
        systolic: 120,
        diastolic: 80,
      ),
    ],
  );

  Widget buildSettingsHarness() {
    return MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLanguage.locales,
      home: MotherSettingsScreen(
        profile: profile,
        vitals: vitals,
        deliveryPlan: plan,
        clinicRecord: clinic,
        onLanguageChanged: (_) {},
      ),
    );
  }

  testWidgets('MotherSettingsScreen renders all sections and tiles', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(412 * 3, 915 * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildSettingsHarness());
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Kumari Sandamali Perera'), findsOneWidget);
    expect(find.text('Record ID: #6720'), findsOneWidget);
    expect(find.text('Encrypted SQLCipher Vault'), findsOneWidget);

    // Sections & Tiles
    expect(find.text('PARTNER TRANSFER'), findsOneWidget);
    expect(find.text('Generate Partner QR Code'), findsOneWidget);
    expect(find.text('SECURITY & ACCESS'), findsOneWidget);
    expect(find.text('Change Vault PIN'), findsOneWidget);
    expect(find.text('Biometric Unlock'), findsOneWidget);
    expect(find.text('Lock Vault Now'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Sync with Midwife Dashboard'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('MIDWIFE CLINICAL SYNC'), findsOneWidget);
    expect(find.text('Sync with Midwife Dashboard'), findsOneWidget);

    // Scroll down to view Preferences and Data Management
    await tester.scrollUntilVisible(
      find.text('PREFERENCES'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('PREFERENCES'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('DATA MANAGEMENT'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('DATA MANAGEMENT'), findsOneWidget);
    expect(find.text('Reset Vault Data'), findsOneWidget);
  });

  testWidgets('Tapping Generate Partner QR Code navigates to PartnerShareQrScreen', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(412 * 3, 915 * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildSettingsHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Generate Partner QR Code'));
    await tester.pumpAndSettle();

    expect(find.byType(PartnerShareQrScreen), findsOneWidget);
    expect(find.text('Transfer to Partner'), findsOneWidget);
    expect(find.text('Shared With Partner'), findsOneWidget);
    expect(find.text('Base Hospital Rampur'), findsOneWidget);
    expect(find.text('Copy Transfer Code'), findsOneWidget);
  });
}
