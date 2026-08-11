/// The five sections of the mother's app, in the order the bottom bar shows
/// them.
///
/// An enum rather than a bare index so the shell's switch over tabs stays
/// exhaustive — adding a section forces every label, glyph and body to be
/// supplied rather than silently falling through to a default.
enum MotherTab {
  /// Registration and demographic details. Where the app opens.
  profile,

  /// Past pregnancies and their outcomes.
  history,

  /// The current pregnancy's obstetric record.
  obstetric,

  /// Clinic visits and check-up findings.
  clinic,

  /// The birth plan and what to prepare.
  plan,
}
