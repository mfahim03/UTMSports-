import 'package:flutter/material.dart';
import '../model/event_registration_model.dart';
import '../repository/event_registration_repository.dart';

class EventRegistrationViewModel extends ChangeNotifier {
  final _repo = EventRegistrationRepository();

  bool _busy = false;
  bool get busy => _busy;

  String? _error;
  String? get error => _error;

  // Submit 
  Future<bool> submit(EventRegistrationModel reg) async {
    _setBusy(true);
    try {
      final already = await _repo.isRegistered(reg.eventId, reg.userId);
      if (already) {
        _error = 'You have already registered for this event.';
        return false;
      }
      await _repo.submit(reg);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  // Check if registered 
  Future<bool> isRegistered(String eventId, String userId) =>
      _repo.isRegistered(eventId, userId);

  // User's registrations 
  Stream<List<EventRegistrationModel>> userRegistrations(String uid) =>
      _repo.watchUserRegistrations(uid);

  // Event registrations (organiser)
  Stream<List<EventRegistrationModel>> eventRegistrations(String eventId) =>
      _repo.watchEventRegistrations(eventId);

  // Update status 
  Future<bool> updateStatus(String id, RegStatus status,
      {String? note}) async {
    _setBusy(true);
    try {
      await _repo.updateStatus(id, status, note: note);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  // Delete Registration
  Future<bool> delete(String id) async {
    _setBusy(true);
    try {
      await _repo.delete(id);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool v) {
    _busy = v;
    if (v) _error = null;
    notifyListeners();
  }
}