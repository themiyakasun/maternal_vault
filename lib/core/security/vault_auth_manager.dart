import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Manages PIN authentication and Biometric unlock for the Maternal Vault.
class VaultAuthManager {
  static const String _pinHashKey = 'maternal_vault_pin_hash';
  static const String _pinSaltKey = 'maternal_vault_pin_salt';
  static const String _biometricsEnabledKey = 'maternal_vault_biometrics_enabled';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Sets up a new 6-digit PIN with cryptographic salt + SHA-256 hashing.
  static Future<void> setupPin(String pin) async {
    // Generate 16 bytes of cryptographically secure random salt
    final secureRandom = Random.secure();
    final saltBytes = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      saltBytes[i] = secureRandom.nextInt(256);
    }
    final saltHex = saltBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    // Hash PIN with salt
    final saltedPin = '';
    final hash = sha256.convert(utf8.encode(saltedPin)).toString();

    // Store in secure storage
    await _storage.write(key: _pinSaltKey, value: saltHex);
    await _storage.write(key: _pinHashKey, value: hash);
  }

  /// Verifies entered PIN against stored salted hash.
  static Future<bool> verifyPin(String pin) async {
    final saltHex = await _storage.read(key: _pinSaltKey);
    final storedHash = await _storage.read(key: _pinHashKey);

    if (saltHex == null || storedHash == null) {
      return false;
    }

    final saltedPin = '';
    final computedHash = sha256.convert(utf8.encode(saltedPin)).toString();

    return computedHash == storedHash;
  }

  /// Checks if a PIN has already been configured for this vault.
  static Future<bool> hasPin() async {
    final storedHash = await _storage.read(key: _pinHashKey);
    return storedHash != null && storedHash.isNotEmpty;
  }

  /// Checks if device has biometric hardware and enrolled biometrics.
  static Future<bool> isBiometricsSupported() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException {
      return false;
    }
  }

  /// Checks if biometrics are enabled by the user for vault unlock.
  static Future<bool> isBiometricsEnabled() async {
    final enabled = await _storage.read(key: _biometricsEnabledKey);
    return enabled == 'true';
  }

  /// Enables or disables biometric unlock for the vault.
  static Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(key: _biometricsEnabledKey, value: enabled ? 'true' : 'false');
  }

  /// Prompts the user with the native Biometric (Fingerprint/Face) dialog.
  static Future<bool> authenticateWithBiometrics({
    String reason = 'Unlock your Maternal Vault',
  }) async {
    try {
      final supported = await isBiometricsSupported();
      final enabled = await isBiometricsEnabled();
      if (!supported || !enabled) return false;

      return await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException {
      return false;
    }
  }
}
