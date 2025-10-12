import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Sign in with email
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }
  
  // Sign up with email
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Error signing up: $e');
      return null;
    }
  }
  
  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Clear any previous sign-in state
      await _googleSignIn.signOut();
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        print('Google Sign-In cancelled by user');
        return null;
      }
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Check if we have valid tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('Google Sign-In failed: Missing tokens');
        return null;
      }
      
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with the Google credential
      UserCredential result = await _auth.signInWithCredential(credential);
      print('Google Sign-In successful: ${result.user?.email}');
      return result.user;
    } catch (e) {
      print('Error signing in with Google: $e');
      
      // Handle specific type casting errors
      if (e.toString().contains('PigeonUserDetails') || e.toString().contains('List<Object?>')) {
        print('Handling Google Sign-In plugin compatibility issue...');
        try {
          // Try alternative approach - check if user is already signed in
          await _googleSignIn.signInSilently();
          if (_auth.currentUser != null) {
            print('User is already signed in: ${_auth.currentUser?.email}');
            return _auth.currentUser;
          }
        } catch (silentError) {
          print('Silent sign-in also failed: $silentError');
        }
      }
      
      // Even if there's an error, check if user is already signed in
      if (_auth.currentUser != null) {
        print('User is already signed in: ${_auth.currentUser?.email}');
        return _auth.currentUser;
      }
      return null;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
  
  // Get Firebase token
  Future<String?> getIdToken() async {
    User? user = _auth.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }
  
  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;
  
  // Get user display name
  String? get userDisplayName => _auth.currentUser?.displayName;
  
  // Get user email
  String? get userEmail => _auth.currentUser?.email;
  
  // Get user photo URL
  String? get userPhotoURL => _auth.currentUser?.photoURL;
  
  // Delete user account from Firebase
  Future<void> deleteUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
        await _googleSignIn.signOut();
        print('User account deleted from Firebase');
      }
    } catch (e) {
      print('Error deleting user from Firebase: $e');
      throw e;
    }
  }

  // Re-authenticate user with Google (required for sensitive operations)
  Future<bool> reauthenticateWithGoogle() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No current user to re-authenticate');
        return false;
      }

      print('Starting Google re-authentication...');
      
      // Sign out from Google first to force account selection
      await _googleSignIn.signOut();
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('Google re-authentication cancelled by user');
        return false;
      }
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Check if we have valid tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('Google re-authentication failed: Missing tokens');
        return false;
      }
      
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Re-authenticate the user
      await user.reauthenticateWithCredential(credential);
      print('Google re-authentication successful');
      return true;
      
    } catch (e) {
      print('Error re-authenticating with Google: $e');
      return false;
    }
  }

  // Delete user with re-authentication if needed
  Future<void> deleteUserWithReauth() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user to delete');
      }

      try {
        // Try to delete directly first
        await user.delete();
        await _googleSignIn.signOut();
        print('User account deleted from Firebase');
      } catch (e) {
        if (e.toString().contains('requires-recent-login')) {
          print('Re-authentication required for user deletion');
          
          // Re-authenticate and try again
          final reauthSuccess = await reauthenticateWithGoogle();
          if (reauthSuccess) {
            await user.delete();
            await _googleSignIn.signOut();
            print('User account deleted from Firebase after re-authentication');
          } else {
            throw Exception('Re-authentication failed');
          }
        } else {
          throw e;
        }
      }
    } catch (e) {
      print('Error deleting user from Firebase: $e');
      throw e;
    }
  }
}
