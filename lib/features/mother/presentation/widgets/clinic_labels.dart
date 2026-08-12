import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/clinic_record.dart';

/// The words and colours the clinic enums are shown as.
///
/// Shared rather than private to the card, so the card that reads a visit and the
/// sheet that writes one cannot drift into naming the same value two ways.

String visitStatusLabel(AppLocalizations l10n, VisitStatus status) {
  switch (status) {
    case VisitStatus.normal:
      return l10n.statusNormal;
    case VisitStatus.review:
      return l10n.statusReview;
  }
}

Color visitStatusAccent(VisitStatus status) {
  switch (status) {
    // Sky blue rather than red: a visit flagged for another look is information,
    // not an emergency, and a red card on a pregnancy record frightens.
    case VisitStatus.review:
      return AppColors.tertiary;
    case VisitStatus.normal:
      return AppColors.health;
  }
}

String urineLabel(AppLocalizations l10n, UrineReading reading) {
  switch (reading) {
    case UrineReading.nil:
      return l10n.urineNil;
    case UrineReading.trace:
      return l10n.urineTrace;
    // The plus scale is not translated for the same reason the em-dash is not:
    // it is punctuation, and it is written this way on the clinic card in every
    // language.
    case UrineReading.plusOne:
      return '+';
    case UrineReading.plusTwo:
      return '++';
    case UrineReading.plusThree:
      return '+++';
  }
}
