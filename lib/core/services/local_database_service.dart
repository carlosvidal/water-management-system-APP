import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:water_readings_app/core/models/reading.dart';
import 'package:water_readings_app/core/models/condominium.dart';

class LocalDatabaseService {
  static Database? _database;
  static const String _databaseName = 'water_readings.db';
  static const int _databaseVersion = 1;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Readings table for offline storage
    await db.execute('''
      CREATE TABLE readings (
        id TEXT PRIMARY KEY,
        unit_id TEXT NOT NULL,
        period_id TEXT NOT NULL,
        value REAL NOT NULL,
        previous_value REAL,
        consumption REAL,
        photo1_path TEXT,
        photo2_path TEXT,
        notes TEXT,
        is_anomalous INTEGER NOT NULL DEFAULT 0,
        is_validated INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0,
        reading_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        validated_at TEXT,
        validated_by TEXT
      )
    ''');

    // Condominiums cache
    await db.execute('''
      CREATE TABLE condominiums (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        city TEXT,
        country TEXT,
        reading_day INTEGER,
        bank_account TEXT,
        bank_account_holder TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_synced TEXT
      )
    ''');

    // Blocks cache
    await db.execute('''
      CREATE TABLE blocks (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        condominium_id TEXT NOT NULL,
        max_units INTEGER,
        last_synced TEXT,
        FOREIGN KEY (condominium_id) REFERENCES condominiums (id)
      )
    ''');

    // Units cache
    await db.execute('''
      CREATE TABLE units (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        block_id TEXT NOT NULL,
        resident_id TEXT,
        area REAL,
        is_active INTEGER NOT NULL DEFAULT 1,
        last_synced TEXT,
        FOREIGN KEY (block_id) REFERENCES blocks (id)
      )
    ''');

    // Periods cache
    await db.execute('''
      CREATE TABLE periods (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        condominium_id TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_synced TEXT,
        FOREIGN KEY (condominium_id) REFERENCES condominiums (id)
      )
    ''');

    // Sync queue for failed uploads
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        action TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_attempt TEXT
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_readings_period ON readings (period_id)');
    await db.execute('CREATE INDEX idx_readings_unit ON readings (unit_id)');
    await db.execute('CREATE INDEX idx_readings_synced ON readings (is_synced)');
    await db.execute('CREATE INDEX idx_units_block ON units (block_id)');
    await db.execute('CREATE INDEX idx_blocks_condominium ON blocks (condominium_id)');
    await db.execute('CREATE INDEX idx_periods_condominium ON periods (condominium_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema migrations here
    if (oldVersion < 2) {
      // Example migration for version 2
      // await db.execute('ALTER TABLE readings ADD COLUMN new_field TEXT');
    }
  }

  // Reading operations
  Future<void> saveReading(Reading reading) async {
    final db = await database;
    await db.insert(
      'readings',
      {
        'id': reading.id,
        'unit_id': reading.unitId,
        'period_id': reading.periodId,
        'value': reading.value,
        'previous_value': reading.previousValue,
        'consumption': reading.consumption,
        'photo1_path': reading.photo1Path,
        'photo2_path': reading.photo2Path,
        'notes': reading.notes,
        'is_anomalous': reading.isAnomalous ? 1 : 0,
        'is_validated': reading.isValidated ? 1 : 0,
        'is_synced': reading.isSynced ? 1 : 0,
        'reading_date': reading.readingDate.toIso8601String(),
        'created_at': reading.createdAt.toIso8601String(),
        'validated_at': reading.validatedAt?.toIso8601String(),
        'validated_by': reading.validatedBy,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Reading>> getPendingReadings() async {
    final db = await database;
    final maps = await db.query(
      'readings',
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'created_at ASC',
    );

    return maps.map((map) => _readingFromMap(map)).toList();
  }

  Future<List<Reading>> getPeriodReadings(String periodId) async {
    final db = await database;
    final maps = await db.query(
      'readings',
      where: 'period_id = ?',
      whereArgs: [periodId],
      orderBy: 'reading_date ASC',
    );

    return maps.map((map) => _readingFromMap(map)).toList();
  }

  Future<void> markReadingAsSynced(String readingId) async {
    final db = await database;
    await db.update(
      'readings',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [readingId],
    );
  }

  Future<Reading?> getReading(String readingId) async {
    final db = await database;
    final maps = await db.query(
      'readings',
      where: 'id = ?',
      whereArgs: [readingId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _readingFromMap(maps.first);
  }

  // Cache operations for offline use
  Future<void> cacheCondominium(Condominium condominium) async {
    final db = await database;
    await db.insert(
      'condominiums',
      {
        'id': condominium.id,
        'name': condominium.name,
        'address': condominium.address,
        'city': condominium.city,
        'country': condominium.country,
        'reading_day': condominium.readingDay,
        'bank_account': condominium.bankAccount,
        'bank_account_holder': condominium.bankAccountHolder,
        'is_active': condominium.isActive ? 1 : 0,
        'created_at': condominium.createdAt.toIso8601String(),
        'updated_at': condominium.updatedAt.toIso8601String(),
        'last_synced': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Condominium>> getCachedCondominiums() async {
    final db = await database;
    final maps = await db.query('condominiums', orderBy: 'name ASC');
    
    return maps.map((map) => _condominiumFromMap(map)).toList();
  }

  // Sync queue operations
  Future<void> addToSyncQueue(String entityType, String entityId, String action, String data) async {
    final db = await database;
    await db.insert('sync_queue', {
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action,
      'data': data,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await database;
    return await db.query('sync_queue', orderBy: 'created_at ASC');
  }

  Future<void> removeSyncQueueItem(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  // Clear cache
  Future<void> clearCache() async {
    final db = await database;
    await db.delete('condominiums');
    await db.delete('blocks');
    await db.delete('units');
    await db.delete('periods');
  }

  // Database maintenance
  Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // Helper methods
  Reading _readingFromMap(Map<String, dynamic> map) {
    return Reading(
      id: map['id'],
      unitId: map['unit_id'],
      periodId: map['period_id'],
      value: map['value'],
      previousValue: map['previous_value'],
      consumption: map['consumption'],
      photo1Path: map['photo1_path'],
      photo2Path: map['photo2_path'],
      notes: map['notes'],
      isAnomalous: map['is_anomalous'] == 1,
      isValidated: map['is_validated'] == 1,
      isSynced: map['is_synced'] == 1,
      readingDate: DateTime.parse(map['reading_date']),
      createdAt: DateTime.parse(map['created_at']),
      validatedAt: map['validated_at'] != null ? DateTime.parse(map['validated_at']) : null,
      validatedBy: map['validated_by'],
    );
  }

  Condominium _condominiumFromMap(Map<String, dynamic> map) {
    return Condominium(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      city: map['city'],
      country: map['country'],
      readingDay: map['reading_day'],
      bankAccount: map['bank_account'],
      bankAccountHolder: map['bank_account_holder'],
      planId: map['plan_id'] ?? 'default-plan-id', // Provide default value for existing data
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}

// Provider
final localDatabaseProvider = Provider<LocalDatabaseService>((ref) {
  return LocalDatabaseService();
});