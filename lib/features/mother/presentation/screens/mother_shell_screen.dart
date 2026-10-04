import 'package:flutter/material.dart';

import '../../../../core/l10n/app_locales.dart';
import '../../../../core/widgets/brand_backdrop.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/basic_profile.dart';
import '../../domain/clinic_record.dart';
import '../../domain/delivery_plan.dart';
import '../../domain/key_vitals.dart';
import '../../domain/medical_history.dart';
import '../../domain/mother_tab.dart';
import '../../domain/obstetric_history.dart';
import '../../domain/read_only_immutability_guard.dart';
import '../widgets/language_sheet.dart';
import '../widgets/pregnancy_record_app_bar.dart';
import 'basic_profile_screen.dart';
import 'clinic_visits_screen.dart';
import 'medical_history_screen.dart';
import 'midwife_sync_scanner_screen.dart';
import 'obstetric_history_screen.dart';
import 'plan_screen.dart';
import 'mother_settings_screen.dart';
import 'mother_notifications_screen.dart';
import '../widgets/model_alert_dialog.dart';
import '../../data/services/midwife_sync_service.dart';
import '../../../../data/datasources/encrypted_db_helper.dart';
import '../../../../data/models/model_notification.dart';
import '../../../../data/services/model_notification_service.dart';

/// The mother's app once setup is done: one header, five sections, one bottom
/// bar.
///
/// Every section is built; the bar switches between them over an [IndexedStack],
/// so each keeps its scroll offset and any half-filled form while another is on
/// screen.
class MotherShellScreen extends StatefulWidget {
  const MotherShellScreen({
    super.key,
    required this.onLanguageChanged,
    this.profile = const BasicProfile.empty(),
    this.vitals = const KeyVitals.empty(),
    this.history = const MedicalHistory.empty(),
    this.obstetric = const ObstetricHistory.empty(),
    this.clinic = const ClinicRecord.empty(),
    this.plan = const DeliveryPlan.empty(),
    this.onSubmitProfile,
    this.onChangeHistory,
    this.onChangeObstetric,
    this.onChangeClinic,
    this.onSavePlan,
    this.onOpenNotifications,
    this.enableDefaultNotifications = false,
    this.initialTab = MotherTab.profile,
    this.isReadOnly = false,
  });

  /// Asks the app root to switch languages, the same contract the welcome flow
  /// uses. The shell never stores the answer — see [_MotherShellScreenState._changeLanguage].
  final ValueChanged<AppLanguage> onLanguageChanged;

  /// Passed through to [BasicProfileScreen].
  final BasicProfile profile;

  /// Passed through to [BasicProfileScreen].
  final KeyVitals vitals;

  /// Passed through to [MedicalHistoryScreen].
  final MedicalHistory history;

  /// Passed through to [ObstetricHistoryScreen].
  final ObstetricHistory obstetric;

  /// Passed through to [ClinicVisitsScreen].
  final ClinicRecord clinic;

  /// Passed through to [PlanScreen].
  final DeliveryPlan plan;

  /// Passed through to [BasicProfileScreen.onSubmit].
  final ValueChanged<BasicProfile>? onSubmitProfile;

  /// Passed through to [MedicalHistoryScreen.onChanged].
  final ValueChanged<MedicalHistory>? onChangeHistory;

  /// Passed through to [ObstetricHistoryScreen.onChanged].
  final ValueChanged<ObstetricHistory>? onChangeObstetric;

  /// Passed through to [ClinicVisitsScreen.onChanged].
  final ValueChanged<ClinicRecord>? onChangeClinic;

  /// Passed through to [PlanScreen.onSave].
  final ValueChanged<DeliveryPlan>? onSavePlan;

  /// Opens the notifications screen.
  final VoidCallback? onOpenNotifications;

  /// Whether to route to [MotherNotificationsScreen] by default when [onOpenNotifications] is null.
  final bool enableDefaultNotifications;

  /// Which section to open on. A param so a notification or a deep link can
  /// land somewhere other than Profile later.
  final MotherTab initialTab;

  /// True when the clinical record carries `"ro": 1` (`is_clinical_readonly = true`),
  /// enforcing 100% edit lockout via [ReadOnlyImmutabilityGuard].
  final bool isReadOnly;

