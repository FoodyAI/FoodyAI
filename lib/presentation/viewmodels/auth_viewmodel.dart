import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/sync_service.dart';
import '../../services/aws_service.dart';
import '../../services/authentication_flow.dart';
import '../../data/repositories/user_profile_repository_impl.dart';
import '../../core/constants/app_colors.dart';

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

  Future<void> signOut([BuildContext? context]) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.signOut();
      _user = null;
      _setAuthState(AuthState.unauthenticated);
      
      print('✅ AuthViewModel: User signed out successfully');
      
      // Handle navigation if context is provided
      if (context != null && context.mounted) {
        await _authFlow.handlePostLogoutNavigation(
          context,
          message: 'Signed out successfully',
          isAccountDeletion: false,
        );
      }
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

  Future<bool> deleteUser([BuildContext? context]) async {
    try {
      _setLoading(true);
      _clearError();
      
      if (_user == null) {
        print('No user to delete');
        _setError('No user to delete');
        return false;
      }

      final userId = _user!.uid;
      final userEmail = _user!.email;
      print('🗑️ AuthViewModel: Starting user deletion process for user: $userId ($userEmail)');

      // Step 1: Delete from AWS FIRST (while we still have valid token)
      bool awsDeleted = false;
      try {
        print('🔄 AuthViewModel: Deleting user from AWS first (while token is valid)');
        final awsResult = await _awsService.deleteUser(userId);
        if (awsResult != null) {
          awsDeleted = true;
          print('✅ AuthViewModel: Successfully deleted user data from AWS');
        } else {
          print('❌ AuthViewModel: Failed to delete user data from AWS');
          throw Exception('Failed to delete user data from AWS');
        }
      } catch (e) {
        print('❌ AuthViewModel: AWS deletion failed: $e');
        _setError('Failed to delete account from database: ${e.toString()}');
        return false; // Don't proceed if AWS deletion fails
      }

      // Step 2: Clear local profile data (while we still have user context)
      try {
        await _userProfileRepository.clearProfile();
        print('✅ AuthViewModel: Cleared local user profile');
      } catch (e) {
        print('⚠️ AuthViewModel: Failed to clear local profile: $e');
        // Continue anyway - this is less critical
      }

      // Step 3: Delete from Firebase LAST (this invalidates the token)
      bool firebaseDeleted = false;
      try {
        await _authService.deleteUser();
        firebaseDeleted = true;
        print('✅ AuthViewModel: Deleted user from Firebase');
      } catch (e) {
        if (e.toString().contains('requires-recent-login')) {
          print('🔐 AuthViewModel: Re-authentication required for Firebase deletion');
          
          // Handle re-authentication flow
          if (context != null && context.mounted) {
            await _handleRecentLoginRequired(context);
            return false; // Let the re-auth flow handle the rest
          } else {
            _setError('For security reasons, please sign in again to delete your account.');
            return false;
          }
        } else {
          // Other Firebase error - this is critical since AWS is already deleted
          print('❌ AuthViewModel: Firebase deletion failed after AWS deletion: $e');
          
          // This is a serious problem - AWS is deleted but Firebase isn't
          // We should still sign out the user since their data is gone
          _user = null;
          _setAuthState(AuthState.unauthenticated);
          
          if (context != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Account data deleted, but Firebase deletion failed: ${e.toString()}. You have been signed out for safety.'),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 5),
              ),
            );
            
            await _authFlow.handlePostLogoutNavigation(
              context,
              message: 'Account partially deleted - signed out for safety',
              isAccountDeletion: true,
            );
          }
          
          return false; // Consider this a failure even though we signed out
        }
      }

      // Step 4: If everything succeeded, update local state and navigate
      if (awsDeleted && firebaseDeleted) {
        _user = null;
        _setAuthState(AuthState.unauthenticated);

        // Handle navigation
        if (context != null && context.mounted) {
          await _authFlow.handlePostLogoutNavigation(
            context,
            message: 'Account deleted successfully',
            isAccountDeletion: true,
          );
        }

        print('✅ AuthViewModel: Account deletion completed successfully');
        return true;
      } else {
        // This should not be reached, but just in case
        print('❌ AuthViewModel: Unexpected state - not all deletions completed');
        return false;
      }
      
    } catch (e) {
      print('❌ AuthViewModel: Unexpected error in user deletion: $e');
      _setError('Failed to delete user: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Handle the requires-recent-login error by prompting re-authentication
  Future<void> _handleRecentLoginRequired(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Security Check'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'For security reasons, you need to confirm your identity to delete your account.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'This ensures that only you can delete your account.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'reauth'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Confirm Identity'),
          ),
        ],
      ),
    );

    if (result == 'reauth' && context.mounted) {
      await _attemptReauthentication(context);
    }
  }

  /// Attempt to re-authenticate the user and retry deletion
  Future<void> _attemptReauthentication(BuildContext context) async {
    try {
      _setLoading(true);
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Confirming your identity...'),
            ],
          ),
        ),
      );

      // Attempt re-authentication
      final reauthSuccess = await _authService.reauthenticateWithGoogle();
      
      // Hide loading dialog
      if (context.mounted) Navigator.pop(context);
      
      if (reauthSuccess) {
        // Re-authentication successful, try deletion again
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Identity confirmed. Deleting account...'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        // Retry deletion with fresh authentication
        await _retryDeletion(context);
      } else {
        // Re-authentication failed
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Identity confirmation cancelled. Account not deleted.'),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading dialog if still showing
      if (context.mounted) Navigator.pop(context);
      
      print('❌ AuthViewModel: Re-authentication error: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Identity confirmation failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Retry deletion after successful re-authentication
  Future<void> _retryDeletion(BuildContext context) async {
    try {
      _setLoading(true);
      
      if (_user == null) {
        throw Exception('No user to delete');
      }

      final userId = _user!.uid;
      final userEmail = _user!.email;
      print('🔄 AuthViewModel: Retrying deletion after re-auth for user: $userId ($userEmail)');

      // Step 1: Delete from AWS FIRST (while we still have valid token)
      bool awsDeleted = false;
      try {
        print('🔄 AuthViewModel: Deleting user from AWS first (after re-auth)');
        final awsResult = await _awsService.deleteUser(userId);
        if (awsResult != null) {
          awsDeleted = true;
          print('✅ AuthViewModel: Successfully deleted user data from AWS after re-auth');
        } else {
          print('❌ AuthViewModel: Failed to delete user data from AWS after re-auth');
          throw Exception('Failed to delete user data from AWS');
        }
      } catch (e) {
        print('❌ AuthViewModel: AWS deletion failed after re-auth: $e');
        _setError('Failed to delete account from database: ${e.toString()}');
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete account from database: ${e.toString()}'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return; // Don't proceed if AWS deletion fails
      }

      // Step 2: Clear local profile data
      try {
        await _userProfileRepository.clearProfile();
        print('✅ AuthViewModel: Cleared local user profile after re-auth');
      } catch (e) {
        print('⚠️ AuthViewModel: Failed to clear local profile after re-auth: $e');
        // Continue anyway - this is less critical
      }

      // Step 3: Delete from Firebase LAST (with fresh authentication)
      bool firebaseDeleted = false;
      try {
        await _authService.deleteUserWithReauth();
        firebaseDeleted = true;
        print('✅ AuthViewModel: Deleted user from Firebase after re-authentication');
      } catch (e) {
        // Firebase deletion failed after re-auth - this is critical since AWS is already deleted
        print('❌ AuthViewModel: Firebase deletion still failed after re-auth: $e');
        
        // This is a serious problem - AWS is deleted but Firebase isn't
        // We should still sign out the user since their data is gone
        _user = null;
        _setAuthState(AuthState.unauthenticated);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account data deleted, but Firebase deletion failed: ${e.toString()}. You have been signed out for safety.'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
          
          await _authFlow.handlePostLogoutNavigation(
            context,
            message: 'Account partially deleted - signed out for safety',
            isAccountDeletion: true,
          );
        }
        return; // Don't continue - this is a failure
      }

      // Step 4: If everything succeeded, update local state and navigate
      if (awsDeleted && firebaseDeleted) {
        _user = null;
        _setAuthState(AuthState.unauthenticated);

        // Handle navigation
        if (context.mounted) {
          await _authFlow.handlePostLogoutNavigation(
            context,
            message: 'Account deleted successfully',
            isAccountDeletion: true,
          );
        }

        print('✅ AuthViewModel: Account deletion completed successfully after re-auth');
      }
      
    } catch (e) {
      print('❌ AuthViewModel: Retry deletion error: $e');
      _setError('Failed to delete account after re-authentication: ${e.toString()}');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
        print('⚠️ AuthViewModel: Error getting user token - user may be deleted: $e');
        if (e.toString().contains('user-not-found') || 
            e.toString().contains('user-disabled') ||
            e.toString().contains('invalid-user-token')) {
          await _handleInconsistentState();
        }
      }
    }
  }

  /// Handle inconsistent state where user appears signed in but is deleted
  Future<void> _handleInconsistentState() async {
    print('🔧 AuthViewModel: Handling inconsistent user state - forcing sign out');
    
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
