import 'package:flutter/material.dart';
import '../model/feedback_model.dart';
import '../repository/feedback_repository.dart';

class FeedbackViewModel extends ChangeNotifier {
  final _repo = FeedbackRepository();

  String _selectedCategory = 'All';
  String get selectedCategory => _selectedCategory;

  bool _busy = false;
  bool get busy => _busy;

  String? _error;
  String? get error => _error;

  static const categories = ['All', 'Events', 'Facilities', 'App'];

  // Stream for UI 
  Stream<List<FeedbackModel>> get stream => _selectedCategory == 'All'
      ? _repo.watchAll()
      : _repo.watchByCategory(_selectedCategory);

  void setCategory(String c) {
    _selectedCategory = c;
    notifyListeners();
  }

  // Submit (student) 
  Future<bool> submit(FeedbackModel f) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.submit(f);
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