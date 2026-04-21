import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/user_model.dart';

class AdminRepository {
  final _db = FirebaseFirestore.instance;

  // Stream all non-admin users 
  Stream<List<UserModel>> watchUsers() => _db
      .collection('users')
      .where('role', whereNotIn: ['admin'])
      .orderBy('role')
      .orderBy('name')
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => UserModel.fromMap(d.id, d.data())).toList());

  // Toggle role between student ↔ organiser 
  Future<void> setRole(String uid, String newRole) =>
      _db.collection('users').doc(uid).update({'role': newRole});

  // Update any user field 
  Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      _db.collection('users').doc(uid).update(data);

  // Delete user document (Auth deletion requires Admin SDK / Cloud Fn) 
  Future<void> deleteUserDoc(String uid) =>
      _db.collection('users').doc(uid).delete();
}