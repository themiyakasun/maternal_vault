import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/security/hardware_key_manager.dart';
import '../../../../data/datasources/encrypted_db_helper.dart';
import '../../domain/vault_setup_stage.dart';

/// Connects the 3-step UI sequence in [VaultSetupScreen] to the backend
/// security and database layers.
class VaultSetupService {
  static String? _pendingRecordId;

  /// Handles each [VaultSetupStage] during onboarding.
  static Future<void> runStage(VaultSetupStage stage) async {
    switch (stage) {
      case VaultSetupStage.creatingRecord:
        // Step 1: Create your secure record
        // Generate unique cryptographic UUID for the mother's record
        _pendingRecordId = const Uuid().v4();
        break;

      case VaultSetupStage.encrypting:
        // Step 2: Encrypting your data
        // 1. Generate/verify 256-bit AES master key in Android Keystore
        await HardwareKeyManager.getOrGenerateKey();
        // 2. Open and verify SQLCipher encrypted database
        await EncryptedDatabaseHelper.database;
        break;

      case VaultSetupStage.finishing:
        // Step 3: Getting everything ready
        // Seed initial record into the encrypted database
        final Database db = await EncryptedDatabaseHelper.database;
        final String recordId = _pendingRecordId ?? const Uuid().v4();

        await db.insert(
          'mother_profile',
          <String, Object?>{
            'id': recordId,
            'mother_name': null,
            'age': null,
            'gestational_weeks': null,
            'created_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        break;
    }
  }
}
