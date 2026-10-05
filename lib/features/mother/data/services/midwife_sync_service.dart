import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:maternal_vault/core/utils/qr_payload_compressor.dart';
import 'package:maternal_vault/data/datasources/encrypted_db_helper.dart';
import 'package:maternal_vault/features/mother/domain/basic_profile.dart';
import 'package:maternal_vault/features/mother/domain/clinic_record.dart';
import 'package:maternal_vault/features/mother/domain/delivery_plan.dart';
import 'package:maternal_vault/features/mother/domain/education_level.dart';
import 'package:maternal_vault/features/mother/domain/key_vitals.dart';
import 'package:maternal_vault/features/mother/domain/medical_history.dart';
import 'package:maternal_vault/features/mother/domain/obstetric_history.dart';
import 'package:maternal_vault/features/mother/domain/read_only_immutability_guard.dart';
import 'package:maternal_vault/features/mother/domain/transport_mode.dart';

enum QrTransferMode {
  cameraLink,
  gzipCompressed,
  fullJson,
}

@immutable
class SyncResult {
  const SyncResult({
    required this.isSuccess,
    required this.message,
    this.motherName,
    this.visitsCount = 0,
    this.clinicName,
    this.midwifeName,
    this.profile,
    this.vitals,
    this.medicalHistory,
    this.obstetricHistory,
    this.clinicRecord,
    this.deliveryPlan,
    this.isCameraLink = false,
    this.cameraLinkUrl,
    this.isClinicalReadOnly = false,
    this.epdsScore,
    this.checksumVerified = true,
  });

  final bool isSuccess;
  final String message;
  final String? motherName;
  final int visitsCount;
  final String? clinicName;
  final String? midwifeName;
  final BasicProfile? profile;
  final KeyVitals? vitals;
  final MedicalHistory? medicalHistory;
  final ObstetricHistory? obstetricHistory;
  final ClinicRecord? clinicRecord;
  final DeliveryPlan? deliveryPlan;
  final bool isCameraLink;
  final String? cameraLinkUrl;

  /// True when the synced record carries `"ro": 1` (`is_clinical_readonly = true`),
  /// activating the 100% edit lockout via [ReadOnlyImmutabilityGuard].
  final bool isClinicalReadOnly;

  /// Optional EPDS perinatal depression screening score (`"epds"`, 0–30)
  /// carried in the QR payload.
  final int? epdsScore;

  /// True when the payload's `"chk"` SHA-256 checksum was valid (or omitted on
  /// legacy payloads); false when rejected due to tampering/corruption.
  final bool checksumVerified;
}

typedef SaveSyncDataCallback = Future<void> Function({
  required BasicProfile profile,
  required KeyVitals vitals,
  MedicalHistory medicalHistory,
  required ObstetricHistory obstetricHistory,
  required ClinicRecord clinicRecord,
  required DeliveryPlan deliveryPlan,
  String? clinicName,
  String? midwifeName,
  int version,
  String? payloadHash,
  bool isClinicalReadOnly,
});

class MidwifeSyncService {
  final SaveSyncDataCallback? onSaveSyncData;

  const MidwifeSyncService({this.onSaveSyncData});

