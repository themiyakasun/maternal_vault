import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../../core/utils/qr_payload_compressor.dart';
import '../../../mother/domain/basic_profile.dart';
import '../../../mother/domain/clinic_record.dart';
import '../../../mother/domain/delivery_plan.dart';
import '../../../mother/domain/key_vitals.dart';
import '../../../mother/domain/obstetric_history.dart';
import '../../domain/emergency_plan.dart';
import '../../domain/partner_agenda.dart';
import '../../domain/partner_summary.dart';

/// Service that generates and decodes partner synchronization payloads.
///
/// Designed with privacy by default: only pregnancy progression, clinic appointments,
/// emergency contacts, and delivery logistics are shared. Intimate medical
/// conditions and confidential lab tests remain locked in the mother's vault.
class PartnerSyncService {
  static const String partnerPrefix = 'MV_PARTNER:';

  /// Generates a JSON map suitable for partner synchronization.
  static Map<String, dynamic> buildPartnerMap({
    required BasicProfile profile,
    required KeyVitals vitals,
    required DeliveryPlan deliveryPlan,
    required ClinicRecord clinicRecord,
    ObstetricHistory? obstetricHistory,
  }) {
    // Determine gestational weeks
    int weeks = 0;
    if (clinicRecord.visits.isNotEmpty) {
      weeks = clinicRecord.visits.first.week;
    }
    if (weeks <= 0 && obstetricHistory?.poaAtRegistrationWeeks != null) {
      weeks = obstetricHistory!.poaAtRegistrationWeeks!;
    }
    if (weeks <= 0) weeks = 38;

    // Check if vitals are within normal range
    bool vitalsWell = true;
    if (clinicRecord.visits.isNotEmpty) {
      final latest = clinicRecord.visits.first;
      if (latest.status == VisitStatus.review ||
          (latest.systolic != null && latest.systolic! >= 140) ||
          (latest.diastolic != null && latest.diastolic! >= 90)) {
        vitalsWell = false;
      }
    }

    // Identify next or latest appointment
    DateTime nextVisitDate = DateTime.now().add(const Duration(days: 7));
    if (clinicRecord.visits.isNotEmpty) {
      final latest = clinicRecord.visits.first.date;
      nextVisitDate = latest.isAfter(DateTime.now())
          ? latest
          : DateTime.now().add(const Duration(days: 7));
    }

    final String hosp = (deliveryPlan.intendedHospital != null &&
            deliveryPlan.intendedHospital!.isNotEmpty)
        ? deliveryPlan.intendedHospital!
        : ((deliveryPlan.deliveryHospital != null &&
                deliveryPlan.deliveryHospital!.isNotEmpty)
            ? deliveryPlan.deliveryHospital!
            : 'Base Hospital Rampur');

    final String transportStr = deliveryPlan.transportMode != null
        ? deliveryPlan.transportMode!.name
        : 'ambulance';

    final String eddStr = obstetricHistory?.expectedDelivery?.toIso8601String() ??
        DateTime.now().add(const Duration(days: 14)).toIso8601String();

    return <String, dynamic>{
      'app': 'MaternaVault',
      'type': 'partner_sync',
      'ver': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'mother': <String, dynamic>{
        'name': profile.motherName.isNotEmpty ? profile.motherName : 'Mother',
        'id': profile.registrationNumber ?? '#6720',
        'bloodGroup': vitals.bloodGroup ?? 'B +ve',
        'weeks': weeks,
        'allVitalsWell': vitalsWell,
        'edd': eddStr,
      },
      'emergency': <String, dynamic>{
        'contactPerson': (profile.emergencyContactPerson != null &&
                profile.emergencyContactPerson!.isNotEmpty)
            ? profile.emergencyContactPerson
            : 'Primary Contact',
        'contactPhone': (profile.emergencyContactPhone != null &&
                profile.emergencyContactPhone!.isNotEmpty)
            ? profile.emergencyContactPhone
            : '1990',
        'phm': (profile.phmArea != null && profile.phmArea!.isNotEmpty)
            ? profile.phmArea
            : 'Local PHM Officer',
        'moh': (profile.mohArea != null && profile.mohArea!.isNotEmpty)
            ? profile.mohArea
            : ((profile.clinicName != null && profile.clinicName!.isNotEmpty)
                ? profile.clinicName
                : 'MOH Office'),
      },
      'delivery': <String, dynamic>{
        'hospital': hosp,
        'transport': transportStr,
        'distanceKm': deliveryPlan.distanceKm ?? 12,
        'estMinutes': deliveryPlan.estimatedTimeMinutes ?? 25,
      },
      'nextAppointment': <String, dynamic>{
        'date': nextVisitDate.toIso8601String(),
        'hospital': hosp,
        'ward': 'Antenatal Clinic / Labour Room',
      },
    };
  }

  /// Encodes the partner map into a compressed (Gzip/Zlib) or plain JSON QR payload string.
  static String generatePartnerQrString({
    required BasicProfile profile,
    required KeyVitals vitals,
    required DeliveryPlan deliveryPlan,
    required ClinicRecord clinicRecord,
    ObstetricHistory? obstetricHistory,
    bool compress = false,
    bool useGzip = false,
  }) {
    final map = buildPartnerMap(
      profile: profile,
      vitals: vitals,
      deliveryPlan: deliveryPlan,
      clinicRecord: clinicRecord,
      obstetricHistory: obstetricHistory,
    );

    if (compress) {
      return useGzip
          ? QrPayloadCompressor.compressGzip(map)
          : QrPayloadCompressor.compress(map);
    }
    return jsonEncode(map);
  }

