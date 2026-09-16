import 'dart:convert';

import 'package:maternal_vault/core/security/hardware_key_manager.dart';
import 'package:maternal_vault/features/mother/domain/basic_profile.dart';
import 'package:maternal_vault/features/mother/domain/clinic_record.dart';
import 'package:maternal_vault/features/mother/domain/delivery_plan.dart';
import 'package:maternal_vault/features/mother/domain/key_vitals.dart';
import 'package:maternal_vault/features/mother/domain/medical_history.dart';
import 'package:maternal_vault/features/mother/domain/obstetric_history.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class EncryptedDatabaseHelper {
  static const String dbName = 'maternal_vault.db';
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final String hexKey = await HardwareKeyManager.getOrGenerateKey();

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    return await openDatabase(
      path,
      password: "x'$hexKey'",
      version: 2,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _createTables(db);
      },
      onOpen: (db) async {
        await _createTables(db);
      },
    );
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mother_profile (
        id TEXT PRIMARY KEY,
        mother_name TEXT,
        age INTEGER,
        gestational_weeks INTEGER,
        profile_json TEXT,
        vitals_json TEXT,
        updated_at TEXT,
        created_at TEXT
      );
    ''');

    // Ensure columns exist in case the table was created in an earlier schema
    final columns = await db.rawQuery('PRAGMA table_info(mother_profile);');
    final colNames =
        columns.map((c) => c['name'] as String).toSet();
    if (!colNames.contains('profile_json')) {
      await db.execute(
          'ALTER TABLE mother_profile ADD COLUMN profile_json TEXT;');
    }
    if (!colNames.contains('vitals_json')) {
      await db
          .execute('ALTER TABLE mother_profile ADD COLUMN vitals_json TEXT;');
    }
    if (!colNames.contains('updated_at')) {
      await db.execute('ALTER TABLE mother_profile ADD COLUMN updated_at TEXT;');
    }

    await db.execute('''
      CREATE TABLE IF NOT EXISTS clinic_visits (
        id TEXT PRIMARY KEY,
        week INTEGER,
        date TEXT,
        systolic INTEGER,
        diastolic INTEGER,
        weight_kg REAL,
        status TEXT,
        visit_json TEXT,
        created_at TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS obstetric_history (
        id TEXT PRIMARY KEY,
        gravida INTEGER,
        para INTEGER,
        history_json TEXT,
        updated_at TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS antenatal_care (
        id TEXT PRIMARY KEY,
        care_json TEXT,
        updated_at TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS delivery_plan (
        id TEXT PRIMARY KEY,
        plan_json TEXT,
        updated_at TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS medical_history (
        id TEXT PRIMARY KEY,
        history_json TEXT,
        updated_at TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_audit_log (
        id TEXT PRIMARY KEY,
        sync_timestamp TEXT,
        clinic_name TEXT,
        midwife_name TEXT,
        record_version INTEGER,
        payload_hash TEXT
      );
    ''');
  }

  /// Atomically saves all data parsed from a midwife dashboard sync payload.
  static Future<void> saveSyncData({
    required BasicProfile profile,
    required KeyVitals vitals,
    MedicalHistory medicalHistory = const MedicalHistory.empty(),
    required ObstetricHistory obstetricHistory,
    required ClinicRecord clinicRecord,
    required DeliveryPlan deliveryPlan,
    String? clinicName,
    String? midwifeName,
    int version = 1,
    String? payloadHash,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      // 1. mother_profile
      final gestationalWeeks = clinicRecord.visits.isNotEmpty
          ? clinicRecord.visits.first.week
          : (obstetricHistory.poaAtRegistrationWeeks ?? 0);
      await txn.insert(
        'mother_profile',
        <String, dynamic>{
          'id': 'active_profile',
          'mother_name': profile.motherName,
          'age': profile.mother.age,
          'gestational_weeks': gestationalWeeks,
          'profile_json': jsonEncode(profile.toJson()),
          'vitals_json': jsonEncode(vitals.toJson()),
          'updated_at': now,
          'created_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. medical_history
      await txn.insert(
        'medical_history',
        <String, dynamic>{
          'id': 'active_medical_history',
          'history_json': jsonEncode(medicalHistory.toJson()),
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 3. obstetric_history
      await txn.insert(
        'obstetric_history',
        <String, dynamic>{
          'id': 'active_history',
          'gravida': obstetricHistory.gravidity,
          'para': obstetricHistory.parity,
          'history_json': jsonEncode(obstetricHistory.toJson()),
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 4. antenatal_care
      await txn.insert(
        'antenatal_care',
        <String, dynamic>{
          'id': 'active_care',
          'care_json': jsonEncode(clinicRecord.toJson()),
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 5. clinic_visits
      await txn.delete('clinic_visits');
      for (final visit in clinicRecord.visits) {
        final visitId =
            'visit_${visit.week}_${visit.date.millisecondsSinceEpoch}';
        await txn.insert(
          'clinic_visits',
          <String, dynamic>{
            'id': visitId,
            'week': visit.week,
            'date': visit.date.toIso8601String(),
            'systolic': visit.systolic,
            'diastolic': visit.diastolic,
            'weight_kg': visit.weightKg,
            'status': visit.status.name,
            'visit_json': jsonEncode(visit.toJson()),
            'created_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 6. delivery_plan
      await txn.insert(
        'delivery_plan',
        <String, dynamic>{
          'id': 'active_delivery_plan',
          'plan_json': jsonEncode(deliveryPlan.toJson()),
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 7. sync_audit_log
      await txn.insert(
        'sync_audit_log',
        <String, dynamic>{
          'id': 'sync_${DateTime.now().millisecondsSinceEpoch}',
          'sync_timestamp': now,
          'clinic_name': clinicName ?? 'MOH Clinic',
          'midwife_name': midwifeName ?? 'Midwife In-charge',
          'record_version': version,
          'payload_hash': payloadHash ?? '',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  /// Loads the full maternal vault dataset saved in the encrypted database.
  /// Returns null if no real midwife dashboard sync has occurred yet.
  static Future<
      ({
        BasicProfile profile,
        KeyVitals vitals,
        MedicalHistory medicalHistory,
        ObstetricHistory obstetricHistory,
        ClinicRecord clinicRecord,
        DeliveryPlan deliveryPlan,
      })?> loadSyncedData() async {
    final db = await database;

    // Only load if a real midwife sync was completed and logged
    final syncLog = await db.query('sync_audit_log', limit: 1);
    if (syncLog.isEmpty) return null;

    final profileRows = await db.query('mother_profile', limit: 1);
    if (profileRows.isEmpty) return null;

    final profileRow = profileRows.first;
    final profileJsonStr = profileRow['profile_json'] as String?;
    final vitalsJsonStr = profileRow['vitals_json'] as String?;

    final profile = profileJsonStr != null && profileJsonStr.isNotEmpty
        ? BasicProfile.fromJson(
            jsonDecode(profileJsonStr) as Map<String, dynamic>)
        : const BasicProfile.empty();

    final vitals = vitalsJsonStr != null && vitalsJsonStr.isNotEmpty
        ? KeyVitals.fromJson(jsonDecode(vitalsJsonStr) as Map<String, dynamic>)
        : const KeyVitals.empty();

    // Medical History
    final medRows = await db.query('medical_history', limit: 1);
    final medicalHistory = medRows.isNotEmpty &&
            medRows.first['history_json'] != null
        ? MedicalHistory.fromJson(
            jsonDecode(medRows.first['history_json'] as String)
                as Map<String, dynamic>)
        : const MedicalHistory.empty();

    // Obstetric History
    final historyRows = await db.query('obstetric_history', limit: 1);
    final history = historyRows.isNotEmpty &&
            historyRows.first['history_json'] != null
        ? ObstetricHistory.fromJson(
            jsonDecode(historyRows.first['history_json'] as String)
                as Map<String, dynamic>)
        : const ObstetricHistory.empty();

    // Antenatal Care & Records
    final careRows = await db.query('antenatal_care', limit: 1);
    ClinicRecord clinicRecord;
    if (careRows.isNotEmpty && careRows.first['care_json'] != null) {
      clinicRecord = ClinicRecord.fromJson(
          jsonDecode(careRows.first['care_json'] as String)
              as Map<String, dynamic>);
    } else {
      clinicRecord = const ClinicRecord.empty();
    }

    // Clinic Visits (ordered)
    final visitRows =
        await db.query('clinic_visits', orderBy: 'week DESC, date DESC');
    if (visitRows.isNotEmpty) {
      final visits = visitRows
          .map((row) => ClinicVisit.fromJson(
              jsonDecode(row['visit_json'] as String) as Map<String, dynamic>))
          .toList();
      clinicRecord = clinicRecord.copyWith(visits: visits);
    }

    // Delivery Plan
    final planRows = await db.query('delivery_plan', limit: 1);
    final deliveryPlan =
        planRows.isNotEmpty && planRows.first['plan_json'] != null
            ? DeliveryPlan.fromJson(
                jsonDecode(planRows.first['plan_json'] as String)
                    as Map<String, dynamic>)
            : const DeliveryPlan.empty();

    return (
      profile: profile,
      vitals: vitals,
      medicalHistory: medicalHistory,
      obstetricHistory: history,
      clinicRecord: clinicRecord,
      deliveryPlan: deliveryPlan,
    );
  }

  /// Clears all stored records across all tables in the encrypted database.
  static Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('mother_profile');
      await txn.delete('medical_history');
      await txn.delete('clinic_visits');
      await txn.delete('antenatal_care');
      await txn.delete('obstetric_history');
      await txn.delete('delivery_plan');
      await txn.delete('sync_audit_log');
    });
  }

  /// Checks whether a real midwife dashboard sync was completed.
  static Future<bool> hasCompletedMidwifeSync() async {
    final db = await database;
    final res =
        await db.rawQuery('SELECT COUNT(*) as count FROM sync_audit_log');
    final count = Sqflite.firstIntValue(res) ?? 0;
    return count > 0;
  }

  /// Checks whether any synced mother records exist in the encrypted store.
  static Future<bool> hasSyncedRecords() async {
    return await hasCompletedMidwifeSync();
  }

  /// Returns the most recent sync audit entry, or null if no sync has occurred.
  static Future<Map<String, dynamic>?> getLastSyncAudit() async {
    final db = await database;
    final rows = await db.query(
      'sync_audit_log',
      orderBy: 'sync_timestamp DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Check if the database file exists on disk
  static Future<bool> doesDatabaseExist() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);
    return await databaseExists(path);
  }

  /// Query all tables inside the encrypted database
  static Future<List<String>> getCreatedTables() async {
    final db = await database;
    final List<Map<String, Object?>> tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'android_%' AND name NOT LIKE 'sqlite_%';",
    );
    return tables.map((row) => row['name'] as String).toList();
  }

  /// Inspect records inside mother_profile
  static Future<List<Map<String, Object?>>> getMotherProfiles() async {
    final db = await database;
    return await db.query('mother_profile');
  }
}