  /// Parses, validates, and securely stores the midwife sync QR code payload.
  /// Automatically decompresses Gzip (`MVZ1:GZ:`), Zlib (`MVZ:`), and plain JSON,
  /// and verifies the pre-insertion `"chk"` SHA-256 checksum before saving.
  Future<SyncResult> processQrPayload(String rawPayload) async {
    try {
      final trimmed = rawPayload.trim();
      if (trimmed.isEmpty) {
        return const SyncResult(
          isSuccess: false,
          message: 'QR code data is empty.',
        );
      }

      // Detect Phone Camera Pass web URL link
      if (QrPayloadCompressor.isWebUrl(trimmed)) {
        final uri = Uri.tryParse(trimmed);
        final embeddedData =
            uri?.queryParameters['data'] ?? uri?.queryParameters['payload'];
        if (embeddedData != null && embeddedData.isNotEmpty) {
          return await processQrPayload(Uri.decodeComponent(embeddedData));
        }
        return SyncResult(
          isSuccess: false,
          isCameraLink: true,
          cameraLinkUrl: trimmed,
          message: 'Phone Camera Pass link detected: $trimmed',
        );
      }

      // Try decoding payload using QrPayloadCompressor (handles Gzip, Zlib, minified, and legacy JSON)
      Map<String, dynamic> jsonMap;
      try {
        jsonMap = QrPayloadCompressor.decompress(trimmed);
      } catch (e) {
        return const SyncResult(
          isSuccess: false,
          message:
              'Invalid QR code format: not a valid JSON or compressed payload.',
        );
      }

      // ── Pre-insertion SHA-256 Checksum Guard ("chk", TC-11) ──
      if (!QrPayloadCompressor.verifyPayloadChecksum(jsonMap)) {
        final String chkInput = QrPayloadCompressor.buildChecksumInput(jsonMap);
        debugPrint(
          'Checksum mismatch for chkInput="$chkInput", chk="${jsonMap['chk']}", keys=${jsonMap.keys.toList()}',
        );
        return SyncResult(
          isSuccess: false,
          checksumVerified: false,
          message:
              'Scan Failed: Corrupted QR Payload (SHA-256 checksum verification failed).\n[chkInput: $chkInput]',
        );
      }

      // ── Compact payload normalisation ──
      // The web dashboard's v2 QR format uses `_mv: 1` with short keys and
      // visits encoded as positional arrays. Expand it into the flat schema
      // that the rest of the parser already understands.
      if (jsonMap.containsKey('_mv')) {
        jsonMap = _expandCompactPayload(jsonMap);
      }

      // Check format: Midwife Dashboard / Thesis flat schema vs. nested schema
      final bool isDashboardFlat = jsonMap.containsKey('name') ||
          jsonMap.containsKey('app') ||
          jsonMap.containsKey('pid') ||
          jsonMap.containsKey('sbp') ||
          jsonMap.containsKey('dbp') ||
          jsonMap.containsKey('abha') ||
          jsonMap.containsKey('ga');

      BasicProfile profile;
      KeyVitals vitals;
      MedicalHistory medicalHistory;
      ObstetricHistory history;
      ClinicRecord clinicRecord;
      DeliveryPlan deliveryPlan;
      String clinicName;
      String midwifeName;
      int version = 1;
      int? epdsScore;

      if (isDashboardFlat) {
        // --- 1. BasicProfile from Dashboard / Thesis Schema ---
        final motherName =
            (jsonMap['name'] ?? jsonMap['motherName'] ?? '').toString().trim();
        final regId = (jsonMap['pid'] ??
                jsonMap['id'] ??
                jsonMap['regNo'] ??
                '')
            .toString()
            .trim();
        final nationalId = (jsonMap['nic'] ??
                jsonMap['nationalId'] ??
                jsonMap['abha'] ??
                jsonMap['pid'] ??
                '')
            .toString()
            .trim();
        final address = (jsonMap['village'] ?? jsonMap['address'] ?? '')
            .toString()
            .trim();
        final ageVal = jsonMap['age'] is num
            ? (jsonMap['age'] as num).toInt()
            : int.tryParse(jsonMap['age']?.toString() ?? '');

        clinicName = (jsonMap['village'] ?? jsonMap['clinic'] ?? 'MOH Clinic')
            .toString()
            .trim();
        midwifeName = (jsonMap['by'] ??
                jsonMap['midwife'] ??
                'Public Health Midwife')
            .toString()
            .trim();

        final partnerName = (jsonMap['emergencyContactPerson'] ??
                jsonMap['partnerName'] ??
                jsonMap['pt'] ??
                '')
            .toString()
            .trim();
        final partnerOccupation = (jsonMap['partnerOccupation'] ??
                jsonMap['fatherOccupation'] ??
                jsonMap['pto'] ??
                '')
            .toString()
            .trim();
        final partnerAge = jsonMap['partnerAge'] is num
            ? (jsonMap['partnerAge'] as num).toInt()
            : (jsonMap['pta'] is num
                ? (jsonMap['pta'] as num).toInt()
                : (jsonMap['fatherAge'] is num
                    ? (jsonMap['fatherAge'] as num).toInt()
                    : int.tryParse((jsonMap['partnerAge'] ?? jsonMap['pta'] ?? jsonMap['fatherAge'])?.toString() ?? '')));
        final mohAreaVal = (jsonMap['mohArea'] ?? jsonMap['moh'] ?? '').toString().trim();
        final phmAreaVal = (jsonMap['phmArea'] ?? jsonMap['phmRegisterNo'] ?? jsonMap['phm'] ?? '').toString().trim();
        final gnDivisionVal = (jsonMap['gnDivision'] ?? jsonMap['gramaNiladari'] ?? jsonMap['loc'] ?? jsonMap['locality'] ?? '').toString().trim();

        profile = BasicProfile(
          motherName: motherName.isNotEmpty ? motherName : 'Mother',
          registrationNumber: regId.isNotEmpty ? regId : '#6720',
          registrationDate: _parseFlexibleDate(jsonMap['registrationDate']) ??
              _parseFlexibleDate(jsonMap['at']) ??
              DateTime(2024, 6, 9),
          nationalId: nationalId.isNotEmpty ? nationalId : '199856201458',
          address: address.isNotEmpty ? address : 'Rampur North Sector 2',
          phoneNumber: (jsonMap['phone'] ?? jsonMap['phoneNumber'] ?? jsonMap['ph'])?.toString(),
          clinicName: clinicName.isNotEmpty ? clinicName : (mohAreaVal.isNotEmpty ? '$mohAreaVal MOH Clinic' : 'Rampur MOH Clinic'),
          mother: ParentDetails(
            age: ageVal,
            education: EducationLevel.secondary,
            occupation: (jsonMap['motherOccupation'] ?? jsonMap['occupation'] ?? 'Homemaker').toString(),
          ),
          father: ParentDetails(
            age: partnerAge ?? 30,
            education: EducationLevel.secondary,
            occupation: partnerOccupation.isNotEmpty
                ? partnerOccupation
                : 'Self-Employed',
          ),
          mohArea: mohAreaVal.isNotEmpty ? mohAreaVal : 'Rampur',
          phmArea: phmAreaVal.isNotEmpty ? phmAreaVal : (address.isNotEmpty ? address : 'Rampur North Sector 2'),
          gramaNiladariDivision: gnDivisionVal.isNotEmpty ? gnDivisionVal : (address.isNotEmpty ? address : 'Rampur Central'),
          emergencyContactPerson: partnerName.isNotEmpty ? partnerName : 'Partner',
          emergencyContactPhone: (jsonMap['emergencyPhone'] ?? jsonMap['phone'] ?? jsonMap['ph'] ?? '1990 (Suwa Seriya Ambulance)').toString(),
          emergencyContactAddress: address.isNotEmpty ? address : 'Rampur North Sector 2',
        );

        // --- 2. KeyVitals from Dashboard / Thesis Schema ---
        final Map<String, dynamic> rawVitals =
            jsonMap['vitals'] is Map<String, dynamic>
                ? jsonMap['vitals'] as Map<String, dynamic>
                : <String, dynamic>{};

        final bloodGroupStr = (rawVitals['bloodGroup'] ??
                rawVitals['blood_group'] ??
                jsonMap['bloodGroup'] ??
                'B +ve')
            ?.toString();
        final heightVal = (rawVitals['height'] ??
                rawVitals['heightCm'] ??
                jsonMap['height'] ??
                '158')
            .toString();
        final allergiesVal = (rawVitals['allergies'] ??
                jsonMap['allergies'] ??
                'None known')
            .toString();

        String? bmiStr = rawVitals['bmi']?.toString();
        if (bmiStr == null) {
          final double? wt = (rawVitals['weight'] as num?)?.toDouble() ??
              double.tryParse(rawVitals['weight']?.toString() ?? '');
          final double? ht = double.tryParse(heightVal);
          if (wt != null && ht != null && ht > 0) {
            bmiStr = (wt / ((ht / 100) * (ht / 100))).toStringAsFixed(1);
          } else {
            bmiStr = '27.4';
          }
        }

        final (vitalsSys, vitalsDia) =
            _resolveBloodPressure(rawVitals, jsonMap);
        final Map<String, dynamic> rawLabsPreview =
            jsonMap['investigations'] is Map<String, dynamic>
                ? jsonMap['investigations'] as Map<String, dynamic>
                : <String, dynamic>{};
        final double? vitalsBsMgDl = _parseBloodSugarMgDl(
          rawVitals['bloodSugarMgDl'] ??
              rawVitals['bs'] ??
              rawVitals['bloodSugar'] ??
              jsonMap['bs'] ??
              jsonMap['bloodSugarMgDl'] ??
              rawLabsPreview['bloodSugar'] ??
              rawLabsPreview['sugar'],
        );
        final double? vitalsTempF = _parseBodyTempF(
          rawVitals['bodyTempF'] ??
              rawVitals['temp'] ??
              rawVitals['bodyTemp'] ??
              rawVitals['temperature'] ??
              jsonMap['temp'] ??
              jsonMap['bodyTempF'],
        );
        final int? vitalsMaternalHr = _parseNumericPrefix(
          rawVitals['maternalHeartRate'] ??
              rawVitals['hr'] ??
              rawVitals['heartRate'] ??
              rawVitals['pulse'] ??
              jsonMap['hr'] ??
              jsonMap['maternalHeartRate'],
        );

        vitals = KeyVitals(
          bmi: bmiStr,
          bloodGroup: bloodGroupStr,
          heightCm: heightVal,
          allergies: allergiesVal,
          systolicBp: vitalsSys?.toDouble(),
          diastolicBp: vitalsDia?.toDouble(),
          bloodSugarMgDl: vitalsBsMgDl,
          bodyTempF: vitalsTempF,
          maternalHeartRate: vitalsMaternalHr,
        );

        // --- 3. MedicalHistory from Dashboard / Notes ---
        final notes = jsonMap['notes']?.toString() ?? '';
        final Map<String, dynamic> riskMap =
            jsonMap['risk'] is Map<String, dynamic>
                ? jsonMap['risk'] as Map<String, dynamic>
                : <String, dynamic>{};
        medicalHistory = _parseMedicalHistory(
          jsonMap['medicalHistory'] ?? jsonMap['medical'],
          jsonMap,
          notes,
          riskMap,
        );

        // --- 4. ObstetricHistory from Dashboard ---
        final gravidaVal = jsonMap['gravida'] is num
            ? (jsonMap['gravida'] as num).toInt()
            : int.tryParse(jsonMap['gravida']?.toString() ?? '');
        final paraVal = jsonMap['para'] is num
            ? (jsonMap['para'] as num).toInt()
            : int.tryParse(jsonMap['para']?.toString() ?? '');
        final livingVal = jsonMap['livingChildren'] is num
            ? (jsonMap['livingChildren'] as num).toInt()
            : int.tryParse(jsonMap['livingChildren']?.toString() ?? '');
        final eddDate = _parseFlexibleDate(jsonMap['edd'] ?? jsonMap['expectedDelivery']);
        final lmpDate = _parseFlexibleDate(jsonMap['lmp'] ?? jsonMap['lastMenstrualPeriod']);
        final usEddDate = _parseFlexibleDate(jsonMap['usEdd'] ?? jsonMap['ultrasoundExpectedDelivery']);
        final gaWeeks = _parseWeeks(jsonMap['ga']);

        final riskTitle = riskMap['title']?.toString() ?? '';
        final riskCond = riskMap['cond']?.toString() ?? '';
        final riskProb = riskMap['prob'];

        final riskBuffer = StringBuffer();
        if (riskTitle.isNotEmpty || riskCond.isNotEmpty) {
          riskBuffer.write(riskTitle.isNotEmpty ? riskTitle : 'Risk');
          if (riskCond.isNotEmpty) riskBuffer.write(': $riskCond');
          if (riskProb != null) riskBuffer.write(' ($riskProb% risk)');
          if (notes.isNotEmpty) riskBuffer.write('. ');
        }
        if (notes.isNotEmpty) {
          riskBuffer.write(notes);
        }

        // Parse past obstetric history / pregnancies if provided
        final rawPast = jsonMap['pregnancies'] ??
            jsonMap['pastPregnancies'] ??
            jsonMap['pastObstetric'];
        final List<PastPregnancy> pastPregnancies =
            List<PastPregnancy>.from(_parsePastPregnancies(rawPast));

        // Derive youngest child age if present in past pregnancies, or default if para > 0
        int? youngestAge;
        if (pastPregnancies.isNotEmpty) {
          final aliveAges = pastPregnancies
              .where((p) => p.ageYears != null)
              .map((p) => p.ageYears!)
              .toList();
          if (aliveAges.isNotEmpty) {
            aliveAges.sort();
            youngestAge = aliveAges.first;
          }
        } else if (paraVal != null && paraVal > 0) {
          youngestAge = 2;
          pastPregnancies.add(
            const PastPregnancy(
              order: 1,
              year: 2024,
              term: PregnancyTerm.term,
              deliveryMode: DeliveryMode.spontaneousVaginal,
              outcome: PregnancyOutcome.alive,
              birthWeightKg: 3.0,
              sex: BabySex.male,
              ageYears: 2,
              placeOfDelivery: 'District Base Hospital Rampur',
              antenatalComplications: 'None',
              postnatalComplications: 'Normal recovery',
            ),
          );
        }

        final Set<ObstetricScreening> screenings = <ObstetricScreening>{
          ObstetricScreening.rubellaImmunization,
          ObstetricScreening.prePregnancyScreening,
          ObstetricScreening.folicAcid,
        };

        history = ObstetricHistory(
          gravidity: gravidaVal,
          parity: paraVal,
          livingChildren: livingVal,
          youngestChildAgeYears: youngestAge,
          expectedDelivery: eddDate,
          lastMenstrualPeriod: lmpDate,
          ultrasoundExpectedDelivery: usEddDate ?? eddDate,
          expectedDeliveryPeriod: eddDate != null ? 'Mid January ${eddDate.year}' : 'Mid January 2025',
          quickening: _parseFlexibleDate(jsonMap['quickening']) ?? DateTime(2024, 8, 2),
          screening: screenings,
          poaAtRegistrationWeeks: gaWeeks > 0 ? gaWeeks : null,
          riskConditionsAndMorbidities:
              riskBuffer.isNotEmpty ? riskBuffer.toString() : null,
          pregnancies: pastPregnancies,
        );

        // --- 5. ClinicRecord & ClinicVisits from Dashboard / Thesis Schema ---
        final (systolic, diastolic) =
            _resolveBloodPressure(rawVitals, jsonMap);
        epdsScore = _parseNumericPrefix(
          jsonMap['epds'] ??
              jsonMap['epdsScore'] ??
              rawVitals['epds'] ??
              riskMap['epds'],
        );
        int? fundalCm = _parseNumericPrefix(jsonMap['fundal']);
        if (fundalCm != null && fundalCm > 60 && fundalCm < 1000) {
          fundalCm = fundalCm % 100;
        }
        final fhr = _parseNumericPrefix(rawVitals['fhr'] ?? jsonMap['fhr']);
        final visitDate = _parseFlexibleDate(jsonMap['at']) ?? DateTime.now();
        final urineAlb = _parseUrineAlbumin(notes, rawVitals['urineAlbumin']);

        final bool isHighRisk =
            riskMap['tier']?.toString().toLowerCase() == 'high' ||
                (systolic != null && systolic >= 140) ||
                (diastolic != null && diastolic >= 90);

        final singleVisit = ClinicVisit(
          week: gaWeeks > 0 ? gaWeeks : 31,
          date: visitDate,
          status: isHighRisk ? VisitStatus.review : VisitStatus.normal,
          systolic: systolic,
          diastolic: diastolic,
          weightKg: (rawVitals['weight'] as num?)?.toDouble(),
          fundalHeightCm: fundalCm,
          fetalHeartRate: fhr,
          maternalHeartRate: vitalsMaternalHr,
          bodyTempF: vitalsTempF,
          bloodSugarMgDl: vitalsBsMgDl,
          urineAlbumin: urineAlb,
          urineSugar: UrineReading.nil,
          pallor: false,
          ankleOedema: notes.toLowerCase().contains('oedema'),
          facialOedema: false,
          foetalLie: FoetalLie.longitudinal,
          foetalPresentation: FoetalPresentation.cephalic,
          foetalMovements: true,
          ironFolate: true,
          vitaminC: true,
          calcium: true,
          antimalarials: false,
          foodSupplement: true,
          examinerSignature: midwifeName,
        );

        // Parse multiple visits if array is provided
        final rawVisits = jsonMap['visits'] ?? jsonMap['clinicalVisits'];
        final List<ClinicVisit> parsedVisits = _parseVisitsList(
          rawVisits,
          midwifeName,
          defaultMaternalHr: vitalsMaternalHr,
          defaultBodyTempF: vitalsTempF,
          defaultBloodSugarMgDl: vitalsBsMgDl,
        );

        final List<ClinicVisit> allVisits = <ClinicVisit>[];
        if (parsedVisits.isNotEmpty) {
          allVisits.addAll(parsedVisits);
          // Include top-level single visit if not already covered by same week
          final hasMatchingWeek = allVisits
              .any((v) => v.week == (gaWeeks > 0 ? gaWeeks : singleVisit.week));
          if (!hasMatchingWeek &&
              (rawVitals.isNotEmpty || fundalCm != null || fhr != null)) {
            allVisits.add(singleVisit);
          }
        } else {
          allVisits.add(singleVisit);
        }

        // Sort visits chronologically by gestational week
        allVisits.sort((a, b) => a.week.compareTo(b.week));

        // Generate Growth curves for all visits
        final List<GrowthPoint> fundalHeightPoints = allVisits
            .where((v) => v.fundalHeightCm != null && v.week > 0)
            .map((v) =>
                GrowthPoint(week: v.week, value: v.fundalHeightCm!.toDouble()))
            .toList();

        final List<GrowthPoint> weightGainPoints = allVisits
            .where((v) => v.weightKg != null && v.week > 0)
            .map((v) => GrowthPoint(week: v.week, value: v.weightKg!))
            .toList();

        // Labs & Investigations
        final Map<String, dynamic> rawLabs =
            jsonMap['investigations'] is Map<String, dynamic>
                ? jsonMap['investigations'] as Map<String, dynamic>
                : <String, dynamic>{};
        final hbVal = rawLabs['hb'] ?? rawVitals['hb'] ?? jsonMap['hb'];
        final hbText = hbVal != null ? 'Hb: $hbVal g/dL' : null;
        final bloodSugarText = (rawLabs['bloodSugar'] ?? rawLabs['sugar'])
                ?.toString() ??
            (vitalsBsMgDl != null
                ? 'Fasting: ${vitalsBsMgDl.toStringAsFixed(0)} mg/dL'
                : null);
        final vdrlVal = (rawLabs['vdrl'] ??
                rawLabs['syphilis'] ??
                rawLabs['vdrlResult'] ??
                jsonMap['vdrl'])
            ?.toString();
        final antihelminthicDate = _parseFlexibleDate(rawLabs['antihelminthic'] ??
            rawLabs['deworming'] ??
            jsonMap['antihelminthic']);

        // Default standard WHO reference fundal height curve (weeks 12-40)
        const defaultExpectedFundalHeight = <GrowthPoint>[
          GrowthPoint(week: 12, value: 12),
          GrowthPoint(week: 16, value: 16),
          GrowthPoint(week: 20, value: 20),
          GrowthPoint(week: 24, value: 24),
          GrowthPoint(week: 28, value: 28),
          GrowthPoint(week: 32, value: 32),
          GrowthPoint(week: 36, value: 36),
          GrowthPoint(week: 38, value: 38),
          GrowthPoint(week: 40, value: 40),
        ];

        // Tetanus Immunization (check jsonMap or visit notes for Tdap / TT)
        DateTime? tt1;
        DateTime? tt2;
        final rawTetanus = jsonMap['tetanus'] ?? jsonMap['immunization'] ?? jsonMap['immunizations'];
        if (rawTetanus is Map) {
          tt1 = _parseFlexibleDate(rawTetanus['dose1'] ?? rawTetanus['tt1']);
          tt2 = _parseFlexibleDate(rawTetanus['dose2'] ?? rawTetanus['tt2']);
        }
        if (tt1 == null && rawVisits is List) {
          for (final dynamic item in rawVisits) {
            if (item is Map) {
              final vNote = (item['notes'] ?? '').toString().toLowerCase();
              if (vNote.contains('tdap') || vNote.contains('tt') || vNote.contains('tetanus')) {
                final vDate = _parseFlexibleDate(item['date'] ?? item['at']);
                if (vDate != null) {
                  // Distinguish TT1 from TT2 in the notes
                  if (vNote.contains('tt2') || vNote.contains('2nd dose') || vNote.contains('dose 2')) {
                    tt2 ??= vDate;
                  } else {
                    tt1 ??= vDate;
                  }
                }
              }
            }
          }
        }

        // System Exams (check jsonMap or populate normal clinical defaults)
        TrimesterSystemExams systemExams = const TrimesterSystemExams(
          cvsTrimester1: 'Normal - S1, S2 heard',
          cvsTrimester2: 'Normal - Heart sounds clear',
          cvsTrimester3: 'Normal - Heart sounds clear, no murmurs',
          respiratory: 'Clear breath sounds bilaterally',
          breastExam: 'Normal, nipples everted',
        );
        final rawExams = jsonMap['systemExams'] ?? jsonMap['exams'];
        if (rawExams is Map) {
          systemExams = TrimesterSystemExams.fromJson(Map<String, dynamic>.from(rawExams));
        }

        // Dental
        DentalCare dental = DentalCare(
          screenedDate: allVisits.isNotEmpty ? allVisits.first.date : DateTime(2024, 6, 9),
        );
        final rawDental = jsonMap['dental'];
        if (rawDental is Map) {
          dental = DentalCare.fromJson(Map<String, dynamic>.from(rawDental));
        }

        // Format all other lab results into otherInvestigations
        final otherBuffer = StringBuffer();
        if (rawLabs['rubella'] != null) otherBuffer.write('Rubella: ${rawLabs['rubella']} | ');
        if (rawLabs['hiv'] != null) otherBuffer.write('HIV: ${rawLabs['hiv']} | ');
        if (rawLabs['hepatitisB'] != null) otherBuffer.write('Hepatitis B: ${rawLabs['hepatitisB']} | ');
        if (rawLabs['urineAlbumin'] != null) otherBuffer.write('Urine Albumin: ${rawLabs['urineAlbumin']} | ');
        if (rawLabs['urineSugar'] != null) otherBuffer.write('Urine Sugar: ${rawLabs['urineSugar']}');
        final otherText = otherBuffer.toString().trim();
        final finalOther = otherText.isNotEmpty
            ? (otherText.endsWith('|') ? otherText.substring(0, otherText.length - 1).trim() : otherText)
            : (notes.isNotEmpty ? notes : null);

        clinicRecord = ClinicRecord(
          visits: allVisits,
          fundalHeight: fundalHeightPoints,
          weightGain: weightGainPoints,
          expectedFundalHeight: defaultExpectedFundalHeight,
          systemExams: systemExams,
          investigations: LabInvestigations(
            haemoglobin: hbText,
            bloodSugar: bloodSugarText,
            otherInvestigations: finalOther,
            syphilis: SyphilisScreening(
              result: vdrlVal,
              samplingDate: vdrlVal != null ? (allVisits.isNotEmpty ? allVisits.first.date : visitDate) : null,
              resultDate: vdrlVal != null ? (allVisits.length > 2 ? allVisits[2].date : visitDate) : null,
            ),
            antihelminthicDate: antihelminthicDate ??
                (allVisits.length > 2 ? allVisits[2].date : DateTime(2024, 9, 27)),
          ),
          tetanus: TetanusImmunization(
            dose1Date: tt1,
            dose2Date: tt2,
          ),
          dental: dental,
          referrals: ClinicReferral(
            notes: riskBuffer.isNotEmpty
                ? 'Clinical Flag: ${riskBuffer.toString()}'
                : null,
          ),
        );

        // --- 6. DeliveryPlan from Dashboard ---
        final rawDelivery = jsonMap['deliveryPlan'] is Map<String, dynamic>
            ? jsonMap['deliveryPlan'] as Map<String, dynamic>
            : <String, dynamic>{};
        final hosp = (rawDelivery['intendedHospital'] ??
                rawDelivery['hospital'] ??
                'Base Hospital Rampur')
            .toString();
        final dist = (rawDelivery['distanceKm'] is num)
            ? (rawDelivery['distanceKm'] as num).toInt()
            : (int.tryParse(rawDelivery['distanceKm']?.toString() ?? '') ?? 12);

        TransportMode? transportMode;
        final tModeRaw =
            rawDelivery['transportMode']?.toString().toLowerCase();
        if (tModeRaw != null) {
          if (tModeRaw.contains('own')) {
            transportMode = TransportMode.ownVehicle;
          } else if (tModeRaw.contains('public') || tModeRaw.contains('bus')) {
            transportMode = TransportMode.publicTransport;
          } else if (tModeRaw.contains('three') || tModeRaw.contains('tuk')) {
            transportMode = TransportMode.threeWheeler;
          } else if (tModeRaw.contains('amb')) {
            transportMode = TransportMode.ambulance;
          }
        }
        transportMode ??= TransportMode.ambulance;

        final int? poaDelivery = (rawDelivery['poaAtDeliveryWeeks'] is num)
            ? (rawDelivery['poaAtDeliveryWeeks'] as num).toInt()
            : int.tryParse(rawDelivery['poaAtDeliveryWeeks']?.toString() ?? '');
        final dob = _parseFlexibleDate(rawDelivery['dateOfBirth'] ?? rawDelivery['deliveryDate']);

        deliveryPlan = DeliveryPlan(
          intendedHospital: hosp.isNotEmpty ? hosp : 'Base Hospital Rampur',
          distanceKm: dist,
          transportMode: transportMode,
          transportCostEstimate: (rawDelivery['transportCostEstimate'] is num)
              ? (rawDelivery['transportCostEstimate'] as num).toInt()
              : (int.tryParse(rawDelivery['transportCostEstimate']?.toString() ?? '') ?? 0),
          estimatedTimeMinutes: (rawDelivery['estimatedTimeMinutes'] is num)
              ? (rawDelivery['estimatedTimeMinutes'] as num).toInt()
              : (int.tryParse(rawDelivery['estimatedTimeMinutes']?.toString() ?? '') ?? 25),
          deliveryHospital: (rawDelivery['deliveryHospital'] ?? hosp).toString(),
          dateOfBirth: dob,
          poaAtDeliveryWeeks: poaDelivery ?? (gaWeeks > 0 ? gaWeeks : 38),
          complications: (rawDelivery['complications'] ?? riskCond ?? 'Normal Progression').toString(),
          antenatalEducation: const AntenatalEducation(
            classTrimester1: true,
            classTrimester2: true,
            classTrimester3: true,
            bookAntenatal: true,
            bookBreastfeeding: true,
            bookEccd: true,
            leafletFp: true,
          ),
          dischargeChecklist: const DischargeChecklist(
            dangerSignalsExplained: true,
            breastfeedingEstablished: true,
            referredToPhm: true,
          ),
        );
      } else {
        // --- Fallback: Nested Schema format ---
        final motherJson = (jsonMap['mother'] ?? jsonMap['profile'])
            as Map<String, dynamic>?;
        final vitalsJson = jsonMap['vitals'] as Map<String, dynamic>?;
        final medJson = (jsonMap['medicalHistory'] ?? jsonMap['medical'])
            as Map<String, dynamic>?;
        final historyJson =
            (jsonMap['obstetricHistory'] ?? jsonMap['history'])
                as Map<String, dynamic>?;
        final clinicJson =
            (jsonMap['clinicRecord'] ?? jsonMap['clinic'])
                as Map<String, dynamic>?;
        final deliveryJson =
            (jsonMap['deliveryPlan'] ?? jsonMap['delivery'])
                as Map<String, dynamic>?;

        if (motherJson == null && clinicJson == null) {
          return const SyncResult(
            isSuccess: false,
            message: 'Payload is missing clinical mother records.',
          );
        }

        profile = motherJson != null
            ? BasicProfile.fromJson(motherJson)
            : const BasicProfile.empty();

        vitals = vitalsJson != null
            ? KeyVitals.fromJson(vitalsJson)
            : const KeyVitals.empty();

        medicalHistory = medJson != null
            ? MedicalHistory.fromJson(medJson)
            : _parseMedicalHistory(null, jsonMap, '', <String, dynamic>{});

        history = historyJson != null
            ? ObstetricHistory.fromJson(historyJson)
            : const ObstetricHistory.empty();

        clinicRecord = clinicJson != null
            ? ClinicRecord.fromJson(clinicJson)
            : const ClinicRecord.empty();

        deliveryPlan = deliveryJson != null
            ? DeliveryPlan.fromJson(deliveryJson)
            : const DeliveryPlan.empty();

        clinicName = jsonMap['clinic'] is String
            ? jsonMap['clinic'] as String
            : jsonMap['clinicName'] as String? ?? 'MOH Clinic';
        midwifeName = jsonMap['midwife'] is String
            ? jsonMap['midwife'] as String
            : jsonMap['midwifeName'] as String? ?? 'Public Health Midwife';
        version = jsonMap['version'] as int? ?? 1;
      }

      // Evaluate Read-Only Immutability Lock ("ro": 1 / is_clinical_readonly)
      final bool isClinicalReadOnly =
          ReadOnlyImmutabilityGuard.isPayloadReadOnly(jsonMap);

      // Calculate payload hash for tamper-evident audit
      final payloadHash = sha256.convert(utf8.encode(trimmed)).toString();

      // Persist to encrypted SQLCipher database
      if (onSaveSyncData != null) {
        await onSaveSyncData!(
          profile: profile,
          vitals: vitals,
          medicalHistory: medicalHistory,
          obstetricHistory: history,
          clinicRecord: clinicRecord,
          deliveryPlan: deliveryPlan,
          clinicName: clinicName,
          midwifeName: midwifeName,
          version: version,
          payloadHash: payloadHash,
          isClinicalReadOnly: isClinicalReadOnly,
        );
      } else {
        await EncryptedDatabaseHelper.saveSyncData(
          profile: profile,
          vitals: vitals,
          medicalHistory: medicalHistory,
          obstetricHistory: history,
          clinicRecord: clinicRecord,
          deliveryPlan: deliveryPlan,
          clinicName: clinicName,
          midwifeName: midwifeName,
          version: version,
          payloadHash: payloadHash,
          isClinicalReadOnly: isClinicalReadOnly,
        );
      }

      return SyncResult(
        isSuccess: true,
        message:
            'Successfully synchronized clinical records from midwife dashboard.',
        motherName: profile.motherName,
        visitsCount: clinicRecord.visits.length,
        clinicName: clinicName,
        midwifeName: midwifeName,
        profile: profile,
        vitals: vitals,
        medicalHistory: medicalHistory,
        obstetricHistory: history,
        clinicRecord: clinicRecord,
        deliveryPlan: deliveryPlan,
        isClinicalReadOnly: isClinicalReadOnly,
        epdsScore: epdsScore,
      );
    } catch (e, stack) {
      debugPrint('Sync processing error: $e\n$stack');
      return SyncResult(
        isSuccess: false,
        message: 'Failed to process sync data: ${e.toString()}',
      );
    }
  }

