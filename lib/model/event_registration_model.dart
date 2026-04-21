import 'package:cloud_firestore/cloud_firestore.dart';

enum RegStatus { pending, confirmed, rejected }

extension RegStatusX on RegStatus {
  String get value => name;
  String get label => switch (this) {
        RegStatus.pending   => 'Under Review',
        RegStatus.confirmed => 'Confirmed',
        RegStatus.rejected  => 'Rejected',
      };
  static RegStatus fromString(String s) =>
      RegStatus.values.firstWhere((e) => e.value == s,
          orElse: () => RegStatus.pending);
}

class EventRegistrationModel {
  final String id;
  final String eventId;
  final String eventTitle;
  final String eventCategory;
  final String eventDate;

  // Captain
  final String userId;
  final String userName;
  final String userEmail;

  // Team
  final String? format;           // Badminton: Solo | Double | Mixed
  final List<String> teamMembers; // extra members beyond captain
  final int totalMembers;

  // Status
  final RegStatus status;
  final String? organiserNote;
  final DateTime registeredAt;

  const EventRegistrationModel({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.eventCategory,
    required this.eventDate,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.format,
    required this.teamMembers,
    required this.totalMembers,
    this.status = RegStatus.pending,
    this.organiserNote,
    required this.registeredAt,
  });

  factory EventRegistrationModel.fromMap(
          String id, Map<String, dynamic> m) =>
      EventRegistrationModel(
        id: id,
        eventId: m['eventId'] ?? '',
        eventTitle: m['eventTitle'] ?? '',
        eventCategory: m['eventCategory'] ?? '',
        eventDate: m['eventDate'] ?? '',
        userId: m['userId'] ?? '',
        userName: m['userName'] ?? '',
        userEmail: m['userEmail'] ?? '',
        format: m['format'],
        teamMembers: List<String>.from(m['teamMembers'] ?? []),
        totalMembers: (m['totalMembers'] ?? 1) as int,
        status: RegStatusX.fromString(m['status'] ?? 'pending'),
        organiserNote: m['organiserNote'],
        registeredAt:
            (m['registeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'eventId': eventId,
        'eventTitle': eventTitle,
        'eventCategory': eventCategory,
        'eventDate': eventDate,
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        if (format != null) 'format': format,
        'teamMembers': teamMembers,
        'totalMembers': totalMembers,
        'status': status.value,
        if (organiserNote != null) 'organiserNote': organiserNote,
        'registeredAt': Timestamp.fromDate(registeredAt),
      };

  EventRegistrationModel copyWithStatus(RegStatus s, {String? note}) =>
      EventRegistrationModel(
        id: id,
        eventId: eventId,
        eventTitle: eventTitle,
        eventCategory: eventCategory,
        eventDate: eventDate,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        format: format,
        teamMembers: teamMembers,
        totalMembers: totalMembers,
        status: s,
        organiserNote: note ?? organiserNote,
        registeredAt: registeredAt,
      );
}