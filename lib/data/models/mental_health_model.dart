import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'model_notification.dart';

/// Clinical prediction output from the Perinatal Mental Health Model.
class MentalHealthRiskResult {
  const MentalHealthRiskResult({
    required this.severity,
    required this.score,
    required this.probabilities,
    required this.supportNotes,
    this.rawOutput = const <double>[],
  });

  final AlertSeverity severity;
  final double score;
  final Map<String, double> probabilities;
  final List<String> supportNotes;
  final List<double> rawOutput;

  bool get isElevated => severity.isElevated;

  /// Creates a warm, confidential patient alert notification.
  ModelNotification? toNotification() {
    if (!isElevated) return null;

    final String title = severity == AlertSeverity.high || severity == AlertSeverity.critical
        ? '🌸 Perinatal Wellbeing Alert • Confidential Support'
        : '🌿 Maternal Emotional Wellbeing Notification';

    final buffer = StringBuffer();
    buffer.write(
      severity == AlertSeverity.high || severity == AlertSeverity.critical
          ? 'Your recent wellbeing self-check indicates elevated emotional strain or anxiety. Pregnancy and postpartum involve major hormonal changes, and caring support is available.'
          : 'Emotional wellbeing check: moderate strain or fatigue noted. Remember that taking time for rest and speaking about your feelings is vital.',
    );

    final recs = <String>[
      'Share how you are feeling with your partner, family, or someone you trust.',
      'Speak openly with Sister Public Health Midwife (PHM) during your clinic or home visit.',
      'Sri Lanka National Mental Health Helpline: dial 1926 (24/7 free, confidential counseling).',
      'Prioritize sleep and gentle relaxation whenever possible.',
    ];

    return ModelNotification(
      modelType: ModelType.mentalHealth,
      severity: severity,
      title: title,
      message: buffer.toString(),
      recommendations: recs,
      metrics: <String, dynamic>{
        'score': score,
        'probabilities': probabilities,
        'notes': supportNotes,
      },
    );
  }
}

/// Quantized INT8 model wrapper for Perinatal Mental Health Assessment.
///
/// Features evaluated: 245 input features (survey indicators, emotional wellbeing scale).
class MentalHealthModel {
  static const String modelAssetPath = 'assets/models/mental_health_int8.tflite';
  static const String modelFilePath = 'lib/data/models/mental_health_int8.tflite';

  Interpreter? _interpreter;
  bool _loadAttempted = false;

  Future<void> loadModel() async {
    if (_interpreter != null || _loadAttempted) return;
    _loadAttempted = true;

    try {
      if (File(modelFilePath).existsSync()) {
        _interpreter = Interpreter.fromFile(File(modelFilePath));
        debugPrint('Loaded MentalHealthModel from file: $modelFilePath');
        return;
      }
    } catch (e) {
      debugPrint('MentalHealthModel file load note: $e');
    }

    try {
      _interpreter = await Interpreter.fromAsset(modelAssetPath);
      debugPrint('Loaded MentalHealthModel from asset: $modelAssetPath');
    } catch (e) {
      debugPrint('MentalHealthModel running in calibrated heuristic fallback mode ($e).');
    }
  }

  /// Runs inference on survey responses or clinical anxiety/depression scores.
  Future<MentalHealthRiskResult> evaluate({
    int epdsScore = 0, // Edinburgh Postnatal Depression Scale (0-30)
    int anxietyScore = 0,
    bool sleepDisturbance = false,
    bool reportedFatigue = false,
    List<double>? rawFeatures,
  }) async {
    await loadModel();

    final notes = <String>[];
    if (epdsScore >= 13) {
      notes.add('Elevated EPDS score ($epdsScore/30)');
    } else if (epdsScore >= 10) {
      notes.add('Moderate EPDS score ($epdsScore/30)');
    }
    if (anxietyScore > 5) {
      notes.add('Notable anxiety indicators');
    }
    if (sleepDisturbance) {
      notes.add('Reported sleep disturbance');
    }

    if (_interpreter != null) {
      try {
        final List<double> inputVector = rawFeatures != null && rawFeatures.length == 245
            ? rawFeatures
            : List<double>.filled(245, 0.0);

        if (rawFeatures == null) {
          inputVector[0] = epdsScore / 30.0;
          inputVector[1] = anxietyScore / 10.0;
          inputVector[2] = sleepDisturbance ? 1.0 : 0.0;
          inputVector[3] = reportedFatigue ? 1.0 : 0.0;
        }

        final input = [inputVector];
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

        return MentalHealthRiskResult(
          severity: severity,
          score: maxProb,
          probabilities: {
            'low': pLow,
            'moderate': pMid,
            'high': pHigh,
          },
          supportNotes: notes,
          rawOutput: raw,
        );
      } catch (e) {
        debugPrint('MentalHealthModel inference error: $e');
      }
    }

    // Heuristic assessment based on EPDS guidelines
    AlertSeverity severity = AlertSeverity.low;
    double highProb = 0.05;
    double midProb = 0.15;
    double lowProb = 0.80;

    if (epdsScore >= 13 || anxietyScore >= 8) {
      severity = AlertSeverity.high;
      highProb = 0.85;
      midProb = 0.10;
      lowProb = 0.05;
    } else if (epdsScore >= 10 || anxietyScore >= 5 || sleepDisturbance) {
      severity = AlertSeverity.moderate;
      highProb = 0.20;
      midProb = 0.65;
      lowProb = 0.15;
    }

    return MentalHealthRiskResult(
      severity: severity,
      score: severity == AlertSeverity.high ? highProb : (severity == AlertSeverity.moderate ? midProb : lowProb),
      probabilities: {
        'low': lowProb,
        'moderate': midProb,
        'high': highProb,
      },
      supportNotes: notes,
      rawOutput: [lowProb, midProb, highProb],
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _loadAttempted = false;
  }
}