  /// Replaces the setup screen: setup is finished and there is nothing behind
  /// this to go back to.
  static Route<void> route({
    required ValueChanged<AppLanguage> onLanguageChanged,
    BasicProfile profile = const BasicProfile.empty(),
    KeyVitals vitals = const KeyVitals.empty(),
    MedicalHistory history = const MedicalHistory.empty(),
    ObstetricHistory obstetric = const ObstetricHistory.empty(),
    ClinicRecord clinic = const ClinicRecord.empty(),
    DeliveryPlan plan = const DeliveryPlan.empty(),
    ValueChanged<BasicProfile>? onSubmitProfile,
    ValueChanged<MedicalHistory>? onChangeHistory,
    ValueChanged<ObstetricHistory>? onChangeObstetric,
    ValueChanged<ClinicRecord>? onChangeClinic,
    ValueChanged<DeliveryPlan>? onSavePlan,
    VoidCallback? onOpenNotifications,
    bool enableDefaultNotifications = true,
    bool isReadOnly = false,
  }) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (BuildContext context, _, _) => MotherShellScreen(
        onLanguageChanged: onLanguageChanged,
        profile: profile,
        vitals: vitals,
        history: history,
        obstetric: obstetric,
        clinic: clinic,
        plan: plan,
        onSubmitProfile: onSubmitProfile,
        onChangeHistory: onChangeHistory,
        onChangeObstetric: onChangeObstetric,
        onChangeClinic: onChangeClinic,
        onSavePlan: onSavePlan,
        onOpenNotifications: onOpenNotifications,
        enableDefaultNotifications: enableDefaultNotifications,
        isReadOnly: isReadOnly,
      ),
      transitionsBuilder:
          (BuildContext context, Animation<double> animation, _, Widget child) {
            return FadeTransition(opacity: animation, child: child);
          },
    );
  }

  @override
  State<MotherShellScreen> createState() => _MotherShellScreenState();
}

class _MotherShellScreenState extends State<MotherShellScreen> {
  late MotherTab _tab = widget.initialTab;
  late BasicProfile _profile = widget.profile;
  late KeyVitals _vitals = widget.vitals;
  late MedicalHistory _history = widget.history;
  late ObstetricHistory _obstetric = widget.obstetric;
  late ClinicRecord _clinic = widget.clinic;
  late DeliveryPlan _plan = widget.plan;
  late bool _isClinicalReadOnly = widget.isReadOnly;
  int _syncEpoch = 0;

  ReadOnlyImmutabilityGuard get _immutabilityGuard =>
      ReadOnlyImmutabilityGuard(isClinicalReadOnly: _isClinicalReadOnly);

  @override
  void initState() {
    super.initState();
    ModelNotificationService.instance.latestAlertNotifier
        .addListener(_onModelAlertEmitted);
  }

  @override
  void dispose() {
    ModelNotificationService.instance.latestAlertNotifier
        .removeListener(_onModelAlertEmitted);
    super.dispose();
  }

