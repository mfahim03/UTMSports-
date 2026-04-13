import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/user_model.dart';

class AuthRepository {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // ── Register (students only) ──────────────────────────────────────────────
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? matric,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);

    final user = UserModel(
      uid: cred.user!.uid,
      email: email,
      name: name,
      role: 'student',
      phone: phone,
      matric: matric,
    );

    await _db.collection('users').doc(user.uid).set(user.toMap());
    return user;
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<UserModel> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);

    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    if (!doc.exists) throw Exception('User record not found.');
    return UserModel.fromMap(doc.id, doc.data()!);
  }

  // ── Fetch single user ─────────────────────────────────────────────────────
  Future<UserModel?> fetchUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.id, doc.data()!);
  }

  // ── Update profile ────────────────────────────────────────────────────────
  Future<void> updateProfile({
    required String name,
    required String phone,
    required String matric,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('No logged in user.');

    await _db.collection('users').doc(uid).update({
      'name':   name,
      'phone':  phone,
      'matric': matric,
    });
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> signOut() => _auth.signOut();
}