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
      version: 6, // Increment version to trigger migration
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
        theme_preference TEXT DEFAULT 'light',
        ai_provider TEXT DEFAULT 'gemini',
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
        id TEXT PRIMARY KEY,
        user_id TEXT,
        image_url TEXT,
        local_image_path TEXT,
        s3_image_url TEXT,
        food_name TEXT NOT NULL,
        calories INTEGER,
        protein REAL,
        carbs REAL,
        fat REAL,
        health_score INTEGER,
        analysis_date TEXT,
        created_at INTEGER,
        synced_to_aws INTEGER DEFAULT 0,
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
    await db.execute('CREATE INDEX idx_foods_user_id ON foods(user_id)');
    await db.execute(
        'CREATE INDEX idx_foods_analysis_date ON foods(analysis_date)');
    await db.execute(
        'CREATE INDEX idx_user_profile_user_id ON user_profile(user_id)');
    await db.execute('CREATE INDEX idx_app_settings_key ON app_settings(key)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    print('🔄 Database upgrading from version $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // Add synced_to_aws column to foods table
      await _addColumnIfNotExists(
          db, 'foods', 'synced_to_aws', 'INTEGER DEFAULT 0');
      print('✅ Database upgraded: Added synced_to_aws column to foods table');
    }

    if (oldVersion < 3) {
      // Migrate from INTEGER id to TEXT id (UUID)
      print(
          '🔄 Database upgraded: Migrating foods table to use UUID for id column');

      // Create new table with UUID support
      await db.execute('''
        CREATE TABLE foods_new (
          id TEXT PRIMARY KEY,
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
          synced_to_aws INTEGER DEFAULT 0,
          FOREIGN KEY (user_id) REFERENCES user_profile(user_id) ON DELETE CASCADE
        )
      ''');

      // Copy data from old table to new table, generating UUIDs for existing records
      await db.execute('''
        INSERT INTO foods_new (id, user_id, image_url, food_name, calories, protein, carbs, fat, health_score, analysis_date, created_at, synced_to_aws)
        SELECT 
          'migrated-' || CAST(id AS TEXT) || '-' || CAST(created_at AS TEXT) as id,
          user_id, image_url, food_name, calories, protein, carbs, fat, health_score, analysis_date, created_at, synced_to_aws
        FROM foods
      ''');

      // Drop old table and rename new table
      await db.execute('DROP TABLE foods');
      await db.execute('ALTER TABLE foods_new RENAME TO foods');

      // Recreate indexes
      await db.execute('CREATE INDEX idx_foods_user_id ON foods(user_id)');
      await db.execute(
          'CREATE INDEX idx_foods_analysis_date ON foods(analysis_date)');

      print(
          '✅ Database upgraded: Successfully migrated to UUID-based food IDs');
    }

    if (oldVersion < 4) {
      // Add local_image_path and s3_image_url columns to foods table
      await _addColumnIfNotExists(db, 'foods', 'local_image_path', 'TEXT');
      await _addColumnIfNotExists(db, 'foods', 's3_image_url', 'TEXT');
      print(
          '✅ Database upgraded: Added local_image_path and s3_image_url columns to foods table');
    }

    if (oldVersion < 5) {
      // Version 5: Ensure all columns exist and handle any migration issues
      print(
          '🔄 Database upgraded: Version 5 migration - ensuring column consistency');

      // Ensure all required columns exist
      await _addColumnIfNotExists(db, 'foods', 'local_image_path', 'TEXT');
      await _addColumnIfNotExists(db, 'foods', 's3_image_url', 'TEXT');
      await _addColumnIfNotExists(
          db, 'foods', 'synced_to_aws', 'INTEGER DEFAULT 0');

      print(
          '✅ Database upgraded: Version 5 migration completed - all columns verified');
    }

    if (oldVersion < 6) {
      // Version 6: Force all users to use Gemini AI provider
      print('🔄 Database upgraded: Version 6 migration - forcing Gemini as AI provider');

      // Ensure ai_provider column exists first
      await _addColumnIfNotExists(db, 'user_profile', 'ai_provider', 'TEXT DEFAULT \'gemini\'');

      // Update all existing users to use Gemini
      await db.execute('''
        UPDATE user_profile
        SET ai_provider = 'gemini'
        WHERE ai_provider != 'gemini' OR ai_provider IS NULL
      ''');

      print('✅ Database upgraded: All users now use Gemini AI provider');
    }
  }

  /// Helper method to add a column only if it doesn't exist
  Future<void> _addColumnIfNotExists(Database db, String tableName,
      String columnName, String columnDefinition) async {
    try {
      // Check if column exists by trying to query it
      await db.rawQuery('SELECT $columnName FROM $tableName LIMIT 1');
      print(
          '📋 Column $columnName already exists in table $tableName, skipping...');
    } catch (e) {
      // Column doesn't exist, add it
      await db.execute(
          'ALTER TABLE $tableName ADD COLUMN $columnName $columnDefinition');
      print('✅ Added column $columnName to table $tableName');
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
      orderBy: 'created_at DESC',
    );
  }

  Future<int> updateFood(String id, Map<String, dynamic> food) async {
    final db = await database;
    return await db.update(
      'foods',
      food,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteFood(String id) async {
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

  // Get unsynced foods
  Future<List<Map<String, dynamic>>> getUnsyncedFoods(String userId) async {
    final db = await database;
    return await db.query(
      'foods',
      where: 'user_id = ? AND synced_to_aws = 0',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  // Mark food as synced
  Future<int> markFoodAsSynced(
      String userId, String foodName, String analysisDate) async {
    final db = await database;
    return await db.update(
      'foods',
      {'synced_to_aws': 1},
      where: 'user_id = ? AND food_name = ? AND analysis_date = ?',
      whereArgs: [userId, foodName, analysisDate],
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
