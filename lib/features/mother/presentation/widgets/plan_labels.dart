import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/family_planning_method.dart';
import '../../domain/transport_mode.dart';

/// The words the plan enums render as, kept out of the screen so the same value
/// reads the same everywhere it is shown.

String transportModeLabel(AppLocalizations l10n, TransportMode mode) {
  switch (mode) {
    case TransportMode.ambulance:
      return l10n.transportAmbulance;
    case TransportMode.ownVehicle:
      return l10n.transportOwnVehicle;
    case TransportMode.threeWheeler:
      return l10n.transportThreeWheeler;
    case TransportMode.publicTransport:
      return l10n.transportPublic;
    case TransportMode.neighbourVehicle:
      return l10n.transportNeighbour;
    case TransportMode.other:
      return l10n.transportOther;
  }
}

String familyPlanningLabel(AppLocalizations l10n, FamilyPlanningMethod method) {
  switch (method) {
    case FamilyPlanningMethod.undecided:
      return l10n.familyPlanningUndecided;
    case FamilyPlanningMethod.none:
      return l10n.familyPlanningNone;
    case FamilyPlanningMethod.pills:
      return l10n.familyPlanningPills;
    case FamilyPlanningMethod.injectable:
      return l10n.familyPlanningInjectable;
    case FamilyPlanningMethod.implant:
      return l10n.familyPlanningImplant;
    case FamilyPlanningMethod.iud:
      return l10n.familyPlanningIud;
    case FamilyPlanningMethod.tubalLigation:
      return l10n.familyPlanningTubalLigation;
    case FamilyPlanningMethod.condoms:
      return l10n.familyPlanningCondoms;
    case FamilyPlanningMethod.other:
      return l10n.familyPlanningOther;
  }
}
