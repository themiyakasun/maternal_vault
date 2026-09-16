import 'package:flutter/foundation.dart';

/// The yes/no questions asked once, at booking, about the pregnancy's starting
/// conditions.
enum ObstetricScreening {
  consanguinity,
  rubellaImmunization,
  prePregnancyScreening,
  folicAcid,
  subfertility,
}

/// How a past pregnancy was delivered.
enum DeliveryMode { spontaneousVaginal, assistedVaginal, caesarean }

/// How a past pregnancy ended.
enum PregnancyOutcome { alive, stillbirth, neonatalDeath, miscarriage }

/// Where a past delivery fell against 37–42 weeks.
enum PregnancyTerm { preterm, term, postTerm }

enum BabySex { male, female }

/// One line in the past obstetric history.
///
/// Every field but [order] is nullable: these are recalled at a booking visit,
/// often years later, and a record that insists on a birth weight nobody
/// remembers gets filled with a guess.
@immutable
class PastPregnancy {
  const PastPregnancy({
    required this.order,
    this.year,
    this.term,
    this.deliveryMode,
    this.outcome,
    this.birthWeightKg,
    this.sex,
    this.ageYears,
    this.placeOfDelivery,
    this.antenatalComplications,
    this.postnatalComplications,
  });

  /// Which pregnancy this was — the G number. 1 is the first.
  final int order;

  /// Year of delivery.
  final int? year;

  final PregnancyTerm? term;
  final DeliveryMode? deliveryMode;
  final PregnancyOutcome? outcome;

  /// Birth weight in kilograms, the unit Sri Lankan clinic records use.
  final double? birthWeightKg;

  final BabySex? sex;

  /// The child's age now, in years. Stored rather than derived: [year] is the
  /// year of birth, not a birthday, so an age computed from it would be a year
  /// out for half of every year.
  final int? ageYears;

  final String? placeOfDelivery;
  final String? antenatalComplications;
  final String? postnatalComplications;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'order': order,
      'year': year,
      'term': term?.name,
      'deliveryMode': deliveryMode?.name,
      'outcome': outcome?.name,
      'birthWeightKg': birthWeightKg,
      'sex': sex?.name,
      'ageYears': ageYears,
      'placeOfDelivery': placeOfDelivery,
      'antenatalComplications': antenatalComplications,
      'postnatalComplications': postnatalComplications,
    };
  }

  factory PastPregnancy.fromJson(Map<String, dynamic> json) {
    PregnancyTerm? term;
    if (json['term'] != null) {
      for (final PregnancyTerm t in PregnancyTerm.values) {
        if (t.name == json['term']) {
          term = t;
          break;
        }
      }
    }
    DeliveryMode? deliveryMode;
    if (json['deliveryMode'] != null) {
      for (final DeliveryMode m in DeliveryMode.values) {
        if (m.name == json['deliveryMode']) {
          deliveryMode = m;
          break;
        }
      }
    }
    PregnancyOutcome? outcome;
    if (json['outcome'] != null) {
      for (final PregnancyOutcome o in PregnancyOutcome.values) {
        if (o.name == json['outcome']) {
          outcome = o;
          break;
        }
      }
    }
    BabySex? sex;
    if (json['sex'] != null) {
      for (final BabySex s in BabySex.values) {
        if (s.name == json['sex']) {
          sex = s;
          break;
        }
      }
    }
    return PastPregnancy(
      order: (json['order'] as num?)?.toInt() ?? 1,
      year: (json['year'] as num?)?.toInt(),
      term: term,
      deliveryMode: deliveryMode,
      outcome: outcome,
      birthWeightKg: (json['birthWeightKg'] as num?)?.toDouble(),
      sex: sex,
      ageYears: (json['ageYears'] as num?)?.toInt(),
      placeOfDelivery: json['placeOfDelivery'] as String?,
      antenatalComplications: json['antenatalComplications'] as String?,
      postnatalComplications: json['postnatalComplications'] as String?,
    );
  }
}

/// The mother's obstetric picture: this pregnancy's numbers and dates, the
/// booking screening answers, and the pregnancies before this one.
@immutable
class ObstetricHistory {
  const ObstetricHistory({
    this.gravidity,
    this.parity,
    this.livingChildren,
    this.youngestChildAgeYears,
    this.poaAtRegistrationWeeks,
    this.screening = const <ObstetricScreening>{},
    this.lastMenstrualPeriod,
    this.expectedDelivery,
    this.ultrasoundExpectedDelivery,
    this.expectedDeliveryPeriod,
    this.quickening,
    this.contraceptiveMethodLastUsed,
    this.riskConditionsAndMorbidities,
    this.pregnancies = const <PastPregnancy>[],
  });

