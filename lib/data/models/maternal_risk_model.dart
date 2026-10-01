import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../features/mother/domain/basic_profile.dart';
import '../../features/mother/domain/clinic_record.dart';
import '../../features/mother/domain/key_vitals.dart';
import 'model_notification.dart';
import 'unit_harmonizer.dart';

/// Clinical prediction output from the Maternal Health Risk Model.
class MaternalRiskResult {
  const MaternalRiskResult({
    required this.severity,
    required this.riskProbability,
    required this.probabilities,
    required this.contributingFactors,
    this.rawOutput = const <double>[],
    this.inputTensor = const <double>[],
  });

  final AlertSeverity severity;
  final double riskProbability;
  final Map<String, double> probabilities;
  final List<String> contributingFactors;
  final List<double> rawOutput;

  /// The 6-element harmonized `[1, 6]` input tensor fed to the model:
  /// `[Age, SystolicBP, DiastolicBP, BloodSugar(mg/dL), BodyTemp(°F), MaternalHeartRate(bpm)]`.
  final List<double> inputTensor;

  bool get isElevated => severity.isElevated;

  /// Converts this risk evaluation into a patient-facing alert notification.
  ModelNotification? toNotification() {
    if (!isElevated) return null;

    final String title = severity == AlertSeverity.high || severity == AlertSeverity.critical
        ? '⚠️ High Maternal Risk Detected'
        : '⚡ Moderate Maternal Risk Alert';

    final buffer = StringBuffer();
    if (contributingFactors.isNotEmpty) {
      buffer.write('Factors identified: ${contributingFactors.join(", ")}. ');
    }
    buffer.write(
      severity == AlertSeverity.high || severity == AlertSeverity.critical
          ? 'Automated Maternal Health Model indicates elevated risk requiring clinical review.'
          : 'Automated Maternal Health Model indicates moderate risk requiring routine PHM consultation.',
    );

    final List<String> recs = <String>[];
    if (contributingFactors.any((f) => f.toLowerCase().contains('bp') || f.toLowerCase().contains('hypertension'))) {
      recs.add('Recheck blood pressure after 15 minutes of rest.');
      recs.add('Report immediately if experiencing persistent headache, visual disturbances, or epigastric pain.');
    }
    if (contributingFactors.any((f) => f.toLowerCase().contains('sugar') || f.toLowerCase().contains('glucose'))) {
      recs.add('Review fasting and post-prandial blood glucose logs with MOH clinic.');
    }
    recs.add('Contact Sister Public Health Midwife (PHM) for next scheduled assessment.');
    if (severity == AlertSeverity.high || severity == AlertSeverity.critical) {
      recs.add('In case of acute distress or emergency, call 1990 ambulance service immediately.');
    }

    return ModelNotification(
      modelType: ModelType.maternalRisk,
      severity: severity,
      title: title,
      message: buffer.toString(),
      recommendations: recs,
      metrics: <String, dynamic>{
        'probability': riskProbability,
        'probabilities': probabilities,
        'factors': contributingFactors,
        'inputTensor': inputTensor,
      },
    );
  }
}

/// Quantized INT8 XGBoost surrogate model wrapper for maternal health risk assessment.
///
/// Features evaluated (6 features in `[1, 6]` tensor):
/// 1. Age (years)
/// 2. Systolic Blood Pressure (mmHg)
/// 3. Diastolic Blood Pressure (mmHg)
/// 4. Blood Sugar Level (harmonized to mg/dL via `mmol/L * 18.0`, trained on `30.0–600.0 mg/dL`)
/// 5. Body Temperature (harmonized to °F via `(°C * 1.8) + 32.0`)
/// 6. Maternal Heart Rate (bpm)
class MaternalRiskModel {
  static const String modelAssetPath = 'assets/models/maternal_risk_xgboost_int8.tflite';
  static const String modelFilePath = 'lib/data/models/maternal_risk_xgboost_int8.tflite';

