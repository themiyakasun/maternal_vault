import 'package:flutter_test/flutter_test.dart';
import 'package:maternal_vault/core/utils/qr_payload_compressor.dart';
import 'package:maternal_vault/features/mother/domain/basic_profile.dart';
import 'package:maternal_vault/features/mother/domain/clinic_record.dart';
import 'package:maternal_vault/features/mother/domain/delivery_plan.dart';
import 'package:maternal_vault/features/mother/domain/key_vitals.dart';
import 'package:maternal_vault/features/mother/domain/obstetric_history.dart';
import 'package:maternal_vault/features/mother/domain/transport_mode.dart';
import 'package:maternal_vault/features/partner/data/services/partner_sync_service.dart';

void main() {
  group('PartnerSyncService Tests', () {
    const profile = BasicProfile(
      motherName: 'Kumari Sandamali Perera',
      registrationNumber: '#6720',
      emergencyContactPerson: 'Sunil Shantha',
      emergencyContactPhone: '077 123 4567',
      clinicName: 'Rampur North Sector 2 Clinic',
      mohArea: 'Rampur MOH',
      phmArea: 'Rampur North Sector 2',
    );

    const vitals = KeyVitals(
      bloodGroup: 'B +ve',
      bmi: '27.4',
      heightCm: '158',
      allergies: 'None known',
    );

    const plan = DeliveryPlan(
      intendedHospital: 'Base Hospital Rampur',
      transportMode: TransportMode.ambulance,
      distanceKm: 12,
      estimatedTimeMinutes: 25,
    );

    final clinic = ClinicRecord(
      visits: [
        ClinicVisit(
          week: 38,
          date: DateTime(2025, 1, 1),
          status: VisitStatus.normal,
          systolic: 120,
          diastolic: 80,
          weightKg: 68.5,
          fundalHeightCm: 38,
          fetalHeartRate: 140,
        ),
      ],
    );

    final obstetric = ObstetricHistory(
      expectedDelivery: DateTime(2025, 1, 17),
      poaAtRegistrationWeeks: 38,
    );

    test('buildPartnerMap produces correct structure and respects privacy', () {
      final map = PartnerSyncService.buildPartnerMap(
        profile: profile,
        vitals: vitals,
        deliveryPlan: plan,
        clinicRecord: clinic,
        obstetricHistory: obstetric,
      );

      expect(map['app'], 'MaternaVault');
      expect(map['type'], 'partner_sync');
      expect(map['mother']['name'], 'Kumari Sandamali Perera');
      expect(map['mother']['weeks'], 38);
      expect(map['mother']['allVitalsWell'], true);
      expect(map['mother']['bloodGroup'], 'B +ve');

      // Emergency logistics
      expect(map['emergency']['contactPerson'], 'Sunil Shantha');
      expect(map['delivery']['hospital'], 'Base Hospital Rampur');
      expect(map['delivery']['transport'], 'ambulance');
      expect(map['delivery']['distanceKm'], 12);
      expect(map['delivery']['estMinutes'], 25);

      // Privacy verification: verify confidential personal details are excluded
      expect(map.containsKey('medicalHistory'), false);
      expect(map.containsKey('surgeries'), false);
      expect(map.containsKey('hiv'), false);
      expect(map.containsKey('syphilis'), false);
    });

    test('generatePartnerQrString and parsePartnerPayload roundtrip cleanly', () {
      final qrString = PartnerSyncService.generatePartnerQrString(
        profile: profile,
        vitals: vitals,
        deliveryPlan: plan,
        clinicRecord: clinic,
        obstetricHistory: obstetric,
        compress: false,
      );

      final result = PartnerSyncService.parsePartnerPayload(qrString);
      expect(result, isNotNull);
      expect(result!.motherName, 'Kumari Sandamali Perera');
      expect(result.summary.week, 38);
      expect(result.summary.totalWeeks, 40);
      expect(result.summary.allVitalsWell, true);

      // Emergency plan
      expect(result.emergencyPlan.logistics, isNotNull);
      expect(result.emergencyPlan.logistics!.hospital, 'Base Hospital Rampur');
      expect(result.emergencyPlan.logistics!.distanceKm, 12);
      expect(result.emergencyPlan.logistics!.estMinutes, 25);
      expect(result.emergencyPlan.contacts.any((c) => c.name == 'Sunil Shantha'), true);

      // Agenda
      expect(result.agenda.nextVisit, isNotNull);
      expect(result.agenda.nextVisit!.hospital, 'Base Hospital Rampur');
    });

    test('compressed partner QR roundtrips through decompressor and parser', () {
      final compressedQr = PartnerSyncService.generatePartnerQrString(
        profile: profile,
        vitals: vitals,
        deliveryPlan: plan,
        clinicRecord: clinic,
        obstetricHistory: obstetric,
        compress: true,
      );

      expect(compressedQr.startsWith(QrPayloadCompressor.prefix), true);

      final result = PartnerSyncService.parsePartnerPayload(compressedQr);
      expect(result, isNotNull);
      expect(result!.motherName, 'Kumari Sandamali Perera');
      expect(result.summary.week, 38);
      expect(result.emergencyPlan.logistics!.hospital, 'Base Hospital Rampur');
    });

    test('gzip ultra-fast (MVZ1:GZ:) partner QR roundtrips cleanly', () {
      final gzipQr = PartnerSyncService.generatePartnerQrString(
        profile: profile,
        vitals: vitals,
        deliveryPlan: plan,
        clinicRecord: clinic,
        obstetricHistory: obstetric,
        compress: true,
        useGzip: true,
      );

      expect(gzipQr.startsWith(QrPayloadCompressor.gzipPrefix), true);

      final result = PartnerSyncService.parsePartnerPayload(gzipQr);
      expect(result, isNotNull);
      expect(result!.motherName, 'Kumari Sandamali Perera');
      expect(result.summary.week, 38);
      expect(result.emergencyPlan.logistics!.hospital, 'Base Hospital Rampur');
    });

    test('invalid payload strings return null without throwing exceptions', () {
      expect(PartnerSyncService.parsePartnerPayload(''), isNull);
      expect(PartnerSyncService.parsePartnerPayload('invalid non-json text'), isNull);
      expect(PartnerSyncService.parsePartnerPayload('{"some":"other_json"}'), isNotNull);
    });
  });
}
