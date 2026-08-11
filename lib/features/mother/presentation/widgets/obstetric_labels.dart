import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/obstetric_history.dart';

/// The words and colours the obstetric enums render as.
///
/// Top-level rather than private to either widget: the past-pregnancy card reads
/// these values and the sheet that adds one writes them, and a label that differs
/// between the two would look like two different records.

String screeningLabel(AppLocalizations l10n, ObstetricScreening question) {
  switch (question) {
    case ObstetricScreening.consanguinity:
      return l10n.screeningConsanguinity;
    case ObstetricScreening.rubellaImmunization:
      return l10n.screeningRubella;
    case ObstetricScreening.prePregnancyScreening:
      return l10n.screeningPrePregnancy;
    case ObstetricScreening.folicAcid:
      return l10n.screeningFolicAcid;
    case ObstetricScreening.subfertility:
      return l10n.screeningSubfertility;
  }
}

String deliveryModeLabel(AppLocalizations l10n, DeliveryMode mode) {
  switch (mode) {
    case DeliveryMode.spontaneousVaginal:
      return l10n.deliverySvd;
    case DeliveryMode.assistedVaginal:
      return l10n.deliveryAssisted;
    case DeliveryMode.caesarean:
      return l10n.deliveryCaesarean;
  }
}

String outcomeLabel(AppLocalizations l10n, PregnancyOutcome outcome) {
  switch (outcome) {
    case PregnancyOutcome.alive:
      return l10n.outcomeAlive;
    case PregnancyOutcome.stillbirth:
      return l10n.outcomeStillbirth;
    case PregnancyOutcome.neonatalDeath:
      return l10n.outcomeNeonatalDeath;
    case PregnancyOutcome.miscarriage:
      return l10n.outcomeMiscarriage;
  }
}

String termLabel(AppLocalizations l10n, PregnancyTerm term) {
  switch (term) {
    case PregnancyTerm.preterm:
      return l10n.termPreterm;
    case PregnancyTerm.term:
      return l10n.termTerm;
    case PregnancyTerm.postTerm:
      return l10n.termPostTerm;
  }
}

String sexLabel(AppLocalizations l10n, BabySex sex) {
  switch (sex) {
    case BabySex.male:
      return l10n.sexMale;
    case BabySex.female:
      return l10n.sexFemale;
  }
}

/// Sage for a living child, red for a loss. Neutral while unrecorded, so an
/// unfinished row does not read as bad news.
Color outcomeAccent(PregnancyOutcome? outcome) {
  switch (outcome) {
    case PregnancyOutcome.alive:
      return AppColors.health;
    case PregnancyOutcome.stillbirth:
    case PregnancyOutcome.neonatalDeath:
    case PregnancyOutcome.miscarriage:
      return AppColors.error;
    case null:
      return AppColors.outlineVariant;
  }
}

Color termAccent(PregnancyTerm term) {
  switch (term) {
    case PregnancyTerm.term:
      return AppColors.health;
    case PregnancyTerm.preterm:
    case PregnancyTerm.postTerm:
      return AppColors.tertiary;
  }
}
