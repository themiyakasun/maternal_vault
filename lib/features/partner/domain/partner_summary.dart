import 'package:flutter/foundation.dart';

/// The at-a-glance picture the partner opens to: how far along, and whether the
/// mother is doing well.
///
/// The descriptive lines on the home screen — the baby's size this week, the
/// tips — are content a real build reads per week from the connected record;
/// this holds only the numbers the layout arithmetic needs. [sample] fills in a
/// week-24 demo until that record is wired in.
@immutable
class PartnerSummary {
  const PartnerSummary({
    required this.week,
    this.totalWeeks = 40,
    this.allVitalsWell = true,
  });

  const PartnerSummary.empty() : this(week: 0);

  const PartnerSummary.sample() : this(week: 24);

  /// Weeks of pregnancy so far.
  final int week;

  /// Full term, the denominator of the progress bar.
  final int totalWeeks;

  /// Whether the latest vitals were all in range — drives the reassuring
  /// "Mother's Status" card.
  final bool allVitalsWell;

  /// How far along, 0..1, for the progress bar. Guards a zero denominator.
  double get progress {
    if (totalWeeks <= 0) return 0;
    return (week / totalWeeks).clamp(0.0, 1.0);
  }
}
