import 'sqlite_service.dart';

class MigrationService {
  final SQLiteService _sqliteService = SQLiteService();

  /// Initializes SQLite database and marks migration as completed
  /// This should be called once during app initialization
  Future<void> migrateFromSharedPreferences() async {
    try {
      // Check if migration has already been completed
      final migrationCompleted = await _sqliteService.getBoolAppSetting('migration_completed', defaultValue: false);
      if (migrationCompleted) {
        print('✅ Migration already completed');
        return; // Migration already completed
      }

      print('🔄 Initializing SQLite database...');

      // Initialize the database (this will create tables if they don't exist)
      await _sqliteService.getUserProfile(); // This triggers database initialization
      
      // Mark migration as completed
      await _sqliteService.setAppSetting('migration_completed', 'true');
      
      print('✅ SQLite database initialized successfully!');
      
    } catch (e) {
      print('❌ Database initialization failed: $e');
      // Don't throw error to prevent app crash
    }
  }

  /// Checks if migration is needed
  Future<bool> isMigrationNeeded() async {
    try {
      final migrationCompleted = await _sqliteService.getBoolAppSetting('migration_completed', defaultValue: false);
      return !migrationCompleted;
    } catch (e) {
      print('❌ Error checking migration status: $e');
      return false;
    }
  }
}
