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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'age': age,
      'education': education?.name,
      'occupation': occupation,
    };
  }

  factory ParentDetails.fromJson(Map<String, dynamic> json) {
    EducationLevel? edu;
    final String? eduStr = json['education'] as String?;
    if (eduStr != null) {
      for (final EducationLevel e in EducationLevel.values) {
        if (e.name == eduStr) {
          edu = e;
          break;
        }
      }
    }
    return ParentDetails(
      age: json['age'] as int?,
      education: edu,
      occupation: json['occupation'] as String?,
    );
  }
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
    this.mohArea,
    this.phmArea,
    this.gramaNiladariDivision,
    this.clinicName,
    this.otherClinics,
    this.eligibleFamilyRegisterNumber,
    this.eligibleFamilyRegisterDate,
    this.emergencyContactPerson,
    this.emergencyContactPhone,
    this.emergencyContactAddress,
    this.mohOfficePhone,
    this.phmPhone,
  });

  const BasicProfile.empty() : this(motherName: '');

  BasicProfile.sample()
    : this(
        motherName: 'Nimali Perera',
        registrationNumber: 'PR/2023/184',
        registrationDate: DateTime(2023, 6, 20),
        nationalId: '199578123456',
        address: 'No. 42, Temple Road, Ampitiya, Kandy',
        phoneNumber: '077 123 4567',
        mother: const ParentDetails(
          age: 28,
          education: EducationLevel.tertiary,
          occupation: 'Teacher',
        ),
        father: const ParentDetails(
          age: 31,
          education: EducationLevel.aLevel,
          occupation: 'Accountant',
        ),
        mohArea: 'Kandy MC',
        phmArea: 'Gangawata Korale Central',
        gramaNiladariDivision: 'Ampitiya South 312',
        clinicName: 'Ampitiya Central MCH Clinic',
        otherClinics: 'Teaching Hospital Kandy Antenatal Clinic',
        eligibleFamilyRegisterNumber: 'EF/2023/412',
        eligibleFamilyRegisterDate: DateTime(2023, 6, 15),
        emergencyContactPerson: 'Sunil Perera (Husband)',
        emergencyContactPhone: '071 987 6543',
        emergencyContactAddress: 'No. 42, Temple Road, Ampitiya, Kandy',
        mohOfficePhone: '081 223 4567',
        phmPhone: '076 543 2109',
      );

  /// The only field the form insists on — a record with no name on it is not a
  /// record anyone can use.
  final String motherName;

  /// Clinic-issued number for this pregnancy (Pregnant Mother's Register).
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

  final String? mohArea;
  final String? phmArea;
  final String? gramaNiladariDivision;
  final String? clinicName;
  final String? otherClinics;
  final String? eligibleFamilyRegisterNumber;
  final DateTime? eligibleFamilyRegisterDate;
  final String? emergencyContactPerson;
  final String? emergencyContactPhone;
  final String? emergencyContactAddress;
  final String? mohOfficePhone;
  final String? phmPhone;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'motherName': motherName,
      'registrationNumber': registrationNumber,
      'registrationDate': registrationDate?.toIso8601String(),
      'nationalId': nationalId,
      'address': address,
      'phoneNumber': phoneNumber,
      'mother': mother.toJson(),
      'father': father.toJson(),
      'mohArea': mohArea,
      'phmArea': phmArea,
      'gramaNiladariDivision': gramaNiladariDivision,
      'clinicName': clinicName,
      'otherClinics': otherClinics,
      'eligibleFamilyRegisterNumber': eligibleFamilyRegisterNumber,
      'eligibleFamilyRegisterDate': eligibleFamilyRegisterDate?.toIso8601String(),
      'emergencyContactPerson': emergencyContactPerson,
      'emergencyContactPhone': emergencyContactPhone,
      'emergencyContactAddress': emergencyContactAddress,
      'mohOfficePhone': mohOfficePhone,
      'phmPhone': phmPhone,
    };
  }

  factory BasicProfile.fromJson(Map<String, dynamic> json) {
    return BasicProfile(
      motherName: (json['motherName'] as String?) ?? '',
      registrationNumber: json['registrationNumber'] as String?,
      registrationDate: json['registrationDate'] != null
          ? DateTime.tryParse(json['registrationDate'] as String)
          : null,
      nationalId: json['nationalId'] as String?,
      address: json['address'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      mother: json['mother'] != null
          ? ParentDetails.fromJson(
              Map<String, dynamic>.from(json['mother'] as Map),
            )
          : const ParentDetails(),
      father: json['father'] != null
          ? ParentDetails.fromJson(
              Map<String, dynamic>.from(json['father'] as Map),
            )
          : const ParentDetails(),
      mohArea: json['mohArea'] as String?,
      phmArea: json['phmArea'] as String?,
      gramaNiladariDivision: json['gramaNiladariDivision'] as String?,
      clinicName: json['clinicName'] as String?,
      otherClinics: json['otherClinics'] as String?,
      eligibleFamilyRegisterNumber:
          json['eligibleFamilyRegisterNumber'] as String?,
      eligibleFamilyRegisterDate: json['eligibleFamilyRegisterDate'] != null
          ? DateTime.tryParse(json['eligibleFamilyRegisterDate'] as String)
          : null,
      emergencyContactPerson: json['emergencyContactPerson'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
      emergencyContactAddress: json['emergencyContactAddress'] as String?,
      mohOfficePhone: json['mohOfficePhone'] as String?,
      phmPhone: json['phmPhone'] as String?,
    );
  }
}

