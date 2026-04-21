import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/event_registration_model.dart';

class EventRegistrationRepository {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('registrations');

  // Submit new registration
  Future<void> submit(EventRegistrationModel reg) async {
    await _col.add(reg.toMap());
  }

  // Check if user already registered for event
  Future<bool> isRegistered(String eventId, String userId) async {
    final snap = await _col
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // Count confirmed registrations for an event
  Future<int> confirmedTeamCount(String eventId) async {
    final snap = await _col
        .where('eventId', isEqualTo: eventId)
        .where('status', isEqualTo: 'confirmed')
        .get();
    return snap.docs.length;
  }

  // Watch user's own registrations
  Stream<List<EventRegistrationModel>> watchUserRegistrations(String uid) =>
      _col
          .where('userId', isEqualTo: uid)
          .orderBy('registeredAt', descending: true)
          .snapshots()
          .map((s) => s.docs
              .map((d) => EventRegistrationModel.fromMap(
                  d.id, d.data() as Map<String, dynamic>))
              .toList());

  // Watch all registrations for an event (organiser)
  Stream<List<EventRegistrationModel>> watchEventRegistrations(
          String eventId) =>
      _col
          .where('eventId', isEqualTo: eventId)
          .orderBy('registeredAt', descending: false)
          .snapshots()
          .map((s) => s.docs
              .map((d) => EventRegistrationModel.fromMap(
                  d.id, d.data() as Map<String, dynamic>))
              .toList());

  // Update registration status
  Future<void> updateStatus(String id, RegStatus status,
      {String? note}) async {
    final data = <String, dynamic>{'status': status.value};
    if (note != null) data['organiserNote'] = note;
    await _col.doc(id).update(data);
  }

  // Delete registration
  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}