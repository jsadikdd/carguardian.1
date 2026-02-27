import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthStatus _status = AuthStatus.initial;
  User?      _user;
  String?    _errorMessage;

  AuthStatus get status       => _status;
  User?      get user         => _user;
  String?    get errorMessage => _errorMessage;
  bool       get isLoggedIn   => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen((user) {
      _user   = user;
      _status = user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      notifyListeners();
    });
  }

  Future<bool> signUp({required String email, required String password, required String name}) async {
    _setLoading();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await cred.user?.updateDisplayName(name);
      _user   = cred.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapError(e.code));
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading();
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      _user   = cred.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapError(e.code));
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user   = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _status       = AuthStatus.error;
    _errorMessage = msg;
    notifyListeners();
  }

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':        return 'No account found with this email.';
      case 'wrong-password':        return 'Incorrect password.';
      case 'email-already-in-use':  return 'Email already registered.';
      case 'weak-password':         return 'Password must be at least 6 characters.';
      case 'invalid-email':         return 'Invalid email address.';
      case 'network-request-failed':return 'Network error. Check connection.';
      default:                      return 'Authentication failed. Please try again.';
    }
  }
}
