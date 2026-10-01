import 'package:flutter/foundation.dart';

/// The four figures summarised above the profile form.
///
/// Every field is nullable and stays nullable: these come from measurements and
/// tests taken at a clinic, not from anything the mother types on this screen, so
/// until one has happened the honest answer is "not recorded" rather than a zero.
/// The tiles render null as an em-dash.
@immutable
class KeyVitals {
  const KeyVitals({
    this.bloodGroup,
    this.bmi,
    this.heightCm,
    this.allergies,
    this.systolicBp,
    this.diastolicBp,
    this.bloodSugarMgDl,
    this.bodyTempF,
    this.maternalHeartRate,
  });

  /// Nothing measured yet — what a freshly created vault holds.
  const KeyVitals.empty() : this();

  /// Sample vitals for preview or defaults.
  const KeyVitals.sample()
      : this(
          bloodGroup: 'B+',
          bmi: '21.4',
          heightCm: '158',
          allergies: 'None',
          systolicBp: 120.0,
          diastolicBp: 80.0,
          bloodSugarMgDl: 84.0,
          bodyTempF: 98.6,
          maternalHeartRate: 80,
        );

  /// ABO group and rhesus factor, e.g. `O+`. Free text rather than an enum
  /// because it is transcribed from a lab report.
  final String? bloodGroup;

  /// Body mass index, pre-computed. Held as text so the value shown matches the
  /// report it came from rather than being re-rounded here.
  final String? bmi;

  /// Height in centimetres, without the unit — the tile supplies that.
  final String? heightCm;

  /// Known allergies, or a translated "none" once someone has actually asked.
  final String? allergies;

  /// Maternal systolic blood pressure in mmHg.
  final double? systolicBp;

  /// Maternal diastolic blood pressure in mmHg.
  final double? diastolicBp;

  /// Quantitative maternal blood glucose in mg/dL.
  final double? bloodSugarMgDl;

  /// Maternal core body temperature in °F.
  final double? bodyTempF;

  /// Maternal resting heart rate (pulse) in beats per minute (bpm).
  final int? maternalHeartRate;

  KeyVitals copyWith({
    String? bloodGroup,
    String? bmi,
    String? heightCm,
    String? allergies,
    double? systolicBp,
    double? diastolicBp,
    double? bloodSugarMgDl,
    double? bodyTempF,
    int? maternalHeartRate,
  }) {
    return KeyVitals(
      bloodGroup: bloodGroup ?? this.bloodGroup,
      bmi: bmi ?? this.bmi,
      heightCm: heightCm ?? this.heightCm,
      allergies: allergies ?? this.allergies,
      systolicBp: systolicBp ?? this.systolicBp,
      diastolicBp: diastolicBp ?? this.diastolicBp,
      bloodSugarMgDl: bloodSugarMgDl ?? this.bloodSugarMgDl,
      bodyTempF: bodyTempF ?? this.bodyTempF,
      maternalHeartRate: maternalHeartRate ?? this.maternalHeartRate,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'bloodGroup': bloodGroup,
      'bmi': bmi,
      'heightCm': heightCm,
      'allergies': allergies,
      if (systolicBp != null) 'systolicBp': systolicBp,
      if (diastolicBp != null) 'diastolicBp': diastolicBp,
      if (bloodSugarMgDl != null) 'bloodSugarMgDl': bloodSugarMgDl,
      if (bodyTempF != null) 'bodyTempF': bodyTempF,
      if (maternalHeartRate != null) 'maternalHeartRate': maternalHeartRate,
    };
  }

  factory KeyVitals.fromJson(Map<String, dynamic> json) {
    return KeyVitals(
      bloodGroup: json['bloodGroup'] as String?,
      bmi: json['bmi'] as String?,
      heightCm: json['heightCm'] as String?,
      allergies: json['allergies'] as String?,
      systolicBp: (json['systolicBp'] as num?)?.toDouble(),
      diastolicBp: (json['diastolicBp'] as num?)?.toDouble(),
      bloodSugarMgDl: (json['bloodSugarMgDl'] as num?)?.toDouble(),
      bodyTempF: (json['bodyTempF'] as num?)?.toDouble(),
      maternalHeartRate: (json['maternalHeartRate'] as num?)?.toInt(),
    );
  }
}
