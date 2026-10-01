import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/l10n/app_locales.dart';
import '../../../../core/security/vault_auth_manager.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/brand_backdrop.dart';
import '../../../../core/widgets/buttons/app_button_tone.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../data/datasources/encrypted_db_helper.dart';
import '../../../auth/presentation/screens/vault_lock_screen.dart';
import '../../domain/basic_profile.dart';
import '../../domain/clinic_record.dart';
import '../../domain/delivery_plan.dart';
import '../../domain/key_vitals.dart';
import '../widgets/language_sheet.dart';
import 'change_pin_screen.dart';
import 'epds_screening_screen.dart';
import 'midwife_sync_scanner_screen.dart';
import 'partner_share_qr_screen.dart';
import '../../data/services/midwife_sync_service.dart';

/// The Mother's Settings Screen providing security configuration, PIN changes,
/// partner data transfer QR generation, clinic sync, language preferences, and data reset.
class MotherSettingsScreen extends StatefulWidget {
  const MotherSettingsScreen({
    super.key,
    required this.profile,
    required this.vitals,
    required this.deliveryPlan,
    required this.clinicRecord,
    required this.onLanguageChanged,
    this.onRecordUpdated,
    this.onResetVault,
  });

  final BasicProfile profile;
  final KeyVitals vitals;
  final DeliveryPlan deliveryPlan;
  final ClinicRecord clinicRecord;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final VoidCallback? onRecordUpdated;
  final VoidCallback? onResetVault;

  static Route<void> route({
    required BasicProfile profile,
    required KeyVitals vitals,
    required DeliveryPlan deliveryPlan,
    required ClinicRecord clinicRecord,
    required ValueChanged<AppLanguage> onLanguageChanged,
    VoidCallback? onRecordUpdated,
    VoidCallback? onResetVault,
  }) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (BuildContext context, _, _) => MotherSettingsScreen(
        profile: profile,
        vitals: vitals,
        deliveryPlan: deliveryPlan,
        clinicRecord: clinicRecord,
        onLanguageChanged: onLanguageChanged,
        onRecordUpdated: onRecordUpdated,
        onResetVault: onResetVault,
      ),
      transitionsBuilder:
          (BuildContext context, Animation<double> animation, _, Widget child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  @override
  State<MotherSettingsScreen> createState() => _MotherSettingsScreenState();
}

class _MotherSettingsScreenState extends State<MotherSettingsScreen> {
  bool _biometricsSupported = false;
  bool _biometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final supported = await VaultAuthManager.isBiometricsSupported();
    final enabled = await VaultAuthManager.isBiometricsEnabled();
    if (mounted) {
      setState(() {
        _biometricsSupported = supported;
        _biometricsEnabled = enabled;
      });
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      final authenticated = await VaultAuthManager.authenticateWithBiometrics(
        reason: 'Verify biometric identity to enable unlock',
      );
      if (!authenticated) return;
    }

