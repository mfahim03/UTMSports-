import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/achievement_model.dart';

class AchievementRepository {
  final _col = FirebaseFirestore.instance.collection('achievements');

  // Stream all achievements ordered by date 
  Stream<List<AchievementModel>> watchAll() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => AchievementModel.fromMap(d.id, d.data()))
          .toList());

  // Stream by category 
  Stream<List<AchievementModel>> watchByCategory(String category) => _col
      .where('category', isEqualTo: category)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => AchievementModel.fromMap(d.id, d.data()))
          .toList());

  // Add 
  Future<void> add(AchievementModel a) => _col.add(a.toMap());

  // Update 
  Future<void> update(AchievementModel a) =>
      _col.doc(a.id).update(a.toMap());

  // Delete 
  Future<void> delete(String id) => _col.doc(id).delete();
}