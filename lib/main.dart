import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/l10n/app_locales.dart';
import 'core/l10n/locale_controller.dart';
import 'core/security/vault_auth_manager.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/encrypted_db_helper.dart';
import 'features/auth/presentation/screens/create_pin_screen.dart';
import 'features/auth/presentation/screens/vault_lock_screen.dart';
import 'features/mother/data/services/vault_setup_service.dart';
import 'features/mother/domain/basic_profile.dart';
import 'features/mother/domain/clinic_record.dart';
import 'features/mother/domain/delivery_plan.dart';
import 'features/mother/domain/key_vitals.dart';
import 'features/mother/domain/medical_history.dart';
import 'features/mother/domain/obstetric_history.dart';
import 'features/mother/presentation/screens/mother_shell_screen.dart';
import 'features/mother/presentation/screens/vault_setup_screen.dart';
import 'features/partner/domain/emergency_plan.dart';
import 'features/partner/domain/partner_agenda.dart';
import 'features/partner/domain/partner_summary.dart';
import 'features/partner/presentation/screens/connect_mother_record_screen.dart';
import 'features/partner/presentation/screens/partner_qr_scanner_screen.dart';
import 'features/partner/presentation/screens/partner_shell_screen.dart';
import 'features/partner/presentation/widgets/partner_connect_sheet.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'features/welcome/domain/user_role.dart';
import 'features/welcome/presentation/screens/welcome_screen.dart';
import 'l10n/generated/app_localizations.dart';

void main() {
  runApp(const MaternalVaultApp());
}

class MaternalVaultApp extends StatefulWidget {
  const MaternalVaultApp({super.key});

  @override
  State<MaternalVaultApp> createState() => _MaternalVaultAppState();
}

class _MaternalVaultAppState extends State<MaternalVaultApp> {
  /// Owned here because [MaterialApp.locale] lives here — the welcome flow only
  /// asks for a change, it never applies one itself.
  final LocaleController _locale = LocaleController();

  /// Routing is driven from here too, and the callbacks that drive it outlive
  /// the routes that trigger them: [_onOnboardingComplete] runs from the
  /// welcome flow, which a replacement then unmounts. A context taken from
  /// inside the tree would already be dead by the time the next push lands, so
  /// the navigator is reached by key instead.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void dispose() {
    _locale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: _locale,
      builder: (BuildContext context, AppLanguage language, _) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          onGenerateTitle: (BuildContext context) =>
              AppLocalizations.of(context).appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: language.locale,
          supportedLocales: AppLanguage.locales,
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: SplashScreen(
            initialization: _checkInitialSession(),
            onComplete: _onSplashComplete,
          ),
        );
      },
    );
  }

  NavigatorState get _navigator => _navigatorKey.currentState!;

  bool _vaultExists = false;
  bool _hasPin = false;

  Future<void> _checkInitialSession() async {
    try {
      _vaultExists = await EncryptedDatabaseHelper.doesDatabaseExist();
      _hasPin = await VaultAuthManager.hasPin();
    } catch (_) {
      _vaultExists = false;
      _hasPin = false;
    }
  }

  void _onSplashComplete() {
    if (_vaultExists && _hasPin) {
      _openVaultLock();
    } else {
      _openWelcome();
    }
  }

  void _openVaultLock() {
    _navigator.pushReplacement(
      VaultLockScreen.route(
        onUnlocked: _openMotherShell,
      ),
    );
  }

  void _openWelcome() {
    _navigator.pushReplacement(
      WelcomeScreen.route(
        onLanguageChanged: (AppLanguage next) => _locale.language = next,
        onCompleted: _onOnboardingComplete,
      ),
    );
  }

  /// The two roles want different histories, so they get different pushes.
  void _onOnboardingComplete(UserRole role) {
    // TODO: persist the role and the chosen language before routing.
    switch (role) {
      case UserRole.expectantMother:
        // Guide expectant mother to set her 6-digit PIN before generating the encrypted vault
        _navigator.pushReplacement(
          CreatePinScreen.route(
            onCompleted: _openVaultSetup,
          ),
        );
      case UserRole.partner:
        // Pushed: the connect screen has a back chip, and someone who picked
        // the wrong role should land back on the role step.
        _navigator.push(
          ConnectMotherRecordScreen.route(
            onScanNow: _openPartnerScanner,
            onEnterCode: _openPartnerManualEntry,
          ),
        );
    }
  }

  void _openVaultSetup() {
    _navigator.pushReplacement(
      VaultSetupScreen.route(
        runStage: VaultSetupService.runStage,
        onComplete: _openMotherShell,
      ),
    );
  }

  void _openPartnerScanner() async {
    final result = await _navigator.push<PartnerConnectionData?>(
      PartnerQrScannerScreen.route(),
    );
    if (result != null) {
      _openPartnerShell(
        summary: result.summary,
        agenda: result.agenda,
        emergencyPlan: result.emergencyPlan,
      );
    }
  }

  void _openPartnerManualEntry() async {
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    final result = await PartnerConnectSheet.show(context);
    if (result != null) {
      _openPartnerShell(
        summary: result.summary,
        agenda: result.agenda,
        emergencyPlan: result.emergencyPlan,
      );
    }
  }

  /// Replaces the connect screen rather than stacking on it — pairing is done
  /// by now and there is nothing to return to.
  void _openPartnerShell({
    PartnerSummary summary = const PartnerSummary.sample(),
    PartnerAgenda? agenda,
    EmergencyPlan emergencyPlan = const EmergencyPlan.sample(),
  }) {
    _navigator.pushReplacement(
      PartnerShellScreen.route(
        summary: summary,
        agenda: agenda ?? PartnerAgenda.sample(),
        emergencyPlan: emergencyPlan,
      ),
    );
  }

  /// Replaces setup rather than stacking on it — the vault is built by now and
  /// there is nothing to return to.
  void _openMotherShell() async {
    // 🔍 Database Verification Check
    final bool fileExists = await EncryptedDatabaseHelper.doesDatabaseExist();
    debugPrint('📂 Database file exists on disk: $fileExists');
    final List<String> tables =
        await EncryptedDatabaseHelper.getCreatedTables();
    debugPrint('📋 Created tables: $tables');
    // Ensure clean state: if no midwife QR sync has been performed, wipe all tables
    final bool hasSynced =
        await EncryptedDatabaseHelper.hasCompletedMidwifeSync();
    if (!hasSynced) {
      await EncryptedDatabaseHelper.clearAllData();
    }

    final records = await EncryptedDatabaseHelper.getMotherProfiles();
    debugPrint('👤 Records in mother_profile (${records.length}): $records');

    // If synced records exist in the encrypted vault, load and display them!
    final syncedData = await EncryptedDatabaseHelper.loadSyncedData();

    _navigator.pushReplacement(
      MotherShellScreen.route(
        onLanguageChanged: (AppLanguage next) => _locale.language = next,
        profile: syncedData?.profile ?? const BasicProfile.empty(),
        vitals: syncedData?.vitals ?? const KeyVitals.empty(),
        history: syncedData?.medicalHistory ?? const MedicalHistory.empty(),
        obstetric:
            syncedData?.obstetricHistory ?? const ObstetricHistory.empty(),
        clinic: syncedData?.clinicRecord ?? const ClinicRecord.empty(),
        plan: syncedData?.deliveryPlan ?? const DeliveryPlan.empty(),
      ),
    );
  }
}
