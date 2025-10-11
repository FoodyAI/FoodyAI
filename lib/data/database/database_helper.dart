import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'foody_db');
    print('Database path: $path');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create user_profile table
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT UNIQUE,
        email TEXT,
        display_name TEXT,
        photo_url TEXT,
        gender TEXT,
        age INTEGER,
        weight_kg REAL,
        height_cm REAL,
        activity_level TEXT,
        weight_goal TEXT,
        daily_calories INTEGER,
        bmi REAL,
        theme_preference TEXT DEFAULT 'system',
        ai_provider TEXT DEFAULT 'openai',
        measurement_unit TEXT DEFAULT 'metric',
        is_guest BOOLEAN DEFAULT 1,
        has_completed_onboarding BOOLEAN DEFAULT 0,
        created_at INTEGER,
        updated_at INTEGER
      )
    ''');

    // Create foods table
    await db.execute('''
      CREATE TABLE foods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        image_url TEXT,
        food_name TEXT NOT NULL,
        calories INTEGER,
        protein REAL,
        carbs REAL,
        fat REAL,
        health_score INTEGER,
        analysis_date TEXT,
        created_at INTEGER,
        FOREIGN KEY (user_id) REFERENCES user_profile(user_id) ON DELETE CASCADE
      )
    ''');

    // Create app_settings table for general app preferences
    await db.execute('''
      CREATE TABLE app_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        value TEXT,
        created_at INTEGER,
        updated_at INTEGER
      )
    ''');

    // Create indexes for better performance
    await db.execute(
        'CREATE INDEX idx_foods_user_id ON foods(user_id)');
    await db.execute(
        'CREATE INDEX idx_foods_analysis_date ON foods(analysis_date)');
    await db.execute(
        'CREATE INDEX idx_user_profile_user_id ON user_profile(user_id)');
    await db.execute('CREATE INDEX idx_app_settings_key ON app_settings(key)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    if (oldVersion < 1) {
      // Migration logic for version 1
    }
  }

  // User Profile Methods
  Future<int> insertUserProfile(Map<String, dynamic> userProfile) async {
    final db = await database;
    return await db.insert('user_profile', userProfile);
  }

  Future<int> updateUserProfile(
      String userId, Map<String, dynamic> userProfile) async {
    final db = await database;
    return await db.update(
      'user_profile',
      userProfile,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final db = await database;
    final result = await db.query(
      'user_profile',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getFirstUserProfile() async {
    final db = await database;
    final result = await db.query(
      'user_profile',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> deleteUserProfile(String userId) async {
    final db = await database;
    return await db.delete(
      'user_profile',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> clearAllUserProfiles() async {
    final db = await database;
    return await db.delete('user_profile');
  }

  // Food Methods
  Future<int> insertFood(Map<String, dynamic> food) async {
    final db = await database;
    return await db.insert('foods', food);
  }

  Future<List<Map<String, dynamic>>> getFoods(String userId) async {
    final db = await database;
    return await db.query(
      'foods',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getFoodsByDate(
      String userId, String date) async {
    final db = await database;
    return await db.query(
      'foods',
      where: 'user_id = ? AND analysis_date = ?',
      whereArgs: [userId, date],
      orderBy: 'created_at ASC',
    );
  }

  Future<int> updateFood(
      int id, Map<String, dynamic> food) async {
    final db = await database;
    return await db.update(
      'foods',
      food,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteFood(int id) async {
    final db = await database;
    return await db.delete(
      'foods',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllFoods(String userId) async {
    final db = await database;
    return await db.delete(
      'foods',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // App Settings Methods
  Future<void> setAppSetting(String key, String value) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      'app_settings',
      {
        'key': key,
        'value': value,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getAppSetting(String key) async {
    final db = await database;
    final result = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    return result.isNotEmpty ? result.first['value'] as String? : null;
  }

  Future<bool> getBoolAppSetting(String key,
      {bool defaultValue = false}) async {
    final value = await getAppSetting(key);
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true';
  }

  Future<int> getIntAppSetting(String key, {int defaultValue = 0}) async {
    final value = await getAppSetting(key);
    if (value == null) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  Future<double> getDoubleAppSetting(String key,
      {double defaultValue = 0.0}) async {
    final value = await getAppSetting(key);
    if (value == null) return defaultValue;
    return double.tryParse(value) ?? defaultValue;
  }

  Future<void> deleteAppSetting(String key) async {
    final db = await database;
    await db.delete(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  // Migration from SharedPreferences
  Future<void> migrateFromSharedPreferences() async {
    // This method will be called to migrate existing SharedPreferences data
    // Implementation will be added based on the migration strategy
  }

  // Utility Methods
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('user_profile');
    await db.delete('foods');
    await db.delete('app_settings');
  }
}
