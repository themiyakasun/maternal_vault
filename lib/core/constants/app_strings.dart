/// User-facing copy.
///
/// Centralised so wording stays consistent and the app is ready to localise.
/// Tone follows the "Clinical Warmth" voice: plain, calm and reassuring, never
/// alarming.
abstract final class AppStrings {
  // App
  static const String appName = 'Maternal Vault';
  static const String appTagline = 'Secure today, stronger tomorrow';

  /// The wordmark is set in two tones; these are its halves.
  static const String brandFirstWord = 'Maternal';
  static const String brandSecondWord = 'Vault';

  // Bottom navigation — 5 tabs
  static const String navHome = 'Home';
  static const String navVitals = 'Vitals';
  static const String navAppointments = 'Appointments';
  static const String navRecords = 'Records';
  static const String navProfile = 'Profile';

  // Home
  static const String homeGreeting = 'Welcome back';
  static const String homeTodayOverview = 'Today';
  static const String homeUpcomingAppointments = 'Upcoming appointments';
  static const String homeRecentVitals = 'Recent vitals';
  static const String homeViewAll = 'View all';

  // Vitals
  static const String vitalsTitle = 'Vitals';
  static const String vitalsWeight = 'Weight';
  static const String vitalsBloodPressure = 'Blood pressure';
  static const String vitalsHeartRate = 'Heart rate';
  static const String vitalsTemperature = 'Temperature';
  static const String vitalsLogEntry = 'Log a reading';
  static const String vitalsLastUpdated = 'Last updated';
  static const String vitalsNoData = 'No readings yet';
  static const String vitalsNoDataBody =
      'Log your first reading to start tracking trends.';

  // Units
  static const String unitKg = 'KG';
  static const String unitLb = 'LB';
  static const String unitBpm = 'BPM';
  static const String unitMmHg = 'MMHG';
  static const String unitWeeks = 'WEEKS';
  static const String unitCelsius = '°C';

  // Chart series
  static const String seriesMother = 'Mother';
  static const String seriesBaby = 'Baby';
  static const String seriesTarget = 'Target';

  // Appointments
  static const String appointmentsTitle = 'Appointments';
  static const String appointmentsUpcoming = 'Upcoming';
  static const String appointmentsPast = 'Past';
  static const String appointmentsAdd = 'Add appointment';
  static const String appointmentsNone = 'Nothing scheduled';
  static const String appointmentsNoneBody =
      'Appointments you add will show up here.';
  static const String appointmentsClinician = 'Clinician';
  static const String appointmentsLocation = 'Location';
  static const String appointmentsNotes = 'Notes';

  // Records
  static const String recordsTitle = 'Records';
  static const String recordsScans = 'Scans';
  static const String recordsLabResults = 'Lab results';
  static const String recordsPrescriptions = 'Prescriptions';
  static const String recordsDocuments = 'Documents';
  static const String recordsAdd = 'Add record';
  static const String recordsEmpty = 'No records saved';

  // Pregnancy progress
  static const String progressTitle = 'Your progress';
  static const String progressDueDate = 'Due date';
  static const String progressTrimester = 'Trimester';
  static const String progressWeeksAlong = 'Weeks along';

  // Profile & settings
  static const String profileTitle = 'Profile';
  static const String profileEdit = 'Edit profile';
  static const String settingsTitle = 'Settings';
  static const String settingsNotifications = 'Notifications';
  static const String settingsReminders = 'Appointment reminders';
  static const String settingsUnits = 'Measurement units';
  static const String settingsPrivacy = 'Privacy';
  static const String settingsSignOut = 'Sign out';

  // Generic actions
  static const String actionSave = 'Save';
  static const String actionCancel = 'Cancel';
  static const String actionDelete = 'Delete';
  static const String actionEdit = 'Edit';
  static const String actionDone = 'Done';
  static const String actionRetry = 'Try again';
  static const String actionContinue = 'Continue';
  static const String actionBack = 'Back';

  // Feedback
  static const String loading = 'Loading';
  static const String savedConfirmation = 'Saved';
  static const String errorGeneric = 'Something went wrong.';
  static const String errorGenericBody =
      'Your data is safe. Give it another try in a moment.';
  static const String errorOffline = 'You are offline';
  static const String errorOfflineBody =
      'Changes will sync once you reconnect.';

  // Validation
  static const String validationRequired = 'This field is required';
  static const String validationInvalidNumber = 'Enter a valid number';
  static const String validationInvalidDate = 'Enter a valid date';
}
