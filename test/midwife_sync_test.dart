import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maternal_vault/core/l10n/app_locales.dart';
import 'package:maternal_vault/core/theme/app_theme.dart';
import 'package:maternal_vault/core/utils/qr_payload_compressor.dart';
import 'package:maternal_vault/features/mother/data/services/midwife_sync_service.dart';
import 'package:maternal_vault/features/mother/domain/basic_profile.dart';
import 'package:maternal_vault/features/mother/domain/clinic_record.dart';
import 'package:maternal_vault/features/mother/domain/delivery_plan.dart';
import 'package:maternal_vault/features/mother/domain/family_planning_method.dart';
import 'package:maternal_vault/features/mother/domain/key_vitals.dart';
import 'package:maternal_vault/features/mother/domain/medical_history.dart';
import 'package:maternal_vault/features/mother/domain/obstetric_history.dart';
import 'package:maternal_vault/features/mother/domain/transport_mode.dart';
import 'package:maternal_vault/features/mother/presentation/screens/clinic_visits_screen.dart';
import 'package:maternal_vault/features/mother/presentation/screens/midwife_sync_scanner_screen.dart';
import 'package:maternal_vault/features/mother/presentation/screens/mother_shell_screen.dart';
import 'package:maternal_vault/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MidwifeSyncService & Domain Serialization Tests', () {
    test('generateSamplePayload produces valid JSON matching midwife dashboard schema', () {
      final String payloadStr = MidwifeSyncService.generateSamplePayload(compressed: false);
      expect(payloadStr, isNotEmpty);

      final dynamic decoded = jsonDecode(payloadStr);
      expect(decoded, isA<Map<String, dynamic>>());
      final map = decoded as Map<String, dynamic>;

      expect(map['app'], 'MaternaVault');
      expect(map['name'], 'Kumari Sandamali Perera');
      expect(map['id'], '#6720');
      expect(map['vitals'], isNotNull);
      expect(map['risk'], isNotNull);
      expect(map['by'], contains('Priya Sharma'));
    });

    test('QrPayloadCompressor compresses and decompresses payload with significant size reduction', () {
      final String rawJson = MidwifeSyncService.generateSamplePayload(compressed: false);
      final rawMap = jsonDecode(rawJson) as Map<String, dynamic>;

      final String compressedPayload = MidwifeSyncService.generateSamplePayload(compressed: true);

      // Verify compression is substantial
      expect(compressedPayload.startsWith('MVZ:'), isTrue);
      expect(compressedPayload.length, lessThan(rawJson.length));

      // Verify lossless decompression
      final decompressedMap = QrPayloadCompressor.decompress(compressedPayload);
      expect(decompressedMap['name'], rawMap['name']);
      expect(decompressedMap['age'], rawMap['age']);
      expect(decompressedMap['by'], rawMap['by']);
      expect(decompressedMap['edd'], rawMap['edd']);
    });

    test('MidwifeSyncService successfully parses and persists real midwife QR payload (Ananya Devi, #8842)', () async {
      bool saved = false;
      final service = MidwifeSyncService(
        onSaveSyncData: ({
          required BasicProfile profile,
          required KeyVitals vitals,
          MedicalHistory medicalHistory = const MedicalHistory.empty(),
          required ObstetricHistory obstetricHistory,
          required ClinicRecord clinicRecord,
          required DeliveryPlan deliveryPlan,
          String? clinicName,
          String? midwifeName,
          int version = 1,
          String? payloadHash,
        }) async {
          saved = true;
          expect(profile.motherName, 'Ananya Devi');
          expect(profile.registrationNumber, '#8842');
          expect(profile.nationalId, '91-4299-8812-4411');
          expect(profile.address, 'Rampur Sector 3');
          expect(profile.mother.age, 26);
          expect(vitals.bmi, '31.2');
          expect(obstetricHistory.gravidity, 2);
          expect(obstetricHistory.parity, 1);
          expect(obstetricHistory.expectedDelivery, DateTime(2024, 11, 18));
          expect(obstetricHistory.poaAtRegistrationWeeks, 31);
          expect(obstetricHistory.riskConditionsAndMorbidities,
              contains('HIGH RISK: Pre-eclampsia'));
          expect(obstetricHistory.riskConditionsAndMorbidities,
              contains('proteinuria'));
          expect(clinicRecord.visits.length, 1);
          final visit = clinicRecord.visits.first;
          expect(visit.week, 31);
          expect(visit.systolic, 148);
          expect(visit.diastolic, 94);
          expect(visit.fundalHeightCm, 31);
          expect(visit.fetalHeartRate, 142);
          expect(visit.urineAlbumin, UrineReading.plusTwo);
          expect(visit.status, VisitStatus.review);
          expect(visit.examinerSignature, 'Priya Sharma, PHM');
          expect(clinicRecord.investigations.haemoglobin, 'Hb: 10.1 g/dL');
          expect(deliveryPlan.poaAtDeliveryWeeks, 31);
          expect(deliveryPlan.complications, 'Pre-eclampsia');
          expect(clinicName, 'Rampur Sector 3');
          expect(midwifeName, 'Priya Sharma, PHM');
          expect(payloadHash, isNotEmpty);
        },
      );

      const realDashboardPayload = '''
{
  "app": "MaternaVault",
  "ver": "1.2.0",
  "id": "#8842",
  "name": "Ananya Devi",
  "age": 26,
  "gravida": 2,
  "para": 1,
  "abha": "91-4299-8812-4411",
  "village": "Rampur Sector 3",
  "ga": "31w 4d",
  "trim": 3,
  "edd": "18 Nov 2024",
  "fundal": "31 cm",
  "vitals": {
    "bp": "148/94",
    "hb": 10.1,
    "bmi": 31.2,
    "fhr": "142 bpm"
  },
  "risk": {
    "tier": "high",
    "title": "HIGH RISK",
    "prob": 68,
    "cond": "Pre-eclampsia"
  },
  "notes": "Reported episodic frontal headache in last 24h. Urine dipstick shows 2+ proteinuria.",
  "by": "Priya Sharma, PHM",
  "at": "2026-09-08T09:09:28.353Z"
}
''';

      final result = await service.processQrPayload(realDashboardPayload);
      expect(result.isSuccess, true);
      expect(result.motherName, 'Ananya Devi');
      expect(result.visitsCount, 1);
      expect(result.clinicName, 'Rampur Sector 3');
      expect(result.midwifeName, 'Priya Sharma, PHM');
      expect(saved, true);
    });

    test('MidwifeSyncService parses multiple clinical visits and past obstetric history', () async {
      bool saved = false;
      final service = MidwifeSyncService(
        onSaveSyncData: ({
          required BasicProfile profile,
          required KeyVitals vitals,
          MedicalHistory medicalHistory = const MedicalHistory.empty(),
          required ObstetricHistory obstetricHistory,
          required ClinicRecord clinicRecord,
          required DeliveryPlan deliveryPlan,
          String? clinicName,
          String? midwifeName,
          int version = 1,
          String? payloadHash,
        }) async {
          saved = true;
          expect(profile.motherName, 'Ananya Devi');
          expect(obstetricHistory.gravidity, 3);
          expect(obstetricHistory.parity, 2);
          expect(obstetricHistory.pregnancies.length, 2);
          expect(obstetricHistory.pregnancies[0].year, 2019);
          expect(obstetricHistory.pregnancies[0].deliveryMode, DeliveryMode.spontaneousVaginal);
          expect(obstetricHistory.pregnancies[0].birthWeightKg, 3.1);
          expect(obstetricHistory.pregnancies[0].sex, BabySex.male);
          expect(obstetricHistory.pregnancies[1].year, 2021);
          expect(obstetricHistory.pregnancies[1].deliveryMode, DeliveryMode.caesarean);
          expect(obstetricHistory.pregnancies[1].birthWeightKg, 2.9);
          expect(obstetricHistory.pregnancies[1].sex, BabySex.female);

          expect(clinicRecord.visits.length, 3);
          expect(clinicRecord.visits[0].week, 16);
          expect(clinicRecord.visits[0].bloodPressure, '110/70');
          expect(clinicRecord.visits[1].week, 24);
          expect(clinicRecord.visits[1].bloodPressure, '120/80');
          expect(clinicRecord.visits[2].week, 31);
          expect(clinicRecord.visits[2].bloodPressure, '148/94');
          expect(clinicRecord.fundalHeight.length, 3);
          expect(clinicRecord.weightGain.length, 3);
        },
      );

      const multiVisitPayload = '''
{
  "app": "MaternaVault",
  "id": "#8842",
  "name": "Ananya Devi",
  "age": 26,
  "gravida": 3,
  "para": 2,
  "livingChildren": 2,
  "village": "Rampur Sector 3",
  "ga": "31w",
  "edd": "18 Nov 2024",
  "pregnancies": [
    {
      "order": 1,
      "year": 2019,
      "term": "term",
      "mode": "vaginal",
      "outcome": "alive",
      "birthWeight": 3.1,
      "sex": "male",
      "age": 5,
      "hospital": "District Base Hospital"
    },
    {
      "order": 2,
      "year": 2021,
      "term": "term",
      "mode": "caesarean",
      "outcome": "alive",
      "birthWeight": 2.9,
      "sex": "female",
      "age": 3,
      "hospital": "Teaching Hospital"
    }
  ],
  "visits": [
    {
      "week": 16,
      "date": "2024-05-10",
      "bp": "110/70",
      "weight": 58.0,
      "fundal": 16,
      "fhr": 140,
      "status": "normal"
    },
    {
      "week": 24,
      "date": "2024-07-05",
      "bp": "120/80",
      "weight": 61.5,
      "fundal": 24,
      "fhr": 144,
      "status": "normal"
    },
    {
      "week": 31,
      "date": "2024-09-08",
      "bp": "148/94",
      "weight": 64.0,
      "fundal": 31,
      "fhr": 142,
      "status": "review",
      "albumin": "2+"
    }
  ]
}
''';

      final result = await service.processQrPayload(multiVisitPayload);
      expect(result.isSuccess, true);
      expect(result.visitsCount, 3);
      expect(saved, true);
    });

    test('MidwifeSyncService successfully parses real dashboard QR payload (Kumari Sandamali Perera, #6720, 7 visits, past pregnancy)', () async {
      bool saved = false;
      final service = MidwifeSyncService(
        onSaveSyncData: ({
          required BasicProfile profile,
          required KeyVitals vitals,
          MedicalHistory medicalHistory = const MedicalHistory.empty(),
          required ObstetricHistory obstetricHistory,
          required ClinicRecord clinicRecord,
          required DeliveryPlan deliveryPlan,
          String? clinicName,
          String? midwifeName,
          int version = 1,
          String? payloadHash,
        }) async {
          saved = true;
          expect(profile.motherName, 'Kumari Sandamali Perera');
          expect(profile.registrationNumber, '#6720');
          expect(profile.nationalId, '91-8706-6196-5349');
          expect(profile.address, 'Rampur North Sector 2');
          expect(profile.mother.age, 26);
          expect(vitals.bloodGroup, 'B +ve');
          expect(vitals.bmi, '27.4');
          expect(vitals.heightCm, '158');
          expect(vitals.allergies, 'None known');

          expect(obstetricHistory.gravidity, 2);
          expect(obstetricHistory.parity, 1);
          expect(obstetricHistory.livingChildren, 1);
          expect(obstetricHistory.expectedDelivery, DateTime(2025, 1, 17));
          expect(obstetricHistory.lastMenstrualPeriod, DateTime(2024, 4, 12));
          expect(obstetricHistory.poaAtRegistrationWeeks, 38);
          expect(obstetricHistory.pregnancies.length, 1);
          final preg = obstetricHistory.pregnancies.first;
          expect(preg.order, 1);
          expect(preg.year, 2024);
          expect(preg.deliveryMode, DeliveryMode.spontaneousVaginal);
          expect(preg.outcome, PregnancyOutcome.alive);
          expect(preg.birthWeightKg, 3.0);
          expect(preg.sex, BabySex.male);
          expect(preg.ageYears, 2);
          expect(preg.placeOfDelivery, 'District Base Hospital');

          expect(clinicRecord.visits.length, 7);
          expect(clinicRecord.visits[0].week, 8);
          expect(clinicRecord.visits[0].systolic, 118);
          expect(clinicRecord.visits[0].diastolic, 76);
          expect(clinicRecord.visits[0].weightKg, 58.0);
          expect(clinicRecord.visits[0].foodSupplement, false);

          expect(clinicRecord.visits[2].week, 24);
          expect(clinicRecord.visits[2].examinerSignature, 'Dr. Rajesh Varma, MO Antenatal');

          expect(clinicRecord.visits[4].week, 32);
          expect(clinicRecord.visits[4].fundalHeightCm, 32); // Sanitized from 232 typo

          expect(clinicRecord.visits[6].week, 38);
          expect(clinicRecord.visits[6].weightKg, 68.5);
          expect(clinicRecord.visits[6].fundalHeightCm, 38);

          expect(clinicRecord.fundalHeight.length, 6); // 8w >20cm skipped, 16, 24, 28, 32, 36, 38
          expect(clinicRecord.weightGain.length, 7);
          expect(clinicRecord.expectedFundalHeight.length, 9);
          expect(clinicRecord.investigations.haemoglobin, 'Hb: 11.8 g/dL');
          expect(clinicRecord.investigations.bloodSugar, 'Fasting: 84 mg/dL, 2h PP: 110 mg/dL');
          expect(clinicRecord.investigations.syphilis.result, 'Non-reactive');
          expect(clinicRecord.tetanus.dose1Date, isNull); // kumariPayload contains no tetanus data

          expect(deliveryPlan.intendedHospital, 'Base Hospital Rampur (Specialist Unit)');
          expect(deliveryPlan.distanceKm, 12);
          expect(deliveryPlan.transportMode, TransportMode.ownVehicle);
        },
      );

      const kumariPayload = '''{"app":"MaternaVault","ver":"1.2.0","id":"#6720","name":"Kumari Sandamali Perera","age":26,"gravida":2,"para":1,"livingChildren":1,"abha":"91-8706-6196-5349","village":"Rampur North Sector 2","ga":"38w 4d","trim":3,"edd":"2025-01-17","lmp":"2024-04-12","fundal":"38 cm","vitals":{"bp":"120/80","hb":11.8,"bmi":27.4,"fhr":"140 bpm","weight":68.5,"bloodGroup":"B +ve","height":"158","allergies":"None known"},"risk":{"tier":"low","title":"LOW RISK","prob":10,"cond":"Normal Progression"},"notes":"Term pregnancy. Good maternal and fetal wellbeing. Instructed to report directly to Base Hospital Rampur Labour Room on onset of true labour pains, show, or leaking membranes.","by":"Sister Priya Sharma (phm_lead)","at":"2026-09-15T05:59:58.782Z","pregnancies":[{"order":1,"year":2024,"term":"term","mode":"vaginal","outcome":"alive","birthWeight":3,"sex":"male","age":2,"hospital":"District Base Hospital","antenatalComplications":"None","postnatalComplications":"Normal recovery"}],"visits":[{"week":8,"date":"2024-06-09","bp":"118/76","weight":58,"fundal":38,"fhr":140,"status":"normal","albumin":"nil","sugar":"nil","foetalLie":"transverse","foetalPresentation":"cephalic","foetalMovements":true,"ironFolate":true,"vitaminC":true,"calcium":true,"foodSupplement":false,"by":"Sister Priya Sharma (phm_lead)"},{"week":16,"date":"2024-08-02","bp":"120/78","weight":59.5,"fundal":16,"fhr":148,"status":"normal","albumin":"nil","sugar":"nil","foetalLie":"longitudinal","foetalPresentation":"cephalic","foetalMovements":true,"ironFolate":true,"vitaminC":true,"calcium":true,"foodSupplement":true,"by":"Sister Priya Sharma (phm_lead)"},{"week":24,"date":"2024-09-27","bp":"122/80","weight":62,"fundal":24,"fhr":144,"status":"normal","albumin":"nil","sugar":"nil","foetalLie":"longitudinal","foetalPresentation":"cephalic","foetalMovements":true,"ironFolate":true,"vitaminC":true,"calcium":true,"foodSupplement":true,"by":"Dr. Rajesh Varma, MO Antenatal"},{"week":28,"date":"2024-10-25","bp":"120/78","weight":64,"fundal":28,"fhr":140,"status":"normal","albumin":"nil","sugar":"nil","foetalLie":"longitudinal","foetalPresentation":"cephalic","foetalMovements":true,"ironFolate":true,"vitaminC":true,"calcium":true,"foodSupplement":true,"by":"Sister Priya Sharma (phm_lead)"},{"week":32,"date":"2024-11-22","bp":"124/82","weight":66,"fundal":232,"fhr":142,"status":"normal","albumin":"nil","sugar":"nil","foetalLie":"longitudinal","foetalPresentation":"cephalic","foetalMovements":true,"ironFolate":true,"vitaminC":true,"calcium":true,"foodSupplement":true,"by":"Sister Priya Sharma (phm_lead)"},{"week":36,"date":"2024-12-20","bp":"122/80","weight":67.5,"fundal":36,"fhr":138,"status":"normal","albumin":"nil","sugar":"nil","foetalLie":"longitudinal","foetalPresentation":"cephalic","foetalMovements":true,"ironFolate":true,"vitaminC":true,"calcium":true,"foodSupplement":true,"by":"Sister Priya Sharma (phm_lead)"},{"week":38,"date":"2025-01-01","bp":"120/80","weight":68.5,"fundal":38,"fhr":140,"status":"normal","albumin":"nil","sugar":"nil","foetalLie":"longitudinal","foetalPresentation":"cephalic","foetalMovements":true,"ironFolate":true,"vitaminC":true,"calcium":true,"foodSupplement":true,"by":"Sister Priya Sharma (phm_lead)"}],"investigations":{"hb":"11.8","bloodSugar":"Fasting: 84 mg/dL, 2h PP: 110 mg/dL","vdrl":"Non-reactive"},"deliveryPlan":{"intendedHospital":"Base Hospital Rampur (Specialist Unit)","distanceKm":12,"transportMode":"ownVehicle"}}''';

      final result = await service.processQrPayload(kumariPayload);
      expect(result.isSuccess, true);
      expect(result.motherName, 'Kumari Sandamali Perera');
      expect(result.visitsCount, 7);
      expect(saved, true);
    });

    test('MidwifeSyncService also parses nested legacy payload format', () async {
      bool saved = false;
      final service = MidwifeSyncService(
        onSaveSyncData: ({
          required BasicProfile profile,
          required KeyVitals vitals,
          MedicalHistory medicalHistory = const MedicalHistory.empty(),
          required ObstetricHistory obstetricHistory,
          required ClinicRecord clinicRecord,
          required DeliveryPlan deliveryPlan,
          String? clinicName,
          String? midwifeName,
          int version = 1,
          String? payloadHash,
        }) async {
          saved = true;
          expect(profile.motherName, 'Nimali Perera');
        },
      );

      final legacyPayload = jsonEncode(<String, dynamic>{
        'type': 'maternal_vault_sync',
        'version': 1,
        'mother': BasicProfile.sample().toJson(),
        'clinicRecord': ClinicRecord.sample().toJson(),
        'clinic': 'Dehiwala MOH',
        'midwife': 'Sister Silva',
      });

      final result = await service.processQrPayload(legacyPayload);
      expect(result.isSuccess, true);
      expect(result.motherName, 'Nimali Perera');
      expect(saved, true);
    });

    test('ClinicRecord roundtrips through toJson and fromJson', () {
      final original = ClinicRecord.sample();
      final json = original.toJson();
      final restored = ClinicRecord.fromJson(json);

      expect(restored.visits.length, original.visits.length);
      expect(restored.visits.first.week, original.visits.first.week);
      expect(restored.visits.first.systolic, original.visits.first.systolic);
      expect(restored.visits.first.diastolic, original.visits.first.diastolic);
      expect(restored.visits.first.status, original.visits.first.status);
      expect(restored.weightGain.length, original.weightGain.length);
      expect(restored.fundalHeight.length, original.fundalHeight.length);
      expect(restored.systemExams.breastExam,
          original.systemExams.breastExam);
      expect(restored.investigations.bloodSugar,
          original.investigations.bloodSugar);
      expect(restored.tetanus.dose1Date, original.tetanus.dose1Date);
      expect(restored.dental.treatmentStatus,
          original.dental.treatmentStatus);
      expect(restored.referrals.notes, original.referrals.notes);
    });

    test('DeliveryPlan roundtrips through toJson and fromJson', () {
      final original = DeliveryPlan.sample();
      final json = original.toJson();
      final restored = DeliveryPlan.fromJson(json);

      expect(restored.intendedHospital, original.intendedHospital);
      expect(restored.transportMode, TransportMode.ownVehicle);
      expect(restored.distanceKm, 8);
      expect(restored.deliveryMode, DeliveryMode.spontaneousVaginal);
      expect(restored.familyPlanningMethod, FamilyPlanningMethod.iud);
      expect(restored.dischargeChecklist.tempNormal48h, true);
      expect(restored.dischargeChecklist.vitAGiven, true);
      expect(restored.postpartumCare.postpartumClinicSchedule,
          original.postpartumCare.postpartumClinicSchedule);
      expect(restored.antenatalEducation.bookBreastfeeding, true);
    });

    test('BasicProfile and KeyVitals roundtrip through toJson and fromJson', () {
      final profile = BasicProfile.sample();
      final pJson = profile.toJson();
      final restoredP = BasicProfile.fromJson(pJson);
      expect(restoredP.motherName, profile.motherName);
      expect(restoredP.mother.age, profile.mother.age);

      const vitals = KeyVitals(
        bloodGroup: 'O+',
        bmi: '22.0',
        heightCm: '160',
        allergies: 'Penicillin',
      );
      final vJson = vitals.toJson();
      final restoredV = KeyVitals.fromJson(vJson);
      expect(restoredV.bloodGroup, 'O+');
      expect(restoredV.bmi, '22.0');
      expect(restoredV.allergies, 'Penicillin');
    });

    test('ObstetricHistory roundtrips through toJson and fromJson', () {
      final original = ObstetricHistory.sample();
      final json = original.toJson();
      final restored = ObstetricHistory.fromJson(json);

      expect(restored.gravidity, original.gravidity);
      expect(restored.parity, original.parity);
      expect(restored.riskConditionsAndMorbidities,
          original.riskConditionsAndMorbidities);
      expect(restored.screening.contains(ObstetricScreening.rubellaImmunization),
          true);
    });

    test('MedicalHistory roundtrips through toJson and fromJson', () {
      const original = MedicalHistory(
        family: <FamilyCondition>{
          FamilyCondition.diabetesMellitus,
          FamilyCondition.hypertension,
        },
        personal: <PersonalCondition>{
          PersonalCondition.bronchialAsthma,
          PersonalCondition.surgeries,
        },
        familyOtherDetails: 'Maternal grandfather had heart disease',
        personalOtherDetails: 'Allergic to sulfonamides',
      );
      final json = original.toJson();
      final restored = MedicalHistory.fromJson(json);

      expect(restored.family.contains(FamilyCondition.diabetesMellitus), true);
      expect(restored.family.contains(FamilyCondition.hypertension), true);
      expect(restored.personal.contains(PersonalCondition.bronchialAsthma), true);
      expect(restored.personal.contains(PersonalCondition.surgeries), true);
      expect(restored.familyOtherDetails, original.familyOtherDetails);
      expect(restored.personalOtherDetails, original.personalOtherDetails);
    });

    test('MidwifeSyncService correctly parses compact _mv:1 payload format', () async {
      bool saved = false;
      final service = MidwifeSyncService(
        onSaveSyncData: ({
          required BasicProfile profile,
          required KeyVitals vitals,
          MedicalHistory medicalHistory = const MedicalHistory.empty(),
          required ObstetricHistory obstetricHistory,
          required ClinicRecord clinicRecord,
          required DeliveryPlan deliveryPlan,
          String? clinicName,
          String? midwifeName,
          int version = 1,
          String? payloadHash,
        }) async {
          saved = true;
          // --- Profile ---
          expect(profile.motherName, 'Kumari Sandamali Perera');
          expect(profile.registrationNumber, '#6720');
          expect(profile.mother.age, 26);

          // --- Vitals ---
          expect(vitals.bloodGroup, 'B +ve');

          // --- Obstetric History ---
          expect(obstetricHistory.gravidity, 2);
          expect(obstetricHistory.parity, 1);
          expect(obstetricHistory.livingChildren, 1);
          expect(obstetricHistory.expectedDelivery, DateTime(2025, 1, 17));
          expect(obstetricHistory.lastMenstrualPeriod, DateTime(2024, 4, 12));
          expect(obstetricHistory.poaAtRegistrationWeeks, 38);

          // --- Clinic Visits ---
          expect(clinicRecord.visits.length, 7);
          expect(clinicRecord.visits[0].week, 8);
          expect(clinicRecord.visits[0].weightKg, 58);
          expect(clinicRecord.visits[1].week, 16);
          expect(clinicRecord.visits[1].fetalHeartRate, 148);
          expect(clinicRecord.visits[2].week, 24);
          expect(clinicRecord.visits[3].week, 28);
          expect(clinicRecord.visits[4].week, 32);
          expect(clinicRecord.visits[4].fundalHeightCm, 32); // Sanitized from 232
          expect(clinicRecord.visits[5].week, 36);
          expect(clinicRecord.visits[6].week, 38);
          expect(clinicRecord.visits[6].weightKg, 68.5);
          expect(clinicRecord.visits[6].fundalHeightCm, 38);

          // --- Growth Charts ---
          expect(clinicRecord.fundalHeight.length, 6); // 8w fundal excluded (early), rest kept
          expect(clinicRecord.weightGain.length, 7);

          // --- Lab Investigations ---
          expect(clinicRecord.investigations.haemoglobin, 'Hb: 11.8 g/dL');
          expect(clinicRecord.investigations.syphilis.result, 'Non-reactive');
          expect(clinicRecord.investigations.bloodSugar, contains('Fasting'));

          // --- TT Immunization from visit notes ---
          expect(clinicRecord.tetanus.dose1Date, DateTime(2024, 8, 2)); // Visit 2: TT1
          expect(clinicRecord.tetanus.dose2Date, DateTime(2024, 9, 27)); // Visit 3: TT2

          // --- Delivery Plan (from last visit notes) ---
          expect(deliveryPlan.intendedHospital, contains('Base Hospital Rampur'));
        },
      );

      const compactPayload = '{"_mv":1,"id":"#6720","n":"Kumari Sandamali Perera","a":26,"g":2,"p":1,"lc":1,"ga":"38w 4d","w":38,"edd":"2025-01-17","lmp":"2024-04-12","bp":"120/80","hb":11.8,"fhr":"140 bpm","wt":68.5,"bg":"B +ve","rt":"low","rc":"Normal Progression","rp":10,"pt":"Sunil Shantha","mh":{"diabetes":false,"chronicHtn":false,"cardiac":false,"asthma":false,"thyroid":false,"epilepsy":false,"thalassaemia":false,"prevLscs":false,"prevPreterm":false,"prevPph":false,"allergies":"None known","surgeries":"None reported"},"lr":{"bg":"B +ve","vd":"Non-reactive","rb":"Immune","hv":"Non-reactive","hb":"Negative","fs":"82 mg/dL","ua":"Nil","us":"Nil"},"pr":[],"vs":[[1,"2024-06-09","8w 2d","118/76",58,"Palpable cm",140,"N/A (Early Trim)","Nil","Nil","Transcribed historical paper record (H 512 B) documented on 09 Jun 2024. Blood group B +ve confirmed."],[2,"2024-08-02","16w 0d","120/78",59.5,"16 cm",148,"Cephalic (Vertex)","Nil","Nil","Anomaly scan scheduled. TT1 (Tetanus Toxoid 1st dose) administered. IFA and Calcium Lactate initiated."],[3,"2024-09-27","24w 0d","122/80",62,"24 cm",144,"Cephalic (Vertex)","Nil","Nil","OGTT 75g normal (Fasting 84 mg/dL, 2hr 112 mg/dL). TT2 dose administered. Symphysis fundal height corresponds with dates."],[4,"2024-10-25","28w 0d","120/78",64,"28 cm",140,"Cephalic (Vertex)","Nil","Nil","Repeat 28-week Hemoglobin Hb is 11.4 g/dL (Adequate). Fetal growth steady. Advised on kick-count chart monitoring."],[5,"2024-11-22","32w 0d","124/82",66,"232 cm",142,"Cephalic (Vertex)","Nil","Nil","Position confirmed Cephalic. Normal blood pressure. Re-emphasized labor signs and 1990 ambulance contact."],[6,"2024-12-20","36w 0d","122/80",67.5,"36 cm",138,"Cephalic (Vertex)","Nil","Nil","Repeat 36-week Hb: 11.6 g/dL. Head dipping into pelvic brim. Institutional delivery pack and transport confirmed for Base Hospital Rampur."],[7,"2025-01-01","38w 4d","120/80",68.5,"38 cm",140,"Cephalic (Vertex)","Nil","Nil","Term pregnancy. Good maternal and fetal wellbeing. Instructed to report directly to Base Hospital Rampur Labour Room on onset of true labour pains, show, or leaking membranes."]]}';

      final result = await service.processQrPayload(compactPayload);
      expect(result.isSuccess, true);
      expect(result.motherName, 'Kumari Sandamali Perera');
      expect(result.visitsCount, 7);
      expect(saved, true);
    });

    test('MidwifeSyncService validates bad payloads cleanly without crashing', () async {
      const service = MidwifeSyncService();

      final emptyResult = await service.processQrPayload('');
      expect(emptyResult.isSuccess, false);
      expect(emptyResult.message, contains('empty'));

      final invalidJsonResult =
          await service.processQrPayload('This is not json or base64');
      expect(invalidJsonResult.isSuccess, false);

      final wrongTypeResult = await service.processQrPayload(
        jsonEncode(<String, dynamic>{
          'type': 'unsupported_qr_type',
        }),
      );
      expect(wrongTypeResult.isSuccess, false);
      expect(wrongTypeResult.message, contains('missing clinical mother records'));
    });
  });

  group('UI Integration Tests', () {
    testWidgets('PregnancyRecordAppBar displays QR scan action icon', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(412 * 3, 915 * 3);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLanguage.locales,
          theme: AppTheme.light,
          home: MotherShellScreen(
            onLanguageChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scan action in header
      final Finder scanIcon = find.byIcon(Icons.qr_code_scanner_rounded);
      expect(scanIcon, findsAtLeast(1));
    });

    testWidgets('ClinicVisitsScreen displays Sync with Midwife Dashboard card', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(412 * 3, 915 * 3);
      addTearDown(tester.view.reset);

      bool scanned = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLanguage.locales,
          theme: AppTheme.light,
          home: Scaffold(
            body: ClinicVisitsScreen(
              record: ClinicRecord.sample(),
              onScanQr: () => scanned = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sync with Midwife Dashboard'), findsOneWidget);
      expect(
        find.text(
          "Scan your midwife's computer screen to download and encrypt today's visit readings.",
        ),
        findsOneWidget,
      );

      // Tap the forward arrow button on the sync card
      final Finder arrowBtn = find.byIcon(Icons.arrow_forward_ios_rounded);
      expect(arrowBtn, findsOneWidget);
      await tester.tap(arrowBtn);
      await tester.pumpAndSettle();

      expect(scanned, true);
    });

    testWidgets('MidwifeSyncScannerScreen displays View QR Code and opens preview dialog', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(412 * 3, 915 * 3);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLanguage.locales,
          theme: AppTheme.light,
          home: const MidwifeSyncScannerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find the QR Code button in app bar or bottom
      final Finder qrBtn = find.byIcon(Icons.qr_code_2_rounded);
      expect(qrBtn, findsAtLeast(1));

      // Tap to open the QR Code modal
      await tester.tap(qrBtn.first);
      await tester.pumpAndSettle();

      expect(find.text('Midwife Clinic QR Code'), findsOneWidget);
      expect(find.textContaining('Kumari Sandamali Perera'), findsOneWidget);
      expect(find.text('Sync This Record Directly'), findsOneWidget);
    });
  });
}
