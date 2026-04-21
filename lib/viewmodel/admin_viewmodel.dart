import 'package:flutter/material.dart';
import '../model/user_model.dart';
import '../repository/admin_repository.dart';

class AdminViewModel extends ChangeNotifier {
  final _repo = AdminRepository();

  Stream<List<UserModel>> get usersStream => _repo.watchUsers();

  String _search = '';
  String get search => _search;
  bool _busy = false;
  String? _error;
  String? get error => _error;

  void setSearch(String q) {
    _search = q.toLowerCase();
    notifyListeners();
  }

  List<UserModel> filter(List<UserModel> all) {
    if (_search.isEmpty) return all;
    return all
        .where((u) =>
            u.name.toLowerCase().contains(_search) ||
            u.email.toLowerCase().contains(_search) ||
            (u.matric ?? '').toLowerCase().contains(_search))
        .toList();
  }

  Future<void> toggleRole(UserModel user) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final newRole = user.role == 'organiser' ? 'student' : 'organiser';
      await _repo.setRole(user.uid, newRole);
    } catch (e) {
      _error = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> deleteUser(String uid) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.deleteUserDoc(uid);
    } catch (e) {
      _error = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}