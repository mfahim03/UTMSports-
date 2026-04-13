import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/booking_model.dart';

class BookingRepository {
  final _col = FirebaseFirestore.instance.collection('bookings');

  // ── Court counts per sport ─────────────────────────────────────────────────
  static const Map<String, int> courtCounts = {
    'Badminton': 8,
    'Table Tennis': 4,
    'Volleyball': 3,
    'Squash': 4,
  };

  // ── Time slots per sport ───────────────────────────────────────────────────
  static const Map<String, List<String>> timeSlots = {
    'Badminton': [
      '08:00 – 09:00', '09:00 – 10:00', '10:00 – 11:00',
      '11:00 – 12:00', '14:00 – 15:00', '15:00 – 16:00',
      '16:00 – 17:00', '17:00 – 18:00', '18:00 – 19:00',
      '19:00 – 20:00',
    ],
    'Table Tennis': [
      '08:00 – 09:00', '09:00 – 10:00', '10:00 – 11:00',
      '14:00 – 15:00', '15:00 – 16:00', '16:00 – 17:00',
      '17:00 – 18:00',
    ],
    'Volleyball': [
      '08:00 – 10:00', '10:00 – 12:00',
      '14:00 – 16:00', '16:00 – 18:00',
    ],
    'Squash': [
      '08:00 – 09:00', '09:00 – 10:00', '10:00 – 11:00',
      '14:00 – 15:00', '15:00 – 16:00', '16:00 – 17:00',
      '17:00 – 18:00',
    ],
  };

  // ── Get booked courts for a sport/date/slot ────────────────────────────────
  Future<Set<int>> getBookedCourts({
    required String sport,
    required String date,
    required String timeSlot,
  }) async {
    final snap = await _col
        .where('sport', isEqualTo: sport)
        .where('date', isEqualTo: date)
        .where('timeSlot', isEqualTo: timeSlot)
        .where('status', isEqualTo: 'confirmed')
        .get();
    return snap.docs
        .map((d) => (d.data()['court'] as int))
        .toSet();
  }

  // ── Submit booking with double-booking check (transaction) ─────────────────
  Future<void> submit(BookingModel booking) async {
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final existing = await _col
          .where('sport', isEqualTo: booking.sport)
          .where('date', isEqualTo: booking.date)
          .where('timeSlot', isEqualTo: booking.timeSlot)
          .where('court', isEqualTo: booking.court)
          .where('status', isEqualTo: 'confirmed')
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception(
            'Court ${booking.court} is already booked for this slot.');
      }

      final ref = _col.doc();
      tx.set(ref, booking.toMap());
    });
  }

  // ── User's own bookings ────────────────────────────────────────────────────
  Stream<List<BookingModel>> watchUserBookings(String userId) => _col
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => BookingModel.fromMap(d.id, d.data()))
          .toList());

  // ── All bookings (admin/organiser) ─────────────────────────────────────────
  Stream<List<BookingModel>> watchAll() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => BookingModel.fromMap(d.id, d.data()))
          .toList());
}