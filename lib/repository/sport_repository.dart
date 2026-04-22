// lib/repository/sport_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/sport_config_model.dart';

class SportRepository {
  final _col = FirebaseFirestore.instance.collection('sports');

  // ── Streams ───────────────────────────────────────────────────────────────

  Stream<List<SportConfig>> watchActiveSports() => _col
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map(_mapDocs);

  Stream<List<SportConfig>> watchAllSports() =>
      _col.snapshots().map(_mapDocs);

  // ── One-shot fetches ──────────────────────────────────────────────────────

  Future<List<SportConfig>> fetchActiveSports() async {
    final s = await _col.where('isActive', isEqualTo: true).get();
    return _mapDocs(s);
  }

  Future<SportConfig?> fetchByName(String name) async {
    final s = await _col.where('name', isEqualTo: name).limit(1).get();
    if (s.docs.isEmpty) return null;
    return SportConfig.fromMap(s.docs.first.id, s.docs.first.data());
  }

  Future<List<SportConfig>> fetchByGroup(String courtGroup) async {
    final s = await _col
        .where('courtGroup', isEqualTo: courtGroup)
        .where('isActive', isEqualTo: true)
        .get();
    return _mapDocs(s);
  }

  Future<Set<String>> fetchAllGroups() async {
    final s = await _col.get();
    return s.docs
        .map((d) => (d.data()['courtGroup'] as String?) ?? '')
        .where((g) => g.isNotEmpty)
        .toSet();
  }

  // ── Create / Update ───────────────────────────────────────────────────────

  Future<void> save(SportConfig sport) async {
    if (sport.id.isEmpty) {
      await _col.add(sport.toMap());
    } else {
      await _col.doc(sport.id).set(sport.toMap());
    }
  }

  Future<void> setActive(String id, {required bool active}) =>
      _col.doc(id).update({'isActive': active});

  Future<void> delete(String id) => _col.doc(id).delete();

  // ── migrateDefaults ───────────────────────────────────────────────────────
  //
  // Call this INSTEAD of seedDefaults() from BookingViewModel._initSports().
  //
  // Hall physical layout (8 courts total):
  //
  //   Phys:         1    2    3    4    5    6    7    8
  //   Badminton:    B1   B2   B3   B4   B5   B6   B7   B8  (mult=1, offset=0)
  //   Table Tennis: T1   T2   T3   T4                       (mult=1, offset=0, count=4)
  //   Volleyball:                       V1   V1   V2   V2   (mult=2, offset=4, count=2)
  //   Squash:       isolated — own courtGroup, own phys pool
  //
  // This function:
  //   • Creates the sport document if it doesn't exist yet.
  //   • ALWAYS patches the physical-court fields (courtGroup,
  //     physicalCourtsPerLogicalCourt, courtStartOffset, courtCount) to the
  //     correct values so stale Firestore data from previous code versions
  //     is healed automatically on every app start.
  //   • Preserves the existing document ID and isActive flag.
  //   • Never touches user bookings.

  // Canonical physical-court config keyed by sport name.
  static const Map<String, Map<String, dynamic>> _physicalConfig = {
    'Badminton': {
      'courtGroup': 'Main Hall',
      'physicalCourtsPerLogicalCourt': 1,
      'courtStartOffset': 0,
      'courtCount': 8,
    },
    'Table Tennis': {
      'courtGroup': 'Main Hall',
      'physicalCourtsPerLogicalCourt': 1,
      'courtStartOffset': 0,
      'courtCount': 4,
    },
    'Volleyball': {
      'courtGroup': 'Main Hall',
      'physicalCourtsPerLogicalCourt': 2,
      'courtStartOffset': 4,   // V1→phys[5,6], V2→phys[7,8]
      'courtCount': 2,
    },
    'Squash': {
      'courtGroup': 'Squash Courts',
      'physicalCourtsPerLogicalCourt': 1,
      'courtStartOffset': 0,
      'courtCount': 4,
    },
  };

  static const Map<String, List<String>> _defaultTimeSlots = {
    'Badminton': [
      '08:00 \u2013 09:00', '09:00 \u2013 10:00', '10:00 \u2013 11:00',
      '11:00 \u2013 12:00', '14:00 \u2013 15:00', '15:00 \u2013 16:00',
      '16:00 \u2013 17:00', '17:00 \u2013 18:00', '18:00 \u2013 19:00',
      '19:00 \u2013 20:00',
    ],
    'Table Tennis': [
      '08:00 \u2013 09:00', '09:00 \u2013 10:00', '10:00 \u2013 11:00',
      '14:00 \u2013 15:00', '15:00 \u2013 16:00', '16:00 \u2013 17:00',
      '17:00 \u2013 18:00',
    ],
    'Volleyball': [
      '08:00 \u2013 10:00', '10:00 \u2013 12:00',
      '14:00 \u2013 16:00', '16:00 \u2013 18:00',
    ],
    'Squash': [
      '08:00 \u2013 09:00', '09:00 \u2013 10:00', '10:00 \u2013 11:00',
      '14:00 \u2013 15:00', '15:00 \u2013 16:00', '16:00 \u2013 17:00',
      '17:00 \u2013 18:00',
    ],
  };

  /// Idempotent migration: safe to call on every app start.
  /// Creates missing sports and patches physical-court fields on existing ones.
  Future<void> migrateDefaults() async {
    for (final name in _physicalConfig.keys) {
      final snap = await _col.where('name', isEqualTo: name).limit(1).get();
      final phys = _physicalConfig[name]!;

      if (snap.docs.isEmpty) {
        // Sport doesn't exist yet — create it
        await _col.add({
          'name': name,
          'isActive': true,
          'timeSlots': _defaultTimeSlots[name] ?? [],
          ...phys,
        });
      } else {
        // Sport exists — patch only the physical-court fields so stale
        // documents from older code versions are corrected automatically.
        await snap.docs.first.reference.update(phys);
      }
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  List<SportConfig> _mapDocs(dynamic snap) {
    final docs = snap.docs as List;
    return (docs
          .map((d) => SportConfig.fromMap(
              d.id as String, d.data() as Map<String, dynamic>))
          .toList() as List<SportConfig>)
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}