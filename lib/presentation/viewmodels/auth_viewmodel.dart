import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/sync_service.dart';
import '../../services/aws_service.dart';
import '../../services/authentication_flow.dart';
import '../../data/repositories/user_profile_repository_impl.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final SyncService _syncService = SyncService();
  final AWSService _awsService = AWSService();
  final AuthenticationFlow _authFlow = AuthenticationFlow();
  final UserProfileRepositoryImpl _userProfileRepository = UserProfileRepositoryImpl();
  
  User? _user;
  AuthState _authState = AuthState.initial;
  String? _errorMessage;
  bool _isLoading = false;

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
    // Listen to Firebase Auth state changes
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      if (user != null) {
        _setAuthState(AuthState.authenticated);
        // Background sync - don't block UI
        _performBackgroundSync();
      } else {
        _setAuthState(AuthState.unauthenticated);
      }
      notifyListeners();
    });
  }

  /// Perform background sync without blocking UI
  void _performBackgroundSync() {
    // Fire and forget - sync in background
    Future.microtask(() async {
      try {
        await _syncService.syncUserProfileOnSignIn();
        await _syncService.syncFoodAnalysesOnSignIn();
        await _syncService.loadUserProfileFromAWS();
      } catch (e) {
        print('⚠️ AuthViewModel: Background sync failed: $e');
        // Don't propagate background sync errors to UI
      }
    });
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
        
        // Handle post-authentication flow if context is provided
        if (context != null && context.mounted) {
          await _authFlow.handlePostAuthNavigation(
            context,
            userDisplayName: user.displayName ?? '',
            userEmail: user.email ?? '',
          );
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

  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.signOut();
      _user = null;
      _setAuthState(AuthState.unauthenticated);
      
      print('✅ AuthViewModel: User signed out successfully');
    } catch (e) {
      print('❌ AuthViewModel: Sign-out error: $e');
      _setError('Sign-out failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> getIdToken() async {
    return await _authService.getIdToken();
  }

  Future<bool> deleteUser() async {
    try {
      _setLoading(true);
      _clearError();
      
      if (_user == null) {
        print('No user to delete');
        _setError('No user to delete');
        return false;
      }

      final userId = _user!.uid;
      print('🗑️ AuthViewModel: Starting user deletion process for user: $userId');

      // 1. Delete user data from AWS (this will cascade delete food analyses)
      final awsResult = await _awsService.deleteUser(userId);
      if (awsResult == null) {
        print('⚠️ AuthViewModel: Failed to delete user data from AWS');
        // Continue with local deletion even if AWS fails
      } else {
        print('✅ AuthViewModel: Successfully deleted user data from AWS');
      }

      // 2. Clear local user profile data
      await _userProfileRepository.clearProfile();
      print('✅ AuthViewModel: Cleared local user profile');

      // 3. Delete user from Firebase (this must be last as it invalidates the token)
      await _authService.deleteUser();
      print('✅ AuthViewModel: Deleted user from Firebase');

      // 4. Update local state
      _user = null;
      _setAuthState(AuthState.unauthenticated);

      return true;
    } catch (e) {
      print('❌ AuthViewModel: User deletion error: $e');
      _setError('Failed to delete user: ${e.toString()}');
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
}
