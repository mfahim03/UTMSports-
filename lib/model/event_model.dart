import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String date;        // display string e.g. "10 Jan 2025"
  final String location;
  final String category;   // Running | Badminton | Volleyball | Squash | Table Tennis | Other
  final String spots;      // e.g. "200 spots left"
  final String? description;
  final String createdBy;  // organiser uid
  final DateTime createdAt;

  const EventModel({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.category,
    required this.spots,
    this.description,
    required this.createdBy,
    required this.createdAt,
  });

  factory EventModel.fromMap(String id, Map<String, dynamic> map) =>
      EventModel(
        id: id,
        title: map['title'] ?? '',
        date: map['date'] ?? '',
        location: map['location'] ?? '',
        category: map['category'] ?? '',
        spots: map['spots'] ?? '',
        description: map['description'],
        createdBy: map['createdBy'] ?? '',
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'date': date,
        'location': location,
        'category': category,
        'spots': spots,
        if (description != null) 'description': description,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  EventModel copyWith({
    String? title,
    String? date,
    String? location,
    String? category,
    String? spots,
    String? description,
  }) =>
      EventModel(
        id: id,
        title: title ?? this.title,
        date: date ?? this.date,
        location: location ?? this.location,
        category: category ?? this.category,
        spots: spots ?? this.spots,
        description: description ?? this.description,
        createdBy: createdBy,
        createdAt: createdAt,
      );
}