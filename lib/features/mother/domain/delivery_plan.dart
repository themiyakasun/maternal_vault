import 'package:flutter/foundation.dart';

import 'family_planning_method.dart';
import 'obstetric_history.dart';
import 'transport_mode.dart';

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
    this.birthWeightKg,
    this.dateOfBirth,
    this.deliveryMode,
    this.episiotomy = false,
    this.complications,
    this.apgarOneMinute,
    this.apgarFiveMinutes,
    this.familyPlanningMethod,
  });

  const DeliveryPlan.empty() : this();

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

  // --- Family planning ---

  final FamilyPlanningMethod? familyPlanningMethod;
}
