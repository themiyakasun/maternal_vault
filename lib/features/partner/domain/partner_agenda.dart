import 'package:flutter/material.dart';

/// A scheduled clinic visit the partner should know about.
@immutable
class ClinicAppointment {
  const ClinicAppointment({
    required this.date,
    required this.time,
    required this.hospital,
    required this.ward,
  });

  /// Demo visit until the connected record is read. Not const — it holds a date.
  ClinicAppointment.sample()
    : this(
        date: DateTime(2023, 10, 25),
        time: const TimeOfDay(hour: 9, minute: 0),
        hospital: 'Mercy General Hospital',
        ward: 'Maternity Wing, Floor 3',
      );

  final DateTime date;
  final TimeOfDay time;

  /// Where to go — a proper noun, so it is not translated.
  final String hospital;

  /// The finer location within the hospital, e.g. "Maternity Wing, Floor 3".
  final String ward;
}

/// The daily preparation tasks shown as a checklist. Fixed for the demo; a real
/// build would read the mother's own list.
enum PartnerPrepTask { hospitalBag, birthPlan, folicAcid }

/// What the partner's calendar tab shows: the next visit and, via
/// [PartnerPrepTask], the tasks to work through before it.
@immutable
class PartnerAgenda {
  const PartnerAgenda({this.nextVisit});

  const PartnerAgenda.empty() : this();

  /// Demo agenda. Not const — the appointment holds a date.
  PartnerAgenda.sample() : nextVisit = ClinicAppointment.sample();

  /// The next scheduled visit, or null if none is booked.
  final ClinicAppointment? nextVisit;
}
