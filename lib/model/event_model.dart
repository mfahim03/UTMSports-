import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String date;      // Display string e.g. "10 Jan 2025" or "10–12 Jan 2025"
  final String dateStr;   // YYYY-MM-DD (start date)
  final String? dateStrEnd; // YYYY-MM-DD (end date, null = single day)
  final String? dateEnd;    // Display string for end date (null = single day)
  final String location;
  final String category;
  final String? description;
  final String createdBy;
  final DateTime createdAt;

  // Player / team configuration
  final int minPlayers;
  final int? maxPlayers;
  final int? maxTeams;          // null = unlimited teams
  final List<String> badmintonTypes;

  // Registration
  final bool registrationOpen;

  const EventModel({
    required this.id,
    required this.title,
    required this.date,
    required this.dateStr,
    this.dateStrEnd,
    this.dateEnd,
    required this.location,
    required this.category,
    this.description,
    required this.createdBy,
    required this.createdAt,
    this.minPlayers = 1,
    this.maxPlayers,
    this.maxTeams,
    this.badmintonTypes = const [],
    this.registrationOpen = true,
  });

  // ── Date helpers ──────────────────────────────────────────────────────────

  /// True once the last day of the event has fully passed (after 23:59:59).
  bool get isEventPassed {
    try {
      final endStr = dateStrEnd ?? dateStr;
      final parts  = endStr.split('-');
      if (parts.length != 3) return false;
      final eventDate = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final closingTime = DateTime(
          eventDate.year, eventDate.month, eventDate.day, 23, 59, 59);
      return DateTime.now().isAfter(closingTime);
    } catch (_) {
      return false;
    }
  }

  /// True if [d] (YYYY-MM-DD) falls within this event's date range.
  bool containsDate(String d) {
  final end = dateStrEnd ?? dateStr;
  return d.compareTo(dateStr) >= 0 && d.compareTo(end) <= 0;
}

  /// Whether this is a multi-day event.
  bool get isMultiDay =>
      dateStrEnd != null && dateStrEnd!.isNotEmpty && dateStrEnd != dateStr;

  // ── Preset defaults per sport ─────────────────────────────────────────────
  static Map<String, dynamic> defaultsFor(String category) {
    return switch (category) {
      'Futsal'         => {'min': 5,  'max': 7,    'badminton': []},
      'Volleyball'     => {'min': 8,  'max': 12,   'badminton': []},
      'Badminton'      => {'min': 1,  'max': 2,    'badminton': ['Solo', 'Double', 'Mixed']},
      'PUBG'           => {'min': 1,  'max': 5,    'badminton': []},
      'Mobile Legends' => {'min': 1,  'max': 6,    'badminton': []},
      _                => {'min': 1,  'max': null, 'badminton': []},
    };
  }

  factory EventModel.fromMap(String id, Map<String, dynamic> map) => EventModel(
        id: id,
        title: map['title'] ?? '',
        date: map['date'] ?? '',
        dateStr: map['dateStr'] ?? '',
        dateStrEnd: map['dateStrEnd'] as String?,
        dateEnd: map['dateEnd'] as String?,
        location: map['location'] ?? '',
        category: map['category'] ?? '',
        description: map['description'],
        createdBy: map['createdBy'] ?? '',
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        minPlayers: (map['minPlayers'] ?? 1) as int,
        maxPlayers: map['maxPlayers'] as int?,
        maxTeams: map['maxTeams'] as int?,
        badmintonTypes: List<String>.from(map['badmintonTypes'] ?? []),
        registrationOpen: map['registrationOpen'] ?? true,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'date': date,
        'dateStr': dateStr,
        if (dateStrEnd != null) 'dateStrEnd': dateStrEnd,
        if (dateEnd != null) 'dateEnd': dateEnd,
        'location': location,
        'category': category,
        if (description != null) 'description': description,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'minPlayers': minPlayers,
        if (maxPlayers != null) 'maxPlayers': maxPlayers,
        if (maxTeams != null) 'maxTeams': maxTeams,
        'badmintonTypes': badmintonTypes,
        'registrationOpen': registrationOpen,
      };

  EventModel copyWith({
    String? title,
    String? date,
    String? dateStr,
    String? dateStrEnd,
    bool clearDateStrEnd = false,
    String? dateEnd,
    bool clearDateEnd = false,
    String? location,
    String? category,
    String? description,
    int? minPlayers,
    int? maxPlayers,
    bool clearMax = false,
    int? maxTeams,
    bool clearMaxTeams = false,
    List<String>? badmintonTypes,
    bool? registrationOpen,
  }) =>
      EventModel(
        id: id,
        title: title ?? this.title,
        date: date ?? this.date,
        dateStr: dateStr ?? this.dateStr,
        dateStrEnd: clearDateStrEnd ? null : (dateStrEnd ?? this.dateStrEnd),
        dateEnd: clearDateEnd ? null : (dateEnd ?? this.dateEnd),
        location: location ?? this.location,
        category: category ?? this.category,
        description: description ?? this.description,
        createdBy: createdBy,
        createdAt: createdAt,
        minPlayers: minPlayers ?? this.minPlayers,
        maxPlayers: clearMax ? null : (maxPlayers ?? this.maxPlayers),
        maxTeams: clearMaxTeams ? null : (maxTeams ?? this.maxTeams),
        badmintonTypes: badmintonTypes ?? this.badmintonTypes,
        registrationOpen: registrationOpen ?? this.registrationOpen,
      );

  // ── Helpers ───────────────────────────────────────────────────────────────
  bool get isBadminton => category == 'Badminton';

  String get spotsLabel {
    if (maxPlayers != null) return '$minPlayers–$maxPlayers players';
    return '$minPlayers+ players';
  }
}