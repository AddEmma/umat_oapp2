// services/auth_service.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';
import '../models/member.dart';
import 'dart:io';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _databaseService = DatabaseService();

  // Cache user locally to avoid race conditions with standard getter
  User? _user;
  User? get user => _user;
  bool get isAuthenticated => _user != null;

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
    // Initialize immediately
    _user = _auth.currentUser;

    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      _isInitialized = true;
      if (user != null) {
        _fetchUserRole(user.uid);
      } else {
        _userRole = null;
        _churchId = null;
        _isLoadingRole = false; // Ensure loading state is cleared
        _hasLoggedInThisSession = false;
      }
      notifyListeners();
    });

    // Also listen to user changes for more granular updates
    _auth.userChanges().listen((User? user) {
      _user = user;
      _isInitialized = true;
      if (user != null) {
        _fetchUserRole(user.uid);
      }
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

  // Wait for auth state and role to be initialized
  Future<void> _waitForRole() async {
    int attempts = 0;
    while (_userRole == null && attempts < 30) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
  }

  Future<void> waitForInitialization() async {
    // Wait for the base auth state
    int attempts = 0;
    while (!_isInitialized && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    // If a user is present, wait for the role to be fetched
    if (user != null) {
      await _waitForRole();
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
        await _fetchUserRole(result.user!.uid);
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
      _user = null; // Explicitly clear user
      await _auth.signOut();
      notifyListeners(); // Ensure UI knows immediately
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
      _user = null;
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      print('Force sign out error: $e');
    }
  }

  // User Role & Church
  String? _userRole;
  String? get userRole => _userRole;

  String? _churchId;
  String? get churchId => _churchId;

  bool _isLoadingRole = false;
  bool get isLoadingRole => _isLoadingRole;

  bool get canEdit => _userRole == 'admin' || _userRole == 'editor';
  bool get isAdmin => _userRole == 'admin';
  bool get isEditor => _userRole == 'editor';

  Future<void> _fetchUserRole(String uid) async {
    _isLoadingRole = true;
    notifyListeners();

    try {
      _userRole = await _databaseService.getUserRole(uid);
      _churchId = await _databaseService.getUserChurchId(uid);
    } catch (e) {
      print('Error fetching user role/church: $e');
    } finally {
      _isLoadingRole = false;
      notifyListeners();
    }
  }

  // Modified register to default to 'viewer'
  Future<bool> registerOrganizer(
    String email,
    String password,
    String name, {
    String? adminCode,
    String? phoneNumber,
    String? year,
    String? department,
    String? localCongregation,
    String? location,
    String? hostel,
    bool isBaptized = false,
    String? ministryRole,
    File? profileImage,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        try {
          // Initialize profile data
          await result.user!.updateDisplayName(name);

          String role = (adminCode == 'UMAT2024') ? 'admin' : 'viewer';

          // Upload profile image if provided - Make it non-fatal for account creation
          String? photoUrl;
          if (profileImage != null) {
            try {
              photoUrl = await _databaseService.uploadProfileImage(
                result.user!.uid,
                profileImage,
              );
              await result.user!.updatePhotoURL(photoUrl);
            } catch (e) {
              print("Non-fatal error uploading profile image: $e");
              // We proceed without the photoUrl to ensure member creation doesn't fail
            }
          }

          // Create user profile in Firestore
          await _databaseService.createUserProfile(
            result.user!.uid,
            email,
            name,
            role,
            phoneNumber: phoneNumber,
            photoUrl: photoUrl,
          );

          // Automatically sync to members collection
          await _databaseService.addMember(
            Member(
              id: '',
              name: name,
              phone: phoneNumber ?? '',
              year: year ?? '',
              department: department ?? '',
              localCongregation: localCongregation ?? '',
              location: location ?? '',
              hostel: hostel ?? '',
              isBaptized: isBaptized,
              ministryRole: ministryRole ?? '',
              photoUrl: photoUrl,
              dateAdded: DateTime.now(),
            ),
          );

          // Crucial: Reload user multiple times to ensure Firebase Auth cache is updated
          await result.user!.reload();
          await Future.delayed(const Duration(milliseconds: 500));
          await result.user!.reload();

          _userRole = role;
          _hasLoggedInThisSession = true;
          notifyListeners();
          return true;
        } catch (e) {
          print("Error during registration sync: $e");
          _setError(
            'Account created, but database sync failed: ${e.toString()}',
          );
          rethrow;
        }
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      rethrow;
    } catch (e) {
      _setError(e.toString());
      rethrow;
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
