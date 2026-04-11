import 'package:flutter/material.dart';
import '../model/user_model.dart';
import '../repository/auth_repository.dart';

enum AuthStatus { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  final _repo = AuthRepository();

  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;
  UserModel? _currentUser;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _status == AuthStatus.loading;

  // ── Register (student only) ───────────────────────────────────────────────
  Future<void> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? matric,
  }) async {
    _set(AuthStatus.loading);
    try {
      _currentUser = await _repo.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
        matric: matric,
      );
      _set(AuthStatus.success);
    } catch (e) {
      _setError(_friendlyError(e));
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<void> login(String email, String password) async {
    _set(AuthStatus.loading);
    try {
      _currentUser = await _repo.login(email, password);
      _set(AuthStatus.success);
    } catch (e) {
      _setError(_friendlyError(e));
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _repo.signOut();
    _currentUser = null;
    _set(AuthStatus.idle);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _set(AuthStatus s) {
    _status = s;
    if (s != AuthStatus.error) _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _status = AuthStatus.error;
    _errorMessage = msg;
    notifyListeners();
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('user-not-found') || msg.contains('wrong-password') || msg.contains('invalid-credential')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('email-already-in-use')) return 'Email is already registered.';
    if (msg.contains('weak-password')) return 'Password is too weak.';
    if (msg.contains('network-request-failed')) return 'No internet connection.';
    if (msg.contains('User record not found')) return 'Account setup incomplete. Contact admin.';
    return 'Something went wrong. Please try again.';
  }
}