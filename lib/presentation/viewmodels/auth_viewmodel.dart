import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/sync_service.dart' as old_sync;
import '../../core/services/sync_service.dart';
import '../../services/aws_service.dart';
import '../../services/authentication_flow.dart';
import '../../services/notification_service.dart';
import '../../data/repositories/user_profile_repository_impl.dart';
import '../../data/services/sqlite_service.dart';
import '../../core/events/profile_update_event.dart';
import 'image_analysis_viewmodel.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final old_sync.SyncService _oldSyncService = old_sync.SyncService();
  final SyncService _syncService = SyncService();
  final AWSService _awsService = AWSService();
  final AuthenticationFlow _authFlow = AuthenticationFlow();
  final NotificationService _notificationService = NotificationService();
  final UserProfileRepositoryImpl _userProfileRepository =
      UserProfileRepositoryImpl();

  User? _user;
  AuthState _authState = AuthState.initial;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isDataLoading = false; // Flag to prevent duplicate data loading

  // Getters
  User? get user => _user;
  AuthState get authState => _authState;
  bool get isSignedIn => _user != null && _authState == AuthState.authenticated;
  bool get isLoading => _isLoading;
  String? get userEmail => _user?.email;
  String? get userDisplayName => _user?.displayName;
  String? get userPhotoURL => _user?.photoURL;
  String? get errorMessage => _errorMessage;

  AuthViewModel() {
    _initializeAuth();
  }

  void _initializeAuth() {
    // 🔧 FIX #5 (CRITICAL): Wait for Firebase to restore persisted session
    // Firebase Auth takes time to restore session from local storage, especially offline
    // We need to check TWICE: immediately + after a short delay

    // First check (may be null if Firebase hasn't restored yet)
    _user = _authService.currentUser;
    if (_user != null) {
      print('✅ AuthViewModel: Found persisted user immediately: ${_user!.email}');
      _setAuthState(AuthState.authenticated);
    } else {
      print('⏳ AuthViewModel: No user found immediately, waiting for Firebase to restore session...');
      _setAuthState(AuthState.initial); // Keep initial state while waiting

      // Give Firebase time to restore session (especially important offline)
      Future.delayed(const Duration(milliseconds: 500), () {
        _user = _authService.currentUser;
        if (_user != null) {
          print('✅ AuthViewModel: Found persisted user after delay: ${_user!.email}');
          _setAuthState(AuthState.authenticated);
          notifyListeners();
        } else {
          print('ℹ️ AuthViewModel: No persisted user found after delay');
          _setAuthState(AuthState.unauthenticated);
          notifyListeners();
        }
      });
    }

    // Listen to Firebase Auth state changes for future updates
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      if (user != null) {
        print('✅ AuthViewModel: Auth state changed - user signed in: ${user.email}');
        _setAuthState(AuthState.authenticated);
      } else {
        print('ℹ️ AuthViewModel: Auth state changed - user signed out');
        _setAuthState(AuthState.unauthenticated);
      }
      notifyListeners();
    });
  }

  /// 🔧 FIX #4: Public method to trigger sync AFTER routing (called from home screen)
  /// This ensures routing happens fast based on local data, then syncs in background
  Future<void> syncAfterRouting() async {
    // Skip if data is already being loaded
    if (_isDataLoading) {
      print('⏭️ AuthViewModel: Skipping sync - data already loading');
      return;
    }

    if (_user == null) {
      print('⏭️ AuthViewModel: No user signed in, skipping sync');
      return;
    }

    try {
      _isDataLoading = true;
      print('🔄 AuthViewModel: Starting background data sync after routing...');
      // Load ALL user data from AWS (profile + foods)
      await _oldSyncService.loadUserDataFromAWS();
      print('✅ AuthViewModel: Background data sync completed');

      // Notify listeners that profile data was updated
      ProfileUpdateEvent.notifyUpdate();
    } catch (e) {
      print('⚠️ AuthViewModel: Background sync failed: $e');
      // Don't propagate background sync errors to UI
    } finally {
      _isDataLoading = false;
    }
  }

  /// Enhanced Google Sign-In with smart flow handling
  Future<bool> signInWithGoogle(BuildContext? context) async {
    try {
      _setLoading(true);
      _clearError();

      print('🔐 AuthViewModel: Starting Google Sign-In...');

      final user = await _authService.signInWithGoogle();

      if (user != null) {
        _user = user;
        _setAuthState(AuthState.authenticated);

        print('✅ AuthViewModel: Google Sign-In successful for ${user.email}');

        // Initialize notification service FIRST to request permission immediately
        print('🔔 AuthViewModel: Initializing notification service...');
        try {
          await _notificationService.initialize(userId: user.uid);
          print('✅ AuthViewModel: Notification service initialized');
        } catch (e) {
          print('⚠️ AuthViewModel: Failed to initialize notifications: $e');
          // Continue anyway - notifications are not critical for sign-in
        }

        // Load user data from AWS FIRST before navigation
        print('🔄 AuthViewModel: Loading user data before navigation...');
        try {
          _isDataLoading = true;
          await _oldSyncService.loadUserDataFromAWS();
          print('✅ AuthViewModel: User data loaded successfully');
          ProfileUpdateEvent.notifyUpdate();

          // Reload food analyses in the UI after AWS sync
          if (context != null && context.mounted) {
            try {
              final imageAnalysisVM = context.read<ImageAnalysisViewModel>();
              // Add a small delay to ensure data is fully saved to SQLite
              await Future.delayed(const Duration(milliseconds: 500));
              await imageAnalysisVM.reloadAnalyses();
              print('✅ AuthViewModel: Food analyses reloaded in UI');
            } catch (e) {
              print('⚠️ AuthViewModel: Failed to reload food analyses: $e');
              // Continue anyway - this is not critical
            }
          }
        } catch (e) {
          print('⚠️ AuthViewModel: Failed to load user data: $e');
          // Continue anyway - navigation will handle this
        } finally {
          _isDataLoading = false;
        }

        // Handle post-authentication flow if context is provided
        if (context != null && context.mounted) {
          await _authFlow.handlePostAuthNavigation(
            context,
            userDisplayName: user.displayName ?? '',
            userEmail: user.email ?? '',
            useLocalCache: true, // Data was just loaded from AWS
          );

          // Reload food analyses after navigation is complete
          // This ensures the UI is ready to display the data
          try {
            final imageAnalysisVM = context.read<ImageAnalysisViewModel>();
            await imageAnalysisVM.reloadAnalyses();
            print('✅ AuthViewModel: Food analyses reloaded after navigation');
          } catch (e) {
            print(
                '⚠️ AuthViewModel: Failed to reload food analyses after navigation: $e');
          }
        }

        return true;
      } else {
        _setAuthState(AuthState.unauthenticated);
        _setError('Sign-in was cancelled or failed');
        return false;
      }
    } catch (e) {
      print('❌ AuthViewModel: Google Sign-In error: $e');
      _setAuthState(AuthState.error);
      _setError('Sign-in failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      final user = await _authService.signInWithEmail(email, password);

      if (user != null) {
        _user = user;
        _setAuthState(AuthState.authenticated);
        return true;
      } else {
        _setAuthState(AuthState.unauthenticated);
        _setError('Invalid email or password');
        return false;
      }
    } catch (e) {
      print('❌ AuthViewModel: Email Sign-In error: $e');
      _setAuthState(AuthState.error);
      _setError('Sign-in failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      final user = await _authService.signUpWithEmail(email, password);

      if (user != null) {
        _user = user;
        _setAuthState(AuthState.authenticated);
        return true;
      } else {
        _setAuthState(AuthState.unauthenticated);
        _setError('Failed to create account');
        return false;
      }
    } catch (e) {
      print('❌ AuthViewModel: Email Sign-Up error: $e');
      _setAuthState(AuthState.error);
      _setError('Sign-up failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signOut([BuildContext? context]) async {
    try {
      _setLoading(true);
      _clearError();

      // Delete FCM token before sign out
      print('🔔 AuthViewModel: Deleting FCM token...');
      await _notificationService.deleteToken();
      print('✅ AuthViewModel: FCM token deleted');

      // Clear all sync flags (no pending syncs after sign out)
      print('🔄 AuthViewModel: Clearing all sync flags...');
      await _syncService.clearAllSyncFlags();
      print('✅ AuthViewModel: All sync flags cleared');

      // Clear local data
      await SQLiteService().clearAllData();
      ProfileUpdateEvent.notifyUpdate();

      // Sign out from Firebase
      await _authService.signOut();
      _user = null;
      _setAuthState(AuthState.unauthenticated);

      // Navigate to welcome with success message
      if (context != null && context.mounted) {
        await _authFlow.handlePostLogoutNavigation(
          context,
          message: 'Signed out successfully',
          isAccountDeletion: false,
        );
      }

      return true;
    } catch (e) {
      print('❌ AuthViewModel: Sign-out error: $e');
      _setError('Sign-out failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> getIdToken() async {
    return await _authService.getIdToken();
  }

  Future<bool> deleteUser([BuildContext? context]) async {
    try {
      _setLoading(true);
      _clearError();

      if (_user == null) {
        _setError('No user to delete');
        return false;
      }

      final userId = _user!.uid;

      // Delete FCM token before account deletion
      print('🔔 AuthViewModel: Deleting FCM token...');
      await _notificationService.deleteToken();
      print('✅ AuthViewModel: FCM token deleted');

      // Clear all sync flags (no pending syncs after account deletion)
      print('🔄 AuthViewModel: Clearing all sync flags...');
      await _syncService.clearAllSyncFlags();
      print('✅ AuthViewModel: All sync flags cleared');

      // Delete from AWS first
      final awsResult = await _awsService.deleteUser(userId);
      if (awsResult == null) {
        _setError('Failed to delete account from database');
        return false;
      }

      // Clear local data
      await SQLiteService().clearAllData();
      ProfileUpdateEvent.notifyUpdate();

      // Delete from Firebase (with automatic re-authentication if needed)
      await _authService.deleteUserWithReauth();
      _user = null;
      _setAuthState(AuthState.unauthenticated);

      // Navigate to welcome with success message
      if (context != null && context.mounted) {
        await _authFlow.handlePostLogoutNavigation(
          context,
          message: 'Account deleted successfully',
          isAccountDeletion: true,
        );
      }

      return true;
    } catch (e) {
      print('❌ AuthViewModel: Delete account error: $e');

      // Provide user-friendly error messages
      String errorMessage;
      if (e.toString().contains('Re-authentication failed')) {
        errorMessage =
            'Account deletion cancelled. Please try again and sign in when prompted.';
      } else if (e.toString().contains('requires-recent-login')) {
        errorMessage =
            'For security, please sign in again to delete your account.';
      } else {
        errorMessage = 'Failed to delete account: ${e.toString()}';
      }

      _setError(errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteUserWithReauth([BuildContext? context]) async {
    try {
      _setLoading(true);
      _clearError();

      if (_user == null) {
        _setError('No user to delete');
        return false;
      }

      // Note: AWS deletion and FCM token deletion were already done in the first attempt
      // We only need to handle Firebase deletion with reauthentication

      // Clear all sync flags (in case they weren't cleared in first attempt)
      print('🔄 AuthViewModel: Clearing all sync flags...');
      await _syncService.clearAllSyncFlags();
      print('✅ AuthViewModel: All sync flags cleared');

      // Clear local data (in case it wasn't cleared in first attempt)
      await SQLiteService().clearAllData();
      ProfileUpdateEvent.notifyUpdate();

      // Delete from Firebase with reauthentication
      await _authService.deleteUserAfterReauth();
      _user = null;
      _setAuthState(AuthState.unauthenticated);

      // Navigate to welcome with success message
      if (context != null && context.mounted) {
        await _authFlow.handlePostLogoutNavigation(
          context,
          message: 'Account deleted successfully',
          isAccountDeletion: true,
        );
      }

      return true;
    } catch (e) {
      print('❌ AuthViewModel: Delete account with reauth error: $e');

      // Provide user-friendly error messages
      String errorMessage;
      if (e.toString().contains('Re-authentication failed')) {
        errorMessage =
            'Account deletion cancelled. Please try again and sign in when prompted.';
      } else {
        errorMessage = 'Failed to delete account: ${e.toString()}';
      }

      _setError(errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set authentication state
  void _setAuthState(AuthState state) {
    _authState = state;
    notifyListeners();
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh user state (force check AWS)
  Future<void> refreshUserState() async {
    if (_user != null) {
      await _authFlow.refreshUserState();
    }
  }

  /// Check if should show home screen
  Future<bool> shouldShowHome() async {
    return await _authFlow.shouldShowHome();
  }

  /// Check user state consistency and fix if needed
  Future<void> validateUserState() async {
    if (_user != null) {
      try {
        // Try to get fresh token to verify user still exists in Firebase
        final token = await _user!.getIdToken();
        if (token == null) {
          print('⚠️ AuthViewModel: User token is null - user may be deleted');
          await _handleInconsistentState();
        }
      } catch (e) {
        print(
            '⚠️ AuthViewModel: Error getting user token - user may be deleted: $e');
        if (e.toString().contains('user-not-found') ||
            e.toString().contains('user-disabled') ||
            e.toString().contains('invalid-user-token')) {
          await _handleInconsistentState();
        }
      }
    }
  }

  /// Check if user should be redirected to welcome (user exists in Firebase but not in AWS)
  Future<bool> shouldRedirectToWelcome() async {
    if (_user == null) return false;

    try {
      // Check if user exists in AWS
      final profileData = await _awsService.getUserProfile(_user!.uid);
      return profileData == null || profileData['success'] == false;
    } catch (e) {
      // If we can't check AWS, assume user should stay
      return false;
    }
  }

  /// Handle inconsistent state where user appears signed in but is deleted
  Future<void> _handleInconsistentState() async {
    print(
        '🔧 AuthViewModel: Handling inconsistent user state - forcing sign out');

    // Force local state cleanup
    _user = null;
    _setAuthState(AuthState.unauthenticated);

    // Clear local profile data
    try {
      await _userProfileRepository.clearProfile();
      print('✅ AuthViewModel: Cleared local profile during state fix');
    } catch (e) {
      print('⚠️ AuthViewModel: Error clearing profile during state fix: $e');
    }

    // Force sign out from all services
    try {
      await _authService.signOut();
      print('✅ AuthViewModel: Forced sign out during state fix');
    } catch (e) {
      print('⚠️ AuthViewModel: Error during forced sign out: $e');
    }
  }
}
