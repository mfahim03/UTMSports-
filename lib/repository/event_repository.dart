import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/event_model.dart';

class EventRepository {
  final _col = FirebaseFirestore.instance.collection('events');

  static const categories = [
    'Running',
    'Badminton',
    'Volleyball',
    'Squash',
    'Table Tennis',
    'Other',
  ];

  // ── Stream all events (students view) ─────────────────────────────────────
  Stream<List<EventModel>> watchAll() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => EventModel.fromMap(d.id, d.data()))
          .toList());

  // ── Stream events by organiser (organiser's own events) ───────────────────
  Stream<List<EventModel>> watchByOrganiser(String uid) => _col
      .where('createdBy', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => EventModel.fromMap(d.id, d.data()))
          .toList());

  // ── Add ───────────────────────────────────────────────────────────────────
  Future<void> add(EventModel e) => _col.add(e.toMap());

  // ── Update ────────────────────────────────────────────────────────────────
  Future<void> update(EventModel e) => _col.doc(e.id).update(e.toMap());

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<void> delete(String id) => _col.doc(id).delete();
}