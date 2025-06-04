import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // Constructor with dependency injection
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream to listen for authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register a new user with email and password
  Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // Save user information in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'fullName': fullName,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseError(e.code);
    } catch (e) {
      throw AuthException(message: 'An unknown error occurred', code: 'unknown-error');
    }
  }

  /// Login existing user with email and password
  Future<User?> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseError(e.code);
    } catch (e) {
      throw AuthException(message: 'An unknown error occurred', code: 'unknown-error');
    }
  }

  /// Logout the current user
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException(message: 'Failed to sign out', code: 'sign-out-error');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseError(e.code);
    } catch (e) {
      throw AuthException(message: 'An unknown error occurred', code: 'unknown-error');
    }
  }
}

/// Custom exception class for authentication errors
class AuthException implements Exception {
  final String message;
  final String code;

  const AuthException({
    this.message = 'Authentication failed',
    this.code = 'unknown-error',
  });

  factory AuthException.fromFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return const AuthException(
          message: 'Email already in use',
          code: 'email-already-in-use',
        );
      case 'invalid-email':
        return const AuthException(
          message: 'Invalid email address',
          code: 'invalid-email',
        );
      case 'weak-password':
        return const AuthException(
          message: 'Password should be at least 6 characters',
          code: 'weak-password',
        );
      case 'user-not-found':
        return const AuthException(
          message: 'No user found with this email',
          code: 'user-not-found',
        );
      case 'wrong-password':
        return const AuthException(
          message: 'Incorrect password',
          code: 'wrong-password',
        );
      default:
        return const AuthException();
    }
  }

  @override
  String toString() => message;
}
