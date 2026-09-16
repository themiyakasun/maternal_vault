import 'package:flutter/foundation.dart';

import 'family_planning_method.dart';
import 'obstetric_history.dart';
import 'transport_mode.dart';

/// 14-point discharge safety checklist from page 8 of the clinic record.
@immutable
class DischargeChecklist {
  const DischargeChecklist({
    this.tempNormal48h = false,
    this.packsChecked = false,
    this.infectionFree = false,
    this.fpDiscussed = false,
    this.dangerSignalsExplained = false,
    this.breastfeedingEstablished = false,
    this.vitAGiven = false,
    this.rubellaGiven = false,
    this.antiDGiven = false,
    this.diagnosisCardIssued = false,
    this.chdrHandedOver = false,
    this.prescriptionIssued = false,
    this.referredToPhm = false,
    this.dischargeDate,
  });

  final bool tempNormal48h;
  final bool packsChecked;
  final bool infectionFree;
  final bool fpDiscussed;
  final bool dangerSignalsExplained;
  final bool breastfeedingEstablished;
  final bool vitAGiven;
  final bool rubellaGiven;
  final bool antiDGiven;
  final bool diagnosisCardIssued;
  final bool chdrHandedOver;
  final bool prescriptionIssued;
  final bool referredToPhm;
  final DateTime? dischargeDate;

  DischargeChecklist copyWith({
    bool? tempNormal48h,
    bool? packsChecked,
    bool? infectionFree,
    bool? fpDiscussed,
    bool? dangerSignalsExplained,
    bool? breastfeedingEstablished,
    bool? vitAGiven,
    bool? rubellaGiven,
    bool? antiDGiven,
    bool? diagnosisCardIssued,
    bool? chdrHandedOver,
    bool? prescriptionIssued,
    bool? referredToPhm,
    DateTime? dischargeDate,
  }) {
    return DischargeChecklist(
      tempNormal48h: tempNormal48h ?? this.tempNormal48h,
      packsChecked: packsChecked ?? this.packsChecked,
      infectionFree: infectionFree ?? this.infectionFree,
      fpDiscussed: fpDiscussed ?? this.fpDiscussed,
      dangerSignalsExplained:
          dangerSignalsExplained ?? this.dangerSignalsExplained,
      breastfeedingEstablished:
          breastfeedingEstablished ?? this.breastfeedingEstablished,
      vitAGiven: vitAGiven ?? this.vitAGiven,
      rubellaGiven: rubellaGiven ?? this.rubellaGiven,
      antiDGiven: antiDGiven ?? this.antiDGiven,
      diagnosisCardIssued: diagnosisCardIssued ?? this.diagnosisCardIssued,
      chdrHandedOver: chdrHandedOver ?? this.chdrHandedOver,
      prescriptionIssued: prescriptionIssued ?? this.prescriptionIssued,
      referredToPhm: referredToPhm ?? this.referredToPhm,
      dischargeDate: dischargeDate ?? this.dischargeDate,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tempNormal48h': tempNormal48h,
      'packsChecked': packsChecked,
      'infectionFree': infectionFree,
      'fpDiscussed': fpDiscussed,
      'dangerSignalsExplained': dangerSignalsExplained,
      'breastfeedingEstablished': breastfeedingEstablished,
      'vitAGiven': vitAGiven,
      'rubellaGiven': rubellaGiven,
      'antiDGiven': antiDGiven,
      'diagnosisCardIssued': diagnosisCardIssued,
      'chdrHandedOver': chdrHandedOver,
      'prescriptionIssued': prescriptionIssued,
      'referredToPhm': referredToPhm,
      if (dischargeDate != null)
        'dischargeDate': dischargeDate!.toIso8601String(),
    };
  }

