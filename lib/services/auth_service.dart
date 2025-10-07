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
}
