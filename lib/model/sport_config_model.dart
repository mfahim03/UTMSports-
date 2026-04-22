// lib/model/sport_config_model.dart

/// Configures a sport available for court booking.
///
/// ─── Physical-court layout (Sports Hall) ──────────────────────────────────
///
///  Physical:   [ 1 ][ 2 ][ 3 ][ 4 ][ 5 ][ 6 ][ 7 ][ 8 ]
///  Badminton:   B1   B2   B3   B4   B5   B6   B7   B8   (mult=1, offset=0)
///  Table Tennis:T1   T2   T3   T4                        (mult=1, offset=0, courtCount=4)
///  Volleyball:                      [  V1   ][  V2   ]   (mult=2, offset=4)
///
/// ─── Court-sharing model ──────────────────────────────────────────────────
///
/// Sports whose [courtGroup] matches share the SAME pool of physical courts.
/// A cross-sport booking check prevents double-booking of the same physical court.
///
/// ─── Physical-court mapping ───────────────────────────────────────────────
///
/// For logical court i (0-indexed):
///   physical courts = [ offset + i*mult + 1 .. offset + i*mult + mult ]
///
/// Examples with offset=0, mult=1 (Badminton / Table Tennis):
///   Court 1 → phys [1],  Court 2 → phys [2],  …
///
/// Examples with offset=4, mult=2 (Volleyball):
///   Court 1 → phys [5, 6],  Court 2 → phys [7, 8]
///
/// [courtStartOffset] lets a sport occupy a non-contiguous slice of the
/// shared physical pool without needing to enumerate courts explicitly.

class SportConfig {
  final String id;
  final String name;
  final List<String> timeSlots;
  final int courtCount;

  /// All sports with the same [courtGroup] share physical courts.
  /// Use a unique string (e.g. the sport name) to make courts dedicated.
  final String courtGroup;

  /// Number of physical courts consumed by one logical court of this sport.
  final int physicalCourtsPerLogicalCourt;

  /// Physical-court numbering offset.
  /// Logical court i occupies physical courts:
  ///   [ courtStartOffset + i*physicalCourtsPerLogicalCourt + 1 .. +mult ]
  ///
  /// Badminton / Table Tennis → offset = 0  (phys starts at 1)
  /// Volleyball               → offset = 4  (phys starts at 5)
  final int courtStartOffset;

  final bool isActive;

  const SportConfig({
    required this.id,
    required this.name,
    required this.timeSlots,
    required this.courtCount,
    required this.courtGroup,
    this.physicalCourtsPerLogicalCourt = 1,
    this.courtStartOffset = 0,
    this.isActive = true,
  });

  // ── Derived ───────────────────────────────────────────────────────────────

  /// True when no other sport shares this sport's physical courts.
  bool get isDedicated => courtGroup == name;

  /// For logical court [i] (0-indexed), returns the list of physical court
  /// numbers it occupies.
  ///
  ///   Badminton court 0   (mult=1, offset=0) → [1]
  ///   Badminton court 4   (mult=1, offset=0) → [5]
  ///   Volleyball court 0  (mult=2, offset=4) → [5, 6]
  ///   Volleyball court 1  (mult=2, offset=4) → [7, 8]
  ///   Table Tennis court 0(mult=1, offset=0) → [1]
  List<List<int>> get physicalCourts => List.generate(courtCount, (i) {
        final start = courtStartOffset + i * physicalCourtsPerLogicalCourt + 1;
        return List.generate(
            physicalCourtsPerLogicalCourt, (j) => start + j);
      });

  /// Total physical courts this sport occupies when all courts are in use.
  int get totalPhysicalCourts => courtCount * physicalCourtsPerLogicalCourt;

  // ── Serialisation ─────────────────────────────────────────────────────────

  factory SportConfig.fromMap(String id, Map<String, dynamic> map) =>
      SportConfig(
        id: id,
        name: map['name'] as String? ?? '',
        timeSlots: List<String>.from(map['timeSlots'] as List? ?? []),
        courtCount: (map['courtCount'] as num?)?.toInt() ?? 1,
        courtGroup: map['courtGroup'] as String? ?? 'shared',
        physicalCourtsPerLogicalCourt:
            (map['physicalCourtsPerLogicalCourt'] as num?)?.toInt() ?? 1,
        courtStartOffset:
            (map['courtStartOffset'] as num?)?.toInt() ?? 0,
        isActive: map['isActive'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'timeSlots': timeSlots,
        'courtCount': courtCount,
        'courtGroup': courtGroup,
        'physicalCourtsPerLogicalCourt': physicalCourtsPerLogicalCourt,
        'courtStartOffset': courtStartOffset,
        'isActive': isActive,
      };

  SportConfig copyWith({
    String? id,
    String? name,
    List<String>? timeSlots,
    int? courtCount,
    String? courtGroup,
    int? physicalCourtsPerLogicalCourt,
    int? courtStartOffset,
    bool? isActive,
  }) =>
      SportConfig(
        id: id ?? this.id,
        name: name ?? this.name,
        timeSlots: timeSlots ?? List<String>.from(this.timeSlots),
        courtCount: courtCount ?? this.courtCount,
        courtGroup: courtGroup ?? this.courtGroup,
        physicalCourtsPerLogicalCourt:
            physicalCourtsPerLogicalCourt ?? this.physicalCourtsPerLogicalCourt,
        courtStartOffset: courtStartOffset ?? this.courtStartOffset,
        isActive: isActive ?? this.isActive,
      );
}