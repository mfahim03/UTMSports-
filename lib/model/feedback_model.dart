import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String studentName;
  final String studentEmail;
  final String category; // Events | Facilities | App
  final String message;
  final int rating; // 1–5
  final DateTime submittedAt;

  const FeedbackModel({
    required this.id,
    required this.studentName,
    required this.studentEmail,
    required this.category,
    required this.message,
    required this.rating,
    required this.submittedAt,
  });

  factory FeedbackModel.fromMap(String id, Map<String, dynamic> map) =>
      FeedbackModel(
        id: id,
        studentName: map['studentName'] ?? '',
        studentEmail: map['studentEmail'] ?? '',
        category: map['category'] ?? '',
        message: map['message'] ?? '',
        rating: (map['rating'] ?? 0) as int,
        submittedAt:
            (map['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'studentName': studentName,
        'studentEmail': studentEmail,
        'category': category,
        'message': message,
        'rating': rating,
        'submittedAt': Timestamp.fromDate(submittedAt),
      };
}