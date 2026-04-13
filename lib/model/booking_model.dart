import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String userId;
  final String userEmail;
  final String sport;
  final int court;
  final String date;       // "YYYY-MM-DD"
  final String timeSlot;   // e.g. "08:00 - 09:00"
  final DateTime createdAt;
  final String status;     // 'confirmed' | 'cancelled'

  const BookingModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.sport,
    required this.court,
    required this.date,
    required this.timeSlot,
    required this.createdAt,
    this.status = 'confirmed',
  });

  factory BookingModel.fromMap(String id, Map<String, dynamic> map) =>
      BookingModel(
        id: id,
        userId: map['userId'] ?? '',
        userEmail: map['userEmail'] ?? '',
        sport: map['sport'] ?? '',
        court: (map['court'] ?? 0) as int,
        date: map['date'] ?? '',
        timeSlot: map['timeSlot'] ?? '',
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: map['status'] ?? 'confirmed',
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userEmail': userEmail,
        'sport': sport,
        'court': court,
        'date': date,
        'timeSlot': timeSlot,
        'createdAt': Timestamp.fromDate(createdAt),
        'status': status,
      };
}