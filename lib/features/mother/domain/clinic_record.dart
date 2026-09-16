import 'package:flutter/foundation.dart';

/// How a routine visit read overall — the chip on the visit card.
///
/// Deliberately only two values: the card is a summary, and anything finer than
/// "fine" versus "the midwife wants another look" belongs in the notes rather
/// than in a colour.
enum VisitStatus { normal, review }

/// A urine dipstick result, for both the sugar and the albumin column.
enum UrineReading { nil, trace, plusOne, plusTwo, plusThree }

/// Foetal lie as recorded on the clinic card.
enum FoetalLie { longitudinal, transverse, oblique }

/// Foetal presentation as recorded on the clinic card.
enum FoetalPresentation { cephalic, breech, shoulder }

/// One routine antenatal visit, as written on the clinic card.
///
/// Everything but the week and the date is nullable: not every visit records
/// every row, and a missing fundal height should read as missing rather than as
/// zero.
@immutable
class ClinicVisit {
  const ClinicVisit({
    required this.week,
    required this.date,
    this.status = VisitStatus.normal,
    this.systolic,
    this.diastolic,
    this.weightKg,
    this.fundalHeightCm,
    this.fetalHeartRate,
    this.urineSugar,
    this.urineAlbumin,
    this.pallor,
    this.ankleOedema,
    this.facialOedema,
    this.foetalLie,
    this.foetalPresentation,
    this.engagement,
    this.foetalMovements,
    this.ironFolate,
    this.vitaminC,
    this.calcium,
    this.antimalarials,
    this.foodSupplement,
    this.examinerSignature,
  });

  /// Gestational week at the visit.
  final int week;

  final DateTime date;

  final VisitStatus status;

  /// Blood pressure, kept as the two numbers it is measured as. Rendering joins
  /// them; storing "110/70" as text would make it unsortable and unsummable.
  final int? systolic;
  final int? diastolic;

  final double? weightKg;

  /// Symphysis–fundal height in centimetres.
  final int? fundalHeightCm;

  /// Fetal heart sounds, in beats per minute.
  final int? fetalHeartRate;

  final UrineReading? urineSugar;
  final UrineReading? urineAlbumin;

  /// Clinical signs on physical examination
  final bool? pallor;
  final bool? ankleOedema;
  final bool? facialOedema;
  final FoetalLie? foetalLie;
  final FoetalPresentation? foetalPresentation;
  final bool? engagement;
  final bool? foetalMovements;

  /// Supplements dispensed at this visit
  final bool? ironFolate;
  final bool? vitaminC;
  final bool? calcium;
  final bool? antimalarials;
  final bool? foodSupplement;

  /// Clinic officer designation / signature
  final String? examinerSignature;

