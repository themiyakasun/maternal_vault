/// How far each parent got in school.
///
/// Follows the Sri Lankan school system, which is what the national maternal
/// record asks for: O/L and A/L are the two public examinations, and are named
/// as such rather than mapped onto grade numbers that would not mean anything to
/// someone filling this in.
enum EducationLevel {
  /// No formal schooling.
  none,

  /// Primary school, grades 1–5.
  primary,

  /// Secondary school, up to but not through O/L.
  secondary,

  /// Ordinary Level qualified.
  oLevel,

  /// Advanced Level qualified.
  aLevel,

  /// A degree, diploma or other post-secondary qualification.
  tertiary,
}