  void _onModelAlertEmitted() {
    final ModelNotification? alert =
        ModelNotificationService.instance.latestAlertNotifier.value;
    if (alert != null &&
        mounted &&
        (alert.severity == AlertSeverity.high ||
            alert.severity == AlertSeverity.critical)) {
      ModelAlertDialog.show(context, alert);
    }
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MotherNotificationsScreen.route(
        profile: _profile,
        vitals: _vitals,
        history: _history,
        obstetric: _obstetric,
        clinic: _clinic,
      ),
    );
  }

  @override
  void didUpdateWidget(MotherShellScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile != oldWidget.profile) _profile = widget.profile;
    if (widget.vitals != oldWidget.vitals) _vitals = widget.vitals;
    if (widget.history != oldWidget.history) _history = widget.history;
    if (widget.obstetric != oldWidget.obstetric) _obstetric = widget.obstetric;
    if (widget.clinic != oldWidget.clinic) _clinic = widget.clinic;
    if (widget.plan != oldWidget.plan) _plan = widget.plan;
    if (widget.isReadOnly != oldWidget.isReadOnly) {
      _isClinicalReadOnly = widget.isReadOnly;
    }
  }

  Future<void> _openQrScanner() async {
    final SyncResult? result = await Navigator.of(context).push<SyncResult>(
      MaterialPageRoute<SyncResult>(
        builder: (BuildContext context) => const MidwifeSyncScannerScreen(),
      ),
    );

    // Guaranteed reload from SQLCipher database in case result was returned or popped
    final syncedData = await EncryptedDatabaseHelper.loadSyncedData();
    if (syncedData != null && mounted) {
      setState(() {
        _syncEpoch++;
        _profile = syncedData.profile;
        _vitals = syncedData.vitals;
        _history = syncedData.medicalHistory;
        _obstetric = syncedData.obstetricHistory;
        _clinic = syncedData.clinicRecord;
        _plan = syncedData.deliveryPlan;
        _isClinicalReadOnly = syncedData.isClinicalReadOnly;
      });

      widget.onSubmitProfile?.call(syncedData.profile);
      widget.onChangeHistory?.call(syncedData.medicalHistory);
      widget.onChangeObstetric?.call(syncedData.obstetricHistory);
      widget.onChangeClinic?.call(syncedData.clinicRecord);
      widget.onSavePlan?.call(syncedData.deliveryPlan);

      // Trigger AI model evaluation on newly synced clinical record
      ModelNotificationService.instance.evaluateAndAlert(
        profile: _profile,
        vitals: _vitals,
        history: _history,
        obstetric: _obstetric,
        clinic: _clinic,
        epdsScore: result?.epdsScore,
      );
      return;
    }

    if (result != null && result.isSuccess && mounted) {
      setState(() {
        _syncEpoch++;
        if (result.profile != null) _profile = result.profile!;
        if (result.vitals != null) _vitals = result.vitals!;
        if (result.medicalHistory != null) _history = result.medicalHistory!;
        if (result.obstetricHistory != null) {
          _obstetric = result.obstetricHistory!;
        }
        if (result.clinicRecord != null) _clinic = result.clinicRecord!;
        if (result.deliveryPlan != null) _plan = result.deliveryPlan!;
        _isClinicalReadOnly = result.isClinicalReadOnly;
      });

      if (result.profile != null) widget.onSubmitProfile?.call(result.profile!);
      if (result.medicalHistory != null) {
        widget.onChangeHistory?.call(result.medicalHistory!);
      }
      if (result.obstetricHistory != null) {
        widget.onChangeObstetric?.call(result.obstetricHistory!);
      }
      if (result.clinicRecord != null) {
        widget.onChangeClinic?.call(result.clinicRecord!);
      }
      if (result.deliveryPlan != null) {
        widget.onSavePlan?.call(result.deliveryPlan!);
      }

      // Trigger AI model evaluation on newly synced clinical record
      ModelNotificationService.instance.evaluateAndAlert(
        profile: _profile,
        vitals: _vitals,
        history: _history,
        obstetric: _obstetric,
        clinic: _clinic,
        epdsScore: result.epdsScore,
      );
    }
  }

  Future<void> _persistToDatabase() async {
    if (_immutabilityGuard.isLocked) return;
    try {
      await EncryptedDatabaseHelper.saveLocalData(
        profile: _profile,
        vitals: _vitals,
        medicalHistory: _history,
        obstetricHistory: _obstetric,
        clinicRecord: _clinic,
        deliveryPlan: _plan,
        isClinicalReadOnly: _isClinicalReadOnly,
      );
    } catch (e) {
      debugPrint('Error auto-persisting shell state: $e');
    }
  }

  void _openSettings() async {
    await Navigator.of(context).push(
      MotherSettingsScreen.route(
        profile: _profile,
        vitals: _vitals,
        deliveryPlan: _plan,
        clinicRecord: _clinic,
        onLanguageChanged: widget.onLanguageChanged,
        onRecordUpdated: () async {
          final syncedData = await EncryptedDatabaseHelper.loadSyncedData();
          if (syncedData != null && mounted) {
            setState(() {
              _syncEpoch++;
              _profile = syncedData.profile;
              _vitals = syncedData.vitals;
              _history = syncedData.medicalHistory;
              _obstetric = syncedData.obstetricHistory;
              _clinic = syncedData.clinicRecord;
              _plan = syncedData.deliveryPlan;
              _isClinicalReadOnly = syncedData.isClinicalReadOnly;
            });
          }
        },
        onResetVault: () {
          setState(() {
            _syncEpoch++;
            _profile = const BasicProfile.empty();
            _vitals = const KeyVitals.empty();
            _history = const MedicalHistory.empty();
            _obstetric = const ObstetricHistory.empty();
            _clinic = const ClinicRecord.empty();
            _plan = const DeliveryPlan.empty();
            _isClinicalReadOnly = false;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    // The shell is the root after setup, so the back gesture is refused rather
    // than popping to a finished setup screen or an empty navigator.
    return PopScope<void>(
      canPop: false,
      child: Scaffold(
        body: BrandBackdrop(
          child: SafeArea(
            // The bar paints its own opaque surface and handles the bottom
            // inset itself, so the body only claims the top one.
            bottom: false,
            child: Column(
              children: <Widget>[
                PregnancyRecordAppBar(
                  title: _headerTitle(l10n, _tab),
                  onChangeLanguage: _changeLanguage,
                  onScanQr: _openQrScanner,
                  onOpenSettings: _openSettings,
                  onOpenNotifications: widget.onOpenNotifications ??
                      (widget.enableDefaultNotifications
                          ? _openNotifications
                          : null),
                ),
                Expanded(
                  // IndexedStack rather than a swap: every tab stays mounted, so
                  // a half-filled form and a scroll position both survive a trip
                  // to another section and back.
                  child: IndexedStack(
                    index: _tab.index,
                    children: <Widget>[
                      for (final MotherTab tab in MotherTab.values)
                        _body(l10n, tab),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab.index,
          onDestinationSelected: (int index) =>
              setState(() => _tab = MotherTab.values[index]),
          destinations: <Widget>[
            for (final MotherTab tab in MotherTab.values)
              NavigationDestination(
                icon: Icon(_icon(tab)),
                label: _label(l10n, tab),
                tooltip: _label(l10n, tab),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n, MotherTab tab) {
    switch (tab) {
      case MotherTab.profile:
        return BasicProfileScreen(
          key: ValueKey('shell_profile_$_syncEpoch'),
          profile: _profile,
          vitals: _vitals,
          isReadOnly: _isClinicalReadOnly,
          onSubmit: _immutabilityGuard.guardCallback((BasicProfile p) {
            setState(() => _profile = p);
            widget.onSubmitProfile?.call(p);
            _persistToDatabase();
          }),
        );
      case MotherTab.history:
        return MedicalHistoryScreen(
          key: ValueKey('shell_history_$_syncEpoch'),
          history: _history,
          isReadOnly: _isClinicalReadOnly,
          onChanged: _immutabilityGuard.guardCallback((MedicalHistory h) {
            setState(() => _history = h);
            widget.onChangeHistory?.call(h);
            _persistToDatabase();
          }),
        );
      case MotherTab.obstetric:
        return ObstetricHistoryScreen(
          key: ValueKey('shell_obstetric_$_syncEpoch'),
          history: _obstetric,
          onChanged: _immutabilityGuard.guardCallback((ObstetricHistory o) {
            setState(() => _obstetric = o);
            widget.onChangeObstetric?.call(o);
            _persistToDatabase();
          }),
        );
      case MotherTab.clinic:
        return ClinicVisitsScreen(
          key: ValueKey('shell_clinic_$_syncEpoch'),
          record: _clinic,
          onScanQr: _openQrScanner,
          onChanged: _immutabilityGuard.guardCallback((ClinicRecord c) {
            setState(() => _clinic = c);
            widget.onChangeClinic?.call(c);
            _persistToDatabase();
          }),
        );
      case MotherTab.plan:
        return PlanScreen(
          key: ValueKey('shell_plan_$_syncEpoch'),
          plan: _plan,
          isReadOnly: _isClinicalReadOnly,
          onSave: _immutabilityGuard.guardCallback((DeliveryPlan pl) {
            setState(() => _plan = pl);
            widget.onSavePlan?.call(pl);
            _persistToDatabase();
          }),
        );
    }
  }

  Future<void> _changeLanguage() async {
    // Read the live locale rather than a stored copy: a field would freeze at
    // whatever was current when the shell was pushed, so the checkmark in the
    // sheet would stop moving after the first change.
    final AppLanguage? picked = await showLanguageSheet(
      context,
      selected: AppLanguage.fromLocale(Localizations.maybeLocaleOf(context)),
    );

    // Null means the sheet was dismissed without a choice.
    if (picked == null) return;
    widget.onLanguageChanged(picked);
  }

  /// What the header reads on a given tab.
  ///
  /// A section that carries no title of its own names itself up there — one
  /// heading, not none and not two. The sections that head their own page keep
  /// the record's name, so Profile still reads "Pregnancy Record" above "Basic
  /// Profile".
  String _headerTitle(AppLocalizations l10n, MotherTab tab) {
    switch (tab) {
      case MotherTab.history:
        return l10n.historyTitle;
      case MotherTab.obstetric:
        return l10n.obstetricTitle;
      case MotherTab.clinic:
        return l10n.clinicTitle;
      case MotherTab.plan:
        return l10n.planTitle;
      case MotherTab.profile:
        return l10n.recordTitle;
    }
  }

  String _label(AppLocalizations l10n, MotherTab tab) {
    switch (tab) {
      case MotherTab.profile:
        return l10n.tabProfile;
      case MotherTab.history:
        return l10n.tabHistory;
      case MotherTab.obstetric:
        return l10n.tabObstetric;
      case MotherTab.clinic:
        return l10n.tabClinic;
      case MotherTab.plan:
        return l10n.tabPlan;
    }
  }

  IconData _icon(MotherTab tab) {
    switch (tab) {
      case MotherTab.profile:
        return Icons.person_outline_rounded;
      case MotherTab.history:
        return Icons.history_rounded;
      case MotherTab.obstetric:
        return Icons.pregnant_woman_rounded;
      case MotherTab.clinic:
        return Icons.local_hospital_outlined;
      case MotherTab.plan:
        return Icons.event_note_outlined;
    }
  }
}
