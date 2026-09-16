import 'package:flutter/foundation.dart';

/// A condition the mother's blood relatives have had.
///
/// Kept separate from [PersonalCondition] even where the names overlap: "my
/// mother has diabetes" and "I have diabetes" are different clinical facts, and
/// the record has to be able to hold one without implying the other.
enum FamilyCondition {
  diabetesMellitus,
  hypertension,

  /// Thalassaemia, sickle cell, clotting disorders.
  haematological,

  other,
}

/// A condition the mother herself has been diagnosed with or treated for.
enum PersonalCondition {
  diabetes,
  hypertension,
  cardiac,
  renal,
  hepatic,
  psychiatric,
  epilepsy,
  malignancies,
  haematological,
  tuberculosis,
  thyroid,
  bronchialAsthma,
  previousDvt,

  /// Any past operation other than Caesarean (LSCS).
  surgeries,

  socialRiskFactors,
  other,
}

/// What the mother has answered on the history screen.
@immutable
class MedicalHistory {
  const MedicalHistory({
    this.family = const <FamilyCondition>{},
    this.personal = const <PersonalCondition>{},
    this.familyOtherDetails,
    this.personalOtherDetails,
  });

  /// Nothing reported.
  const MedicalHistory.empty() : this();

  final Set<FamilyCondition> family;
  final Set<PersonalCondition> personal;
  final String? familyOtherDetails;
  final String? personalOtherDetails;

  bool hasFamily(FamilyCondition condition) => family.contains(condition);

  bool hasPersonal(PersonalCondition condition) => personal.contains(condition);

  MedicalHistory withFamily(FamilyCondition condition, {required bool present}) {
    final Set<FamilyCondition> next = <FamilyCondition>{...family};
    if (present) {
      next.add(condition);
    } else {
      next.remove(condition);
    }
    return MedicalHistory(
      family: next,
      personal: personal,
      familyOtherDetails: familyOtherDetails,
      personalOtherDetails: personalOtherDetails,
    );
  }

  MedicalHistory withPersonal(
    PersonalCondition condition, {
    required bool present,
  }) {
    final Set<PersonalCondition> next = <PersonalCondition>{...personal};
    if (present) {
      next.add(condition);
    } else {
      next.remove(condition);
    }
    return MedicalHistory(
      family: family,
      personal: next,
      familyOtherDetails: familyOtherDetails,
      personalOtherDetails: personalOtherDetails,
    );
  }

  MedicalHistory copyWith({
    Set<FamilyCondition>? family,
    Set<PersonalCondition>? personal,
    String? familyOtherDetails,
    String? personalOtherDetails,
  }) {
    return MedicalHistory(
      family: family ?? this.family,
      personal: personal ?? this.personal,
      familyOtherDetails: familyOtherDetails ?? this.familyOtherDetails,
      personalOtherDetails: personalOtherDetails ?? this.personalOtherDetails,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'family': family.map((FamilyCondition e) => e.name).toList(),
      'personal': personal.map((PersonalCondition e) => e.name).toList(),
      if (familyOtherDetails != null) 'familyOtherDetails': familyOtherDetails,
      if (personalOtherDetails != null)
        'personalOtherDetails': personalOtherDetails,
    };
  }

  factory MedicalHistory.fromJson(Map<String, dynamic> json) {
    final familyList = (json['family'] as List<dynamic>?)
            ?.map((dynamic e) => FamilyCondition.values.asNameMap()[e.toString()])
            .whereType<FamilyCondition>()
            .toSet() ??
        const <FamilyCondition>{};
    final personalList = (json['personal'] as List<dynamic>?)
            ?.map((dynamic e) =>
                PersonalCondition.values.asNameMap()[e.toString()])
            .whereType<PersonalCondition>()
            .toSet() ??
        const <PersonalCondition>{};
    return MedicalHistory(
      family: familyList,
      personal: personalList,
      familyOtherDetails: json['familyOtherDetails'] as String?,
      personalOtherDetails: json['personalOtherDetails'] as String?,
    );
  }
}

