import 'package:maternal_vault/core/security/hardware_key_manager.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class EncryptedDatabaseHelper {
  static const String dbName = "maternal_vault.db";
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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS mother_profile (
            id TEXT PRIMARY KEY,
            mother_name TEXT,
            age INTEGER,
            gestational_weeks INTEGER,
            created_at TEXT
          );
        ''');
      },
    );
  }

  // 1. Check if the database file exists on disk
  static Future<bool> doesDatabaseExist() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);
    return await databaseExists(path);
  }

  // 2. Query all tables inside the encrypted database
  static Future<List<String>> getCreatedTables() async {
    final db = await database;
    final List<Map<String, Object?>> tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'android_%' AND name NOT LIKE 'sqlite_%';",
    );
    return tables.map((row) => row['name'] as String).toList();
  }

  // 3. Inspect records inside mother_profile
  static Future<List<Map<String, Object?>>> getMotherProfiles() async {
    final db = await database;
    return await db.query('mother_profile');
  }
}
