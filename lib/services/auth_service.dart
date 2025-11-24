// services/auth_service.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get user => _auth.currentUser;
  bool get isAuthenticated => user != null;

  // Loading states
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Error handling
  String? _lastError;
  String? get lastError => _lastError;

  // Track if auth state has been initialized
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Track if user has gone through login flow in current session
  bool _hasLoggedInThisSession = false;
  bool get hasLoggedInThisSession => _hasLoggedInThisSession;

  AuthService() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      _isInitialized = true;
      // Reset login session flag when user signs out
      if (user == null) {
        _hasLoggedInThisSession = false;
      }
      notifyListeners();
    });

    // Also listen to user changes for more granular updates
    _auth.userChanges().listen((User? user) {
      _isInitialized = true;
      notifyListeners();
    });
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _lastError = error;
    notifyListeners();
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  // Wait for auth state to be initialized
  Future<void> waitForInitialization() async {
    if (_isInitialized) return;

    // Wait up to 5 seconds for auth state to initialize
    int attempts = 0;
    while (!_isInitialized && attempts < 50) {
      await Future.delayed(Duration(milliseconds: 100));
      attempts++;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        _hasLoggedInThisSession = true;
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      print('Sign in error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      _hasLoggedInThisSession = false;
      await _auth.signOut();
    } catch (e) {
      _setError('Error signing out. Please try again.');
      print('Sign out error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Force sign out - useful when app starts and we want to ensure fresh login
  Future<void> forceSignOut() async {
    try {
      _hasLoggedInThisSession = false;
      await _auth.signOut();
    } catch (e) {
      print('Force sign out error: $e');
    }
  }

  Future<bool> registerOrganizer(
    String email,
    String password,
    String name,
  ) async {
    try {
      _setLoading(true);
      _setError(null);

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await result.user!.updateDisplayName(name);
        // Reload user to get updated info
        await result.user!.reload();
        _hasLoggedInThisSession = true;
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('Registration failed. Please try again.');
      print('Registration error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _setError(null);

      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('Failed to send reset email. Please try again.');
      print('Password reset error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'invalid-credential':
        return 'Invalid login credentials. Please check and try again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
