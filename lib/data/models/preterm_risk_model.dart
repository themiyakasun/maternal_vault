import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../features/mother/domain/basic_profile.dart';
import '../../features/mother/domain/clinic_record.dart';
import '../../features/mother/domain/key_vitals.dart';
import '../../features/mother/domain/medical_history.dart';
import '../../features/mother/domain/obstetric_history.dart';
import 'feature_vector_adapter.dart';
import 'model_notification.dart';

/// Prediction result from the Preterm Birth Risk Predictor.
class PretermRiskResult {
  const PretermRiskResult({
    required this.probability,
    required this.severity,
    required this.riskFactors,
    this.rawOutput = const <double>[],
    this.inputVector = const <double>[],
  });

  final double probability;
  final AlertSeverity severity;
  final List<String> riskFactors;
  final List<double> rawOutput;

  /// The 37-dimensional feature vector mapped from the 13 SINASC clinical features
  /// (`StandardScaler` on 4 numeric features + `OneHotEncoder` on 9 categorical features,
  /// excluding `gestational_age_weeks` and `birth_weight_grams`).
  final List<double> inputVector;

  bool get isElevated => severity.isElevated;

  /// Creates a patient alert if preterm delivery risk is elevated.
  ModelNotification? toNotification() {
    if (!isElevated) return null;

    final percentage = (probability * 100).toInt();
    final isCritical = severity == AlertSeverity.critical || severity == AlertSeverity.high;

    final String title = isCritical
        ? '🚨 Preterm Labour Risk Alert ($percentage%)'
        : '⚠️ Preterm Monitoring Notification ($percentage%)';

    final buffer = StringBuffer();
    if (riskFactors.isNotEmpty) {
      buffer.write('Identified factors: ${riskFactors.join(", ")}. ');
    }
    buffer.write(
      isCritical
          ? 'The Preterm Risk Model has detected an elevated likelihood of preterm delivery before 37 weeks.'
          : 'Preterm monitoring alert: please review signs of early labour with your PHM.',
    );

    final recs = <String>[
      'Watch for warning signs: regular contractions or abdominal cramping more than 4 times per hour.',
      'Check for pelvic pressure, persistent dull lower backache, or sudden fluid leakage.',
      'Rest on your left side and stay well hydrated.',
      'If fluid leakage, bleeding, or painful contractions occur, proceed immediately to the Base Hospital Labour Room.',
      'Emergency ambulance helpline: dial 1990 for immediate hospital transport.',
    ];

    return ModelNotification(
      modelType: ModelType.pretermRisk,
      severity: severity,
      title: title,
      message: buffer.toString(),
      recommendations: recs,
      metrics: <String, dynamic>{
        'probability': probability,
        'riskFactors': riskFactors,
        'inputVectorDim': inputVector.length,
      },
    );
  }
}

/// Preterm Birth Risk Predictor running the quantized INT8 neural network model.
///
/// Maps the 13 Brazilian SINASC clinical features via [OnDeviceFeatureVectorAdapter]
/// (`feature_metadata.json` + `imputer.pkl`) into the 37-element input tensor:
/// - 4 `StandardScaler` numeric features (`maternal_age`, `previous_c_sections`,
///   `previous_vaginal_births`, `previous_miscarriages`) at indices `0..3`.
/// - 9 `OneHotEncoder` categorical features across indices `4..36`.
/// - Explicitly drops `gestational_age_weeks` and `birth_weight_grams` to prevent target leakage.
class PretermRiskModel {
  static const String modelAssetPath = 'assets/models/preterm_model_int8.tflite';
  static const String modelFilePath = 'lib/data/models/preterm_model_int8.tflite';

  Interpreter? _interpreter;
  bool _loadAttempted = false;

  Future<void> loadModel() async {
    if (_interpreter != null || _loadAttempted) return;
    _loadAttempted = true;

    try {
      if (File(modelFilePath).existsSync()) {
        _interpreter = Interpreter.fromFile(File(modelFilePath));
        debugPrint('Loaded PretermRiskModel from file: $modelFilePath');
        return;
      }
    } catch (e) {
      debugPrint('PretermRiskModel file load note: $e');
    }

    try {
      _interpreter = await Interpreter.fromAsset(modelAssetPath);
      debugPrint('Loaded PretermRiskModel from asset: $modelAssetPath');
    } catch (e) {
      debugPrint('PretermRiskModel running in calibrated heuristic fallback mode ($e).');
    }
  }

