import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/sync_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final SyncService _syncService = SyncService();
  User? _user;
  bool _isLoading = false;

  // Getters
  User? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get userEmail => _user?.email;
  String? get userDisplayName => _user?.displayName;
  String? get userPhotoURL => _user?.photoURL;

  AuthViewModel() {
    _initializeAuth();
  }

  void _initializeAuth() {
    // Listen to Firebase Auth state changes
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      if (user != null) {
        // User signed in - sync with AWS
        _syncService.syncUserProfileOnSignIn();
        _syncService.syncFoodAnalysesOnSignIn();
        _syncService.loadUserProfileFromAWS();
      }
      notifyListeners();
    });
  }

  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      final user = await _authService.signInWithGoogle();
      _user = user;
      notifyListeners();
      return user != null;
    } catch (e) {
      print('AuthViewModel signInWithGoogle error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _setLoading(true);
      final user = await _authService.signInWithEmail(email, password);
      _user = user;
      notifyListeners();
      return user != null;
    } catch (e) {
      print('AuthViewModel signInWithEmail error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    try {
      _setLoading(true);
      final user = await _authService.signUpWithEmail(email, password);
      _user = user;
      notifyListeners();
      return user != null;
    } catch (e) {
      print('AuthViewModel signUpWithEmail error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _authService.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      print('AuthViewModel signOut error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> getIdToken() async {
    return await _authService.getIdToken();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
