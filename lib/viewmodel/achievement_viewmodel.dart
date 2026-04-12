import 'package:flutter/material.dart';
import '../model/achievement_model.dart';
import '../repository/achievement_repository.dart';

class AchievementViewModel extends ChangeNotifier {
  final _repo = AchievementRepository();

  String _selectedCategory = 'All';
  String get selectedCategory => _selectedCategory;

  bool _busy = false;
  bool get busy => _busy;

  String? _error;
  String? get error => _error;

  static const categories = [
    'All',
    'Badminton',
    'Running',
    'Volleyball',
    'Squash',
    'Table Tennis',
    'Other',
  ];

  // ── Stream for UI ─────────────────────────────────────────────────────────
  Stream<List<AchievementModel>> get stream => _selectedCategory == 'All'
      ? _repo.watchAll()
      : _repo.watchByCategory(_selectedCategory);

  void setCategory(String c) {
    _selectedCategory = c;
    notifyListeners();
  }

  // ── Add ───────────────────────────────────────────────────────────────────
  Future<bool> add(AchievementModel a) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.add(a);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  // ── Update ────────────────────────────────────────────────────────────────
  Future<bool> update(AchievementModel a) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.update(a);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<bool> delete(String id) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.delete(id);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}