  /// "110/70", or null unless both halves were taken — half a blood pressure is
  /// not a reading.
  String? get bloodPressure {
    if (systolic == null || diastolic == null) return null;
    return '$systolic/$diastolic';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'week': week,
      'date': date.toIso8601String(),
      'status': status.name,
      if (systolic != null) 'systolic': systolic,
      if (diastolic != null) 'diastolic': diastolic,
      if (weightKg != null) 'weightKg': weightKg,
      if (fundalHeightCm != null) 'fundalHeightCm': fundalHeightCm,
      if (fetalHeartRate != null) 'fetalHeartRate': fetalHeartRate,
      if (urineSugar != null) 'urineSugar': urineSugar!.name,
      if (urineAlbumin != null) 'urineAlbumin': urineAlbumin!.name,
      if (pallor != null) 'pallor': pallor,
      if (ankleOedema != null) 'ankleOedema': ankleOedema,
      if (facialOedema != null) 'facialOedema': facialOedema,
      if (foetalLie != null) 'foetalLie': foetalLie!.name,
      if (foetalPresentation != null)
        'foetalPresentation': foetalPresentation!.name,
      if (engagement != null) 'engagement': engagement,
      if (foetalMovements != null) 'foetalMovements': foetalMovements,
      if (ironFolate != null) 'ironFolate': ironFolate,
      if (vitaminC != null) 'vitaminC': vitaminC,
      if (calcium != null) 'calcium': calcium,
      if (antimalarials != null) 'antimalarials': antimalarials,
      if (foodSupplement != null) 'foodSupplement': foodSupplement,
      if (examinerSignature != null) 'examinerSignature': examinerSignature,
    };
  }

  factory ClinicVisit.fromJson(Map<String, dynamic> json) {
    return ClinicVisit(
      week: json['week'] as int? ?? 0,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      status:
          VisitStatus.values.asNameMap()[json['status']] ?? VisitStatus.normal,
      systolic: json['systolic'] as int?,
      diastolic: json['diastolic'] as int?,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      fundalHeightCm: json['fundalHeightCm'] as int?,
      fetalHeartRate: json['fetalHeartRate'] as int?,
      urineSugar: json['urineSugar'] != null
          ? UrineReading.values.asNameMap()[json['urineSugar']]
          : null,
      urineAlbumin: json['urineAlbumin'] != null
          ? UrineReading.values.asNameMap()[json['urineAlbumin']]
          : null,
      pallor: json['pallor'] as bool?,
      ankleOedema: json['ankleOedema'] as bool?,
      facialOedema: json['facialOedema'] as bool?,
      foetalLie: json['foetalLie'] != null
          ? FoetalLie.values.asNameMap()[json['foetalLie']]
          : null,
      foetalPresentation: json['foetalPresentation'] != null
          ? FoetalPresentation.values.asNameMap()[json['foetalPresentation']]
          : null,
      engagement: json['engagement'] as bool?,
      foetalMovements: json['foetalMovements'] as bool?,
      ironFolate: json['ironFolate'] as bool?,
      vitaminC: json['vitaminC'] as bool?,
      calcium: json['calcium'] as bool?,
      antimalarials: json['antimalarials'] as bool?,
      foodSupplement: json['foodSupplement'] as bool?,
      examinerSignature: json['examinerSignature'] as String?,
    );
  }
}

/// One plotted measurement: a gestational week and what was measured at it.
@immutable
class GrowthPoint {
  const GrowthPoint({required this.week, required this.value});

