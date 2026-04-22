// lib/repository/booking_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/booking_model.dart';
import '../model/sport_config_model.dart';
import 'sport_repository.dart';

class BookingRepository {
  final _col      = FirebaseFirestore.instance.collection('bookings');
  final _eventCol = FirebaseFirestore.instance.collection('events');
  final _sportRepo = SportRepository();

  // ── Time-slot overlap helpers ─────────────────────────────────────────────
  //
  // Time slots are stored as strings like "08:00 – 09:00" or "08:00 - 09:00".
  // Different sports use different slot lengths (Badminton/Table Tennis: 1 hr,
  // Volleyball: 2 hr), so an exact string match will NEVER find cross-sport
  // conflicts.
  //
  // Solution: parse each slot into (startMinutes, endMinutes) and check:
  //   A overlaps B  iff  A.start < B.end  &&  B.start < A.end

  /// Parse a time-slot string like "08:00 – 10:00" into (startMins, endMins).
  /// Returns null if unparseable.
  static (int start, int end)? _parseSlot(String slot) {
    // Normalise em-dash / en-dash / regular dash and extra whitespace
    final clean = slot
        .replaceAll('\u2013', '-') // en-dash –
        .replaceAll('\u2014', '-') // em-dash —
        .replaceAll('–', '-')
        .replaceAll('—', '-');
    final parts = clean.split('-').map((s) => s.trim()).toList();
    if (parts.length < 2) return null;

    int? toMins(String t) {
      final hm = t.split(':');
      if (hm.length < 2) return null;
      final h = int.tryParse(hm[0].trim());
      final m = int.tryParse(hm[1].trim());
      if (h == null || m == null) return null;
      return h * 60 + m;
    }

    final start = toMins(parts[0]);
    final end   = toMins(parts[1]);
    if (start == null || end == null) return null;
    return (start, end);
  }

  /// Returns true if slot strings [a] and [b] overlap in time.
  static bool _slotsOverlap(String a, String b) {
    final pa = _parseSlot(a);
    final pb = _parseSlot(b);
    if (pa == null || pb == null) return a.trim() == b.trim(); // safe fallback
    // Classic interval-overlap test
    return pa.$1 < pb.$2 && pb.$1 < pa.$2;
  }

  // ── Event day helpers ─────────────────────────────────────────────────────

  Future<bool> isEventDay({
    required String sport,
    required String dateStr,
  }) async {
    final snap = await _eventCol
        .where('category', isEqualTo: sport)
        .get();

    return snap.docs.any((doc) {
      final data  = doc.data();
      final start = (data['dateStr']    as String?) ?? '';
      final end   = (data['dateStrEnd'] as String?) ?? start;
      if (start.isEmpty) return false;
      return dateStr.compareTo(start) >= 0 && dateStr.compareTo(end) <= 0;
    });
  }

  Future<Set<String>> getEventBlockedDates(String sport) async {
    final snap = await _eventCol
        .where('category', isEqualTo: sport)
        .get();

    final Set<String> blocked = {};
    for (final doc in snap.docs) {
      final data  = doc.data();
      final start = (data['dateStr']    as String?) ?? '';
      final end   = (data['dateStrEnd'] as String?) ?? start;
      if (start.isEmpty) continue;
      try {
        final startDate = DateTime.parse(start);
        final endDate   = DateTime.parse(end.isEmpty ? start : end);
        for (var d = startDate;
            !d.isAfter(endDate);
            d = d.add(const Duration(days: 1))) {
          blocked.add(
            '${d.year}-${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}',
          );
        }
      } catch (_) {}
    }
    return blocked;
  }

  // ── Booked-courts query ───────────────────────────────────────────────────
  //
  // Hall physical layout:
  //
  //   Phys:         1    2    3    4    5    6    7    8
  //   Badminton:    B1   B2   B3   B4   B5   B6   B7   B8
  //   Table Tennis: T1   T2   T3   T4   (phys 1-4 only)
  //   Volleyball:                       V1   V1   V2   V2  (phys 5-8)
  //
  // Cross-sport slot overlap examples:
  //   Volleyball "08:00–10:00" overlaps Badminton "08:00–09:00" and "09:00–10:00"
  //   Badminton  "08:00–09:00" overlaps Volleyball "08:00–10:00"
  //
  // We CANNOT use Firestore's timeSlot filter for cross-sport queries because
  // the string values differ.  Instead we fetch all bookings for that date
  // and filter for time-overlap client-side.

