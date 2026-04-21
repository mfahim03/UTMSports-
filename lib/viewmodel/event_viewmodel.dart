import 'package:flutter/material.dart';
import '../model/event_model.dart';
import '../repository/event_repository.dart';

class EventViewModel extends ChangeNotifier {
  final _repo = EventRepository();

  bool _busy = false;
  bool get busy => _busy;

  String? _error;
  String? get error => _error;

  static List<String> get categories => EventRepository.categories;

  // All events stream (for students) 
  Stream<List<EventModel>> get allStream => _repo.watchAll();

  // Organiser's own events 
  Stream<List<EventModel>> organiserStream(String uid) =>
      _repo.watchByOrganiser(uid);

  // Add 
  Future<bool> add(EventModel e) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.add(e);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  // Update 
  Future<bool> update(EventModel e) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.update(e);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  // Delete 
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