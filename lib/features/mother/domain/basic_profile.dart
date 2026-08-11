import 'package:flutter/foundation.dart';

import 'education_level.dart';

/// One parent's details, as the Personal Information section collects them.
///
/// The same three questions are asked of both parents, so they are one type used
/// twice rather than six fields on the profile — which also means the two
/// sub-forms cannot drift apart.
@immutable
class ParentDetails {
  const ParentDetails({this.age, this.education, this.occupation});

  /// Age in years. Null until entered; the form rejects anything non-numeric or
  /// implausible before it gets here.
  final int? age;

  final EducationLevel? education;

  final String? occupation;
}

/// Everything the Basic Profile form collects.
///
/// A plain value object: the screen builds one on Save and hands it to whoever
/// asked. Nothing here knows how it will be stored, which is deliberate — the
/// record layer does not exist yet.
@immutable
class BasicProfile {
  const BasicProfile({
    required this.motherName,
    this.registrationNumber,
    this.registrationDate,
    this.nationalId,
    this.address,
    this.phoneNumber,
    this.mother = const ParentDetails(),
    this.father = const ParentDetails(),
  });

  /// The only field the form insists on — a record with no name on it is not a
  /// record anyone can use.
  final String motherName;

  /// Clinic-issued number for this pregnancy.
  final String? registrationNumber;

  /// When the pregnancy was registered at the clinic.
  final DateTime? registrationDate;

  final String? nationalId;

  final String? address;

  final String? phoneNumber;

  /// The mother's own age, education and occupation.
  final ParentDetails mother;

  /// The father's.
  final ParentDetails father;
}
