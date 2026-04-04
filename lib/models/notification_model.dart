import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String targetUserId;
  final String title;
  final String message;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.targetUserId,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> data, String documentId) {
    return NotificationModel(
      id: documentId,
      targetUserId: data['targetUserId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'targetUserId': targetUserId,
      'title': title,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