    await VaultAuthManager.setBiometricsEnabled(value);
    if (mounted) {
      setState(() {
        _biometricsEnabled = value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Biometric unlock enabled.'
                : 'Biometric unlock disabled.',
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openChangePin() async {
    final updated = await Navigator.of(context).push<bool>(
      ChangePinScreen.route(),
    );
    if (updated == true && mounted) {
      _loadSecuritySettings();
    }
  }

  void _lockVault() {
    Navigator.of(context).pushAndRemoveUntil(
      VaultLockScreen.route(
        onUnlocked: () {
          Navigator.of(context).pop();
        },
      ),
      (route) => false,
    );
  }

  void _openPartnerQr() {
    Navigator.of(context).push(
      PartnerShareQrScreen.route(
        profile: widget.profile,
        vitals: widget.vitals,
        deliveryPlan: widget.deliveryPlan,
        clinicRecord: widget.clinicRecord,
      ),
    );
  }

  void _openMidwifeScanner() async {
    final result = await Navigator.of(context).push<SyncResult>(
      MaterialPageRoute<SyncResult>(
        builder: (context) => const MidwifeSyncScannerScreen(),
      ),
    );

    if (result != null && result.isSuccess && mounted) {
      widget.onRecordUpdated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Records synchronized for ${result.motherName}!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _openLanguagePicker() async {
    final chosen = await showLanguageSheet(
      context,
      selected: AppLanguage.english,
    );
    if (chosen != null && mounted) {
      widget.onLanguageChanged(chosen);
    }
  }

  void _showResetConfirmation() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Vault Data?'),
          content: const Text(
            'Are you sure you want to reset all stored records? '
            'All local health records and visits will be permanently erased. '
            'You will need to re-scan the midwife QR code to restore records.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              onPressed: () async {
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                nav.pop();
                await EncryptedDatabaseHelper.clearAllData();
                if (mounted) {
                  widget.onResetVault?.call();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Vault data reset successfully.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  nav.pop();
                }
              },
              child: const Text('Reset All Data'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final motherName = widget.profile.motherName.isNotEmpty
        ? widget.profile.motherName
        : 'Expectant Mother';
    final regId = widget.profile.registrationNumber ?? '#6720';

    return Scaffold(
      body: BrandBackdrop(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.stackSm,
                ),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: AppSpacing.stackSm),
                    Text(
                      'Settings',
                      style: AppTextStyles.h3,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                    vertical: AppSpacing.stackSm,
                  ),
                  children: <Widget>[
                    // Mother & Vault Status Card
                    AppCard(
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  motherName,
                                  style: AppTextStyles.h3.copyWith(fontSize: 18),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Record ID: $regId',
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryContainer.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.lock_rounded,
                                        size: 12,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Encrypted SQLCipher Vault',
                                          style: AppTextStyles.labelCaps.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sectionGap),

                    // SECTION 1: PARTNER DATA TRANSFER
                    _SectionHeader(title: 'Partner Transfer'),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.qr_code_2_rounded,
                                  color: AppColors.primary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Transfer Data to Partner',
                                      style: AppTextStyles.bodySm.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Generate a QR code to sync key health, appointment, and emergency info.',
                                      style: AppTextStyles.bodySm.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AppPrimaryButton(
                            label: 'Generate Partner QR Code',
                            onPressed: _openPartnerQr,
                            icon: Icons.qr_code_rounded,
                            tone: AppButtonTone.secondary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sectionGap),

                    // SECTION 2: SECURITY & PASSWORDS
                    _SectionHeader(title: 'Security & Access'),
                    AppCard(
                      child: Column(
                        children: <Widget>[
                          _SettingTile(
                            icon: Icons.lock_reset_rounded,
                            title: 'Change Vault PIN',
                            subtitle: 'Update your 6-digit vault access code',
                            onTap: _openChangePin,
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            secondary: const Icon(
                              Icons.fingerprint_rounded,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              'Biometric Unlock',
                              style: AppTextStyles.bodySm.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              _biometricsSupported
                                  ? 'Unlock vault with fingerprint or face'
                                  : 'Biometrics unavailable on this device',
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            value: _biometricsEnabled,
                            onChanged: _biometricsSupported
                                ? _toggleBiometrics
                                : null,
                            activeThumbColor: AppColors.primary,
                          ),
                          const Divider(height: 1),
                          _SettingTile(
                            icon: Icons.lock_outline_rounded,
                            title: 'Lock Vault Now',
                            subtitle: 'Instantly lock vault and require PIN',
                            onTap: _lockVault,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sectionGap),

                    // SECTION 3: CLINICAL SYNC
                    _SectionHeader(title: 'Midwife Clinical Sync'),
                    AppCard(
                      child: Column(
                        children: <Widget>[
                          _SettingTile(
                            icon: Icons.qr_code_scanner_rounded,
                            title: 'Sync with Midwife Dashboard',
                            subtitle: 'Scan clinic computer screen to update visits',
                            onTap: _openMidwifeScanner,
                          ),
                          const Divider(height: 1),
                          _SettingTile(
                            icon: Icons.self_improvement_rounded,
                            title: '10-Item EPDS & Symptom Log',
                            subtitle: 'Perinatal wellbeing check & daily mood log',
                            onTap: () {
                              Navigator.of(context).push(
                                EpdsScreeningScreen.route(
                                  profile: widget.profile,
                                  vitals: widget.vitals,
                                  clinic: widget.clinicRecord,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sectionGap),

                    // SECTION 4: PREFERENCES
                    _SectionHeader(title: 'Preferences'),
                    AppCard(
                      child: _SettingTile(
                        icon: Icons.language_rounded,
                        title: 'Language',
                        subtitle: 'English / සිංහල / தமிழ்',
                        onTap: _openLanguagePicker,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sectionGap),

                    // SECTION 5: DATA MANAGEMENT
                    _SectionHeader(title: 'Data Management'),
                    AppCard(
                      child: _SettingTile(
                        icon: Icons.delete_forever_rounded,
                        iconColor: AppColors.error,
                        title: 'Reset Vault Data',
                        subtitle: 'Erase all locally stored clinical records',
                        textColor: AppColors.error,
                        onTap: _showResetConfirmation,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sectionGap),

                    // SECTION 6: ABOUT
                    Center(
                      child: Column(
                        children: <Widget>[
                          Text(
                            'MaternaVault v1.2.0',
                            style: AppTextStyles.labelCaps.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Offline & Hardware-Backed 256-bit AES SQLCipher',
                            style: AppTextStyles.labelCaps.copyWith(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelCaps.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? AppColors.primary,
      ),
      title: Text(
        title,
        style: AppTextStyles.bodySm.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySm.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
