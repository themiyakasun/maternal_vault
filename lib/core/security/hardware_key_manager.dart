import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HardwareKeyManager {
  static const String _keyAlias = "maternal_vault_master_dek";

  // Uses android Keystore hardware encryption
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
      keyCipherAlgorithm:
          KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Retrieves the existing 256-bit key, or create a new high-entropy key on first launch
  static Future<String> getOrGenerateKey() async {
    String? hexKey = await _storage.read(key: _keyAlias);

    if (hexKey == null) {
      // Generate 32 bytes (256 bits) of true cryptographic random data
      final secureRandom = Random.secure();
      final keyBytes = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        keyBytes[i] = secureRandom.nextInt(256);
      }

      // Convert to 64 hexadecimal characters
      hexKey = keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

      // Store sealed key inside Keystore
      await _storage.write(key: _keyAlias, value: hexKey);
    }

    return hexKey;
  }
}
