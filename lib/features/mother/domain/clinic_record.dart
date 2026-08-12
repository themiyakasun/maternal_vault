import 'package:flutter/foundation.dart';

/// How a routine visit read overall — the chip on the visit card.
///
/// Deliberately only two values: the card is a summary, and anything finer than
/// "fine" versus "the midwife wants another look" belongs in the notes rather
/// than in a colour.
enum VisitStatus { normal, review }

/// A urine dipstick result, for both the sugar and the albumin column.
enum UrineReading { nil, trace, plusOne, plusTwo, plusThree }

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

  /// "110/70", or null unless both halves were taken — half a blood pressure is
  /// not a reading.
  String? get bloodPressure {
    if (systolic == null || diastolic == null) return null;
    return '$systolic/$diastolic';
  }
}

/// One plotted measurement: a gestational week and what was measured at it.
@immutable
class GrowthPoint {
  const GrowthPoint({required this.week, required this.value});

  final int week;
  final double value;
}

/// Everything the clinic tab shows: the visits behind it and the curves they
/// add up to.
@immutable
class ClinicRecord {
  const ClinicRecord({
    this.visits = const <ClinicVisit>[],
    this.weightGain = const <GrowthPoint>[],
    this.fundalHeight = const <GrowthPoint>[],
    this.expectedFundalHeight = const <GrowthPoint>[],
  });

  const ClinicRecord.empty() : this();

  /// A record with something in it, so the tab can be seen the way it will look
  /// in use rather than as two empty frames.
  ///
  /// Not const — [DateTime] has no const constructor — and not built inside the
  /// screen: invented clinical values live at the wiring site, where they are one
  /// line to delete.
  ///
  /// TODO: drop this and the call in main.dart once the record layer can supply
  /// a real record.
  ClinicRecord.sample()
    : this(
        visits: <ClinicVisit>[
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
          ),
        ],
        weightGain: const <GrowthPoint>[
          GrowthPoint(week: 12, value: 55),
          GrowthPoint(week: 16, value: 55.8),
          GrowthPoint(week: 20, value: 57),
          GrowthPoint(week: 24, value: 58.8),
          GrowthPoint(week: 28, value: 61),
          GrowthPoint(week: 32, value: 63.6),
          GrowthPoint(week: 36, value: 66.5),
        ],
        fundalHeight: const <GrowthPoint>[
          GrowthPoint(week: 12, value: 11),
          GrowthPoint(week: 16, value: 15),
          GrowthPoint(week: 20, value: 20),
          GrowthPoint(week: 24, value: 24),
          GrowthPoint(week: 28, value: 28.5),
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

  ClinicRecord copyWith({
    List<ClinicVisit>? visits,
    List<GrowthPoint>? weightGain,
    List<GrowthPoint>? fundalHeight,
    List<GrowthPoint>? expectedFundalHeight,
  }) {
    return ClinicRecord(
      visits: visits ?? this.visits,
      weightGain: weightGain ?? this.weightGain,
      fundalHeight: fundalHeight ?? this.fundalHeight,
      expectedFundalHeight: expectedFundalHeight ?? this.expectedFundalHeight,
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
