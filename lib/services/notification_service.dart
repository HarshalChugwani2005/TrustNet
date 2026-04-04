import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendNotification({
    required String targetUserId,
    required String title,
    required String message,
  }) async {
    final docRef = _firestore.collection('notifications').doc();
    final model = NotificationModel(
      id: docRef.id,
      targetUserId: targetUserId,
      title: title,
      message: message,
      createdAt: DateTime.now(),
    );
    await docRef.set(model.toMap());
  }

  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('targetUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
           final list = snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .toList();
           list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
           return list;
        });
  }
}