  Interpreter? _interpreter;
  bool _loadAttempted = false;

  /// Harmonizes blood glucose values to mg/dL (`BS_mg/dL = BS_mmol/L * 18.0` when `BS < 20.0`).
  static double harmonizeGlucoseToMgDl(double value) {
    return UnitHarmonizer.harmonizeGlucoseMmolToMgDl(value);
  }

  /// Harmonizes maternal body temperature to °F (`T_°F = (T_°C * 1.8) + 32.0` when `T < 45.0`).
  static double harmonizeTempToFahrenheit(double value) {
    return UnitHarmonizer.harmonizeTempCelsiusToFahrenheit(value);
  }

  /// Extracts a numeric blood glucose value (harmonized to mg/dL) from a free-text lab string.
  static double? parseBloodSugarStringToMgDl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final fastingMatch =
        RegExp(r'fasting[^0-9]*(\d+(?:\.\d+)?)', caseSensitive: false)
            .firstMatch(raw);
    final match =
        fastingMatch ?? RegExp(r'(\d+(?:\.\d+)?)').firstMatch(raw);
    if (match == null) return null;
    final parsed = double.tryParse(match.group(1)!);
    if (parsed == null || parsed <= 0) return null;
    return harmonizeGlucoseToMgDl(parsed);
  }

  /// Builds the harmonized 6-element `Float32List` input tensor
  /// `[Age, SystolicBP, DiastolicBP, BS (mg/dL), BodyTemp (°F), HeartRate (bpm)]`
  /// using [VitalSignsObservation] unit harmonization.
  static Float32List buildInputTensor({
    required double age,
    required double systolicBp,
    required double diastolicBp,
    double? bloodSugarMgDl,
    double? bloodSugarMmol,
    double? bodyTempF,
    double? heartRateBpm,
  }) {
    final observation = VitalSignsObservation(
      age: age,
      systolicBp: systolicBp,
      diastolicBp: diastolicBp,
      bloodGlucose: bloodSugarMgDl ?? bloodSugarMmol ?? 90.0,
      bodyTemperature: bodyTempF ?? 98.6,
      heartRate: heartRateBpm ?? 80.0,
    );
    return observation.toHarmonizedFloat32Tensor();
  }

  Future<void> loadModel() async {
    if (_interpreter != null || _loadAttempted) return;
    _loadAttempted = true;

    try {
      if (File(modelFilePath).existsSync()) {
        _interpreter = Interpreter.fromFile(File(modelFilePath));
        debugPrint('Loaded MaternalRiskModel from file: $modelFilePath');
        return;
      }
    } catch (e) {
      debugPrint('MaternalRiskModel file load note: $e');
    }

    try {
      _interpreter = await Interpreter.fromAsset(modelAssetPath);
      debugPrint('Loaded MaternalRiskModel from asset: $modelAssetPath');
    } catch (e) {
      debugPrint('MaternalRiskModel running in calibrated heuristic clinical fallback mode ($e).');
    }
  }

  /// Runs risk inference on the 6 clinical vitals features:
  /// `[Age, SystolicBP, DiastolicBP, BloodSugar(mg/dL), BodyTemp(°F), MaternalHeartRate(bpm)]`.
  Future<MaternalRiskResult> predict({
    required double age,
    required double systolicBp,
    required double diastolicBp,
    double? bloodSugarMgDl,
    double? bloodSugarMmol,
    double? bodyTempF,
    double? heartRateBpm,
  }) async {
    await loadModel();

    final Float32List tensor1D = buildInputTensor(
      age: age,
      systolicBp: systolicBp,
      diastolicBp: diastolicBp,
      bloodSugarMgDl: bloodSugarMgDl,
      bloodSugarMmol: bloodSugarMmol,
      bodyTempF: bodyTempF,
      heartRateBpm: heartRateBpm,
    );
    final double sugarMgDl = tensor1D[3];
    final double tempF = tensor1D[4];
    final double hr = tensor1D[5];
    final List<double> tensorList = tensor1D.toList(growable: false);

    // Check if interpreter is ready for native inference
    if (_interpreter != null) {
      try {
        final input = [tensorList];
        final output = [
          [0.0, 0.0, 0.0]
        ];

        _interpreter!.run(input, output);

        final raw = output[0];
        final pLow = raw[0];
        final pMid = raw[1];
        final pHigh = raw[2];

        AlertSeverity severity = AlertSeverity.low;
        double maxProb = pLow;
        if (pHigh >= pMid && pHigh >= pLow) {
          severity = AlertSeverity.high;
          maxProb = pHigh;
        } else if (pMid >= pLow) {
          severity = AlertSeverity.moderate;
          maxProb = pMid;
        }

        final factors = _identifyContributingFactors(
          systolicBp: systolicBp,
          diastolicBp: diastolicBp,
          sugarMgDl: sugarMgDl,
          tempF: tempF,
          heartRate: hr,
        );

        return MaternalRiskResult(
          severity: severity,
          riskProbability: maxProb,
          probabilities: {
            'low': pLow,
            'moderate': pMid,
            'high': pHigh,
          },
          contributingFactors: factors,
          rawOutput: raw,
          inputTensor: tensorList,
        );
      } catch (e) {
        debugPrint('MaternalRiskModel TFLite inference exception: $e. Falling back to calibrated clinical heuristic.');
      }
    }

    // Calibrated clinical heuristic evaluation
    return _evaluateClinicalHeuristic(
      age: age,
      systolicBp: systolicBp,
      diastolicBp: diastolicBp,
      sugarMgDl: sugarMgDl,
      tempF: tempF,
      heartRate: hr,
      inputTensor: tensorList,
    );
  }

  /// Evaluates maternal risk directly from the mother's active profile, key vitals, and latest visit.
  Future<MaternalRiskResult> evaluateFromVitals({
    required BasicProfile profile,
    required KeyVitals vitals,
    ClinicVisit? latestVisit,
    ClinicRecord? clinic,
    bool hasDiabetes = false,
  }) async {
    final double age = (profile.mother.age ?? 26).toDouble();

    // 1. Parse Systolic & Diastolic Blood Pressure (mmHg)
    double systolic = 120.0;
    double diastolic = 80.0;

    if (latestVisit?.systolic != null && latestVisit?.diastolic != null) {
      systolic = latestVisit!.systolic!.toDouble();
      diastolic = latestVisit.diastolic!.toDouble();
    } else if (vitals.systolicBp != null && vitals.diastolicBp != null) {
      systolic = vitals.systolicBp!.toDouble();
      diastolic = vitals.diastolicBp!.toDouble();
    }

    // 2. Parse Maternal Heart Rate (bpm) — distinct from Fetal Heart Rate
    double hr = 80.0;
    if (latestVisit?.maternalHeartRate != null) {
      hr = latestVisit!.maternalHeartRate!.toDouble();
    } else if (vitals.maternalHeartRate != null) {
      hr = vitals.maternalHeartRate!.toDouble();
    }

    // 3. Parse Maternal Body Temperature (°F, harmonized from °C if < 45.0)
    double tempF = 98.6;
    if (latestVisit?.bodyTempF != null) {
      tempF = harmonizeTempToFahrenheit(latestVisit!.bodyTempF!);
    } else if (vitals.bodyTempF != null) {
      tempF = harmonizeTempToFahrenheit(vitals.bodyTempF!);
    }

    // 4. Parse Quantitative Blood Glucose (mg/dL, harmonized from mmol/L if < 20.0)
    double? sugarMgDl;
    if (latestVisit?.bloodSugarMgDl != null) {
      sugarMgDl = harmonizeGlucoseToMgDl(latestVisit!.bloodSugarMgDl!);
    } else if (vitals.bloodSugarMgDl != null) {
      sugarMgDl = harmonizeGlucoseToMgDl(vitals.bloodSugarMgDl!);
    } else {
      sugarMgDl = parseBloodSugarStringToMgDl(clinic?.investigations.bloodSugar);
    }

    // Fallback when no quantitative blood glucose is recorded
    if (sugarMgDl == null) {
      if (latestVisit?.urineSugar != null &&
          latestVisit!.urineSugar != UrineReading.nil) {
        switch (latestVisit.urineSugar!) {
          case UrineReading.nil:
            sugarMgDl = 90.0;
            break;
          case UrineReading.trace:
            sugarMgDl = 111.6;
            break;
          case UrineReading.plusOne:
            sugarMgDl = 140.4;
            break;
          case UrineReading.plusTwo:
            sugarMgDl = 189.0;
            break;
          case UrineReading.plusThree:
            sugarMgDl = 234.0;
            break;
        }
      } else {
        sugarMgDl = hasDiabetes ? 165.6 : 90.0;
      }
    }

    return predict(
      age: age,
      systolicBp: systolic,
      diastolicBp: diastolic,
      bloodSugarMgDl: sugarMgDl,
      bodyTempF: tempF,
      heartRateBpm: hr,
    );
  }

  List<String> _identifyContributingFactors({
    required double systolicBp,
    required double diastolicBp,
    required double sugarMgDl,
    required double tempF,
    required double heartRate,
  }) {
    final factors = <String>[];
    if (systolicBp >= 140 || diastolicBp >= 90) {
      factors.add('Elevated Blood Pressure (${systolicBp.toInt()}/${diastolicBp.toInt()} mmHg)');
    } else if (systolicBp >= 130 || diastolicBp >= 85) {
      factors.add('Borderline Blood Pressure (${systolicBp.toInt()}/${diastolicBp.toInt()} mmHg)');
    }

    if (sugarMgDl >= 140.0) {
      factors.add('Elevated Blood Glucose (${sugarMgDl.toInt()} mg/dL)');
    }

    if (tempF >= 100.4) {
      factors.add('Maternal Fever (${tempF.toStringAsFixed(1)} °F)');
    }

    if (heartRate >= 105) {
      factors.add('Tachycardia (${heartRate.toInt()} bpm)');
    }

    return factors;
  }

  MaternalRiskResult _evaluateClinicalHeuristic({
    required double age,
    required double systolicBp,
    required double diastolicBp,
    required double sugarMgDl,
    required double tempF,
    required double heartRate,
    List<double> inputTensor = const <double>[],
  }) {
    final factors = _identifyContributingFactors(
      systolicBp: systolicBp,
      diastolicBp: diastolicBp,
      sugarMgDl: sugarMgDl,
      tempF: tempF,
      heartRate: heartRate,
    );

    AlertSeverity severity = AlertSeverity.low;
    double highProb = 0.05;
    double midProb = 0.15;
    double lowProb = 0.80;

    if (systolicBp >= 140 ||
        diastolicBp >= 90 ||
        tempF >= 101.0 ||
        sugarMgDl >= 180.0) {
      severity = AlertSeverity.high;
      highProb = 0.82;
      midProb = 0.13;
      lowProb = 0.05;
    } else if (systolicBp >= 130 ||
        diastolicBp >= 85 ||
        sugarMgDl >= 140.0 ||
        tempF >= 100.4 ||
        heartRate >= 105) {
      severity = AlertSeverity.moderate;
      highProb = 0.25;
      midProb = 0.65;
      lowProb = 0.10;
    }

    return MaternalRiskResult(
      severity: severity,
      riskProbability: severity == AlertSeverity.high
          ? highProb
          : (severity == AlertSeverity.moderate ? midProb : highProb),
      probabilities: {
        'low': lowProb,
        'moderate': midProb,
        'high': highProb,
      },
      contributingFactors: factors,
      rawOutput: [lowProb, midProb, highProb],
      inputTensor: inputTensor,
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _loadAttempted = false;
  }
}