  /// Parses a partner QR payload string and produces partner domain objects.
  static ({
    PartnerSummary summary,
    PartnerAgenda agenda,
    EmergencyPlan emergencyPlan,
    String motherName,
  })? parsePartnerPayload(String raw) {
    try {
      String clean = raw.trim();
      if (clean.startsWith(partnerPrefix)) {
        clean = clean.substring(partnerPrefix.length).trim();
      }

      Map<String, dynamic> jsonMap;
      if (clean.startsWith(QrPayloadCompressor.prefix) ||
          clean.startsWith(QrPayloadCompressor.gzipPrefix) ||
          clean.startsWith('MVZ1:GZ:')) {
        jsonMap = QrPayloadCompressor.decompress(clean);
      } else {
        try {
          final decoded = jsonDecode(clean);
          if (decoded is! Map) return null;
          jsonMap = Map<String, dynamic>.from(decoded);
        } catch (_) {
          jsonMap = QrPayloadCompressor.decompress(clean);
        }
      }

      // Handle compact or verbose partner schema
      final motherMap = (jsonMap['mother'] ?? jsonMap) as Map<String, dynamic>;
      final emergencyMap =
          (jsonMap['emergency'] ?? <String, dynamic>{}) as Map<String, dynamic>;
      final deliveryMap =
          (jsonMap['delivery'] ?? <String, dynamic>{}) as Map<String, dynamic>;
      final apptMap = (jsonMap['nextAppointment'] ?? <String, dynamic>{})
          as Map<String, dynamic>;

      final String motherName = (motherMap['name'] ?? 'Mother').toString();
      final int weeks = (motherMap['weeks'] is num)
          ? (motherMap['weeks'] as num).toInt()
          : (int.tryParse(motherMap['weeks']?.toString() ?? '') ?? 38);
      final bool allVitalsWell = motherMap['allVitalsWell'] == true;

      // 1. PartnerSummary
      final summary = PartnerSummary(
        week: weeks,
        totalWeeks: 40,
        allVitalsWell: allVitalsWell,
      );

      // 2. EmergencyPlan
      final List<EmergencyContact> contacts = <EmergencyContact>[];

      final contactPerson = emergencyMap['contactPerson']?.toString() ?? '';
      final contactPhone = emergencyMap['contactPhone']?.toString() ?? '';
      if (contactPerson.isNotEmpty) {
        contacts.add(
          EmergencyContact(
            kind: EmergencyContactKind.emergencyPerson,
            name: contactPerson,
            phone: contactPhone,
          ),
        );
      }

      final phm = emergencyMap['phm']?.toString() ?? '';
      if (phm.isNotEmpty) {
        contacts.add(
          EmergencyContact(
            kind: EmergencyContactKind.phm,
            name: phm,
            phone: '1990',
          ),
        );
      }

      final moh = emergencyMap['moh']?.toString() ?? '';
      if (moh.isNotEmpty) {
        contacts.add(
          EmergencyContact(
            kind: EmergencyContactKind.moh,
            name: moh,
          ),
        );
      }

      if (contacts.isEmpty) {
        contacts.addAll(const <EmergencyContact>[
          EmergencyContact(
            kind: EmergencyContactKind.emergencyPerson,
            name: 'Family Emergency Contact',
            phone: '1990',
          ),
          EmergencyContact(
            kind: EmergencyContactKind.phm,
            name: 'Local PHM Midwife',
            phone: '1990',
          ),
        ]);
      }

      final hospName = (deliveryMap['hospital'] ?? 'Base Hospital Rampur').toString();
      final transportName = (deliveryMap['transport'] ?? 'Ambulance / 1990').toString();
      final distance = (deliveryMap['distanceKm'] is num)
          ? (deliveryMap['distanceKm'] as num).toInt()
          : (int.tryParse(deliveryMap['distanceKm']?.toString() ?? '') ?? 12);
      final minutes = (deliveryMap['estMinutes'] is num)
          ? (deliveryMap['estMinutes'] as num).toInt()
          : (int.tryParse(deliveryMap['estMinutes']?.toString() ?? '') ?? 25);

      final logistics = BirthPlanLogistics(
        hospital: hospName,
        transport: transportName,
        distanceKm: distance,
        estMinutes: minutes,
      );

      final emergencyPlan = EmergencyPlan(
        contacts: contacts,
        logistics: logistics,
      );

      // 3. PartnerAgenda
      DateTime apptDate = DateTime.now().add(const Duration(days: 7));
      if (apptMap['date'] != null) {
        apptDate = DateTime.tryParse(apptMap['date'].toString()) ?? apptDate;
      }
      final apptHospital = (apptMap['hospital'] ?? hospName).toString();
      final apptWard = (apptMap['ward'] ?? 'Antenatal Clinic / Labour Room').toString();

      final agenda = PartnerAgenda(
        nextVisit: ClinicAppointment(
          date: apptDate,
          time: const TimeOfDay(hour: 9, minute: 0),
          hospital: apptHospital,
          ward: apptWard,
        ),
      );

      return (
        summary: summary,
        agenda: agenda,
        emergencyPlan: emergencyPlan,
        motherName: motherName,
      );
    } catch (e) {
      debugPrint('Error parsing partner payload: $e');
      return null;
    }
  }
}
