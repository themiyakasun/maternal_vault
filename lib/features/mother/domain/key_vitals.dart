import 'package:flutter/foundation.dart';

/// The four figures summarised above the profile form.
///
/// Every field is nullable and stays nullable: these come from measurements and
/// tests taken at a clinic, not from anything the mother types on this screen, so
/// until one has happened the honest answer is "not recorded" rather than a zero.
/// The tiles render null as an em-dash.
@immutable
class KeyVitals {
  const KeyVitals({this.bloodGroup, this.bmi, this.heightCm, this.allergies});

  /// Nothing measured yet — what a freshly created vault holds.
  const KeyVitals.empty() : this();

  /// Sample vitals for preview or defaults.
  const KeyVitals.sample()
      : this(
          bloodGroup: 'B+',
          bmi: '21.4',
          heightCm: '158',
          allergies: 'None',
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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'bloodGroup': bloodGroup,
      'bmi': bmi,
      'heightCm': heightCm,
      'allergies': allergies,
    };
  }

  factory KeyVitals.fromJson(Map<String, dynamic> json) {
    return KeyVitals(
      bloodGroup: json['bloodGroup'] as String?,
      bmi: json['bmi'] as String?,
      heightCm: json['heightCm'] as String?,
      allergies: json['allergies'] as String?,
    );
  }
}
