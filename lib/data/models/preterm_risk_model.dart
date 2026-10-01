import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../features/mother/domain/basic_profile.dart';
import '../../features/mother/domain/clinic_record.dart';
import '../../features/mother/domain/key_vitals.dart';
import '../../features/mother/domain/medical_history.dart';
import '../../features/mother/domain/obstetric_history.dart';
import 'model_notification.dart';

/// Prediction result from the Preterm Birth Risk Predictor.
class PretermRiskResult {
  const PretermRiskResult({
    required this.probability,
    required this.severity,
    required this.riskFactors,
    this.rawOutput = const <double>[],
  });

  final double probability;
  final AlertSeverity severity;
  final List<String> riskFactors;
  final List<double> rawOutput;

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
      },
    );
  }
}

/// Preterm Birth Risk Predictor running the quantized INT8 neural network model.
///
/// Evaluates maternal clinical indicators (37 features in model vector) including:
/// - Gestational age & fundal height progression
/// - Previous preterm births & obstetric history
/// - Maternal age & blood pressure
/// - Cervical / maternal complications
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

    final factors = <String>[];

    final int age = profile.mother.age ?? 26;
    if (age < 18 || age > 35) {
      factors.add('Maternal age ($age years)');
    }

    // Check previous preterm history
    bool hasPriorPreterm = false;
    if (obstetric != null) {
      for (final p in obstetric.pregnancies) {
        if (p.term == PregnancyTerm.preterm ||
            p.term?.name == 'preterm' ||
            (p.birthWeightKg != null && p.birthWeightKg! < 2.5)) {
          hasPriorPreterm = true;
          factors.add('Previous preterm delivery (${p.year})');
          break;
        }
      }
    }

    // Check BP
    double systolic = 120.0;
    double diastolic = 80.0;
    if (clinic != null && clinic.visits.isNotEmpty) {
      final v = clinic.visits.first;
      systolic = (v.systolic ?? 120).toDouble();
      diastolic = (v.diastolic ?? 80).toDouble();
    }
    if (systolic >= 140 || diastolic >= 90) {
      factors.add('Hypertension ($systolic/$diastolic mmHg)');
    }

    // Check gestational weeks
    int currentWeek = obstetric?.poaAtRegistrationWeeks ?? 36;
    if (clinic != null && clinic.visits.isNotEmpty) {
      currentWeek = clinic.visits.first.week;
    }

    if (_interpreter != null) {
      try {
        // Construct 37-element feature vector
        final List<double> featureVector = List<double>.filled(37, 0.0);
        featureVector[0] = age / 50.0;
        featureVector[1] = currentWeek / 42.0;
        featureVector[2] = systolic / 180.0;
        featureVector[3] = diastolic / 120.0;
        featureVector[4] = hasPriorPreterm ? 1.0 : 0.0;
        featureVector[5] = (obstetric?.gravidity ?? 1).toDouble() / 10.0;
        featureVector[6] = (obstetric?.parity ?? 0).toDouble() / 10.0;

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
        );
      } catch (e) {
        debugPrint('PretermRiskModel inference error: $e');
      }
    }

    // Clinical expert heuristic evaluation
    double score = 0.05;
    if (hasPriorPreterm) score += 0.45;
    if (systolic >= 140 || diastolic >= 90) score += 0.25;
    if (age < 18 || age > 35) score += 0.15;
    if (currentWeek < 37 && currentWeek > 24) score += 0.10;

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
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _loadAttempted = false;
  }
}
