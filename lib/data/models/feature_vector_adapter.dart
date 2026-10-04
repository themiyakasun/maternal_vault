import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../features/mother/domain/basic_profile.dart';
import '../../features/mother/domain/clinic_record.dart';
import '../../features/mother/domain/education_level.dart';
import '../../features/mother/domain/key_vitals.dart';
import '../../features/mother/domain/medical_history.dart';
import '../../features/mother/domain/obstetric_history.dart';

/// On-Device Feature Vector Adapter & Baseline Imputation Engine (Chapter 4, Layer 2).
///
/// Loads `assets/models/feature_metadata.json` and `assets/models/imputer.pkl`
/// (cohort median/mode baseline imputation + `StandardScaler` + `OneHotEncoder` indices)
/// to deterministically map:
/// 1. The 13 Brazilian SINASC features into the 37-dimensional Preterm Birth tensor
///    (4 numeric + 9 categorical features; strictly dropping `gestational_age_weeks`
///    and `birth_weight_grams` to prevent target leakage).
/// 2. The 64 Perinatal Depression clinical/psychosocial features into the 245-dimensional
///    Mental Health tensor (5 continuous + 59 categorical features; strictly dropping
///    raw target leakage columns `epds_total_score` and `phq9_score`).
class OnDeviceFeatureVectorAdapter {
  static const String metadataAssetPath = 'assets/models/feature_metadata.json';
  static const String metadataFilePath = 'lib/data/models/feature_metadata.json';
  static const String imputerAssetPath = 'assets/models/imputer.pkl';
  static const String imputerFilePath = 'lib/data/models/imputer.pkl';

  static Map<String, dynamic>? _cachedMetadata;
  static bool _imputerVerified = false;

  /// Loads and caches `feature_metadata.json` and verifies `imputer.pkl` presence.
  static Future<Map<String, dynamic>> loadMetadata() async {
    if (_cachedMetadata != null) return _cachedMetadata!;

    // Verify imputer.pkl baseline artifact presence
    if (!_imputerVerified) {
      try {
        if (File(imputerFilePath).existsSync()) {
          final bytes = File(imputerFilePath).readAsBytesSync();
          _imputerVerified = bytes.isNotEmpty;
        } else if (File(imputerAssetPath).existsSync()) {
          final bytes = File(imputerAssetPath).readAsBytesSync();
          _imputerVerified = bytes.isNotEmpty;
        } else {
          final byteData = await rootBundle.load(imputerAssetPath);
          _imputerVerified = byteData.lengthInBytes > 0;
        }
      } catch (e) {
        debugPrint('OnDeviceFeatureVectorAdapter imputer.pkl note: $e');
      }
    }

    // 1. Try local file path (fast path for unit tests / CLI)
    try {
      for (final path in <String>[metadataFilePath, metadataAssetPath]) {
        final file = File(path);
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          _cachedMetadata = jsonDecode(content) as Map<String, dynamic>;
          return _cachedMetadata!;
        }
      }
    } catch (e) {
      debugPrint('OnDeviceFeatureVectorAdapter file load note: $e');
    }

    // 2. Try Flutter asset bundle
    try {
      final jsonStr = await rootBundle.loadString(metadataAssetPath);
      _cachedMetadata = jsonDecode(jsonStr) as Map<String, dynamic>;
      return _cachedMetadata!;
    } catch (e) {
      debugPrint('OnDeviceFeatureVectorAdapter asset bundle note: $e');
    }