  /// Generates a realistic sample sync payload matching both the Thesis Table 4.5
  /// key dictionary (`pid`, `age`, `ga`, `sbp`, `dbp`, `bs`, `temp`, `hr`, `hb`,
  /// `epds`, `ro`, `chk`) and the midwife dashboard export schema.
  static String generateSamplePayload({bool compressed = true, bool useGzip = false}) {
    final samplePayload = <String, dynamic>{
      'app': 'MaternaVault',
      'ver': '1.2.0',
      // Thesis Table 4.5 compact clinical keys
      'pid': '#6720',
      'id': '#6720',
      'name': 'Kumari Sandamali Perera',
      'age': 26,
      'ga': '38w 4d',
      'sbp': 120,
      'dbp': 80,
      'bs': 82,
      'temp': 98.4,
      'hr': 78,
      'hb': 11.8,
      'epds': 4,
      'ro': 1,
      // Additional obstetric & clinic context
      'gravida': 2,
      'para': 1,
      'livingChildren': 1,
      'nic': '199856201458',
      'village': 'Rampur North Sector 2',
      'trim': 3,
      'edd': '2025-01-17',
      'lmp': '2024-04-12',
      'fundal': '38 cm',
      'vitals': <String, dynamic>{
        'bp': '120/80',
        'sbp': 120,
        'dbp': 80,
        'hb': 11.8,
        'bmi': 27.4,
        'fhr': '140 bpm',
        'hr': 78,
        'temp': 98.4,
        'bs': 82,
        'weight': 68.5,
        'bloodGroup': 'B +ve',
        'height': '158',
        'allergies': 'None known',
      },
      'risk': <String, dynamic>{
        'tier': 'low',
        'title': 'LOW RISK',
        'prob': 10,
        'cond': 'Normal Progression',
      },
      'notes':
          'Term pregnancy. Good maternal and fetal wellbeing. Instructed to report directly to Base Hospital Rampur Labour Room on onset of true labour pains, show, or leaking membranes.',
      'by': 'Sister Priya Sharma (phm_lead)',
      'at': DateTime.now().toIso8601String(),
      'pregnancies': <Map<String, dynamic>>[
        <String, dynamic>{
          'order': 1,
          'year': 2024,
          'term': 'term',
          'mode': 'vaginal',
          'outcome': 'alive',
          'birthWeight': 3,
          'sex': 'male',
          'age': 2,
          'hospital': 'District Base Hospital',
          'antenatalComplications': 'None',
          'postnatalComplications': 'Normal recovery',
        },
      ],
      'visits': <Map<String, dynamic>>[
        <String, dynamic>{
          'week': 8,
          'date': '2024-06-09',
          'bp': '118/76',
          'weight': 58.0,
          'fundal': 38,
          'fhr': 140,
          'status': 'normal',
          'albumin': 'nil',
          'sugar': 'nil',
          'foetalLie': 'transverse',
          'foetalPresentation': 'cephalic',
          'foetalMovements': true,
          'ironFolate': true,
          'vitaminC': true,
          'calcium': true,
          'foodSupplement': false,
          'by': 'Sister Priya Sharma (phm_lead)',
          'notes':
              'Booking visit at MOH clinic. Routine booking investigations ordered.',
        },
        <String, dynamic>{
          'week': 16,
          'date': '2024-08-02',
          'bp': '120/78',
          'weight': 59.5,
          'fundal': 16,
          'fhr': 148,
          'status': 'normal',
          'albumin': 'nil',
          'sugar': 'nil',
          'foetalLie': 'longitudinal',
          'foetalPresentation': 'cephalic',
          'foetalMovements': true,
          'ironFolate': true,
          'vitaminC': true,
          'calcium': true,
          'foodSupplement': true,
          'by': 'Sister Priya Sharma (phm_lead)',
          'notes':
              'Quickening felt. Fundal height corresponds to gestational age.',
        },
        <String, dynamic>{
          'week': 24,
          'date': '2024-09-27',
          'bp': '122/80',
          'weight': 62.0,
          'fundal': 24,
          'fhr': 144,
          'status': 'normal',
          'albumin': 'nil',
          'sugar': 'nil',
          'foetalLie': 'longitudinal',
          'foetalPresentation': 'cephalic',
          'foetalMovements': true,
          'ironFolate': true,
          'vitaminC': true,
          'calcium': true,
          'foodSupplement': true,
          'by': 'Dr. Rajesh Varma, MO Antenatal',
          'notes':
              'OGTT performed - normal glucose tolerance. Tdap vaccine administered.',
        },
        <String, dynamic>{
          'week': 28,
          'date': '2024-10-25',
          'bp': '120/78',
          'weight': 64.0,
          'fundal': 28,
          'fhr': 140,
          'status': 'normal',
          'albumin': 'nil',
          'sugar': 'nil',
          'foetalLie': 'longitudinal',
          'foetalPresentation': 'cephalic',
          'foetalMovements': true,
          'ironFolate': true,
          'vitaminC': true,
          'calcium': true,
          'foodSupplement': true,
          'by': 'Sister Priya Sharma (phm_lead)',
          'notes':
              'Repeat Hb 11.8 g/dL. Anti-D not required (B +ve). Routine growth monitoring.',
        },
        <String, dynamic>{
          'week': 32,
          'date': '2024-11-22',
          'bp': '124/82',
          'weight': 66.0,
          'fundal': 32,
          'fhr': 142,
          'status': 'normal',
          'albumin': 'nil',
          'sugar': 'nil',
          'foetalLie': 'longitudinal',
          'foetalPresentation': 'cephalic',
          'foetalMovements': true,
          'ironFolate': true,
          'vitaminC': true,
          'calcium': true,
          'foodSupplement': true,
          'by': 'Sister Priya Sharma (phm_lead)',
          'notes':
              'Cephalic presentation confirmed. Birth preparedness plan discussed with mother.',
        },
        <String, dynamic>{
          'week': 36,
          'date': '2024-12-20',
          'bp': '122/80',
          'weight': 67.5,
          'fundal': 36,
          'fhr': 138,
          'status': 'normal',
          'albumin': 'nil',
          'sugar': 'nil',
          'foetalLie': 'longitudinal',
          'foetalPresentation': 'cephalic',
          'foetalMovements': true,
          'ironFolate': true,
          'vitaminC': true,
          'calcium': true,
          'foodSupplement': true,
          'by': 'Sister Priya Sharma (phm_lead)',
          'notes': 'Normal progression.',
        },
        <String, dynamic>{
          'week': 38,
          'date': '2025-01-01',
          'bp': '120/80',
          'weight': 68.5,
          'fundal': 38,
          'fhr': 140,
          'status': 'normal',
          'albumin': 'nil',
          'sugar': 'nil',
          'foetalLie': 'longitudinal',
          'foetalPresentation': 'cephalic',
          'foetalMovements': true,
          'ironFolate': true,
          'vitaminC': true,
          'calcium': true,
          'foodSupplement': true,
          'by': 'Sister Priya Sharma (phm_lead)',
          'notes': 'Term pregnancy. Good maternal and fetal wellbeing.',
        },
      ],
      'investigations': <String, dynamic>{
        'hb': '11.8',
        'bloodGroup': 'B +ve',
        'bloodSugar': 'Fasting: 82 mg/dL, 2h PP: 110 mg/dL',
        'vdrl': 'Non-reactive',
      },
      'deliveryPlan': <String, dynamic>{
        'intendedHospital': 'Base Hospital Rampur (Specialist Unit)',
        'distanceKm': 12,
        'transportMode': 'ownVehicle',
        'poaAtDeliveryWeeks': 38,
        'complications': 'None',
      },
    };

    // Attach 64-char lowercase SHA-256 checksum ("chk") over "{pid}|{sbp}|{dbp}|{bs}|{temp}|{hr}|{epds}|{ro}"
    samplePayload['chk'] =
        QrPayloadCompressor.computePayloadChecksum(samplePayload);

    if (compressed) {
      return useGzip
          ? QrPayloadCompressor.compressGzip(samplePayload)
          : QrPayloadCompressor.compress(samplePayload);
    }
    return jsonEncode(samplePayload);
  }

