import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/feedback_model.dart';

class FeedbackRepository {
  final _col = FirebaseFirestore.instance.collection('feedback');

  // Stream all feedback (admin/organiser) 
  Stream<List<FeedbackModel>> watchAll() => _col
      .orderBy('submittedAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => FeedbackModel.fromMap(d.id, d.data()))
          .toList());

  // Stream by category 
  Stream<List<FeedbackModel>> watchByCategory(String category) => _col
      .where('category', isEqualTo: category)
      .orderBy('submittedAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => FeedbackModel.fromMap(d.id, d.data()))
          .toList());

  // Submit feedback (student) 
  Future<void> submit(FeedbackModel f) => _col.add(f.toMap());
}