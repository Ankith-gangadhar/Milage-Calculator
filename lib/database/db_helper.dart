import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/vehicle.dart';
import '../models/fuel_entry.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mileage_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: _configureDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE fuel_entries ADD COLUMN rate REAL');
      await db.execute('ALTER TABLE fuel_entries ADD COLUMN fuelType TEXT');
      await db.execute('ALTER TABLE fuel_entries ADD COLUMN bunkName TEXT');
    }
  }

  Future _configureDB(Database db) async {
    // Enable foreign key support to allow ON DELETE CASCADE
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        initialOdometer REAL NOT NULL,
        useReserveOffset INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE fuel_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleId INTEGER NOT NULL,
        odometer REAL NOT NULL,
        litres REAL NOT NULL,
        date TEXT NOT NULL,
        reserveOdometer REAL,
        reserveOffset REAL,
        distance REAL,
        mileage REAL,
        rate REAL,
        fuelType TEXT,
        bunkName TEXT,
        FOREIGN KEY (vehicleId) REFERENCES vehicles (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  // --- VEHICLE CRUD ---

  Future<int> insertVehicle(Vehicle vehicle) async {
    final db = await instance.database;
    return await db.insert('vehicles', vehicle.toMap());
  }

  Future<List<Vehicle>> getVehicles() async {
    final db = await instance.database;
    final result = await db.query('vehicles');
    return result.map((json) => Vehicle.fromMap(json)).toList();
  }

  Future<int> updateVehicle(Vehicle vehicle) async {
    final db = await instance.database;
    return await db.update(
      'vehicles',
      vehicle.toMap(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }

  Future<int> deleteVehicle(int id) async {
    final db = await instance.database;
    return await db.delete(
      'vehicles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- FUEL ENTRY CRUD ---

  Future<int> insertFuelEntry(FuelEntry entry) async {
    final db = await instance.database;
    return await db.insert('fuel_entries', entry.toMap());
  }

  Future<List<FuelEntry>> getFuelEntries(int vehicleId) async {
    final db = await instance.database;
    final result = await db.query(
      'fuel_entries',
      where: 'vehicleId = ?',
      orderBy: 'date DESC, odometer DESC',
      whereArgs: [vehicleId],
    );
    return result.map((json) => FuelEntry.fromMap(json)).toList();
  }

  Future<List<FuelEntry>> getAllFuelEntries() async {
    final db = await instance.database;
    final result = await db.query('fuel_entries', orderBy: 'date DESC, odometer DESC');
    return result.map((json) => FuelEntry.fromMap(json)).toList();
  }

  Future<int> updateFuelEntry(FuelEntry entry) async {
    final db = await instance.database;
    return await db.update(
      'fuel_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteFuelEntry(int id) async {
    final db = await instance.database;
    return await db.delete(
      'fuel_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- SETTINGS CRUD ---
  Future<void> saveSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await instance.database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isNotEmpty) {
      return result.first['value'] as String?;
    }
    return null;
  }

  // Close the database connection
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
