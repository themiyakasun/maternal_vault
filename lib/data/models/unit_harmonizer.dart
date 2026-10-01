import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Preprocessing & Unit Harmonization Layer (Layer 2) for clinical AI models.
///
/// Harmonizes international SI clinical units recorded at Sri Lankan MOH clinics
/// into the training distribution expected by the quantized TFLite tensors:
/// - Blood Glucose: $\text{BS}_{\text{mg/dL}} = \text{BS}_{\text{mmol/L}} \times 18.0$ when $\text{BS} < 20.0$
///   (trained on `30.0–600.0 mg/dL`).
/// - Body Temperature: $T_{^\circ\text{F}} = (T_{^\circ\text{C}} \times 1.8) + 32.0$ when $T < 45.0$
///   (trained on `95.0–106.0 °F`).
class UnitHarmonizer {
  const UnitHarmonizer._();

  /// Minimum and maximum blood glucose bounds (in mg/dL) from model training.
  static const double minTrainingGlucoseMgDl = 30.0;
  static const double maxTrainingGlucoseMgDl = 600.0;

  /// Threshold below which a blood glucose reading is in mmol/L rather than mg/dL.
  static const double mmolThreshold = 20.0;

  /// Threshold below which a body temperature reading is in °C rather than °F.
  static const double celsiusThreshold = 45.0;

  /// Converts blood glucose from mmol/L to mg/dL via `BS_mg/dL = BS_mmol/L * 18.0`
  /// whenever `value < 20.0`, and clamps to the model's `[30.0, 600.0]` mg/dL domain.
  static double harmonizeGlucoseMmolToMgDl(
    double value, {
    bool clampToTrainingRange = true,
  }) {
    final double mgDl = value < mmolThreshold ? value * 18.0 : value;
    if (!clampToTrainingRange) return mgDl;
    return mgDl.clamp(minTrainingGlucoseMgDl, maxTrainingGlucoseMgDl).toDouble();
  }

  /// Converts maternal body temperature from °C to °F via `T_°F = (T_°C * 1.8) + 32.0`
  /// whenever `value < 45.0`.
  static double harmonizeTempCelsiusToFahrenheit(double value) {
    if (value < celsiusThreshold) {
      return (value * 1.8) + 32.0;
    }
    return value;
  }
}

/// Domain value object representing a 6-feature maternal physiological observation
/// with built-in unit harmonization prior to TFLite tensor packing (Chapter 4, Figure 4.3).
@immutable
class VitalSignsObservation {
  const VitalSignsObservation({
    required this.age,
    required this.systolicBp,
    required this.diastolicBp,
    required this.bloodGlucose,
    required this.bodyTemperature,
    required this.heartRate,
  });

  final double age;
  final double systolicBp;
  final double diastolicBp;

  /// Raw blood glucose reading (either in mmol/L if < 20.0, or mg/dL if >= 20.0).
  final double bloodGlucose;

  /// Raw maternal body temperature (either in °C if < 45.0, or °F if >= 45.0).
  final double bodyTemperature;

  /// Maternal resting heart rate in beats per minute (bpm).
  final double heartRate;

  /// Harmonizes [bloodGlucose] from mmol/L to mg/dL (`BS_mmol/L * 18.0` when `< 20.0`).
  double harmonizeGlucoseMmolToMgDl({bool clampToTrainingRange = true}) {
    return UnitHarmonizer.harmonizeGlucoseMmolToMgDl(
      bloodGlucose,
      clampToTrainingRange: clampToTrainingRange,
    );
  }

  /// Harmonizes [bodyTemperature] from °C to °F (`(T_°C * 1.8) + 32.0` when `< 45.0`).
  double harmonizeTempCelsiusToFahrenheit() {
    return UnitHarmonizer.harmonizeTempCelsiusToFahrenheit(bodyTemperature);
  }

  /// Packs the 6 harmonized clinical features into a 1D `Float32List` for the `[1, 6]` TFLite tensor:
  /// `[Age, SystolicBP, DiastolicBP, BS (mg/dL), BodyTemp (°F), HeartRate (bpm)]`.
  Float32List toHarmonizedFloat32Tensor() {
    return Float32List.fromList(<double>[
      age,
      systolicBp,
      diastolicBp,
      harmonizeGlucoseMmolToMgDl(),
      harmonizeTempCelsiusToFahrenheit(),
      heartRate,
    ]);
  }
}
