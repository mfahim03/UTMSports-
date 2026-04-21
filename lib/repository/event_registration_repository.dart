import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/event_registration_model.dart';

class EventRegistrationRepository {
  final _col =
      FirebaseFirestore.instance.collection('event_registrations');

  // Submit 
  Future<void> submit(EventRegistrationModel reg) =>
      _col.add(reg.toMap());

  // Already registered? 
  Future<bool> isRegistered(String eventId, String userId) async {
    final snap = await _col
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // User's own registrations 
  Stream<List<EventRegistrationModel>> watchUserRegistrations(
          String userId) =>
      _col
          .where('userId', isEqualTo: userId)
          .orderBy('registeredAt', descending: true)
          .snapshots()
          .map((s) => s.docs
              .map((d) => EventRegistrationModel.fromMap(d.id, d.data()))
              .toList());

  // All registrations for an event (organiser) 
  Stream<List<EventRegistrationModel>> watchEventRegistrations(
          String eventId) =>
      _col
          .where('eventId', isEqualTo: eventId)
          .orderBy('registeredAt', descending: false)
          .snapshots()
          .map((s) => s.docs
              .map((d) => EventRegistrationModel.fromMap(d.id, d.data()))
              .toList());

  // Update status 
  Future<void> updateStatus(String id, RegStatus status,
      {String? note}) {
    final data = <String, dynamic>{'status': status.value};
    if (note != null) data['organiserNote'] = note;
    return _col.doc(id).update(data);
  }

  // Delete registration 
  Future<void> delete(String id) => _col.doc(id).delete();
}