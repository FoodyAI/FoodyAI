import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/sqlite_service.dart';
import '../../services/aws_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_profile.dart';
import '../../services/notification_service.dart';

/// Service to manage synchronization between SQLite and AWS
/// Uses SharedPreferences to persist sync flags across app restarts
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  // SharedPreferences keys for sync flags
  static const String _profileSyncFlagKey = 'profile_needs_sync';
  static const String _notificationSyncFlagKey = 'notification_needs_sync';
  static const String _themeSyncFlagKey = 'theme_needs_sync';

  final SQLiteService _sqliteService = SQLiteService();
  final AWSService _awsService = AWSService();
  final NotificationService _notificationService = NotificationService();

  // ==================== SYNC FLAG MANAGEMENT ====================

  /// Mark profile as needing sync to AWS
  Future<void> markProfileNeedsSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_profileSyncFlagKey, true);
      print('🔄 SyncService: Profile marked as needs sync');
    } catch (e) {
      print('❌ SyncService: Error marking profile for sync: $e');
    }
  }

  /// Mark notification settings as needing sync to AWS
  Future<void> markNotificationNeedsSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationSyncFlagKey, true);
      print('🔄 SyncService: Notification settings marked as needs sync');
    } catch (e) {
      print('❌ SyncService: Error marking notification for sync: $e');
    }
  }

  /// Mark theme as needing sync to AWS
  Future<void> markThemeNeedsSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeSyncFlagKey, true);
      print('🔄 SyncService: Theme marked as needs sync');
    } catch (e) {
      print('❌ SyncService: Error marking theme for sync: $e');
    }
  }

  /// Check if profile needs sync
  Future<bool> hasProfilePendingSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_profileSyncFlagKey) ?? false;
    } catch (e) {
      print('❌ SyncService: Error checking profile sync flag: $e');
      return false;
    }
  }

  /// Check if notification settings need sync
  Future<bool> hasNotificationPendingSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_notificationSyncFlagKey) ?? false;
    } catch (e) {
      print('❌ SyncService: Error checking notification sync flag: $e');
      return false;
    }
  }

  /// Check if theme needs sync
  Future<bool> hasThemePendingSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_themeSyncFlagKey) ?? false;
    } catch (e) {
      print('❌ SyncService: Error checking theme sync flag: $e');
      return false;
    }
  }

  /// Check if ANY data needs sync
  Future<bool> hasAnyPendingSync() async {
    final profilePending = await hasProfilePendingSync();
    final notificationPending = await hasNotificationPendingSync();
    final themePending = await hasThemePendingSync();
    return profilePending || notificationPending || themePending;
  }

  /// Clear profile sync flag
  Future<void> clearProfileSyncFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileSyncFlagKey);
      print('✅ SyncService: Profile sync flag cleared');
    } catch (e) {
      print('❌ SyncService: Error clearing profile sync flag: $e');
    }
  }

  /// Clear notification sync flag
  Future<void> clearNotificationSyncFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationSyncFlagKey);
      print('✅ SyncService: Notification sync flag cleared');
    } catch (e) {
      print('❌ SyncService: Error clearing notification sync flag: $e');
    }
  }

  /// Clear theme sync flag
  Future<void> clearThemeSyncFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_themeSyncFlagKey);
      print('✅ SyncService: Theme sync flag cleared');
    } catch (e) {
      print('❌ SyncService: Error clearing theme sync flag: $e');
    }
  }

  /// Clear ALL sync flags (use on sign out / delete account)
  Future<void> clearAllSyncFlags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileSyncFlagKey);
      await prefs.remove(_notificationSyncFlagKey);
      await prefs.remove(_themeSyncFlagKey);
      print('✅ SyncService: All sync flags cleared');
    } catch (e) {
      print('❌ SyncService: Error clearing all sync flags: $e');
    }
  }

  // ==================== SYNC OPERATIONS ====================

  /// Sync all pending changes to AWS
  /// Called when connection is restored
  Future<void> syncPendingChanges() async {
    print('🔄 SyncService: Starting sync of pending changes...');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ SyncService: No user signed in, skipping sync');
      return;
    }

    // Check what needs to be synced
    final profilePending = await hasProfilePendingSync();
    final notificationPending = await hasNotificationPendingSync();
    final themePending = await hasThemePendingSync();

    if (!profilePending && !notificationPending && !themePending) {
      print('✅ SyncService: No pending syncs');
      return;
    }

    print('📋 SyncService: Pending syncs - Profile: $profilePending, Notification: $notificationPending, Theme: $themePending');

    // Sync each component
    if (profilePending) {
      await _syncProfile(user.uid);
    }

    if (notificationPending) {
      await _syncNotificationSettings(user.uid);
    }

    if (themePending) {
      await _syncTheme(user.uid);
    }

    print('✅ SyncService: Sync completed');
  }

  /// Sync profile data to AWS
  Future<bool> _syncProfile(String userId) async {
    try {
      print('📤 SyncService: Syncing profile to AWS...');

      // Get profile from SQLite
      final profile = await _sqliteService.getUserProfile(userId: userId);
      if (profile == null) {
        print('⚠️ SyncService: No profile found in SQLite, clearing sync flag');
        await clearProfileSyncFlag();
        return false;
      }

      // Get user email (required by AWS)
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        print('❌ SyncService: No user email available');
        return false;
      }

      // Get measurement unit and theme from SQLite
      final isMetric = await _sqliteService.getIsMetric();
      final measurementUnit = isMetric ? 'metric' : 'imperial';
      final themePreference = await _sqliteService.getThemePreference() ?? 'system';  // Default to 'system' if null

      // Sync to AWS using saveUserProfile with ALL data
      final result = await _awsService.saveUserProfile(
        userId: userId,
        email: user.email!,
        displayName: user.displayName,
        photoUrl: user.photoURL,
        gender: profile.gender,
        age: profile.age,
        weight: profile.weightKg,
        height: profile.heightCm,
        activityLevel: profile.activityLevel.name,
        goal: profile.weightGoal.name,
        aiProvider: profile.aiProvider.name,
        measurementUnit: measurementUnit,
        themePreference: themePreference,  // ✅ NOW INCLUDED!
      );

      if (result != null && result['success'] == true) {
        // Clear sync flag on success
        await clearProfileSyncFlag();
        print('✅ SyncService: Profile synced successfully');
        return true;
      } else {
        print('❌ SyncService: Profile sync returned null or failed');
        return false;
      }
    } catch (e) {
      print('❌ SyncService: Failed to sync profile: $e');
      // Keep sync flag set for retry
      return false;
    }
  }

  /// Sync notification settings to AWS
  Future<bool> _syncNotificationSettings(String userId) async {
    try {
      print('📤 SyncService: Syncing notification settings to AWS...');

      // Get notification status from SQLite
      final profile = await _sqliteService.getUserProfile(userId: userId);
      final notificationsEnabled = profile?.notificationsEnabled ?? true;

      // Update AWS
      final success = await _notificationService.updateNotificationPreferences(
        userId: userId,
        notificationsEnabled: notificationsEnabled,
      );

      if (success) {
        await clearNotificationSyncFlag();
        print('✅ SyncService: Notification settings synced successfully');
        return true;
      } else {
        print('❌ SyncService: Failed to sync notification settings');
        return false;
      }
    } catch (e) {
      print('❌ SyncService: Failed to sync notification settings: $e');
      return false;
    }
  }

  /// Sync theme to AWS
  Future<bool> _syncTheme(String userId) async {
    try {
      print('📤 SyncService: Syncing theme to AWS...');

      // Get theme from SQLite
      final themePreference = await _sqliteService.getThemePreference();
      if (themePreference == null) {
        print('⚠️ SyncService: No theme preference found, clearing sync flag');
        await clearThemeSyncFlag();
        return false;
      }

      // IMPORTANT: Get FULL profile from SQLite to avoid overwriting other fields
      final profile = await _sqliteService.getUserProfile(userId: userId);
      final isMetric = await _sqliteService.getIsMetric();
      final measurementUnit = isMetric ? 'metric' : 'imperial';

      // Get user email (required by AWS)
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        print('❌ SyncService: No user email available');
        return false;
      }

      // Sync to AWS using saveUserProfile with ALL profile data
      final result = await _awsService.saveUserProfile(
        userId: userId,
        email: user.email!,
        displayName: user.displayName,
        photoUrl: user.photoURL,
        // Include ALL profile fields to prevent overwriting
        gender: profile?.gender,
        age: profile?.age,
        weight: profile?.weightKg,
        height: profile?.heightCm,
        activityLevel: profile?.activityLevel.name,
        goal: profile?.weightGoal.name,
        aiProvider: profile?.aiProvider.name,
        measurementUnit: measurementUnit,
        // Include theme preference
        themePreference: themePreference,
      );

      if (result != null && result['success'] == true) {
        await clearThemeSyncFlag();
        print('✅ SyncService: Theme synced successfully');
        return true;
      } else {
        print('❌ SyncService: Theme sync returned null or failed');
        return false;
      }
    } catch (e) {
      print('❌ SyncService: Failed to sync theme: $e');
      return false;
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Try to sync profile immediately (if online)
  /// If offline or fails, mark for later sync
  Future<bool> trySyncProfile(UserProfile profile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      print('⚠️ SyncService: No user signed in or no email, marking profile for sync');
      await markProfileNeedsSync();
      return false;
    }

    try {
      // Get measurement unit and theme from SQLite
      final isMetric = await _sqliteService.getIsMetric();
      final measurementUnit = isMetric ? 'metric' : 'imperial';
      final themePreference = await _sqliteService.getThemePreference() ?? 'system';  // Default to 'system' if null

      final result = await _awsService.saveUserProfile(
        userId: user.uid,
        email: user.email!,
        displayName: user.displayName,
        photoUrl: user.photoURL,
        gender: profile.gender,
        age: profile.age,
        weight: profile.weightKg,
        height: profile.heightCm,
        activityLevel: profile.activityLevel.name,
        goal: profile.weightGoal.name,
        aiProvider: profile.aiProvider.name,
        measurementUnit: measurementUnit,
        themePreference: themePreference,  // ✅ NOW INCLUDED!
      );

      if (result != null && result['success'] == true) {
        print('✅ SyncService: Profile synced immediately');
        return true;
      } else {
        print('❌ SyncService: Immediate sync returned null or failed, marking for later');
        await markProfileNeedsSync();
        return false;
      }
    } catch (e) {
      print('❌ SyncService: Immediate sync failed, marking for later: $e');
      await markProfileNeedsSync();
      return false;
    }
  }

  /// Try to sync notification settings immediately
  Future<bool> trySyncNotificationSettings(String userId, bool enabled) async {
    try {
      final success = await _notificationService.updateNotificationPreferences(
        userId: userId,
        notificationsEnabled: enabled,
      );

      if (success) {
        print('✅ SyncService: Notification settings synced immediately');
        return true;
      } else {
        print('❌ SyncService: Immediate notification sync failed, marking for later');
        await markNotificationNeedsSync();
        return false;
      }
    } catch (e) {
      print('❌ SyncService: Immediate notification sync failed, marking for later: $e');
      await markNotificationNeedsSync();
      return false;
    }
  }

  /// Try to sync theme preference immediately
  Future<bool> trySyncTheme(String themePreference) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      print('⚠️ SyncService: No user signed in, marking theme for sync');
      await markThemeNeedsSync();
      return false;
    }

    try {
      // IMPORTANT: Get FULL profile from SQLite to avoid overwriting other fields
      final profile = await _sqliteService.getUserProfile(userId: user.uid);
      final isMetric = await _sqliteService.getIsMetric();
      final measurementUnit = isMetric ? 'metric' : 'imperial';

      // Sync theme to AWS using saveUserProfile with ALL profile data
      final result = await _awsService.saveUserProfile(
        userId: user.uid,
        email: user.email!,
        displayName: user.displayName,
        photoUrl: user.photoURL,
        // Include ALL profile fields to prevent overwriting
        gender: profile?.gender,
        age: profile?.age,
        weight: profile?.weightKg,
        height: profile?.heightCm,
        activityLevel: profile?.activityLevel.name,
        goal: profile?.weightGoal.name,
        aiProvider: profile?.aiProvider.name,
        measurementUnit: measurementUnit,
        // Include theme preference
        themePreference: themePreference,
      );

      if (result != null && result['success'] == true) {
        print('✅ SyncService: Theme synced immediately');
        return true;
      } else {
        print('❌ SyncService: Immediate theme sync failed, marking for later');
        await markThemeNeedsSync();
        return false;
      }
    } catch (e) {
      print('❌ SyncService: Immediate theme sync failed, marking for later: $e');
      await markThemeNeedsSync();
      return false;
    }
  }

  /// Sync on app startup (if user is signed in and has pending syncs)
  Future<void> syncOnStartup() async {
    print('🚀 SyncService: Checking for pending syncs on startup...');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('ℹ️ SyncService: No user signed in, skipping startup sync');
      return;
    }

    final hasPending = await hasAnyPendingSync();
    if (hasPending) {
      print('🔄 SyncService: Found pending syncs on startup, syncing...');
      await syncPendingChanges();
    } else {
      print('✅ SyncService: No pending syncs on startup');
    }
  }
}
