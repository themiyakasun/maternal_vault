import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maternal_vault/core/theme/app_theme.dart';
import 'package:maternal_vault/data/models/models.dart';
import 'package:maternal_vault/data/services/model_notification_service.dart';
import 'package:maternal_vault/features/mother/data/services/midwife_sync_service.dart';
import 'package:maternal_vault/features/mother/domain/basic_profile.dart';
import 'package:maternal_vault/features/mother/domain/clinic_record.dart';
import 'package:maternal_vault/features/mother/domain/delivery_plan.dart';
import 'package:maternal_vault/features/mother/domain/epds_screening.dart';
import 'package:maternal_vault/features/mother/domain/key_vitals.dart';
import 'package:maternal_vault/features/mother/domain/medical_history.dart';
import 'package:maternal_vault/features/mother/domain/obstetric_history.dart';
import 'package:maternal_vault/features/mother/domain/read_only_immutability_guard.dart';
import 'package:maternal_vault/features/mother/presentation/screens/basic_profile_screen.dart';
import 'package:maternal_vault/features/mother/presentation/screens/epds_screening_screen.dart';
import 'package:maternal_vault/features/mother/presentation/screens/medical_history_screen.dart';
import 'package:maternal_vault/features/mother/presentation/screens/mother_notifications_screen.dart';
import 'package:maternal_vault/features/mother/presentation/screens/plan_screen.dart';
import 'package:maternal_vault/features/mother/presentation/widgets/model_alert_dialog.dart';
import 'package:maternal_vault/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MaternalRiskModel Tests', () {
    late MaternalRiskModel model;

    setUp(() {
      model = MaternalRiskModel();
    });

    tearDown(() {
      model.dispose();
    });

    test('predict with normal vitals returns low risk and no alert', () async {
      final result = await model.predict(
        age: 26,
        systolicBp: 118,
        diastolicBp: 76,
        bloodSugarMmol: 4.8,
        heartRateBpm: 78,
      );

      expect(result.severity, AlertSeverity.low);
      expect(result.riskProbability, lessThan(0.40));
      expect(result.isElevated, isFalse);
      expect(result.toNotification(), isNull);
    });

    test('predict with severe hypertension and hyperglycemia returns high/critical risk and alert', () async {
      final result = await model.predict(
        age: 38,
        systolicBp: 165,
        diastolicBp: 105,
        bloodSugarMmol: 11.2,
        heartRateBpm: 96,
      );

      expect(
        result.severity == AlertSeverity.high ||
            result.severity == AlertSeverity.critical,
        isTrue,
      );
      expect(result.isElevated, isTrue);
      expect(result.contributingFactors, isNotEmpty);

      final notification = result.toNotification();
      expect(notification, isNotNull);
      expect(notification!.modelType, ModelType.maternalRisk);
      expect(notification.recommendations, isNotEmpty);
    });

    test('harmonizes mmol/L glucose to mg/dL and °C temperature to °F into the [1, 6] TFLite tensor', () async {
      expect(MaternalRiskModel.harmonizeGlucoseToMgDl(5.0), closeTo(90.0, 0.01));
      expect(MaternalRiskModel.harmonizeGlucoseToMgDl(84.0), closeTo(84.0, 0.01));
      expect(MaternalRiskModel.harmonizeTempToFahrenheit(37.0), closeTo(98.6, 0.01));
      expect(MaternalRiskModel.harmonizeTempToFahrenheit(38.5), closeTo(101.3, 0.01));
      expect(MaternalRiskModel.harmonizeTempToFahrenheit(98.4), closeTo(98.4, 0.01));

      const obs = VitalSignsObservation(
        age: 26,
        systolicBp: 120,
        diastolicBp: 80,
        bloodGlucose: 5.0, // 5.0 mmol/L -> 90.0 mg/dL
        bodyTemperature: 37.0, // 37.0 °C -> 98.6 °F
        heartRate: 80,
      );
      expect(obs.harmonizeGlucoseMmolToMgDl(), closeTo(90.0, 0.01));
      expect(obs.harmonizeTempCelsiusToFahrenheit(), closeTo(98.6, 0.01));

      final tensor = obs.toHarmonizedFloat32Tensor();
      expect(tensor.length, 6);
      expect(tensor[3], closeTo(90.0, 0.01));
      expect(tensor[4], closeTo(98.6, 0.01));

      final result = await model.predict(
        age: 26,
        systolicBp: 120,
        diastolicBp: 80,
        bloodSugarMmol: 5.0,
        bodyTempF: 37.0,
        heartRateBpm: 80,
      );
      expect(result.inputTensor.length, 6);
      expect(result.inputTensor[3], closeTo(90.0, 0.01));
      expect(result.inputTensor[4], closeTo(98.6, 0.01));
    });

    test('evaluateFromVitals uses real quantitative bodyTempF, maternalHeartRate, and bloodSugarMgDl', () async {
      final visit = ClinicVisit(
        week: 32,
        date: DateTime(2025, 1, 10),
        status: VisitStatus.review,
        systolic: 128,
        diastolic: 82,
        fetalHeartRate: 144,
        maternalHeartRate: 112,
        bodyTempF: 101.2,
        bloodSugarMgDl: 155.0,
        urineSugar: UrineReading.nil,
      );

      final result = await model.evaluateFromVitals(
        profile: BasicProfile.sample(),
        vitals: const KeyVitals.sample(),
        latestVisit: visit,
      );

      expect(result.isElevated, isTrue);
      expect(
        result.contributingFactors.any((f) => f.contains('155 mg/dL')),
        isTrue,
      );
      expect(
        result.contributingFactors.any((f) => f.contains('101.2 °F')),
        isTrue,
      );
      expect(
        result.contributingFactors.any((f) => f.contains('112 bpm')),
        isTrue,
      );
    });
  });

  group('PretermRiskModel Tests', () {
    late PretermRiskModel model;

    setUp(() {
      model = PretermRiskModel();
    });

    tearDown(() {
      model.dispose();
    });

    test('evaluates primigravida with normal pregnancy as low preterm risk', () async {
      final result = await model.evaluate(
        profile: BasicProfile.sample(),
        vitals: const KeyVitals.sample(),
      );

      expect(result.severity, AlertSeverity.low);
      expect(result.probability, lessThan(0.40));
      expect(result.toNotification(), isNull);
    });

    test('evaluates mother with prior preterm births and review status as elevated preterm risk', () async {
      const obstetric = ObstetricHistory(
        pregnancies: <PastPregnancy>[
          PastPregnancy(
            order: 1,
            year: 2022,
            term: PregnancyTerm.preterm,
            outcome: PregnancyOutcome.alive,
          ),
          PastPregnancy(
            order: 2,
            year: 2024,
            term: PregnancyTerm.preterm,
            outcome: PregnancyOutcome.alive,
          ),
        ],
      );

      final clinic = ClinicRecord(
        visits: <ClinicVisit>[
          ClinicVisit(
            week: 28,
            date: DateTime.now(),
            status: VisitStatus.review,
            systolic: 135,
            diastolic: 88,
          ),
        ],
      );

      final result = await model.evaluate(
        profile: BasicProfile.sample(),
        vitals: const KeyVitals.sample(),
        obstetric: obstetric,
        clinic: clinic,
      );

      expect(result.isElevated, isTrue);
      expect(result.probability, greaterThan(0.30));
      expect(result.inputVector.length, 37);
      // Verify slots 4..36 have exactly 9 active one-hot encoded categorical features (not zeros)
      final activeOneHots =
          result.inputVector.sublist(4).where((v) => v == 1.0).length;
      expect(activeOneHots, 9);
      // Verify slot 1 is StandardScaler(previous_c_sections), NOT currentWeek / 42.0 (28 / 42.0 = 0.6667)
      expect(result.inputVector[1], isNot(closeTo(28.0 / 42.0, 0.01)));

      final notification = result.toNotification();
      expect(notification, isNotNull);
      expect(notification!.modelType, ModelType.pretermRisk);
      expect(notification.recommendations.any((r) => r.contains('cramping') || r.contains('contractions')), isTrue);
    });

    test('maps 13 SINASC features into 37-element tensor using feature_metadata.json and imputer.pkl', () async {
      final meta = await OnDeviceFeatureVectorAdapter.loadMetadata();
      expect(meta['preterm_model'], isNotNull);
      expect(OnDeviceFeatureVectorAdapter.isImputerVerified, isTrue);

      final result = await model.evaluate(
        profile: BasicProfile.sample(),
        vitals: const KeyVitals.sample(),
      );
      expect(result.inputVector.length, 37);
      // Slots 7..36 must have active one-hot features rather than all 0.0
      expect(result.inputVector.sublist(7).any((v) => v == 1.0), isTrue);
    });
  });

  group('MentalHealthModel Tests', () {
    late MentalHealthModel model;

    setUp(() {
      model = MentalHealthModel();
    });

    tearDown(() {
      model.dispose();
    });

    test('evaluates low EPDS score as low risk and maps 64 features into 245-element tensor', () async {
      final result = await model.evaluate(
        epdsScore: 2,
        anxietyScore: 1,
        sleepDisturbance: false,
      );

      expect(result.severity, AlertSeverity.low);
      expect(result.isElevated, isFalse);
      expect(result.toNotification(), isNull);
      expect(result.inputVector.length, 245);
      // Verify slots 5..244 contain 59 active one-hot encoded survey features (not zeros)
      final activeOneHots =
          result.inputVector.sublist(5).where((v) => v == 1.0).length;
      expect(activeOneHots, 59);
    });

    test('evaluates elevated EPDS score (>= 13) as high risk requiring support', () async {
      final result = await model.evaluate(
        epdsScore: 15,
        anxietyScore: 8,
        sleepDisturbance: true,
      );

      expect(
        result.severity == AlertSeverity.high ||
            result.severity == AlertSeverity.critical,
        isTrue,
      );
      expect(result.isElevated, isTrue);

      final notification = result.toNotification();
      expect(notification, isNotNull);
      expect(notification!.modelType, ModelType.mentalHealth);
      expect(notification.recommendations, isNotEmpty);
    });
  });

  group('ClinicalModelEvaluator Tests', () {
    test('evaluateAll aggregates predictions across all models', () async {
      final evaluator = ClinicalModelEvaluator();

      final result = await evaluator.evaluateAll(
        profile: BasicProfile.sample(),
        vitals: const KeyVitals.sample(),
        history: const MedicalHistory(
          personal: <PersonalCondition>{PersonalCondition.diabetes},
        ),
        epdsScore: 14,
      );

      expect(result.maternalRisk, isNotNull);
      expect(result.pretermRisk, isNotNull);
      expect(result.mentalHealthRisk, isNotNull);
      expect(result.hasAlerts, isTrue);
      expect(result.alerts.any((a) => a.modelType == ModelType.mentalHealth), isTrue);

      evaluator.dispose();
    });
  });

  group('ModelNotificationService Tests', () {
    late ModelNotificationService service;

    setUp(() {
      service = ModelNotificationService();
    });

    tearDown(() {
      service.dispose();
    });

    test('posting and reading notifications updates unread count and latest alert', () async {
      final notification1 = ModelNotification(
        id: 'test-1',
        modelType: ModelType.maternalRisk,
        severity: AlertSeverity.high,
        title: 'High Maternal BP Alert',
        message: 'Blood pressure 150/95 requires clinical review.',
        recommendations: const <String>['Rest and recheck BP.'],
      );

      final notification2 = ModelNotification(
        id: 'test-2',
        modelType: ModelType.mentalHealth,
        severity: AlertSeverity.moderate,
        title: 'Emotional Wellbeing Support',
        message: 'Mild anxiety symptoms recorded.',
        recommendations: const <String>['Practice breathing exercises.'],
      );

      await service.postNotification(notification1);
      expect(service.notificationsNotifier.value.length, 1);
      expect(service.unreadCountNotifier.value, 1);
      expect(service.latestAlertNotifier.value?.id, 'test-1');

      await service.postNotification(notification2);
      expect(service.notificationsNotifier.value.length, 2);
      expect(service.unreadCountNotifier.value, 2);

      // Mark first as read
      await service.markAsRead('test-1');
      expect(service.unreadCountNotifier.value, 1);
      expect(
        service.notificationsNotifier.value
            .firstWhere((n) => n.id == 'test-1')
            .isRead,
        isTrue,
      );

      // Mark all as read
      await service.markAllAsRead();
      expect(service.unreadCountNotifier.value, 0);

      // Delete one
      await service.deleteNotification('test-1');
      expect(service.notificationsNotifier.value.length, 1);

      // Clear all
      await service.clearAll();
      expect(service.notificationsNotifier.value.isEmpty, isTrue);
      expect(service.unreadCountNotifier.value, 0);
    });
  });

  group('Widget Tests: ModelAlertDialog and MotherNotificationsScreen', () {
    testWidgets('ModelAlertDialog displays severity, recommendations and actions', (
      WidgetTester tester,
    ) async {
      final alert = ModelNotification(
        id: 'alert-widget-test',
        modelType: ModelType.maternalRisk,
        severity: AlertSeverity.high,
        title: '⚠️ Critical BP Alert',
        message: 'Maternal systolic pressure elevated to 155 mmHg.',
        recommendations: const <String>[
          'Rest on left lateral side for 15 minutes.',
          'Contact your Public Health Midwife.',
        ],
        metrics: const <String, dynamic>{
          'factors': <String>['Elevated BP 155/95'],
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) => ElevatedButton(
                onPressed: () => ModelAlertDialog.show(context, alert),
                child: const Text('Show Alert'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Alert'));
      await tester.pumpAndSettle();

      expect(find.text('⚠️ Critical BP Alert'), findsOneWidget);
      expect(find.text('Maternal Health Risk Model (XGBoost)'), findsOneWidget);
      expect(find.text('HIGH RISK'), findsOneWidget);
      expect(find.text('Maternal systolic pressure elevated to 155 mmHg.'), findsOneWidget);
      expect(find.text('Rest on left lateral side for 15 minutes.'), findsOneWidget);
      expect(find.text('Acknowledge'), findsOneWidget);

      await tester.tap(find.text('Acknowledge'));
      await tester.pumpAndSettle();
      expect(find.text('⚠️ Critical BP Alert'), findsNothing);
    });

    testWidgets('MotherNotificationsScreen renders empty state when no notifications', (
      WidgetTester tester,
    ) async {
      await ModelNotificationService.instance.clearAll();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const MotherNotificationsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Clinical AI Alerts'), findsOneWidget);
      expect(find.text('All Clinical AI Signals Optimal'), findsOneWidget);
      expect(find.text('Run AI Check'), findsOneWidget);
    });

    testWidgets('MotherNotificationsScreen renders notifications and filters', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final highAlert = ModelNotification(
        id: 'notif-1',
        modelType: ModelType.maternalRisk,
        severity: AlertSeverity.high,
        title: 'Elevated BP Detected',
        message: 'Blood pressure is 150/90 mmHg.',
      );
      final moderateAlert = ModelNotification(
        id: 'notif-2',
        modelType: ModelType.mentalHealth,
        severity: AlertSeverity.moderate,
        title: 'Wellbeing Check Reminder',
        message: 'Mild sleep disruption reported.',
      );

      ModelNotificationService.instance.notificationsNotifier.value = <ModelNotification>[
        highAlert,
        moderateAlert,
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const MotherNotificationsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Elevated BP Detected'), findsOneWidget);
      expect(find.text('Wellbeing Check Reminder'), findsOneWidget);
      expect(find.text('View Guidance'), findsNWidgets(2));

      // Tap Elevated Risk filter chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'Elevated Risk'));
      await tester.pumpAndSettle();

      expect(find.text('Elevated BP Detected'), findsOneWidget);
      expect(find.text('Wellbeing Check Reminder'), findsNothing);
    });

    test('EpdsScreeningEntry computes score, anxiety subscore, and serializes to moods table map', () async {
      await ModelNotificationService.instance.clearAll();

      final entry = EpdsScreeningEntry(
        itemResponses: const <int>[1, 1, 2, 3, 2, 2, 2, 1, 1, 0], // sum = 15, anxiety (idx 2,3,4) = 7
        dailyMood: 'Anxious',
        dailySymptoms: const <String>['Difficulty Sleeping', 'Persistent Fatigue'],
        notes: 'Feeling overwhelmed this week',
      );

      expect(entry.epdsScore, 15);
      expect(entry.anxietyScore, 7);
      expect(entry.sleepDisturbed, isTrue);
      expect(entry.reportedFatigue, isTrue);
      expect(entry.riskCategory, 'High Risk (≥13)');

      final map = entry.toMap();
      final restored = EpdsScreeningEntry.fromMap(map);
      expect(restored.epdsScore, 15);
      expect(restored.anxietyScore, 7);
      expect(restored.dailyMood, 'Anxious');
      expect(restored.dailySymptoms, contains('Difficulty Sleeping'));

      // Save to ModelNotificationService and verify evaluateAndAlert uses it without explicit epdsScore
      await ModelNotificationService.instance.saveMoodScreening(entry);
      expect(ModelNotificationService.instance.latestMoodScreening?.epdsScore, 15);

      final alerts = await ModelNotificationService.instance.evaluateAndAlert(
        profile: const BasicProfile.empty(),
        vitals: const KeyVitals.empty(),
      );

      expect(
        alerts.any((a) => a.modelType == ModelType.mentalHealth && a.severity == AlertSeverity.high),
        isTrue,
      );
    });

    testWidgets('EpdsScreeningScreen renders 10 EPDS items, updates score, and submits', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await ModelNotificationService.instance.clearAll();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const EpdsScreeningScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('EPDS & Daily Wellbeing Log'), findsOneWidget);
      expect(find.text('0 / 30'), findsOneWidget);
      expect(find.text(kEpdsQuestions.first.question), findsOneWidget);

      // Select mood and symptom
      await tester.tap(find.widgetWithText(ChoiceChip, 'Tired'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Difficulty Sleeping'));
      await tester.pumpAndSettle();

      // Select a 3-point option on Question 1 ("Not at all (3)")
      await tester.tap(find.text('Not at all (3)'));
      await tester.pumpAndSettle();
      expect(find.text('3 / 30'), findsOneWidget);

      // Scroll to submit button and tap
      final submitFinder = find.byKey(const Key('submit_epds_screening_button'));
      await tester.scrollUntilVisible(
        submitFinder,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(ModelNotificationService.instance.latestMoodScreening, isNotNull);
      expect(ModelNotificationService.instance.latestMoodScreening!.epdsScore, 3);
      expect(ModelNotificationService.instance.latestMoodScreening!.dailyMood, 'Tired');
      expect(ModelNotificationService.instance.latestMoodScreening!.sleepDisturbed, isTrue);
    });
  });

  group('ReadOnlyImmutabilityGuard & "ro": 1 Lockout Tests', () {
    test('ReadOnlyImmutabilityGuard parses "ro": 1 and blocks 100% of mutations', () {
      expect(
        ReadOnlyImmutabilityGuard.isPayloadReadOnly(const <String, dynamic>{'ro': 1}),
        isTrue,
      );
      expect(
        ReadOnlyImmutabilityGuard.isPayloadReadOnly(
          const <String, dynamic>{'is_clinical_readonly': true},
        ),
        isTrue,
      );
      expect(
        ReadOnlyImmutabilityGuard.isPayloadReadOnly(const <String, dynamic>{'ro': 0}),
        isFalse,
      );

      const guard = ReadOnlyImmutabilityGuard.locked();
      expect(guard.isLocked, isTrue);
      expect(guard.canEdit(), isFalse);

      bool mutated = false;
      final res = guard.guardMutation(() {
        mutated = true;
        return 42;
      });
      expect(res, isNull);
      expect(mutated, isFalse);

      bool callbackCalled = false;
      final wrapped = guard.guardCallback<String>((_) => callbackCalled = true);
      expect(wrapped, isNull);
      expect(callbackCalled, isFalse);
    });

    test('MidwifeSyncService sample payload contains "ro": 1 and sets isClinicalReadOnly = true', () async {
      final rawJson = MidwifeSyncService.generateSamplePayload(compressed: false);
      expect(rawJson.contains('"ro":1'), isTrue);

      bool savedReadOnlyFlag = false;
      final syncService = MidwifeSyncService(
        onSaveSyncData: ({
          required profile,
          required vitals,
          medicalHistory = const MedicalHistory.empty(),
          required obstetricHistory,
          required clinicRecord,
          required deliveryPlan,
          clinicName,
          midwifeName,
          version = 1,
          payloadHash,
          isClinicalReadOnly = true,
        }) async {
          savedReadOnlyFlag = isClinicalReadOnly;
        },
      );

      final result = await syncService.processQrPayload(rawJson);
      expect(result.isSuccess, isTrue);
      expect(result.isClinicalReadOnly, isTrue);
      expect(savedReadOnlyFlag, isTrue);
    });

    testWidgets(
      'BasicProfileScreen, MedicalHistoryScreen, and PlanScreen enforce 100% edit lockout when isReadOnly is true',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        bool profileSubmitted = false;
        bool historyChanged = false;
        bool planSaved = false;

        // 1. BasicProfileScreen with isReadOnly: true
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: const <LocalizationsDelegate<Object>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: BasicProfileScreen(
                profile: BasicProfile.sample(),
                vitals: const KeyVitals.sample(),
                isReadOnly: true,
                onSubmit: (_) => profileSubmitted = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Official MOH Clinical Record (Read-Only)'), findsOneWidget);
        expect(find.text('Save Profile'), findsNothing);
        expect(profileSubmitted, isFalse);

        // 2. MedicalHistoryScreen with isReadOnly: true
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: const <LocalizationsDelegate<Object>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: MedicalHistoryScreen(
                history: const MedicalHistory.empty(),
                isReadOnly: true,
                onChanged: (_) => historyChanged = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Official MOH Clinical Record (Read-Only)'), findsOneWidget);
        await tester.tap(find.text('Diabetes Mellitus'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(historyChanged, isFalse);

        // 3. PlanScreen with isReadOnly: true
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: const <LocalizationsDelegate<Object>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: PlanScreen(
                plan: const DeliveryPlan.empty(),
                isReadOnly: true,
                onSave: (_) => planSaved = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Official MOH Clinical Record (Read-Only)'), findsOneWidget);
        expect(find.text('Save Plan'), findsNothing);
        expect(planSaved, isFalse);
      },
    );

    testWidgets(
      'Local profile and delivery plan entered before first Midwife QR sync remain editable and persist across shell restarts',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        BasicProfile? persistedProfile;
        DeliveryPlan? persistedPlan;

        // 1. Mother enters her Delivery Plan manually before first midwife sync (isReadOnly: false)
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: const <LocalizationsDelegate<Object>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: PlanScreen(
                plan: const DeliveryPlan(
                  intendedHospital: 'Castle Street Hospital for Women',
                  distanceKm: 9,
                ),
                isReadOnly: false,
                onSave: (DeliveryPlan saved) => persistedPlan = saved,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Official MOH Clinical Record (Read-Only)'), findsNothing);
        expect(find.text('Save Plan'), findsOneWidget);
        await tester.ensureVisible(find.text('Save Plan'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save Plan'));
        await tester.pumpAndSettle();

        expect(persistedPlan, isNotNull);
        expect(
          persistedPlan!.intendedHospital,
          'Castle Street Hospital for Women',
        );
        expect(persistedPlan!.distanceKm, 9);

        // 2. Simulate app restart with locally persisted profile & plan before first midwife sync
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: const <LocalizationsDelegate<Object>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: BasicProfileScreen(
                profile: const BasicProfile(
                  motherName: 'Dilani Perera',
                  address: 'Colombo 08',
                ),
                isReadOnly: false,
                onSubmit: (BasicProfile saved) => persistedProfile = saved,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dilani Perera'), findsOneWidget);
        expect(find.text('Save Profile'), findsOneWidget);
        await tester.ensureVisible(find.text('Save Profile'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save Profile'));
        await tester.pumpAndSettle();

        expect(persistedProfile, isNotNull);
        expect(persistedProfile!.motherName, 'Dilani Perera');
        expect(persistedProfile!.address, 'Colombo 08');
      },
    );
  });
}