  Future<Set<int>> getBookedCourts({
    required String sport,
    required String date,
    required String timeSlot,
  }) async {
    final eventDay = await isEventDay(sport: sport, dateStr: date);
    final config   = await _sportRepo.fetchByName(sport);
    final count    = config?.courtCount ?? 4;

    if (eventDay) {
      return Set<int>.from(List.generate(count, (i) => i + 1));
    }

    if (config == null) {
      return _directBookedCourts(sport: sport, date: date, timeSlot: timeSlot);
    }

    if (config.isDedicated) {
      return _directBookedCourts(sport: sport, date: date, timeSlot: timeSlot);
    }

    // ── Shared hall: check every sport in the same courtGroup ─────────────
    final sharedSports      = await _sportRepo.fetchByGroup(config.courtGroup);
    final Set<int> occupiedPhysical = {};

    for (final s in sharedSports) {
      // Fetch all confirmed bookings for sport [s] on this date.
      // We do NOT filter by timeSlot here — we do overlap checks below.
      final snap = await _col
          .where('sport',  isEqualTo: s.name)
          .where('date',   isEqualTo: date)
          .where('status', isEqualTo: 'confirmed')
          .get();

      for (final doc in snap.docs) {
        final bookedSlot = (doc.data()['timeSlot'] as String?) ?? '';
        // Only care about bookings whose time window overlaps [timeSlot]
        if (!_slotsOverlap(bookedSlot, timeSlot)) continue;

        final courtNum = (doc.data()['court'] as num?)?.toInt() ?? 0;
        if (courtNum >= 1 && courtNum <= s.physicalCourts.length) {
          occupiedPhysical.addAll(s.physicalCourts[courtNum - 1]);
        }
      }
    }

    // Mark every logical court of THIS sport that touches an occupied phys court
    final Set<int> booked = {};
    for (int i = 0; i < config.physicalCourts.length; i++) {
      if (config.physicalCourts[i].any(occupiedPhysical.contains)) {
        booked.add(i + 1);
      }
    }
    return booked;
  }

  // ── Submit booking (time-overlap-aware conflict guard) ────────────────────

  Future<void> submit(BookingModel booking) async {
    final config = await _sportRepo.fetchByName(booking.sport);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      // Event day guard
      final eventDay =
          await isEventDay(sport: booking.sport, dateStr: booking.date);
      if (eventDay) {
        throw Exception(
          'This facility is reserved for a sports event on ${booking.date}. '
          'Daily booking is unavailable.',
        );
      }

      // ── Same-sport duplicate guard (overlap-aware) ──────────────────────
      final sameSnap = await _col
          .where('sport',  isEqualTo: booking.sport)
          .where('date',   isEqualTo: booking.date)
          .where('court',  isEqualTo: booking.court)
          .where('status', isEqualTo: 'confirmed')
          .get();

      for (final doc in sameSnap.docs) {
        final existingSlot = (doc.data()['timeSlot'] as String?) ?? '';
        if (_slotsOverlap(existingSlot, booking.timeSlot)) {
          throw Exception(
              'Court ${booking.court} is already booked for an overlapping time slot.');
        }
      }

      // ── Cross-sport physical-court conflict guard (overlap-aware) ───────
      if (config != null &&
          !config.isDedicated &&
          booking.court >= 1 &&
          booking.court <= config.physicalCourts.length) {
        final physicalNeeded = config.physicalCourts[booking.court - 1];
        final sharedSports   = await _sportRepo.fetchByGroup(config.courtGroup);

        for (final s in sharedSports) {
          if (s.name == booking.sport) continue;

          // Fetch all bookings for the other sport on the same date
          final otherSnap = await _col
              .where('sport',  isEqualTo: s.name)
              .where('date',   isEqualTo: booking.date)
              .where('status', isEqualTo: 'confirmed')
              .get();

          for (final doc in otherSnap.docs) {
            final otherSlot = (doc.data()['timeSlot'] as String?) ?? '';
            // Skip if their time window doesn't overlap ours
            if (!_slotsOverlap(otherSlot, booking.timeSlot)) continue;

            final otherCourt = (doc.data()['court'] as num?)?.toInt() ?? 0;
            if (otherCourt >= 1 && otherCourt <= s.physicalCourts.length) {
              final otherPhysical = s.physicalCourts[otherCourt - 1];
              if (physicalNeeded.any(otherPhysical.contains)) {
                throw Exception(
                  '${booking.sport} Court ${booking.court} conflicts with '
                  'an existing ${s.name} booking ($otherSlot) '
                  'on the same physical court.',
                );
              }
            }
          }
        }
      }

      tx.set(_col.doc(), booking.toMap());
    });
  }

  // ── Streams ───────────────────────────────────────────────────────────────

  Stream<List<BookingModel>> watchUserBookings(String userId) => _col
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => BookingModel.fromMap(d.id, d.data())).toList());

  Stream<List<BookingModel>> watchAll() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => BookingModel.fromMap(d.id, d.data())).toList());

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<Set<int>> _directBookedCourts({
    required String sport,
    required String date,
    required String timeSlot,
  }) async {
    final snap = await _col
        .where('sport',  isEqualTo: sport)
        .where('date',   isEqualTo: date)
        .where('status', isEqualTo: 'confirmed')
        .get();

    return snap.docs
        .where((d) {
          final slot = (d.data()['timeSlot'] as String?) ?? '';
          return _slotsOverlap(slot, timeSlot);
        })
        .map((d) => (d.data()['court'] as num?)?.toInt() ?? 0)
        .where((c) => c > 0)
        .toSet();
  }
}