  factory DischargeChecklist.fromJson(Map<String, dynamic> json) {
    return DischargeChecklist(
      tempNormal48h: json['tempNormal48h'] as bool? ?? false,
      packsChecked: json['packsChecked'] as bool? ?? false,
      infectionFree: json['infectionFree'] as bool? ?? false,
      fpDiscussed: json['fpDiscussed'] as bool? ?? false,
      dangerSignalsExplained: json['dangerSignalsExplained'] as bool? ?? false,
      breastfeedingEstablished:
          json['breastfeedingEstablished'] as bool? ?? false,
      vitAGiven: json['vitAGiven'] as bool? ?? false,
      rubellaGiven: json['rubellaGiven'] as bool? ?? false,
      antiDGiven: json['antiDGiven'] as bool? ?? false,
      diagnosisCardIssued: json['diagnosisCardIssued'] as bool? ?? false,
      chdrHandedOver: json['chdrHandedOver'] as bool? ?? false,
      prescriptionIssued: json['prescriptionIssued'] as bool? ?? false,
      referredToPhm: json['referredToPhm'] as bool? ?? false,
      dischargeDate: json['dischargeDate'] != null
          ? DateTime.tryParse(json['dischargeDate'] as String)
          : null,
    );
  }
}

/// Postpartum field care and postnatal clinic visits from page 9.
@immutable
class PostpartumCare {
  const PostpartumCare({
    this.phmVisitDate,
    this.micronutrientsDate,
    this.postpartumClinicSchedule,
    this.postpartumMorbidities,
  });

  final DateTime? phmVisitDate;
  final DateTime? micronutrientsDate;
  final String? postpartumClinicSchedule;
  final String? postpartumMorbidities;

  PostpartumCare copyWith({
    DateTime? phmVisitDate,
    DateTime? micronutrientsDate,
    String? postpartumClinicSchedule,
    String? postpartumMorbidities,
  }) {
    return PostpartumCare(
      phmVisitDate: phmVisitDate ?? this.phmVisitDate,
      micronutrientsDate: micronutrientsDate ?? this.micronutrientsDate,
      postpartumClinicSchedule:
          postpartumClinicSchedule ?? this.postpartumClinicSchedule,
      postpartumMorbidities:
          postpartumMorbidities ?? this.postpartumMorbidities,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (phmVisitDate != null) 'phmVisitDate': phmVisitDate!.toIso8601String(),
      if (micronutrientsDate != null)
        'micronutrientsDate': micronutrientsDate!.toIso8601String(),
      if (postpartumClinicSchedule != null)
        'postpartumClinicSchedule': postpartumClinicSchedule,
      if (postpartumMorbidities != null)
        'postpartumMorbidities': postpartumMorbidities,
    };
  }

  factory PostpartumCare.fromJson(Map<String, dynamic> json) {
    return PostpartumCare(
      phmVisitDate: json['phmVisitDate'] != null
          ? DateTime.tryParse(json['phmVisitDate'] as String)
          : null,
      micronutrientsDate: json['micronutrientsDate'] != null
          ? DateTime.tryParse(json['micronutrientsDate'] as String)
          : null,
      postpartumClinicSchedule: json['postpartumClinicSchedule'] as String?,
      postpartumMorbidities: json['postpartumMorbidities'] as String?,
    );
  }
}

/// Antenatal classes and IEC educational materials from page 10.
@immutable
class AntenatalEducation {
  const AntenatalEducation({
    this.classTrimester1 = false,
    this.classTrimester2 = false,
    this.classTrimester3 = false,
    this.bookAntenatal = false,
    this.bookBreastfeeding = false,
    this.bookEccd = false,
    this.leafletFp = false,
  });

  final bool classTrimester1;
  final bool classTrimester2;
  final bool classTrimester3;
  final bool bookAntenatal;
  final bool bookBreastfeeding;
  final bool bookEccd;
  final bool leafletFp;