  const ObstetricHistory.empty() : this();

  ObstetricHistory.sample()
    : this(
        gravidity: 2,
        parity: 1,
        livingChildren: 1,
        youngestChildAgeYears: 4,
        poaAtRegistrationWeeks: 8,
        screening: const <ObstetricScreening>{
          ObstetricScreening.rubellaImmunization,
          ObstetricScreening.prePregnancyScreening,
          ObstetricScreening.folicAcid,
        },
        lastMenstrualPeriod: DateTime(2023, 4, 28),
        expectedDelivery: DateTime(2024, 2, 2),
        ultrasoundExpectedDelivery: DateTime(2024, 2, 4),
        expectedDeliveryPeriod: 'Late January - Early February 2024',
        quickening: DateTime(2023, 8, 25),
        contraceptiveMethodLastUsed: 'DMPA (Depo-Provera)',
        riskConditionsAndMorbidities:
            'Previous Lower Segment Caesarean Section (LSCS) in 2020; Rh Positive; No medical morbidities detected.',
        pregnancies: const <PastPregnancy>[
          PastPregnancy(
            order: 1,
            year: 2020,
            term: PregnancyTerm.term,
            deliveryMode: DeliveryMode.caesarean,
            outcome: PregnancyOutcome.alive,
            birthWeightKg: 3.2,
            sex: BabySex.male,
            ageYears: 4,
            placeOfDelivery: 'Teaching Hospital Kandy',
            antenatalComplications: 'None',
            postnatalComplications: 'Uneventful recovery',
          ),
        ],
      );

  /// Total pregnancies including this one.
  final int? gravidity;

  /// Total past births / parity.
  final int? parity;

  /// Children alive now.
  final int? livingChildren;

  final int? youngestChildAgeYears;

  final int? poaAtRegistrationWeeks;

  /// Which screening questions were answered yes.
  final Set<ObstetricScreening> screening;

  /// Last regular menstrual period — what the whole dating of the pregnancy
  /// hangs off.
  final DateTime? lastMenstrualPeriod;

  /// Expected date of delivery, calculated from [lastMenstrualPeriod].
  final DateTime? expectedDelivery;

  /// Expected date of delivery as corrected by a dating scan. Kept beside the
  /// calculated one rather than replacing it: the clinic wants to see both.
  final DateTime? ultrasoundExpectedDelivery;

  final String? expectedDeliveryPeriod;

  /// When the mother first felt the baby move.
  final DateTime? quickening;

  final String? contraceptiveMethodLastUsed;

  final String? riskConditionsAndMorbidities;

  /// Earlier pregnancies, oldest first.
  final List<PastPregnancy> pregnancies;

  bool hasScreening(ObstetricScreening question) => screening.contains(question);

  ObstetricHistory withScreening(
    ObstetricScreening question, {
    required bool present,
  }) {
    final Set<ObstetricScreening> next = <ObstetricScreening>{...screening};
    if (present) {
      next.add(question);
    } else {
      next.remove(question);
    }
    return copyWith(screening: next);
  }

