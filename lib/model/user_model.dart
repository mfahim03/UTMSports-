class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String? phone;
  final String? matric;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.matric,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) => UserModel(
        uid: uid,
        email: map['email'] ?? '',
        name: map['name'] ?? '',
        role: map['role'] ?? 'student',
        phone: map['phone'],
        matric: map['matric'],
      );

  Map<String, dynamic> toMap() => {
        'email': email,
        'name': name,
        'role': role,
        if (phone != null) 'phone': phone,
        if (matric != null) 'matric': matric,
      };

  UserModel copyWith({String? role, String? name, String? phone, String? matric}) =>
      UserModel(
        uid: uid,
        email: email,
        name: name ?? this.name,
        role: role ?? this.role,
        phone: phone ?? this.phone,
        matric: matric ?? this.matric,
      );
}