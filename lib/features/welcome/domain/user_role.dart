/// Who the person setting up the app is.
///
/// Drives which shell the app opens into after onboarding: the mother owns the
/// vault and writes to it, the partner holds a read-only mirror synced by code.
enum UserRole { expectantMother, partner }
