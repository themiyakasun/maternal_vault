import 'package:flutter/foundation.dart';

/// A condition the mother's blood relatives have had.
///
/// Kept separate from [PersonalCondition] even where the names overlap: "my
/// mother has diabetes" and "I have diabetes" are different clinical facts, and
/// the record has to be able to hold one without implying the other.
enum FamilyCondition {
  diabetesMellitus,
  hypertension,

  /// Thalassaemia, sickle cell, clotting disorders — asked as one question
  /// because the follow-up happens at the clinic, not in this form.
  haematological,
}

/// A condition the mother herself has been diagnosed with or treated for.
enum PersonalCondition {
  diabetes,
  hypertension,
  cardiac,
  renal,

  /// Liver disease.
  hepatic,

  /// Any past operation. Broad on purpose — the detail belongs in a note, not in
  /// a yes/no.
  surgeries,
}

/// What the mother has answered on the history screen.
///
/// Sets rather than a field per condition: adding a condition is then one enum
/// value and one label, instead of a new boolean threaded through the model, the
/// screen and every constructor call. Absent from the set means "not reported" —
/// which for a form nobody has opened yet is the same as unanswered, and that is
/// deliberately not distinguished from "no" here. A clinician reads an unticked
/// box the same way.
@immutable
class MedicalHistory {
  const MedicalHistory({
    this.family = const <FamilyCondition>{},
    this.personal = const <PersonalCondition>{},
  });

  /// Nothing reported.
  const MedicalHistory.empty() : this();

  final Set<FamilyCondition> family;
  final Set<PersonalCondition> personal;

  bool hasFamily(FamilyCondition condition) => family.contains(condition);

  bool hasPersonal(PersonalCondition condition) => personal.contains(condition);

  /// A copy with [condition] reported or withdrawn. Copy-on-write, so the value
  /// handed to a caller can never be mutated behind their back.
  MedicalHistory withFamily(FamilyCondition condition, {required bool present}) {
    final Set<FamilyCondition> next = <FamilyCondition>{...family};
    if (present) {
      next.add(condition);
    } else {
      next.remove(condition);
    }
    return MedicalHistory(family: next, personal: personal);
  }

  /// A copy with [condition] reported or withdrawn.
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
    return MedicalHistory(family: family, personal: next);
  }
}