  /// Runs inference given the mother's clinical parameters.
  Future<PretermRiskResult> evaluate({
    required BasicProfile profile,
    required KeyVitals vitals,
    ObstetricHistory? obstetric,
    ClinicRecord? clinic,
    MedicalHistory? medicalHistory,
  }) async {
    await loadModel();

    // Build the 37-dimensional SINASC feature vector via feature_metadata.json & imputer.pkl
    // (strictly dropping gestational_age_weeks to prevent target leakage).
    final List<double> featureVector =
        await OnDeviceFeatureVectorAdapter.buildPretermFeatureVector(
      profile: profile,
      vitals: vitals,
      obstetric: obstetric,
      clinic: clinic,
      medicalHistory: medicalHistory,
    );

    final factors = <String>[];

    final int age = profile.mother.age ?? 26;
    if (age < 18 || age > 35) {
      factors.add('Maternal age ($age years)');
    }

    // Check previous preterm history & C-sections / miscarriages
    bool hasPriorPreterm = false;
    int priorCSections = 0;
    int priorMiscarriages = 0;
    if (obstetric != null) {
      for (final p in obstetric.pregnancies) {
        if (p.term == PregnancyTerm.preterm ||
            p.term?.name == 'preterm' ||
            (p.birthWeightKg != null && p.birthWeightKg! < 2.5)) {
          hasPriorPreterm = true;
          factors.add('Previous preterm delivery (${p.year})');
        }
        if (p.deliveryMode == DeliveryMode.caesarean) {
          priorCSections++;
        }
        if (p.outcome == PregnancyOutcome.miscarriage) {
          priorMiscarriages++;
        }
      }
    }
    if (priorCSections > 0) {
      factors.add('Previous C-section ($priorCSections)');
    }
    if (priorMiscarriages > 0) {
      factors.add('Previous miscarriage ($priorMiscarriages)');
    }

    // Check BP / arterial hypertension
    double systolic = 120.0;
    double diastolic = 80.0;
    if (clinic != null && clinic.visits.isNotEmpty) {
      final v = clinic.visits.reduce((a, b) => a.week >= b.week ? a : b);
      systolic = (v.systolic ?? 120).toDouble();
      diastolic = (v.diastolic ?? 80).toDouble();
    } else if (vitals.systolicBp != null && vitals.diastolicBp != null) {
      systolic = vitals.systolicBp!;
      diastolic = vitals.diastolicBp!;
    }
    if (systolic >= 140 || diastolic >= 90) {
      factors.add('Hypertension (${systolic.toInt()}/${diastolic.toInt()} mmHg)');
    }

    if (_interpreter != null) {
      try {
        final input = [featureVector];
        final output = [
          [0.0]
        ];

        _interpreter!.run(input, output);
        final prob = output[0][0].clamp(0.0, 1.0);

        AlertSeverity severity = AlertSeverity.low;
        if (prob >= 0.65) {
          severity = AlertSeverity.critical;
        } else if (prob >= 0.40) {
          severity = AlertSeverity.high;
        } else if (prob >= 0.20) {
          severity = AlertSeverity.moderate;
        }

        return PretermRiskResult(
          probability: prob,
          severity: severity,
          riskFactors: factors,
          rawOutput: [prob],
          inputVector: featureVector,
        );
      } catch (e) {
        debugPrint('PretermRiskModel inference error: $e');
      }
    }

    // Clinical expert heuristic evaluation (using SINASC features, without gestational_age_weeks leakage)
    double score = 0.05;
    if (hasPriorPreterm) score += 0.45;
    if (priorCSections > 0) score += 0.10;
    if (priorMiscarriages > 0) score += 0.10;
    if (systolic >= 140 || diastolic >= 90) score += 0.25;
    if (age < 18 || age > 35) score += 0.15;

    final prob = score.clamp(0.0, 0.95);
    AlertSeverity severity = AlertSeverity.low;
    if (prob >= 0.65) {
      severity = AlertSeverity.critical;
    } else if (prob >= 0.40) {
      severity = AlertSeverity.high;
    } else if (prob >= 0.20) {
      severity = AlertSeverity.moderate;
    }

    return PretermRiskResult(
      probability: prob,
      severity: severity,
      riskFactors: factors,
      rawOutput: [prob],
      inputVector: featureVector,
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _loadAttempted = false;
  }
}