  AntenatalEducation copyWith({
    bool? classTrimester1,
    bool? classTrimester2,
    bool? classTrimester3,
    bool? bookAntenatal,
    bool? bookBreastfeeding,
    bool? bookEccd,
    bool? leafletFp,
  }) {
    return AntenatalEducation(
      classTrimester1: classTrimester1 ?? this.classTrimester1,
      classTrimester2: classTrimester2 ?? this.classTrimester2,
      classTrimester3: classTrimester3 ?? this.classTrimester3,
      bookAntenatal: bookAntenatal ?? this.bookAntenatal,
      bookBreastfeeding: bookBreastfeeding ?? this.bookBreastfeeding,
      bookEccd: bookEccd ?? this.bookEccd,
      leafletFp: leafletFp ?? this.leafletFp,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'classTrimester1': classTrimester1,
      'classTrimester2': classTrimester2,
      'classTrimester3': classTrimester3,
      'bookAntenatal': bookAntenatal,
      'bookBreastfeeding': bookBreastfeeding,
      'bookEccd': bookEccd,
      'leafletFp': leafletFp,
    };
  }

  factory AntenatalEducation.fromJson(Map<String, dynamic> json) {
    return AntenatalEducation(
      classTrimester1: json['classTrimester1'] as bool? ?? false,
      classTrimester2: json['classTrimester2'] as bool? ?? false,
      classTrimester3: json['classTrimester3'] as bool? ?? false,
      bookAntenatal: json['bookAntenatal'] as bool? ?? false,
      bookBreastfeeding: json['bookBreastfeeding'] as bool? ?? false,
      bookEccd: json['bookEccd'] as bool? ?? false,
      leafletFp: json['leafletFp'] as bool? ?? false,
    );
  }
}

/// Everything the Emergency & Delivery plan collects: how the mother will get to
/// hospital, what happened at the birth, and what comes after it.
///
/// A plain value object, like [BasicProfile] — the screen builds one on Save and
/// hands it back. Every field is nullable: a plan made before labour has the
/// emergency half filled and the delivery half empty, and both are valid states.
@immutable
class DeliveryPlan {
  const DeliveryPlan({
    this.intendedHospital,
    this.transportMode,
    this.transportCostEstimate,
    this.distanceKm,
    this.estimatedTimeMinutes,
    this.deliveryHospital,
    this.poaAtDeliveryWeeks,
    this.birthWeightKg,
    this.dateOfBirth,
    this.deliveryMode,
    this.episiotomy = false,
    this.complications,
    this.apgarOneMinute,
    this.apgarFiveMinutes,
    this.apgarTenMinutes,
    this.familyPlanningMethod,
    this.dischargeChecklist = const DischargeChecklist(),
    this.postpartumCare = const PostpartumCare(),
    this.antenatalEducation = const AntenatalEducation(),
  });

  const DeliveryPlan.empty() : this();

  DeliveryPlan.sample()
    : this(
        intendedHospital: 'Teaching Hospital Kandy',
        transportMode: TransportMode.ownVehicle,
        transportCostEstimate: 2500,
        distanceKm: 8,
        estimatedTimeMinutes: 20,
        deliveryHospital: 'Teaching Hospital Kandy',
        poaAtDeliveryWeeks: 39,
        birthWeightKg: 3.2,
        dateOfBirth: DateTime(2024, 1, 28),
        deliveryMode: DeliveryMode.spontaneousVaginal,
        episiotomy: false,
        complications: 'None',
        apgarOneMinute: 9,
        apgarFiveMinutes: 10,
        apgarTenMinutes: 10,
        familyPlanningMethod: FamilyPlanningMethod.iud,
        dischargeChecklist: DischargeChecklist(
          tempNormal48h: true,
          packsChecked: true,
          infectionFree: true,
          fpDiscussed: true,
          dangerSignalsExplained: true,
          breastfeedingEstablished: true,
          vitAGiven: true,
          rubellaGiven: true,
          antiDGiven: false,
          diagnosisCardIssued: true,
          chdrHandedOver: true,
          prescriptionIssued: true,
          referredToPhm: true,
          dischargeDate: DateTime(2024, 1, 30),
        ),
        postpartumCare: PostpartumCare(
          phmVisitDate: DateTime(2024, 1, 31),
          micronutrientsDate: DateTime(2024, 1, 31),
          postpartumClinicSchedule: '2 Weeks (2024-02-11), 6 Weeks (2024-03-10)',
          postpartumMorbidities: 'No fever, lochia normal, uterus well contracted',
        ),
        antenatalEducation: const AntenatalEducation(
          classTrimester1: true,
          classTrimester2: true,
          classTrimester3: true,
          bookAntenatal: true,
          bookBreastfeeding: true,
          bookEccd: true,
          leafletFp: true,
        ),
      );

