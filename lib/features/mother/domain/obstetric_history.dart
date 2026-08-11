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
}

/// The mother's obstetric picture: this pregnancy's numbers and dates, the
/// booking screening answers, and the pregnancies before this one.
@immutable
class ObstetricHistory {
  const ObstetricHistory({
    this.gravidity,
    this.livingChildren,
    this.screening = const <ObstetricScreening>{},
    this.lastMenstrualPeriod,
    this.expectedDelivery,
    this.ultrasoundExpectedDelivery,
    this.quickening,
    this.pregnancies = const <PastPregnancy>[],
  });

  const ObstetricHistory.empty() : this();

  /// A record with something in it, so the obstetric tab can be seen the way it
  /// will look in use rather than as four empty fields and an empty-state card.
  ///
  /// Deliberately not built inside the screen: invented medical values live at
  /// the wiring site, where they are one line to delete, and never in the widget
  /// tree where they could outlive the demo. No dates — [DateTime] has no const
  /// constructor, and a const sample is worth more than seeded dates.
  ///
  /// TODO: drop this and the call in main.dart once the record layer can supply
  /// a real record.
  const ObstetricHistory.sample()
    : this(
        gravidity: 2,
        livingChildren: 1,
        screening: const <ObstetricScreening>{
          ObstetricScreening.rubellaImmunization,
          ObstetricScreening.folicAcid,
        },
        pregnancies: const <PastPregnancy>[
          PastPregnancy(
            order: 1,
            year: 2020,
            term: PregnancyTerm.term,
            deliveryMode: DeliveryMode.spontaneousVaginal,
            outcome: PregnancyOutcome.alive,
            birthWeightKg: 3.2,
            sex: BabySex.male,
            ageYears: 4,
          ),
        ],
      );

  /// Total pregnancies including this one.
  final int? gravidity;

  /// Children alive now.
  final int? livingChildren;

  /// Which screening questions were answered yes. A set for the same reason
  /// `MedicalHistory` uses one: another question is one enum value and one ARB
  /// key, not another boolean threaded through every constructor call.
  final Set<ObstetricScreening> screening;

  /// Last regular menstrual period — what the whole dating of the pregnancy
  /// hangs off.
  final DateTime? lastMenstrualPeriod;

  /// Expected date of delivery, calculated from [lastMenstrualPeriod].
  final DateTime? expectedDelivery;

  /// Expected date of delivery as corrected by a dating scan. Kept beside the
  /// calculated one rather than replacing it: the clinic wants to see both.
  final DateTime? ultrasoundExpectedDelivery;

  /// When the mother first felt the baby move.
  final DateTime? quickening;

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
    Object? livingChildren = _unset,
    Set<ObstetricScreening>? screening,
    Object? lastMenstrualPeriod = _unset,
    Object? expectedDelivery = _unset,
    Object? ultrasoundExpectedDelivery = _unset,
    Object? quickening = _unset,
    List<PastPregnancy>? pregnancies,
  }) {
    return ObstetricHistory(
      gravidity: gravidity == _unset ? this.gravidity : gravidity as int?,
      livingChildren: livingChildren == _unset
          ? this.livingChildren
          : livingChildren as int?,
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
      quickening: quickening == _unset
          ? this.quickening
          : quickening as DateTime?,
      pregnancies: pregnancies ?? this.pregnancies,
    );
  }
}

/// Stands for "this argument was not passed" in [ObstetricHistory.copyWith].
const Object _unset = Object();

