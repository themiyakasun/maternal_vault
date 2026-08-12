/// The contraceptive method chosen for after the birth.
///
/// [undecided] is a real answer, not the absence of one: it is what a mother who
/// has been asked and has not settled yet should be recorded as, distinct from
/// null, which is nobody having asked.
enum FamilyPlanningMethod {
  undecided,
  none,
  pills,
  injectable,
  implant,
  iud,
  tubalLigation,
  condoms,
  other,
}
