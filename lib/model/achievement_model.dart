import 'package:cloud_firestore/cloud_firestore.dart';

class AchievementModel {
  final String id;
  final String studentName;
  final String title;
  final String category; // e.g. Badminton, Running, Volleyball, Squash
  final String award;    // e.g. Champion, Gold Medal, 2nd Place
  final String date;     // display string e.g. "10 Oct 2024"
  final String? description;
  final DateTime createdAt;

  const AchievementModel({
    required this.id,
    required this.studentName,
    required this.title,
    required this.category,
    required this.award,
    required this.date,
    this.description,
    required this.createdAt,
  });

  factory AchievementModel.fromMap(String id, Map<String, dynamic> map) =>
      AchievementModel(
        id: id,
        studentName: map['studentName'] ?? '',
        title: map['title'] ?? '',
        category: map['category'] ?? '',
        award: map['award'] ?? '',
        date: map['date'] ?? '',
        description: map['description'],
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'studentName': studentName,
        'title': title,
        'category': category,
        'award': award,
        'date': date,
        if (description != null) 'description': description,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  AchievementModel copyWith({
    String? studentName,
    String? title,
    String? category,
    String? award,
    String? date,
    String? description,
  }) =>
      AchievementModel(
        id: id,
        studentName: studentName ?? this.studentName,
        title: title ?? this.title,
        category: category ?? this.category,
        award: award ?? this.award,
        date: date ?? this.date,
        description: description ?? this.description,
        createdAt: createdAt,
      );
}