  /// Copy-on-write. Nullable fields take an `Object?` defaulted to a sentinel, so
  /// omitting one leaves it alone while passing null clears it — otherwise a
  /// cleared count would be indistinguishable from an untouched one.
  ObstetricHistory copyWith({
    Object? gravidity = _unset,
    Object? parity = _unset,
    Object? livingChildren = _unset,
    Object? youngestChildAgeYears = _unset,
    Object? poaAtRegistrationWeeks = _unset,
    Set<ObstetricScreening>? screening,
    Object? lastMenstrualPeriod = _unset,
    Object? expectedDelivery = _unset,
    Object? ultrasoundExpectedDelivery = _unset,
    Object? expectedDeliveryPeriod = _unset,
    Object? quickening = _unset,
    Object? contraceptiveMethodLastUsed = _unset,
    Object? riskConditionsAndMorbidities = _unset,
    List<PastPregnancy>? pregnancies,
  }) {
    return ObstetricHistory(
      gravidity: gravidity == _unset ? this.gravidity : gravidity as int?,
      parity: parity == _unset ? this.parity : parity as int?,
      livingChildren: livingChildren == _unset
          ? this.livingChildren
          : livingChildren as int?,
      youngestChildAgeYears: youngestChildAgeYears == _unset
          ? this.youngestChildAgeYears
          : youngestChildAgeYears as int?,
      poaAtRegistrationWeeks: poaAtRegistrationWeeks == _unset
          ? this.poaAtRegistrationWeeks
          : poaAtRegistrationWeeks as int?,
      screening: screening ?? this.screening,
      lastMenstrualPeriod: lastMenstrualPeriod == _unset
          ? this.lastMenstrualPeriod
          : lastMenstrualPeriod as DateTime?,
      expectedDelivery: expectedDelivery == _unset
          ? this.expectedDelivery
          : expectedDelivery as DateTime?,
      ultrasoundExpectedDelivery: ultrasoundExpectedDelivery == _unset
          ? this.ultrasoundExpectedDelivery
          : ultrasoundExpectedDelivery as DateTime?,
      expectedDeliveryPeriod: expectedDeliveryPeriod == _unset
          ? this.expectedDeliveryPeriod
          : expectedDeliveryPeriod as String?,
      quickening: quickening == _unset
          ? this.quickening
          : quickening as DateTime?,
      contraceptiveMethodLastUsed: contraceptiveMethodLastUsed == _unset
          ? this.contraceptiveMethodLastUsed
          : contraceptiveMethodLastUsed as String?,
      riskConditionsAndMorbidities: riskConditionsAndMorbidities == _unset
          ? this.riskConditionsAndMorbidities
          : riskConditionsAndMorbidities as String?,
      pregnancies: pregnancies ?? this.pregnancies,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'gravidity': gravidity,
      'parity': parity,
      'livingChildren': livingChildren,
      'youngestChildAgeYears': youngestChildAgeYears,
      'poaAtRegistrationWeeks': poaAtRegistrationWeeks,
      'screening': screening.map((ObstetricScreening s) => s.name).toList(),
      'lastMenstrualPeriod': lastMenstrualPeriod?.toIso8601String(),
      'expectedDelivery': expectedDelivery?.toIso8601String(),
      'ultrasoundExpectedDelivery':
          ultrasoundExpectedDelivery?.toIso8601String(),
      'expectedDeliveryPeriod': expectedDeliveryPeriod,
      'quickening': quickening?.toIso8601String(),
      'contraceptiveMethodLastUsed': contraceptiveMethodLastUsed,
      'riskConditionsAndMorbidities': riskConditionsAndMorbidities,
      'pregnancies':
          pregnancies.map((PastPregnancy p) => p.toJson()).toList(),
    };
  }

  factory ObstetricHistory.fromJson(Map<String, dynamic> json) {
    final Set<ObstetricScreening> screening = <ObstetricScreening>{};
    final List<dynamic>? rawScreening = json['screening'] as List<dynamic>?;
    if (rawScreening != null) {
      for (final dynamic item in rawScreening) {
        for (final ObstetricScreening s in ObstetricScreening.values) {
          if (s.name == item) {
            screening.add(s);
            break;
          }
        }
      }
    }

    final List<PastPregnancy> pregnancies = <PastPregnancy>[];
    final List<dynamic>? rawPregnancies =
        json['pregnancies'] as List<dynamic>?;
    if (rawPregnancies != null) {
      for (final dynamic item in rawPregnancies) {
        if (item is Map) {
          pregnancies.add(
            PastPregnancy.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return ObstetricHistory(
      gravidity: (json['gravidity'] as num?)?.toInt(),
      parity: (json['parity'] as num?)?.toInt(),
      livingChildren: (json['livingChildren'] as num?)?.toInt(),
      youngestChildAgeYears: (json['youngestChildAgeYears'] as num?)?.toInt(),
      poaAtRegistrationWeeks: (json['poaAtRegistrationWeeks'] as num?)?.toInt(),
      screening: screening,
      lastMenstrualPeriod: json['lastMenstrualPeriod'] != null
          ? DateTime.tryParse(json['lastMenstrualPeriod'] as String)
          : null,
      expectedDelivery: json['expectedDelivery'] != null
          ? DateTime.tryParse(json['expectedDelivery'] as String)
          : null,
      ultrasoundExpectedDelivery: json['ultrasoundExpectedDelivery'] != null
          ? DateTime.tryParse(json['ultrasoundExpectedDelivery'] as String)
          : null,
      expectedDeliveryPeriod: json['expectedDeliveryPeriod'] as String?,
      quickening: json['quickening'] != null
          ? DateTime.tryParse(json['quickening'] as String)
          : null,
      contraceptiveMethodLastUsed:
          json['contraceptiveMethodLastUsed'] as String?,
      riskConditionsAndMorbidities:
          json['riskConditionsAndMorbidities'] as String?,
      pregnancies: pregnancies,
    );
  }
}

/// Stands for "this argument was not passed" in [ObstetricHistory.copyWith].
const Object _unset = Object();