  // --- Emergency plan ---

  /// Where the mother intends to deliver.
  final String? intendedHospital;

  final TransportMode? transportMode;

  /// Rough cost of that transport, in rupees. Kept as a number so it could be
  /// summed or budgeted against later.
  final int? transportCostEstimate;

  final int? distanceKm;

  final int? estimatedTimeMinutes;

  // --- Delivery summary ---

  final String? deliveryHospital;

  final int? poaAtDeliveryWeeks;

  final double? birthWeightKg;

  final DateTime? dateOfBirth;

  /// Shares the obstetric [DeliveryMode] rather than a parallel enum, so a
  /// caesarean here and a caesarean in the past history read the same word.
  final DeliveryMode? deliveryMode;

  /// Whether an episiotomy was performed. A plain bool — the switch has no third
  /// state, and "not recorded" and "no" read the same for this question.
  final bool episiotomy;

  final String? complications;

  /// Apgar score at one minute, 0–10.
  final int? apgarOneMinute;

  /// Apgar score at five minutes, 0–10.
  final int? apgarFiveMinutes;

  /// Apgar score at ten minutes, 0–10.
  final int? apgarTenMinutes;

  // --- Family planning ---

  final FamilyPlanningMethod? familyPlanningMethod;

  // --- Discharge, Postpartum & Education ---

  final DischargeChecklist dischargeChecklist;
  final PostpartumCare postpartumCare;
  final AntenatalEducation antenatalEducation;