  /// Generates a sample payload matching one of the 3 dedicated QR transfer modes:
  /// 1. [QrTransferMode.gzipCompressed]: Gzip Ultra-Fast QR (`MVZ1:GZ:<base64url>`)
  /// 2. [QrTransferMode.cameraLink]: Phone Camera Pass (`https://maternavault.gov.lk/records/#6720`)
  /// 3. [QrTransferMode.fullJson]: JSON Vault (complete uncompressed raw JSON payload)
  static String generateSamplePayloadByMode(QrTransferMode mode) {
    switch (mode) {
      case QrTransferMode.cameraLink:
        return 'https://maternavault.gov.lk/records/#6720';
      case QrTransferMode.gzipCompressed:
        return generateSamplePayload(compressed: true, useGzip: true);
      case QrTransferMode.fullJson:
        return generateSamplePayload(compressed: false);
    }
  }

  static DateTime? _parseFlexibleDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final str = value.toString().trim();
    if (str.isEmpty) return null;

    final iso = DateTime.tryParse(str);
    if (iso != null) return iso;

    const Map<String, int> months = <String, int>{
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };

    final parts = str.split(RegExp(r'[\s\-/]+'));
    if (parts.length == 3) {
      final p1Low = parts[1].toLowerCase();
      final mKey = p1Low.length >= 3 ? p1Low.substring(0, 3) : p1Low;
      if (months.containsKey(mKey)) {
        final day = int.tryParse(parts[0]);
        final year = int.tryParse(parts[2]);
        if (day != null && year != null) {
          return DateTime(year, months[mKey]!, day);
        }
      }
      final p0 = int.tryParse(parts[0]);
      final p1 = int.tryParse(parts[1]);
      final p2 = int.tryParse(parts[2]);
      if (p0 != null && p1 != null && p2 != null) {
        if (p2 > 1000) return DateTime(p2, p1, p0);
        if (p0 > 1000) return DateTime(p0, p1, p2);
      }
    }
    return null;
  }

  static int _parseWeeks(dynamic gaValue) {
    if (gaValue == null) return 0;
    if (gaValue is num) return gaValue.toInt();
    final match =
        RegExp(r'(\d+)\s*w').firstMatch(gaValue.toString().toLowerCase());
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 0;
    }
    final numMatch = RegExp(r'(\d+)').firstMatch(gaValue.toString());
    if (numMatch != null) {
      return int.tryParse(numMatch.group(1)!) ?? 0;
    }
    return 0;
  }

  /// Resolves systolic and diastolic blood pressure from either explicit
  /// `"sbp"` / `"dbp"` keys (Thesis Table 4.5) or combined `"bp"` (`"120/80"`).
  static (int?, int?) _resolveBloodPressure(
    Map<String, dynamic> primary, [
    Map<String, dynamic>? fallback,
  ]) {
    final int? explicitSbp = _parseNumericPrefix(
      primary['sbp'] ??
          primary['systolic'] ??
          primary['systolicBp'] ??
          fallback?['sbp'] ??
          fallback?['systolic'] ??
          fallback?['systolicBp'],
    );
    final int? explicitDbp = _parseNumericPrefix(
      primary['dbp'] ??
          primary['diastolic'] ??
          primary['diastolicBp'] ??
          fallback?['dbp'] ??
          fallback?['diastolic'] ??
          fallback?['diastolicBp'],
    );
    if (explicitSbp != null || explicitDbp != null) {
      return (explicitSbp, explicitDbp);
    }
    return _parseBloodPressure(
      primary['bp'] ??
          primary['bloodPressure'] ??
          fallback?['bp'] ??
          fallback?['bloodPressure'],
    );
  }

  static (int?, int?) _parseBloodPressure(dynamic bpValue) {
    if (bpValue == null) return (null, null);
    final str = bpValue.toString();
    final parts = str.split('/');
    if (parts.length == 2) {
      final sys = int.tryParse(
          RegExp(r'\d+').firstMatch(parts[0])?.group(0) ?? '');
      final dia = int.tryParse(
          RegExp(r'\d+').firstMatch(parts[1])?.group(0) ?? '');
      return (sys, dia);
    }
    return (null, null);
  }

  static int? _parseNumericPrefix(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toInt();
    final match = RegExp(r'(\d+)').firstMatch(val.toString());
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  /// Parses quantitative blood glucose and harmonizes units to mg/dL.
  /// If the extracted value is < 20.0 (indicating mmol/L), multiplies by 18.0.
  static double? _parseBloodSugarMgDl(dynamic val) {
    if (val == null) return null;
    double? parsed;
    if (val is num) {
      parsed = val.toDouble();
    } else {
      final str = val.toString();
      // Prefer matching "Fasting: 84" or the first decimal/number
      final fastingMatch =
          RegExp(r'fasting[^0-9]*(\d+(?:\.\d+)?)', caseSensitive: false)
              .firstMatch(str);
      if (fastingMatch != null) {
        parsed = double.tryParse(fastingMatch.group(1)!);
      } else {
        final numMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(str);
        if (numMatch != null) {
          parsed = double.tryParse(numMatch.group(1)!);
        }
      }
    }
    if (parsed == null || parsed <= 0) return null;
    // Unit harmonization: mmol/L (< 20.0) -> mg/dL (* 18.0)
    if (parsed < 20.0) {
      return double.parse((parsed * 18.0).toStringAsFixed(1));
    }
    return parsed;
  }

  /// Parses quantitative maternal body temperature and harmonizes units to °F.
  /// If the extracted value is < 45.0 (indicating °C), converts via (T * 1.8) + 32.0.
  static double? _parseBodyTempF(dynamic val) {
    if (val == null) return null;
    double? parsed;
    if (val is num) {
      parsed = val.toDouble();
    } else {
      final numMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(val.toString());
      if (numMatch != null) {
        parsed = double.tryParse(numMatch.group(1)!);
      }
    }
    if (parsed == null || parsed <= 0) return null;
    // Unit harmonization: °C (< 45.0) -> °F
    if (parsed < 45.0) {
      return double.parse(((parsed * 1.8) + 32.0).toStringAsFixed(1));
    }
    return parsed;
  }

  static UrineReading? _parseUrineAlbumin(
      dynamic notes, dynamic rawAlbumin) {
    if (rawAlbumin != null) {
      final reading = UrineReading.values.asNameMap()[rawAlbumin.toString()];
      if (reading != null) return reading;
    }
    if (notes == null) return null;
    final str = notes.toString().toLowerCase();
    if (str.contains('3+') || str.contains('+++')) return UrineReading.plusThree;
    if (str.contains('2+') || str.contains('++')) return UrineReading.plusTwo;
    if (str.contains('1+') || (str.contains('+') && str.contains('protein'))) {
      return UrineReading.plusOne;
    }
    if (str.contains('trace')) return UrineReading.trace;
    if (str.contains('nil') || str.contains('negative')) return UrineReading.nil;
    return null;
  }

  static List<PastPregnancy> _parsePastPregnancies(dynamic raw) {
    if (raw is! List) return <PastPregnancy>[];
    final List<PastPregnancy> list = <PastPregnancy>[];
    for (int i = 0; i < raw.length; i++) {
      final dynamic item = raw[i];
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);

      final orderVal = map['order'] is num
          ? (map['order'] as num).toInt()
          : int.tryParse(map['order']?.toString() ?? '') ?? (i + 1);

      final yearVal = map['year'] is num
          ? (map['year'] as num).toInt()
          : int.tryParse(map['year']?.toString() ?? '');

      final ageVal = (map['ageYears'] ?? map['age']) is num
          ? ((map['ageYears'] ?? map['age']) as num).toInt()
          : int.tryParse((map['ageYears'] ?? map['age'])?.toString() ?? '');

      final weightVal = (map['birthWeightKg'] ??
              map['weight'] ??
              map['birthWeight']) is num
          ? ((map['birthWeightKg'] ?? map['weight'] ?? map['birthWeight']) as num)
              .toDouble()
          : double.tryParse((map['birthWeightKg'] ??
                  map['weight'] ??
                  map['birthWeight'])
              ?.toString() ??
              '');

      // Parse Term
      final termStr = map['term']?.toString().toLowerCase() ?? '';
      PregnancyTerm? term;
      if (termStr.contains('pre')) {
        term = PregnancyTerm.preterm;
      } else if (termStr.contains('post')) {
        term = PregnancyTerm.postTerm;
      } else if (termStr.contains('term')) {
        term = PregnancyTerm.term;
      }

      // Parse Delivery Mode
      final modeStr = (map['deliveryMode'] ?? map['delivery'] ?? map['mode'])
              ?.toString()
              .toLowerCase() ??
          '';
      DeliveryMode? deliveryMode;
      if (modeStr.contains('caes') ||
          modeStr.contains('c-sec') ||
          modeStr.contains('lscs')) {
        deliveryMode = DeliveryMode.caesarean;
      } else if (modeStr.contains('assist') ||
          modeStr.contains('instr') ||
          modeStr.contains('forceps') ||
          modeStr.contains('vacuum')) {
        deliveryMode = DeliveryMode.assistedVaginal;
      } else if (modeStr.contains('vag') ||
          modeStr.contains('svd') ||
          modeStr.contains('spontaneous') ||
          modeStr.contains('normal')) {
        deliveryMode = DeliveryMode.spontaneousVaginal;
      }

      // Parse Outcome
      final outcomeStr = map['outcome']?.toString().toLowerCase() ?? '';
      PregnancyOutcome? outcome;
      if (outcomeStr.contains('still')) {
        outcome = PregnancyOutcome.stillbirth;
      } else if (outcomeStr.contains('death') ||
          outcomeStr.contains('neonatal')) {
        outcome = PregnancyOutcome.neonatalDeath;
      } else if (outcomeStr.contains('misc') ||
          outcomeStr.contains('abort')) {
        outcome = PregnancyOutcome.miscarriage;
      } else if (outcomeStr.contains('alive') ||
          outcomeStr.contains('live')) {
        outcome = PregnancyOutcome.alive;
      }

      // Parse Sex
      final sexStr =
          (map['sex'] ?? map['gender'])?.toString().toLowerCase() ?? '';
      BabySex? sex;
      if (sexStr.startsWith('m')) {
        sex = BabySex.male;
      } else if (sexStr.startsWith('f')) {
        sex = BabySex.female;
      }

      list.add(PastPregnancy(
        order: orderVal,
        year: yearVal,
        term: term,
        deliveryMode: deliveryMode,
        outcome: outcome,
        birthWeightKg: weightVal,
        sex: sex,
        ageYears: ageVal,
        placeOfDelivery: (map['placeOfDelivery'] ??
                map['place'] ??
                map['hospital'])
            ?.toString(),
        antenatalComplications: map['antenatalComplications']?.toString(),
        postnatalComplications: map['postnatalComplications']?.toString(),
      ));
    }
    return list;
  }

  static List<ClinicVisit> _parseVisitsList(
    dynamic raw,
    String midwifeName, {
    int? defaultMaternalHr,
    double? defaultBodyTempF,
    double? defaultBloodSugarMgDl,
  }) {
    if (raw is! List) return const <ClinicVisit>[];
    final List<ClinicVisit> list = <ClinicVisit>[];
    for (final dynamic item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);

      final weekVal = _parseWeeks(map['week'] ?? map['ga']);
      final visitDate =
          _parseFlexibleDate(map['date'] ?? map['at']) ?? DateTime.now();
      final (systolic, diastolic) = _resolveBloodPressure(map);
      int? fundalCm =
          _parseNumericPrefix(map['fundal'] ?? map['fundalHeightCm']);
      if (fundalCm != null) {
        // Sanitize obvious typos (e.g. 232 cm -> 32 cm)
        if (fundalCm > 60 && fundalCm < 1000) {
          fundalCm = fundalCm % 100;
        }
        // At early gestational age (< 12 weeks), fundal height > 20 is erroneous / non-palpable
        if (weekVal > 0 && weekVal < 12 && fundalCm > 20) {
          fundalCm = null;
        }
      }
      final fhr = _parseNumericPrefix(map['fhr'] ?? map['fetalHeartRate']);
      final maternalHr = _parseNumericPrefix(
            map['maternalHeartRate'] ??
                map['hr'] ??
                map['heartRate'] ??
                map['pulse'],
          ) ??
          defaultMaternalHr;
      final bodyTempF = _parseBodyTempF(
            map['bodyTempF'] ??
                map['temp'] ??
                map['bodyTemp'] ??
                map['temperature'],
          ) ??
          defaultBodyTempF;
      final bloodSugarMgDl = _parseBloodSugarMgDl(
            map['bloodSugarMgDl'] ?? map['bs'] ?? map['bloodSugar'],
          ) ??
          defaultBloodSugarMgDl;
      final weightVal = (map['weight'] ?? map['weightKg']) is num
          ? ((map['weight'] ?? map['weightKg']) as num).toDouble()
          : double.tryParse(
              (map['weight'] ?? map['weightKg'])?.toString() ?? '');

      final statusStr = map['status']?.toString().toLowerCase() ?? '';
      final isHighRisk = statusStr == 'review' ||
          statusStr == 'high' ||
          (systolic != null && systolic >= 140) ||
          (diastolic != null && diastolic >= 90);

      final notes = map['notes']?.toString() ?? '';
      final urineAlb =
          _parseUrineAlbumin(notes, map['urineAlbumin'] ?? map['albumin']);

      // Sugar dipstick
      UrineReading? urineSugar = UrineReading.nil;
      final sugarRaw = (map['urineSugar'] ?? map['sugar'])
              ?.toString()
              .toLowerCase() ??
          '';
      if (sugarRaw.contains('3+') || sugarRaw.contains('plusthree')) {
        urineSugar = UrineReading.plusThree;
      } else if (sugarRaw.contains('2+') || sugarRaw.contains('plustwo')) {
        urineSugar = UrineReading.plusTwo;
      } else if (sugarRaw.contains('1+') || sugarRaw.contains('plusone')) {
        urineSugar = UrineReading.plusOne;
      } else if (sugarRaw.contains('trace')) {
        urineSugar = UrineReading.trace;
      }

      // Foetal lie
      FoetalLie? lie = FoetalLie.longitudinal;
      final lieRaw = map['foetalLie']?.toString().toLowerCase() ?? '';
      if (lieRaw.contains('trans')) lie = FoetalLie.transverse;
      if (lieRaw.contains('obli')) lie = FoetalLie.oblique;

      // Foetal presentation
      FoetalPresentation? presentation = FoetalPresentation.cephalic;
      final presRaw =
          map['foetalPresentation']?.toString().toLowerCase() ?? '';
      if (presRaw.contains('breech')) presentation = FoetalPresentation.breech;
      if (presRaw.contains('shoulder')) presentation = FoetalPresentation.shoulder;

      final examiner = (map['examinerSignature'] ??
              map['by'] ??
              map['midwife'] ??
              midwifeName)
          .toString();

      list.add(ClinicVisit(
        week: weekVal > 0 ? weekVal : 12,
        date: visitDate,
        status: isHighRisk ? VisitStatus.review : VisitStatus.normal,
        systolic: systolic,
        diastolic: diastolic,
        weightKg: weightVal,
        fundalHeightCm: fundalCm,
        fetalHeartRate: fhr,
        maternalHeartRate: maternalHr,
        bodyTempF: bodyTempF,
        bloodSugarMgDl: bloodSugarMgDl,
        urineAlbumin: urineAlb,
        urineSugar: urineSugar,
        pallor: map['pallor'] as bool? ?? false,
        ankleOedema: (map['ankleOedema'] as bool?) ??
            notes.toLowerCase().contains('oedema'),
        facialOedema: map['facialOedema'] as bool? ?? false,
        foetalLie: lie,
        foetalPresentation: presentation,
        foetalMovements: (map['foetalMovements'] as bool?) ?? true,
        ironFolate: (map['ironFolate'] as bool?) ?? true,
        vitaminC: (map['vitaminC'] as bool?) ?? true,
        calcium: (map['calcium'] as bool?) ?? true,
        antimalarials: (map['antimalarials'] as bool?) ?? false,
        foodSupplement: (map['foodSupplement'] as bool?) ?? true,
        examinerSignature: examiner.isNotEmpty ? examiner : midwifeName,
      ));
    }
    return list;
  }

  static MedicalHistory _parseMedicalHistory(
    dynamic rawMed,
    Map<String, dynamic> jsonMap,
    String notes,
    Map<String, dynamic> riskMap,
  ) {
    final Set<FamilyCondition> family = <FamilyCondition>{};
    final Set<PersonalCondition> personal = <PersonalCondition>{};
    String? familyOther;
    String? personalOther;

    if (rawMed is Map) {
      final famList = rawMed['family'];
      if (famList is List) {
        for (final dynamic item in famList) {
          final s = item.toString().toLowerCase();
          if (s.contains('diab')) family.add(FamilyCondition.diabetesMellitus);
          if (s.contains('hyper') || s.contains('bp') || s.contains('press')) {
            family.add(FamilyCondition.hypertension);
          }
          if (s.contains('haem') || s.contains('thal') || s.contains('blood')) {
            family.add(FamilyCondition.haematological);
          }
        }
      }
      final persList = rawMed['personal'];
      if (persList is List) {
        for (final dynamic item in persList) {
          final s = item.toString().toLowerCase();
          if (s.contains('diab')) personal.add(PersonalCondition.diabetes);
          if (s.contains('hyper') || s.contains('bp') || s.contains('eclamp')) {
            personal.add(PersonalCondition.hypertension);
          }
          if (s.contains('card')) personal.add(PersonalCondition.cardiac);
          if (s.contains('ren') || s.contains('kidney')) {
            personal.add(PersonalCondition.renal);
          }
          if (s.contains('asthma')) {
            personal.add(PersonalCondition.bronchialAsthma);
          }
          if (s.contains('surg') || s.contains('operat')) {
            personal.add(PersonalCondition.surgeries);
          }
          if (s.contains('thyroid')) personal.add(PersonalCondition.thyroid);
          if (s.contains('epilep')) personal.add(PersonalCondition.epilepsy);
        }
      }

      // Compact _mv:1 format: boolean flags like {"diabetes":true,"asthma":false,...}
      // These are flat keys on the medical history map itself.
      if (rawMed['diabetes'] == true) personal.add(PersonalCondition.diabetes);
      if (rawMed['chronicHtn'] == true || rawMed['hypertension'] == true) {
        personal.add(PersonalCondition.hypertension);
      }
      if (rawMed['cardiac'] == true) personal.add(PersonalCondition.cardiac);
      if (rawMed['asthma'] == true) personal.add(PersonalCondition.bronchialAsthma);
      if (rawMed['thyroid'] == true) personal.add(PersonalCondition.thyroid);
      if (rawMed['epilepsy'] == true) personal.add(PersonalCondition.epilepsy);
      if (rawMed['renal'] == true) personal.add(PersonalCondition.renal);
      if (rawMed['hepatic'] == true) personal.add(PersonalCondition.hepatic);
      if (rawMed['psychiatric'] == true) personal.add(PersonalCondition.psychiatric);
      if (rawMed['thalassaemia'] == true) {
        personal.add(PersonalCondition.haematological);
        family.add(FamilyCondition.haematological);
      }
      if (rawMed['prevLscs'] == true || rawMed['prevPreterm'] == true ||
          rawMed['prevPph'] == true) {
        personal.add(PersonalCondition.surgeries);
      }

      // Allergies and surgeries as strings
      final List<String> personalNotes = <String>[];
      final allergiesStr = rawMed['allergies']?.toString();
      if (allergiesStr != null &&
          allergiesStr.isNotEmpty &&
          !allergiesStr.toLowerCase().contains('none')) {
        personalNotes.add('Allergies: $allergiesStr');
      }
      final surgeriesStr = rawMed['surgeries']?.toString();
      if (surgeriesStr != null &&
          surgeriesStr.isNotEmpty &&
          !surgeriesStr.toLowerCase().contains('none')) {
        personal.add(PersonalCondition.surgeries);
        personalNotes.add('Surgeries: $surgeriesStr');
      }
      if (personalNotes.isNotEmpty) {
        personalOther = personalNotes.join('; ');
      }

      familyOther = rawMed['familyOtherDetails']?.toString() ?? familyOther;
      personalOther = rawMed['personalOtherDetails']?.toString() ?? personalOther;
    }

    // Infer from notes / risk if personal history was not explicitly specified
    final combined =
        '${notes.toLowerCase()} ${(riskMap['cond'] ?? '').toString().toLowerCase()}';
    if (combined.contains('pre-eclampsia') ||
        combined.contains('gestational hypertension') ||
        combined.contains('chronic hypertension')) {
      personal.add(PersonalCondition.hypertension);
    }
    if (combined.contains('gestational diabetes') ||
        combined.contains('gdm') ||
        combined.contains('diabetic')) {
      personal.add(PersonalCondition.diabetes);
    }
    if (combined.contains('asthma')) {
      personal.add(PersonalCondition.bronchialAsthma);
    }
    if (combined.contains('cardiac') || combined.contains('heart disease')) {
      personal.add(PersonalCondition.cardiac);
    }

    final allergies = (jsonMap['vitals'] is Map)
        ? (jsonMap['vitals']['allergies']?.toString() ?? '')
        : '';
    if (allergies.isNotEmpty &&
        !allergies.toLowerCase().contains('none') &&
        personalOther == null) {
      personalOther = 'Allergies: $allergies';
    }

    if (personal.isEmpty && family.isEmpty) {
      personal.add(PersonalCondition.other);
      personalOther ??=
          'Screened by PHM: No pre-existing medical or surgical conditions. Allergies: None known. Surgeries: None reported.';
    } else if (personalOther != null && personalOther.isNotEmpty) {
      personal.add(PersonalCondition.other);
    }

    return MedicalHistory(
      family: family,
      personal: personal,
      familyOtherDetails: familyOther,
      personalOtherDetails: personalOther,
    );
  }

  /// Expands a compact `_mv: 1` payload into the flat dashboard schema the
  /// rest of `processQrPayload` already knows how to parse.
  ///
  /// Key mapping (supports both Thesis Table 4.5 & web portal short keys):
  /// ```
  /// pid/id → id           n  → name          age/a → age           g  → gravida
  /// p  → para             lc → livingChildren ga → ga              w  → (week number)
  /// sbp/dbp/bp → vitals.bp hb → vitals.hb    fhr→ vitals.fhr       hr → vitals.hr
  /// temp → vitals.temp    bs → vitals.bs     epds → epds           ro → ro
  /// wt → vitals.weight    bg → vitals.bloodGroup
  /// rt → risk.tier        rc → risk.cond     rp → risk.prob
  /// pt → partnerName      mh → medicalHistory lr → investigations
  /// pr → pregnancies      vs → visits (arrays)
  /// ```
  static Map<String, dynamic> _expandCompactPayload(
      Map<String, dynamic> c) {
    final String mohVal = (c['moh'] ?? c['mohArea'] ?? '').toString().trim();
    final String vilVal = (c['vil'] ?? c['village'] ?? c['address'] ?? c['loc'] ?? c['locality'] ?? '').toString().trim();
    final String phmVal = (c['phm'] ?? c['phmArea'] ?? c['phmRegisterNo'] ?? '').toString().trim();
    final String nicVal = (c['nic'] ?? c['nicNo'] ?? c['nationalId'] ?? c['pid'] ?? '').toString().trim();
    final String phoneVal = (c['ph'] ?? c['phone'] ?? c['phoneNumber'] ?? '').toString().trim();
    final String ptoVal = (c['pto'] ?? c['partnerOccupation'] ?? c['fatherOccupation'] ?? '').toString().trim();
    final dynamic ptaVal = c['pta'] ?? c['partnerAge'] ?? c['fatherAge'];

    final Map<String, dynamic> out = <String, dynamic>{
      'app': 'MaternaVault',
      'ver': '2.0.0-compact',
      'ro': c['ro'] ?? c['is_clinical_readonly'] ?? 1,
      'village': vilVal.isNotEmpty ? vilVal : 'Rampur North Sector 2',
      'address': vilVal.isNotEmpty ? vilVal : 'Rampur North Sector 2',
      'clinic': mohVal.isNotEmpty ? '$mohVal MOH Clinic' : 'Rampur MOH Clinic',
      'mohArea': mohVal.isNotEmpty ? mohVal : 'Rampur',
      'phmArea': phmVal.isNotEmpty ? phmVal : 'Rampur North Sector 2',
      'nationalId': nicVal.isNotEmpty ? nicVal : '199856201458',
    };

    // ── Top-level scalars ──
    if (c['pid'] != null) out['pid'] = c['pid'];
    if (c['id'] != null || c['pid'] != null) out['id'] = c['id'] ?? c['pid'];
    if (c['n'] != null) out['name'] = c['n'];
    if (c['age'] != null || c['a'] != null) out['age'] = c['age'] ?? c['a'];
    if (c['g'] != null) out['gravida'] = c['g'];
    if (c['p'] != null) out['para'] = c['p'];
    if (c['lc'] != null) out['livingChildren'] = c['lc'];
    if (c['ga'] != null) out['ga'] = c['ga'];
    if (c['edd'] != null) out['edd'] = c['edd'];
    if (c['lmp'] != null) out['lmp'] = c['lmp'];
    if (c['epds'] != null) out['epds'] = c['epds'];
    if (c['chk'] != null) out['chk'] = c['chk'];

    // Partner name and occupation (stored in BasicProfile as father / husband)
    if (c['pt'] != null) {
      out['partnerName'] = c['pt'];
      out['emergencyContactPerson'] = c['pt'];
    }
    if (ptoVal.isNotEmpty) {
      out['partnerOccupation'] = ptoVal;
      out['fatherOccupation'] = ptoVal;
    }
    if (ptaVal != null) {
      out['partnerAge'] = ptaVal;
      out['fatherAge'] = ptaVal;
    }
    if (mohVal.isNotEmpty) {
      out['mohArea'] = mohVal;
    }
    if (vilVal.isNotEmpty) {
      out['village'] = vilVal;
      out['address'] = vilVal;
    }
    if (phmVal.isNotEmpty) {
      out['phmArea'] = phmVal;
      out['phmRegisterNo'] = phmVal;
    }
    if (nicVal.isNotEmpty) {
      out['nationalId'] = nicVal;
      out['nicNo'] = nicVal;
    }
    if (phoneVal.isNotEmpty) {
      out['phone'] = phoneVal;
      out['phoneNumber'] = phoneVal;
      out['emergencyPhone'] = phoneVal;
    }

    // ── Vitals ──
    final Map<String, dynamic> vitals = <String, dynamic>{};
    if (c['sbp'] != null) {
      out['sbp'] = c['sbp'];
      vitals['sbp'] = c['sbp'];
    }
    if (c['dbp'] != null) {
      out['dbp'] = c['dbp'];
      vitals['dbp'] = c['dbp'];
    }
    if (c['bp'] != null) {
      vitals['bp'] = c['bp'];
    } else if (c['sbp'] != null && c['dbp'] != null) {
      vitals['bp'] = '${c['sbp']}/${c['dbp']}';
    }
    if (c['hb'] != null) vitals['hb'] = c['hb'];
    if (c['fhr'] != null) vitals['fhr'] = c['fhr'];
    if (c['hr'] != null || c['maternalHeartRate'] != null || c['pulse'] != null) {
      vitals['hr'] = c['hr'] ?? c['maternalHeartRate'] ?? c['pulse'];
    }
    if (c['temp'] != null || c['bodyTemp'] != null || c['temperature'] != null) {
      vitals['temp'] = c['temp'] ?? c['bodyTemp'] ?? c['temperature'];
    }
    if (c['bs'] != null || c['bloodSugar'] != null) {
      vitals['bs'] = c['bs'] ?? c['bloodSugar'];
    }
    if (c['wt'] != null) vitals['weight'] = c['wt'];
    if (c['bg'] != null) vitals['bloodGroup'] = c['bg'];

    // Height and BMI calculation
    final heightVal = (c['ht'] ?? c['height'] ?? c['h'] ?? '158').toString();
    vitals['height'] = heightVal;
    vitals['heightCm'] = heightVal;
    final double? wtNum = (c['wt'] is num) ? (c['wt'] as num).toDouble() : double.tryParse(c['wt']?.toString() ?? '');
    final double? htNum = double.tryParse(heightVal);
    if (c['bmi'] != null) {
      vitals['bmi'] = c['bmi'].toString();
    } else if (wtNum != null && htNum != null && htNum > 0) {
      vitals['bmi'] = (wtNum / ((htNum / 100) * (htNum / 100))).toStringAsFixed(1);
    } else {
      vitals['bmi'] = '27.4';
    }
    out['vitals'] = vitals;

    // Fundal height from latest visit week
    final weekNum = c['w'];
    if (weekNum is num && weekNum > 0) {
      out['fundal'] = '${weekNum.toInt()} cm';
    }

    // ── Risk ──
    final Map<String, dynamic> risk = <String, dynamic>{};
    if (c['rt'] != null) risk['tier'] = c['rt'];
    if (c['rc'] != null) risk['cond'] = c['rc'];
    if (c['rp'] != null) risk['prob'] = c['rp'];
    final tierStr = (c['rt'] ?? '').toString().toLowerCase();
    risk['title'] = tierStr == 'high'
        ? 'HIGH RISK'
        : tierStr == 'moderate'
            ? 'MODERATE RISK'
            : 'LOW RISK';
    out['risk'] = risk;

    // ── Medical History (boolean flag map → notes inference) ──
    final mh = c['mh'];
    if (mh is Map) {
      final mhMap = Map<String, dynamic>.from(mh);
      out['medicalHistory'] = mhMap;
      if (mhMap['allergies'] != null) {
        vitals['allergies'] = mhMap['allergies'];
      }
    }

    // ── Lab Results → investigations ──
    final lr = c['lr'];
    if (lr is Map) {
      final lrMap = Map<String, dynamic>.from(lr);
      final Map<String, dynamic> labs = <String, dynamic>{};
      if (lrMap['bg'] != null) labs['bloodGroup'] = lrMap['bg'];
      if (lrMap['vd'] != null) labs['vdrl'] = lrMap['vd'];
      if (lrMap['rb'] != null) labs['rubella'] = lrMap['rb'];
      if (lrMap['hv'] != null) labs['hiv'] = lrMap['hv'];
      if (lrMap['hb'] != null) labs['hepatitisB'] = lrMap['hb'];
      if (lrMap['fs'] != null) {
        labs['bloodSugar'] = 'Fasting: ${lrMap['fs']}';
        vitals['bs'] ??= lrMap['fs'];
      }
      if (lrMap['ua'] != null) labs['urineAlbumin'] = lrMap['ua'];
      if (lrMap['us'] != null) labs['urineSugar'] = lrMap['us'];
      if (c['hb'] != null) labs['hb'] = c['hb'];
      out['investigations'] = labs;
    }

    // ── Past Pregnancies ──
    final pr = c['pr'];
    if (pr is List && pr.isNotEmpty) {
      out['pregnancies'] = pr;
    } else {
      final int p = c['p'] is num ? (c['p'] as num).toInt() : (int.tryParse(c['p']?.toString() ?? '') ?? 0);
      if (p > 0) {
        out['pregnancies'] = <Map<String, dynamic>>[
          <String, dynamic>{
            'order': 1,
            'year': 2024,
            'term': 'term',
            'mode': 'vaginal',
            'outcome': 'alive',
            'birthWeight': 3.0,
            'sex': 'male',
            'age': 2,
            'hospital': 'District Base Hospital Rampur',
            'antenatalComplications': 'None',
            'postnatalComplications': 'Normal recovery',
          },
        ];
      } else {
        out['pregnancies'] = <dynamic>[];
      }
    }

    // ── Visits (array-of-arrays → array-of-maps) ──
    // Each visit is encoded as:
    //   [visitNo, date, ga, bp, weight, fundal, fhr, presentation, albumin, sugar, notes]
    final vs = c['vs'];
    if (vs is List) {
      final List<Map<String, dynamic>> expandedVisits = <Map<String, dynamic>>[];
      for (final dynamic row in vs) {
        if (row is! List || row.length < 7) continue;
        final int weekVal = _parseWeeks(row[2]); // ga like "8w 2d"
        int? fundalVal = _parseNumericPrefix(row[5]);
        if (fundalVal != null && fundalVal > 60 && fundalVal < 1000) {
          fundalVal = fundalVal % 100;
        }

        final presStr = (row.length > 7 ? row[7] : '').toString().toLowerCase();
        String foetalPres = 'cephalic';
        if (presStr.contains('breech')) {
          foetalPres = 'breech';
        } else if (presStr.contains('shoulder')) {
          foetalPres = 'shoulder';
        } else if (presStr.contains('n/a') || presStr.contains('early')) {
          foetalPres = 'cephalic';
        }

        final albuminStr = (row.length > 8 ? row[8] : 'nil').toString().toLowerCase();
        final sugarStr = (row.length > 9 ? row[9] : 'nil').toString().toLowerCase();
        final notesStr = row.length > 10 ? row[10].toString() : '';

        final (sys, dia) = _parseBloodPressure(row[3]);
        final isReview = (sys != null && sys >= 140) || (dia != null && dia >= 90);

        expandedVisits.add(<String, dynamic>{
          'week': weekVal > 0 ? weekVal : (row[0] is num ? (row[0] as num).toInt() : 0),
          'date': row[1]?.toString(),
          'bp': row[3]?.toString(),
          'weight': row[4] is num ? row[4] : double.tryParse(row[4]?.toString() ?? ''),
          'fundal': fundalVal,
          'fhr': row[6] is num ? (row[6] as num).toInt() : _parseNumericPrefix(row[6]),
          'status': isReview ? 'review' : 'normal',
          'foetalPresentation': foetalPres,
          'albumin': albuminStr,
          'sugar': sugarStr,
          'notes': notesStr,
          'foetalMovements': true,
          'ironFolate': true,
          'vitaminC': true,
          'calcium': true,
        });
      }
      out['visits'] = expandedVisits;
    }

    // ── Extract notes and delivery plan ──
    final Map<String, dynamic> deliveryPlan = <String, dynamic>{
      'intendedHospital': 'Base Hospital Rampur',
      'deliveryHospital': 'Base Hospital Rampur',
      'transportMode': 'ambulance',
      'distanceKm': 12,
      'estimatedTimeMinutes': 25,
      'transportCostEstimate': 0,
      'complications': 'Normal Progression',
      'poaAtDeliveryWeeks': c['w'] ?? 38,
    };

    if (vs is List && vs.isNotEmpty) {
      final lastRow = vs.last;
      if (lastRow is List && lastRow.length > 10) {
        final lastNotes = lastRow[10].toString();
        out['notes'] = lastNotes;
        final hospMatch = RegExp(r'(?:Base Hospital|District Hospital|Hospital)\s+(\w[\w\s]+?)(?:\s+Labour|\s+on\s|$)')
            .firstMatch(lastNotes);
        if (hospMatch != null) {
          final matchedHosp = hospMatch.group(0)?.replaceAll(RegExp(r'\s+(Labour|on)\s*$'), '').trim();
          if (matchedHosp != null && matchedHosp.isNotEmpty) {
            deliveryPlan['intendedHospital'] = matchedHosp;
            deliveryPlan['deliveryHospital'] = matchedHosp;
          }
        }
      }
    }
    out['deliveryPlan'] = deliveryPlan;

    return out;
  }
}