  final int week;
  final double value;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'week': week,
      'value': value,
    };
  }

  factory GrowthPoint.fromJson(Map<String, dynamic> json) {
    return GrowthPoint(
      week: json['week'] as int? ?? 0,
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Trimester-specific system examinations from page 4 of the clinic card.
@immutable
class TrimesterSystemExams {
  const TrimesterSystemExams({
    this.cvsTrimester1,
    this.cvsTrimester2,
    this.cvsTrimester3,
    this.respiratory,
    this.breastExam,
  });

  final String? cvsTrimester1;
  final String? cvsTrimester2;
  final String? cvsTrimester3;
  final String? respiratory;
  final String? breastExam;

  TrimesterSystemExams copyWith({
    String? cvsTrimester1,
    String? cvsTrimester2,
    String? cvsTrimester3,
    String? respiratory,
    String? breastExam,
  }) {
    return TrimesterSystemExams(
      cvsTrimester1: cvsTrimester1 ?? this.cvsTrimester1,
      cvsTrimester2: cvsTrimester2 ?? this.cvsTrimester2,
      cvsTrimester3: cvsTrimester3 ?? this.cvsTrimester3,
      respiratory: respiratory ?? this.respiratory,
      breastExam: breastExam ?? this.breastExam,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (cvsTrimester1 != null) 'cvsTrimester1': cvsTrimester1,
      if (cvsTrimester2 != null) 'cvsTrimester2': cvsTrimester2,
      if (cvsTrimester3 != null) 'cvsTrimester3': cvsTrimester3,
      if (respiratory != null) 'respiratory': respiratory,
      if (breastExam != null) 'breastExam': breastExam,
    };
  }

  factory TrimesterSystemExams.fromJson(Map<String, dynamic> json) {
    return TrimesterSystemExams(
      cvsTrimester1: json['cvsTrimester1'] as String?,
      cvsTrimester2: json['cvsTrimester2'] as String?,
      cvsTrimester3: json['cvsTrimester3'] as String?,
      respiratory: json['respiratory'] as String?,
      breastExam: json['breastExam'] as String?,
    );
  }
}

/// Syphilis (VDRL) screening details.
@immutable
class SyphilisScreening {
  const SyphilisScreening({
    this.samplingDate,
    this.resultDate,
    this.result,
    this.referralDate,
  });

  final DateTime? samplingDate;
  final DateTime? resultDate;
  final String? result;
  final DateTime? referralDate;

  SyphilisScreening copyWith({
    DateTime? samplingDate,
    DateTime? resultDate,
    String? result,
    DateTime? referralDate,
  }) {
    return SyphilisScreening(
      samplingDate: samplingDate ?? this.samplingDate,
      resultDate: resultDate ?? this.resultDate,
      result: result ?? this.result,
      referralDate: referralDate ?? this.referralDate,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (samplingDate != null) 'samplingDate': samplingDate!.toIso8601String(),
      if (resultDate != null) 'resultDate': resultDate!.toIso8601String(),
      if (result != null) 'result': result,
      if (referralDate != null) 'referralDate': referralDate!.toIso8601String(),
    };
  }

  factory SyphilisScreening.fromJson(Map<String, dynamic> json) {
    return SyphilisScreening(
      samplingDate: json['samplingDate'] != null
          ? DateTime.tryParse(json['samplingDate'] as String)
          : null,
      resultDate: json['resultDate'] != null
          ? DateTime.tryParse(json['resultDate'] as String)
          : null,
      result: json['result'] as String?,
      referralDate: json['referralDate'] != null
          ? DateTime.tryParse(json['referralDate'] as String)
          : null,
    );
  }
}

/// Laboratory investigations and screening from page 5 of the clinic card.
@immutable
class LabInvestigations {
  const LabInvestigations({
    this.bloodSugar,
    this.haemoglobin,
    this.otherInvestigations,
    this.syphilis = const SyphilisScreening(),
    this.antihelminthicDate,
  });

  final String? bloodSugar;
  final String? haemoglobin;
  final String? otherInvestigations;
  final SyphilisScreening syphilis;
  final DateTime? antihelminthicDate;

  LabInvestigations copyWith({
    String? bloodSugar,
    String? haemoglobin,
    String? otherInvestigations,
    SyphilisScreening? syphilis,
    DateTime? antihelminthicDate,
  }) {
    return LabInvestigations(
      bloodSugar: bloodSugar ?? this.bloodSugar,
      haemoglobin: haemoglobin ?? this.haemoglobin,
      otherInvestigations: otherInvestigations ?? this.otherInvestigations,
      syphilis: syphilis ?? this.syphilis,
      antihelminthicDate: antihelminthicDate ?? this.antihelminthicDate,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (bloodSugar != null) 'bloodSugar': bloodSugar,
      if (haemoglobin != null) 'haemoglobin': haemoglobin,
      if (otherInvestigations != null)
        'otherInvestigations': otherInvestigations,
      'syphilis': syphilis.toJson(),
      if (antihelminthicDate != null)
        'antihelminthicDate': antihelminthicDate!.toIso8601String(),
    };
  }

  factory LabInvestigations.fromJson(Map<String, dynamic> json) {
    return LabInvestigations(
      bloodSugar: json['bloodSugar'] as String?,
      haemoglobin: json['haemoglobin'] as String?,
      otherInvestigations: json['otherInvestigations'] as String?,
      syphilis: json['syphilis'] is Map<String, dynamic>
          ? SyphilisScreening.fromJson(json['syphilis'] as Map<String, dynamic>)
          : const SyphilisScreening(),
      antihelminthicDate: json['antihelminthicDate'] != null
          ? DateTime.tryParse(json['antihelminthicDate'] as String)
          : null,
    );
  }
}

/// Tetanus Toxoid (TT) Immunization records.
@immutable
class TetanusImmunization {
  const TetanusImmunization({
    this.dose1Date,
    this.dose2Date,
    this.dose3Date,
    this.dose4Date,
    this.dose5Date,
  });

  final DateTime? dose1Date;
  final DateTime? dose2Date;
  final DateTime? dose3Date;
  final DateTime? dose4Date;
  final DateTime? dose5Date;

  TetanusImmunization copyWith({
    DateTime? dose1Date,
    DateTime? dose2Date,
    DateTime? dose3Date,
    DateTime? dose4Date,
    DateTime? dose5Date,
  }) {
    return TetanusImmunization(
      dose1Date: dose1Date ?? this.dose1Date,
      dose2Date: dose2Date ?? this.dose2Date,
      dose3Date: dose3Date ?? this.dose3Date,
      dose4Date: dose4Date ?? this.dose4Date,
      dose5Date: dose5Date ?? this.dose5Date,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (dose1Date != null) 'dose1Date': dose1Date!.toIso8601String(),
      if (dose2Date != null) 'dose2Date': dose2Date!.toIso8601String(),
      if (dose3Date != null) 'dose3Date': dose3Date!.toIso8601String(),
      if (dose4Date != null) 'dose4Date': dose4Date!.toIso8601String(),
      if (dose5Date != null) 'dose5Date': dose5Date!.toIso8601String(),
    };
  }

  factory TetanusImmunization.fromJson(Map<String, dynamic> json) {
    return TetanusImmunization(
      dose1Date: json['dose1Date'] != null
          ? DateTime.tryParse(json['dose1Date'] as String)
          : null,
      dose2Date: json['dose2Date'] != null
          ? DateTime.tryParse(json['dose2Date'] as String)
          : null,
      dose3Date: json['dose3Date'] != null
          ? DateTime.tryParse(json['dose3Date'] as String)
          : null,
      dose4Date: json['dose4Date'] != null
          ? DateTime.tryParse(json['dose4Date'] as String)
          : null,
      dose5Date: json['dose5Date'] != null
          ? DateTime.tryParse(json['dose5Date'] as String)
          : null,
    );
  }
}

/// Dental care screening and treatment.
@immutable
class DentalCare {
  const DentalCare({
    this.referralDate,
    this.screenedDate,
    this.treatmentStatus,
  });

  final DateTime? referralDate;
  final DateTime? screenedDate;
  final String? treatmentStatus;

  DentalCare copyWith({
    DateTime? referralDate,
    DateTime? screenedDate,
    String? treatmentStatus,
  }) {
    return DentalCare(
      referralDate: referralDate ?? this.referralDate,
      screenedDate: screenedDate ?? this.screenedDate,
      treatmentStatus: treatmentStatus ?? this.treatmentStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (referralDate != null) 'referralDate': referralDate!.toIso8601String(),
      if (screenedDate != null) 'screenedDate': screenedDate!.toIso8601String(),
      if (treatmentStatus != null) 'treatmentStatus': treatmentStatus,
    };
  }

  factory DentalCare.fromJson(Map<String, dynamic> json) {
    return DentalCare(
      referralDate: json['referralDate'] != null
          ? DateTime.tryParse(json['referralDate'] as String)
          : null,
      screenedDate: json['screenedDate'] != null
          ? DateTime.tryParse(json['screenedDate'] as String)
          : null,
      treatmentStatus: json['treatmentStatus'] as String?,
    );
  }
}

/// Specialist clinic referrals and back referrals.
@immutable
class ClinicReferral {
  const ClinicReferral({
    this.notes,
  });

  final String? notes;

  ClinicReferral copyWith({
    String? notes,
  }) {
    return ClinicReferral(
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (notes != null) 'notes': notes,
    };
  }

  factory ClinicReferral.fromJson(Map<String, dynamic> json) {
    return ClinicReferral(
      notes: json['notes'] as String?,
    );
  }
}

/// Everything the clinic tab shows: the visits behind it, the curves they
/// add up to, and the antenatal care sections.
@immutable
class ClinicRecord {
  const ClinicRecord({
    this.visits = const <ClinicVisit>[],
    this.weightGain = const <GrowthPoint>[],
    this.fundalHeight = const <GrowthPoint>[],
    this.expectedFundalHeight = const <GrowthPoint>[],
    this.systemExams = const TrimesterSystemExams(),
    this.investigations = const LabInvestigations(),
    this.tetanus = const TetanusImmunization(),
    this.dental = const DentalCare(),
    this.referrals = const ClinicReferral(),
  });

  const ClinicRecord.empty() : this();

  ClinicRecord.sample()
    : this(
        visits: <ClinicVisit>[
          ClinicVisit(
            week: 28,
            date: DateTime(2023, 11, 10),
            systolic: 110,
            diastolic: 70,
            weightKg: 69.5,
            fundalHeightCm: 28,
            fetalHeartRate: 142,
            urineSugar: UrineReading.nil,
            urineAlbumin: UrineReading.nil,
            pallor: false,
            ankleOedema: false,
            facialOedema: false,
            foetalLie: FoetalLie.longitudinal,
            foetalPresentation: FoetalPresentation.cephalic,
            engagement: false,
            foetalMovements: true,
            ironFolate: true,
            vitaminC: true,
            calcium: true,
            antimalarials: false,
            foodSupplement: true,
            examinerSignature: 'Dr. K. Silva (MO-MCH)',
          ),
          ClinicVisit(
            week: 24,
            date: DateTime(2023, 10, 12),
            systolic: 110,
            diastolic: 70,
            weightKg: 68,
            fundalHeightCm: 24,
            fetalHeartRate: 140,
            urineSugar: UrineReading.nil,
            urineAlbumin: UrineReading.trace,
            pallor: false,
            ankleOedema: false,
            facialOedema: false,
            foetalLie: FoetalLie.longitudinal,
            foetalPresentation: FoetalPresentation.cephalic,
            engagement: false,
            foetalMovements: true,
            ironFolate: true,
            vitaminC: true,
            calcium: true,
            antimalarials: false,
            foodSupplement: true,
            examinerSignature: 'Dr. K. Silva (MO-MCH)',
          ),
          ClinicVisit(
            week: 20,
            date: DateTime(2023, 9, 15),
            systolic: 112,
            diastolic: 72,
            weightKg: 66.5,
            fundalHeightCm: 20,
            fetalHeartRate: 144,
            urineSugar: UrineReading.nil,
            urineAlbumin: UrineReading.nil,
            pallor: false,
            ankleOedema: false,
            facialOedema: false,
            foetalLie: FoetalLie.longitudinal,
            foetalPresentation: FoetalPresentation.cephalic,
            engagement: false,
            foetalMovements: true,
            ironFolate: true,
            vitaminC: true,
            calcium: true,
            antimalarials: false,
            foodSupplement: true,
            examinerSignature: 'Sister M. Jayawardena (PHM)',
          ),
          ClinicVisit(
            week: 14,
            date: DateTime(2023, 8, 4),
            systolic: 110,
            diastolic: 70,
            weightKg: 65,
            fundalHeightCm: 14,
            fetalHeartRate: 148,
            urineSugar: UrineReading.nil,
            urineAlbumin: UrineReading.nil,
            pallor: false,
            ankleOedema: false,
            facialOedema: false,
            foetalLie: FoetalLie.longitudinal,
            foetalPresentation: FoetalPresentation.cephalic,
            engagement: false,
            foetalMovements: true,
            ironFolate: true,
            vitaminC: true,
            calcium: true,
            antimalarials: false,
            foodSupplement: true,
            examinerSignature: 'Sister M. Jayawardena (PHM)',
          ),
        ],
        weightGain: const <GrowthPoint>[
          GrowthPoint(week: 12, value: 55),
          GrowthPoint(week: 14, value: 65),
          GrowthPoint(week: 16, value: 55.8),
          GrowthPoint(week: 20, value: 66.5),
          GrowthPoint(week: 24, value: 68),
          GrowthPoint(week: 28, value: 69.5),
          GrowthPoint(week: 32, value: 63.6),
          GrowthPoint(week: 36, value: 66.5),
        ],
        fundalHeight: const <GrowthPoint>[
          GrowthPoint(week: 12, value: 11),
          GrowthPoint(week: 14, value: 14),
          GrowthPoint(week: 16, value: 15),
          GrowthPoint(week: 20, value: 20),
          GrowthPoint(week: 24, value: 24),
          GrowthPoint(week: 28, value: 28),
          GrowthPoint(week: 32, value: 32),
          GrowthPoint(week: 36, value: 34.5),
        ],
        expectedFundalHeight: const <GrowthPoint>[
          GrowthPoint(week: 12, value: 8.5),
          GrowthPoint(week: 16, value: 12),
          GrowthPoint(week: 20, value: 16),
          GrowthPoint(week: 24, value: 20),
          GrowthPoint(week: 28, value: 24),
          GrowthPoint(week: 32, value: 28),
          GrowthPoint(week: 36, value: 31),
        ],
        systemExams: const TrimesterSystemExams(
          cvsTrimester1: 'Normal - S1, S2 heard, No murmurs',
          cvsTrimester2: 'Normal - Heart sounds clear',
          cvsTrimester3: 'Normal - Pulse 78 bpm regular',
          respiratory: 'Bilateral vesicular breath sounds, Clear',
          breastExam: 'Normal - No masses or retraction, Nipples everted',
        ),
        investigations: LabInvestigations(
          bloodSugar: 'FBS: 82 mg/dL (12w), OGTT: 112 mg/dL (24w)',
          haemoglobin: '1st Trim: 11.8 g/dL, 3rd Trim: 12.2 g/dL',
          otherInvestigations: 'Blood Group: B Rh Positive, Blood Film for Malaria: Negative',
          syphilis: SyphilisScreening(
            samplingDate: DateTime(2023, 7, 10),
            resultDate: DateTime(2023, 7, 24),
            result: 'VDRL / WR Non-Reactive',
          ),
          antihelminthicDate: DateTime(2023, 9, 15),
        ),
        tetanus: TetanusImmunization(
          dose1Date: DateTime(2023, 8, 4),
          dose2Date: DateTime(2023, 9, 15),
        ),
        dental: DentalCare(
          screenedDate: DateTime(2023, 8, 10),
          treatmentStatus: 'Screening normal, dental scaling completed',
        ),
        referrals: const ClinicReferral(
          notes: 'Referred to Consultant Obstetrician at 24w for anomaly ultrasound - Foetal growth and morphology normal',
        ),
      );

  /// Newest first, the order the cards are read in.
  final List<ClinicVisit> visits;

  /// The mother's weight through the pregnancy.
  final List<GrowthPoint> weightGain;

  /// Measured symphysis–fundal height.
  final List<GrowthPoint> fundalHeight;

  /// The reference curve the measured one is read against. Drawn dashed, and
  /// left empty when there is nothing to compare to.
  final List<GrowthPoint> expectedFundalHeight;

  final TrimesterSystemExams systemExams;
  final LabInvestigations investigations;
  final TetanusImmunization tetanus;
  final DentalCare dental;
  final ClinicReferral referrals;

  ClinicRecord copyWith({
    List<ClinicVisit>? visits,
    List<GrowthPoint>? weightGain,
    List<GrowthPoint>? fundalHeight,
    List<GrowthPoint>? expectedFundalHeight,
    TrimesterSystemExams? systemExams,
    LabInvestigations? investigations,
    TetanusImmunization? tetanus,
    DentalCare? dental,
    ClinicReferral? referrals,
  }) {
    return ClinicRecord(
      visits: visits ?? this.visits,
      weightGain: weightGain ?? this.weightGain,
      fundalHeight: fundalHeight ?? this.fundalHeight,
      expectedFundalHeight: expectedFundalHeight ?? this.expectedFundalHeight,
      systemExams: systemExams ?? this.systemExams,
      investigations: investigations ?? this.investigations,
      tetanus: tetanus ?? this.tetanus,
      dental: dental ?? this.dental,
      referrals: referrals ?? this.referrals,
    );
  }

  /// The record with [visit] in it: the strip gains a card, and each curve gains
  /// a point for whatever that visit actually measured.
  ///
  /// Adding the point here rather than in the screen is what stops the form
  /// looking broken — a visit whose weight never reaches the chart above it reads
  /// as a save that did not take.
  ClinicRecord withVisit(ClinicVisit visit) {
    final double? weight = visit.weightKg;
    final int? height = visit.fundalHeightCm;

    return copyWith(
      // Newest first, which is the order the cards are read in — so a visit
      // entered late for an earlier week still lands in its place.
      visits: <ClinicVisit>[...visits, visit]
        ..sort((ClinicVisit a, ClinicVisit b) => b.date.compareTo(a.date)),
      weightGain: weight == null
          ? null
          : _upsert(weightGain, GrowthPoint(week: visit.week, value: weight)),
      fundalHeight: height == null
          ? null
          : _upsert(
              fundalHeight,
              GrowthPoint(week: visit.week, value: height.toDouble()),
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'visits': visits.map((ClinicVisit v) => v.toJson()).toList(),
      'weightGain': weightGain.map((GrowthPoint g) => g.toJson()).toList(),
      'fundalHeight': fundalHeight.map((GrowthPoint g) => g.toJson()).toList(),
      'expectedFundalHeight':
          expectedFundalHeight.map((GrowthPoint g) => g.toJson()).toList(),
      'systemExams': systemExams.toJson(),
      'investigations': investigations.toJson(),
      'tetanus': tetanus.toJson(),
      'dental': dental.toJson(),
      'referrals': referrals.toJson(),
    };
  }

  factory ClinicRecord.fromJson(Map<String, dynamic> json) {
    return ClinicRecord(
      visits: (json['visits'] as List<dynamic>?)
              ?.map((dynamic e) =>
                  ClinicVisit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ClinicVisit>[],
      weightGain: (json['weightGain'] as List<dynamic>?)
              ?.map((dynamic e) =>
                  GrowthPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <GrowthPoint>[],
      fundalHeight: (json['fundalHeight'] as List<dynamic>?)
              ?.map((dynamic e) =>
                  GrowthPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <GrowthPoint>[],
      expectedFundalHeight: (json['expectedFundalHeight'] as List<dynamic>?)
              ?.map((dynamic e) =>
                  GrowthPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <GrowthPoint>[],
      systemExams: json['systemExams'] is Map<String, dynamic>
          ? TrimesterSystemExams.fromJson(
              json['systemExams'] as Map<String, dynamic>)
          : const TrimesterSystemExams(),
      investigations: json['investigations'] is Map<String, dynamic>
          ? LabInvestigations.fromJson(
              json['investigations'] as Map<String, dynamic>)
          : const LabInvestigations(),
      tetanus: json['tetanus'] is Map<String, dynamic>
          ? TetanusImmunization.fromJson(
              json['tetanus'] as Map<String, dynamic>)
          : const TetanusImmunization(),
      dental: json['dental'] is Map<String, dynamic>
          ? DentalCare.fromJson(json['dental'] as Map<String, dynamic>)
          : const DentalCare(),
      referrals: json['referrals'] is Map<String, dynamic>
          ? ClinicReferral.fromJson(json['referrals'] as Map<String, dynamic>)
          : const ClinicReferral(),
    );
  }
}

/// Ascending by week and one point per week, which is what the chart's axis
/// labels assume.
///
/// A second measurement at a week already plotted replaces the first: a corrected
/// reading is not an extra one, and two points at the same x draw a vertical
/// spike.
List<GrowthPoint> _upsert(List<GrowthPoint> points, GrowthPoint point) {
  return <GrowthPoint>[
    ...points.where((GrowthPoint each) => each.week != point.week),
    point,
  ]..sort((GrowthPoint a, GrowthPoint b) => a.week.compareTo(b.week));
}