  DeliveryPlan copyWith({
    String? intendedHospital,
    TransportMode? transportMode,
    int? transportCostEstimate,
    int? distanceKm,
    int? estimatedTimeMinutes,
    String? deliveryHospital,
    int? poaAtDeliveryWeeks,
    double? birthWeightKg,
    DateTime? dateOfBirth,
    DeliveryMode? deliveryMode,
    bool? episiotomy,
    String? complications,
    int? apgarOneMinute,
    int? apgarFiveMinutes,
    int? apgarTenMinutes,
    FamilyPlanningMethod? familyPlanningMethod,
    DischargeChecklist? dischargeChecklist,
    PostpartumCare? postpartumCare,
    AntenatalEducation? antenatalEducation,
  }) {
    return DeliveryPlan(
      intendedHospital: intendedHospital ?? this.intendedHospital,
      transportMode: transportMode ?? this.transportMode,
      transportCostEstimate:
          transportCostEstimate ?? this.transportCostEstimate,
      distanceKm: distanceKm ?? this.distanceKm,
      estimatedTimeMinutes: estimatedTimeMinutes ?? this.estimatedTimeMinutes,
      deliveryHospital: deliveryHospital ?? this.deliveryHospital,
      poaAtDeliveryWeeks: poaAtDeliveryWeeks ?? this.poaAtDeliveryWeeks,
      birthWeightKg: birthWeightKg ?? this.birthWeightKg,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      deliveryMode: deliveryMode ?? this.deliveryMode,
      episiotomy: episiotomy ?? this.episiotomy,
      complications: complications ?? this.complications,
      apgarOneMinute: apgarOneMinute ?? this.apgarOneMinute,
      apgarFiveMinutes: apgarFiveMinutes ?? this.apgarFiveMinutes,
      apgarTenMinutes: apgarTenMinutes ?? this.apgarTenMinutes,
      familyPlanningMethod: familyPlanningMethod ?? this.familyPlanningMethod,
      dischargeChecklist: dischargeChecklist ?? this.dischargeChecklist,
      postpartumCare: postpartumCare ?? this.postpartumCare,
      antenatalEducation: antenatalEducation ?? this.antenatalEducation,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (intendedHospital != null) 'intendedHospital': intendedHospital,
      if (transportMode != null) 'transportMode': transportMode!.name,
      if (transportCostEstimate != null)
        'transportCostEstimate': transportCostEstimate,
      if (distanceKm != null) 'distanceKm': distanceKm,
      if (estimatedTimeMinutes != null)
        'estimatedTimeMinutes': estimatedTimeMinutes,
      if (deliveryHospital != null) 'deliveryHospital': deliveryHospital,
      if (poaAtDeliveryWeeks != null) 'poaAtDeliveryWeeks': poaAtDeliveryWeeks,
      if (birthWeightKg != null) 'birthWeightKg': birthWeightKg,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      if (deliveryMode != null) 'deliveryMode': deliveryMode!.name,
      'episiotomy': episiotomy,
      if (complications != null) 'complications': complications,
      if (apgarOneMinute != null) 'apgarOneMinute': apgarOneMinute,
      if (apgarFiveMinutes != null) 'apgarFiveMinutes': apgarFiveMinutes,
      if (apgarTenMinutes != null) 'apgarTenMinutes': apgarTenMinutes,
      if (familyPlanningMethod != null)
        'familyPlanningMethod': familyPlanningMethod!.name,
      'dischargeChecklist': dischargeChecklist.toJson(),
      'postpartumCare': postpartumCare.toJson(),
      'antenatalEducation': antenatalEducation.toJson(),
    };
  }

  factory DeliveryPlan.fromJson(Map<String, dynamic> json) {
    return DeliveryPlan(
      intendedHospital: json['intendedHospital'] as String?,
      transportMode: json['transportMode'] != null
          ? TransportMode.values.asNameMap()[json['transportMode']]
          : null,
      transportCostEstimate: json['transportCostEstimate'] as int?,
      distanceKm: json['distanceKm'] as int?,
      estimatedTimeMinutes: json['estimatedTimeMinutes'] as int?,
      deliveryHospital: json['deliveryHospital'] as String?,
      poaAtDeliveryWeeks: json['poaAtDeliveryWeeks'] as int?,
      birthWeightKg: (json['birthWeightKg'] as num?)?.toDouble(),
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'] as String)
          : null,
      deliveryMode: json['deliveryMode'] != null
          ? DeliveryMode.values.asNameMap()[json['deliveryMode']]
          : null,
      episiotomy: json['episiotomy'] as bool? ?? false,
      complications: json['complications'] as String?,
      apgarOneMinute: json['apgarOneMinute'] as int?,
      apgarFiveMinutes: json['apgarFiveMinutes'] as int?,
      apgarTenMinutes: json['apgarTenMinutes'] as int?,
      familyPlanningMethod: json['familyPlanningMethod'] != null
          ? FamilyPlanningMethod.values
              .asNameMap()[json['familyPlanningMethod']]
          : null,
      dischargeChecklist: json['dischargeChecklist'] is Map<String, dynamic>
          ? DischargeChecklist.fromJson(
              json['dischargeChecklist'] as Map<String, dynamic>)
          : const DischargeChecklist(),
      postpartumCare: json['postpartumCare'] is Map<String, dynamic>
          ? PostpartumCare.fromJson(
              json['postpartumCare'] as Map<String, dynamic>)
          : const PostpartumCare(),
      antenatalEducation: json['antenatalEducation'] is Map<String, dynamic>
          ? AntenatalEducation.fromJson(
              json['antenatalEducation'] as Map<String, dynamic>)
          : const AntenatalEducation(),
    );
  }
}
