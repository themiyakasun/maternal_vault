import 'package:flutter/foundation.dart';

/// Which of the fixed emergency roles a contact fills. Drives its colour, avatar
/// glyph and label on the screen.
enum EmergencyContactKind { emergencyPerson, phm, moh }

/// One person or office to reach in a hurry.
@immutable
class EmergencyContact {
  const EmergencyContact({
    required this.kind,
    required this.name,
    this.phone = '',
  });

  final EmergencyContactKind kind;

  /// The person or place — data, so not translated.
  final String name;

  /// Dialled when the call button is wired up. May be empty for now.
  final String phone;
}

/// The how-to-get-there half of the plan: where, by what, how far, how long.
@immutable
class BirthPlanLogistics {
  const BirthPlanLogistics({
    required this.hospital,
    required this.transport,
    required this.distanceKm,
    required this.estMinutes,
  });

  final String hospital;
  final String transport;
  final int distanceKm;
  final int estMinutes;
}

/// What the partner's emergency tab shows: who to call and how to reach the
/// hospital.
@immutable
class EmergencyPlan {
  const EmergencyPlan({
    this.contacts = const <EmergencyContact>[],
    this.logistics,
  });

  const EmergencyPlan.empty() : this();

  /// Demo plan until the connected record is read.
  const EmergencyPlan.sample()
    : this(
        contacts: const <EmergencyContact>[
          EmergencyContact(
            kind: EmergencyContactKind.emergencyPerson,
            name: 'Sarah Jenkins',
          ),
          EmergencyContact(
            kind: EmergencyContactKind.phm,
            name: 'Jane Doe RN',
          ),
          EmergencyContact(
            kind: EmergencyContactKind.moh,
            name: 'Central Clinic',
          ),
        ],
        logistics: const BirthPlanLogistics(
          hospital: "St. Jude's Maternity Ward",
          transport: 'Personal Vehicle (Primary) / Taxi (Backup)',
          distanceKm: 12,
          estMinutes: 25,
        ),
      );

  final List<EmergencyContact> contacts;

  /// The travel plan, or null if none has been recorded.
  final BirthPlanLogistics? logistics;
}