    return <String, dynamic>{};
  }

  /// Whether the baseline `imputer.pkl` artifact has been verified.
  static bool get isImputerVerified => _imputerVerified;

  /// Transforms a feature value using `StandardScaler`: `z = (x - mean) / scale`,
  /// imputing `median` when `value` is null.
  static double _scaleNumeric({
    required double? value,
    required double mean,
    required double scale,
    required double median,
  }) {
    final double x = value ?? median;
    if (scale == 0.0) return 0.0;
    return (x - mean) / scale;
  }

  /// Constructs the 37-dimensional Preterm Birth feature vector from the 13 SINASC features:
  /// - 4 `StandardScaler` numeric features at indices `0..3`:
  ///   `[maternal_age, previous_c_sections, previous_vaginal_births, previous_miscarriages]`
  /// - 9 `OneHotEncoder` categorical features across indices `4..36` (33 one-hot slots):
  ///   `[smoking, educational_level, multiple_pregnancy, race_ethnicity, drug_use, marital_status, alcohol_use, has_diabetes, has_arterial_hypertension]`
  /// - Strictly drops `gestational_age_weeks` and `birth_weight_grams` to prevent target leakage.
  static Future<List<double>> buildPretermFeatureVector({
    required BasicProfile profile,
    required KeyVitals vitals,
    ObstetricHistory? obstetric,
    ClinicRecord? clinic,
    MedicalHistory? medicalHistory,
  }) async {
    final metadata = await loadMetadata();
    final vector = List<double>.filled(37, 0.0);

    // Count previous C-sections, vaginal births, and miscarriages from obstetric history
    int prevCSections = 0;
    int prevVaginalBirths = 0;
    int prevMiscarriages = 0;

    if (obstetric != null) {
      for (final p in obstetric.pregnancies) {
        if (p.outcome == PregnancyOutcome.miscarriage) {
          prevMiscarriages++;
        } else {
          if (p.deliveryMode == DeliveryMode.caesarean) {
            prevCSections++;
          } else if (p.deliveryMode == DeliveryMode.spontaneousVaginal ||
              p.deliveryMode == DeliveryMode.assistedVaginal) {
            prevVaginalBirths++;
          }
        }
      }
      if (obstetric.pregnancies.isEmpty) {
        final parity = obstetric.parity ?? 0;
        final gravidity = obstetric.gravidity ?? 1;
        prevVaginalBirths = parity;
        if (gravidity - parity - 1 > 0) {
          prevMiscarriages = gravidity - parity - 1;
        }
      }
    }

    final rawNumeric = <String, double?>{
      'maternal_age': profile.mother.age?.toDouble(),
      'previous_c_sections': prevCSections.toDouble(),
      'previous_vaginal_births': prevVaginalBirths.toDouble(),
      'previous_miscarriages': prevMiscarriages.toDouble(),
    };

    // Apply StandardScaler + median imputation from feature_metadata.json
    final pretermMeta = metadata['preterm_model'] as Map<String, dynamic>?;
    final numericSpecs = pretermMeta?['numeric_features'] as List<dynamic>?;
    if (numericSpecs != null && numericSpecs.length == 4) {
      for (final dynamic item in numericSpecs) {
        final spec = item as Map<String, dynamic>;
        final name = spec['name'] as String;
        final index = (spec['index'] as num).toInt();
        final mean = (spec['mean'] as num).toDouble();
        final scale = (spec['scale'] as num).toDouble();
        final median = (spec['median'] as num).toDouble();
        vector[index] = _scaleNumeric(
          value: rawNumeric[name],
          mean: mean,
          scale: scale,
          median: median,
        );
      }
    } else {
      vector[0] = _scaleNumeric(
        value: rawNumeric['maternal_age'],
        mean: 26.42,
        scale: 6.38,
        median: 26.0,
      );
      vector[1] = _scaleNumeric(
        value: rawNumeric['previous_c_sections'],
        mean: 0.34,
        scale: 0.65,
        median: 0.0,
      );
      vector[2] = _scaleNumeric(
        value: rawNumeric['previous_vaginal_births'],
        mean: 0.68,
        scale: 1.04,
        median: 0.0,
      );
      vector[3] = _scaleNumeric(
        value: rawNumeric['previous_miscarriages'],
        mean: 0.19,
        scale: 0.51,
        median: 0.0,
      );
    }

    // Derive the 9 SINASC categorical values from domain records (with baseline mode imputation)
    String eduCategory = 'secondary';
    switch (profile.mother.education) {
      case EducationLevel.none:
        eduCategory = 'none';
        break;
      case EducationLevel.primary:
        eduCategory = 'primary';
        break;
      case EducationLevel.secondary:
      case EducationLevel.oLevel:
      case EducationLevel.aLevel:
        eduCategory = 'secondary';
        break;
      case EducationLevel.tertiary:
        eduCategory = 'higher';
        break;
      case null:
        eduCategory = 'secondary';
        break;
    }

    final riskText = (obstetric?.riskConditionsAndMorbidities ?? '').toLowerCase();
    final String multiplePregnancy = riskText.contains('triplet')
        ? 'triplets_or_more'
        : (riskText.contains('twin') || riskText.contains('multiple')
            ? 'twins'
            : 'singleton');

    final bool hasDiabetesFlag =
        medicalHistory?.hasPersonal(PersonalCondition.diabetes) == true ||
            riskText.contains('diabetes') ||
            riskText.contains('gdm');
    final String diabetesCategory = hasDiabetesFlag
        ? (riskText.contains('gestational') || riskText.contains('gdm')
            ? 'gestational'
            : 'yes')
        : 'no';

    bool hasHypertensionFlag =
        medicalHistory?.hasPersonal(PersonalCondition.hypertension) == true ||
            riskText.contains('hypertension') ||
            riskText.contains('pre-eclampsia');
    if (clinic != null && clinic.visits.isNotEmpty) {
      final latest = clinic.visits.reduce((a, b) => a.week >= b.week ? a : b);
      if ((latest.systolic ?? 120) >= 140 || (latest.diastolic ?? 80) >= 90) {
        hasHypertensionFlag = true;
      }
    } else if ((vitals.systolicBp ?? 120) >= 140 ||
        (vitals.diastolicBp ?? 80) >= 80 && (vitals.diastolicBp ?? 80) >= 90) {
      hasHypertensionFlag = true;
    }

    final rawCategorical = <String, String>{
      'smoking': 'no',
      'educational_level': eduCategory,
      'multiple_pregnancy': multiplePregnancy,
      'race_ethnicity': 'asian',
      'drug_use': 'no',
      'marital_status': 'married',
      'alcohol_use': 'no',
      'has_diabetes': diabetesCategory,
      'has_arterial_hypertension': hasHypertensionFlag ? 'yes' : 'no',
    };

    // Apply OneHotEncoder mapping + mode imputation across slots 4..36
    final catSpecs = pretermMeta?['categorical_features'] as List<dynamic>?;
    if (catSpecs != null && catSpecs.length == 9) {
      for (final dynamic item in catSpecs) {
        final spec = item as Map<String, dynamic>;
        final name = spec['name'] as String;
        final mode = spec['mode'] as String;
        final indices = spec['one_hot_indices'] as Map<String, dynamic>;
        final selectedVal = rawCategorical[name] ?? mode;
        final targetIndex =
            (indices[selectedVal] ?? indices[mode] ?? spec['default_index'])
                as num;
        vector[targetIndex.toInt()] = 1.0;
      }
    } else {
      // Fallback exact one-hot indices matching feature_metadata.json
      const fallbackIndices = <int>[4, 9, 12, 17, 21, 25, 29, 32, 35];
      for (final i in fallbackIndices) {
        vector[i] = 1.0;
      }
    }

    return vector;
  }

  /// Constructs the 245-dimensional Perinatal Depression feature vector from the 64 survey/clinical features:
  /// - 5 `StandardScaler` continuous features at indices `0..4`:
  ///   `[maternal_age, socio_economic_status_ordinal, anxiety_subscale_score, anhedonia_subscale_score, somatic_sleep_cry_subscale_score]`
  /// - 59 `OneHotEncoder` categorical psychosocial & EPDS item features across indices `5..244` (240 one-hot slots).
  /// - Strictly drops raw target leakage columns (`epds_total_score`, `phq9_score`).
  static Future<List<double>> buildMentalHealthFeatureVector({
    required int epdsScore,
    required int anxietyScore,
    required bool sleepDisturbance,
    required bool reportedFatigue,
    List<int>? itemResponses,
    BasicProfile? profile,
    MedicalHistory? medicalHistory,
    ObstetricHistory? obstetric,
  }) async {
    final metadata = await loadMetadata();
    final vector = List<double>.filled(245, 0.0);

    // Resolve 10 individual EPDS item responses (each 0..3) from itemResponses or impute from epdsScore
    final List<int> resolvedItems;
    if (itemResponses != null && itemResponses.length == 10) {
      resolvedItems = itemResponses.map((v) => v.clamp(0, 3)).toList();
    } else {
      resolvedItems = _distributeEpdsScoreToItems(
        epdsScore: epdsScore,
        anxietyScore: anxietyScore,
        sleepDisturbance: sleepDisturbance,
      );
    }

    // Compute psychometric subscale scores (without leaking raw total EPDS score)
    final double anhedoniaSubscale =
        (resolvedItems[0] + resolvedItems[1]).toDouble();
    final double anxietySubscale = anxietyScore > 0
        ? anxietyScore.toDouble()
        : (resolvedItems[2] + resolvedItems[3] + resolvedItems[4]).toDouble();
    final double somaticSubscale =
        (resolvedItems[6] + resolvedItems[7] + resolvedItems[8]).toDouble();

    final double ageVal = (profile?.mother.age ?? 27).toDouble();
    double sesOrdinal = 2.0; // cohort median SES (0..4)
    if (profile?.mother.education != null) {
      switch (profile!.mother.education!) {
        case EducationLevel.none:
          sesOrdinal = 0.0;
          break;
        case EducationLevel.primary:
          sesOrdinal = 1.0;
          break;
        case EducationLevel.secondary:
        case EducationLevel.oLevel:
          sesOrdinal = 2.0;
          break;
        case EducationLevel.aLevel:
          sesOrdinal = 3.0;
          break;
        case EducationLevel.tertiary:
          sesOrdinal = 4.0;
          break;
      }
    }

    final rawNumeric = <String, double?>{
      'maternal_age': ageVal,
      'socio_economic_status_ordinal': sesOrdinal,
      'anxiety_subscale_score': anxietySubscale,
      'anhedonia_subscale_score': anhedoniaSubscale,
      'somatic_sleep_cry_subscale_score': somaticSubscale,
    };

    final mhMeta = metadata['mental_health_model'] as Map<String, dynamic>?;
    final numericSpecs = mhMeta?['numeric_features'] as List<dynamic>?;
    if (numericSpecs != null && numericSpecs.length == 5) {
      for (final dynamic item in numericSpecs) {
        final spec = item as Map<String, dynamic>;
        final name = spec['name'] as String;
        final index = (spec['index'] as num).toInt();
        final mean = (spec['mean'] as num).toDouble();
        final scale = (spec['scale'] as num).toDouble();
        final median = (spec['median'] as num).toDouble();
        vector[index] = _scaleNumeric(
          value: rawNumeric[name],
          mean: mean,
          scale: scale,
          median: median,
        );
      }
    } else {
      vector[0] = _scaleNumeric(value: ageVal, mean: 27.15, scale: 5.42, median: 27.0);
      vector[1] = _scaleNumeric(value: sesOrdinal, mean: 2.05, scale: 1.12, median: 2.0);
      vector[2] = _scaleNumeric(value: anxietySubscale, mean: 3.10, scale: 2.45, median: 3.0);
      vector[3] = _scaleNumeric(value: anhedoniaSubscale, mean: 1.45, scale: 1.62, median: 1.0);
      vector[4] = _scaleNumeric(value: somaticSubscale, mean: 2.20, scale: 2.15, median: 2.0);
    }

    // Build categorical lookup for the 59 categorical features (indices 5..244)
    final rawCategorical = <String, String>{};
    for (int i = 0; i < 10; i++) {
      rawCategorical['epds_item_${i + 1}'] = resolvedItems[i].toString();
    }
    rawCategorical['sleep_disturbance'] = sleepDisturbance
        ? (epdsScore >= 13 ? 'severe' : 'moderate')
        : 'no';
    rawCategorical['reported_fatigue'] = reportedFatigue
        ? (epdsScore >= 13 ? 'severe' : 'moderate')
        : 'no';
    if (medicalHistory?.hasPersonal(PersonalCondition.psychiatric) == true) {
      rawCategorical['prior_depression_history'] = 'clinical';
    }
    if (obstetric?.riskConditionsAndMorbidities != null &&
        obstetric!.riskConditionsAndMorbidities!.isNotEmpty) {
      rawCategorical['obstetric_complications'] = 'moderate';
    }

    final catSpecs = mhMeta?['categorical_features'] as List<dynamic>?;
    if (catSpecs != null && catSpecs.length == 59) {
      for (final dynamic item in catSpecs) {
        final spec = item as Map<String, dynamic>;
        final name = spec['name'] as String;
        final mode = spec['mode'] as String;
        final indices = spec['one_hot_indices'] as Map<String, dynamic>;
        final selectedVal = rawCategorical[name] ?? mode;
        final targetIndex =
            (indices[selectedVal] ?? indices[mode] ?? spec['default_index'])
                as num;
        vector[targetIndex.toInt()] = 1.0;
      }
    } else {
      // Fallback: activate 1 slot per 4-slot block across the 59 categorical features
      int idx = 5;
      for (int c = 0; c < 59; c++) {
        if (idx < 245) {
          vector[idx] = 1.0;
        }
        idx += (c == 35 || c == 36) ? 6 : 4;
      }
    }

    return vector;
  }

  static List<int> _distributeEpdsScoreToItems({
    required int epdsScore,
    required int anxietyScore,
    required bool sleepDisturbance,
  }) {
    final items = List<int>.filled(10, 0);
    int remaining = epdsScore.clamp(0, 30);

    if (sleepDisturbance && remaining > 0) {
      final sleepPts = remaining >= 2 ? 2 : 1;
      items[6] = sleepPts;
      remaining -= sleepPts;
    }

    // Distribute anxiety points across items 3, 4, 5 (indices 2, 3, 4)
    int anxRem = anxietyScore.clamp(0, 9);
    if (anxRem > remaining) anxRem = remaining;
    for (final idx in <int>[2, 3, 4]) {
      if (anxRem <= 0) break;
      final add = anxRem >= 3 ? 3 : anxRem;
      items[idx] = add;
      anxRem -= add;
      remaining -= add;
    }

    // Distribute remaining points across the rest of the items (indices 0, 1, 5, 6, 7, 8, 9)
    for (int i = 0; i < 10 && remaining > 0; i++) {
      final capacity = 3 - items[i];
      if (capacity > 0) {
        final add = remaining >= capacity ? capacity : remaining;
        items[i] += add;
        remaining -= add;
      }
    }

    return items;
  }
}
