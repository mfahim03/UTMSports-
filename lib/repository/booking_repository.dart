import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/booking_model.dart';

class BookingRepository {
  final _col      = FirebaseFirestore.instance.collection('bookings');
  final _eventCol = FirebaseFirestore.instance.collection('events');

  // Court counts per sport 
  static const Map<String, int> courtCounts = {
    'Badminton':    8,
    'Table Tennis': 4,
    'Volleyball':   3,
    'Squash':       4,
  };

  // Time slots per sport 
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

  // Check if an event occupies this sport + date (blocks ALL courts) 
  // Events store date as display string (e.g. "10 Jan 2025") so we store a
  // separate "dateStr" (YYYY-MM-DD) on event documents written from the form.
  // We match against the booking dateStr.
  Future<bool> isEventDay({
    required String sport,
    required String dateStr, // "YYYY-MM-DD"
  }) async {
    // Events with matching category and dateStr block all daily bookings
    final snap = await _eventCol
        .where('category', isEqualTo: sport)
        .where('dateStr', isEqualTo: dateStr)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // Get booked courts for a sport/date/slot 
  // Also returns ALL courts as booked if an event is scheduled that day
  Future<Set<int>> getBookedCourts({
    required String sport,
    required String date,
    required String timeSlot,
  }) async {
    // Check for event day first
    final eventDay = await isEventDay(sport: sport, dateStr: date);
    if (eventDay) {
      // Block all courts — event has reserved this sport on this date
      final total = courtCounts[sport] ?? 4;
      return Set<int>.from(List.generate(total, (i) => i + 1));
    }

    final snap = await _col
        .where('sport', isEqualTo: sport)
        .where('date', isEqualTo: date)
        .where('timeSlot', isEqualTo: timeSlot)
        .where('status', isEqualTo: 'confirmed')
        .get();
    return snap.docs.map((d) => (d.data()['court'] as int)).toSet();
  }

  // Submit booking with double-booking check (transaction) 
  Future<void> submit(BookingModel booking) async {
    await FirebaseFirestore.instance.runTransaction((tx) async {
      // Also check event day block
      final eventDay = await isEventDay(
          sport: booking.sport, dateStr: booking.date);
      if (eventDay) {
        throw Exception(
            'This court is reserved for a sports event on ${booking.date}. Daily booking is unavailable.');
      }

      final existing = await _col
          .where('sport', isEqualTo: booking.sport)
          .where('date', isEqualTo: booking.date)
          .where('timeSlot', isEqualTo: booking.timeSlot)
          .where('court', isEqualTo: booking.court)
          .where('status', isEqualTo: 'confirmed')
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('Court ${booking.court} is already booked for this slot.');
      }

      tx.set(_col.doc(), booking.toMap());
    });
  }

  // User's own bookings 
  Stream<List<BookingModel>> watchUserBookings(String userId) => _col
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => BookingModel.fromMap(d.id, d.data())).toList());

  // All bookings (admin/organiser) 
  Stream<List<BookingModel>> watchAll() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => BookingModel.fromMap(d.id, d.data())).toList());
}