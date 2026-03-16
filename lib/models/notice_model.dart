import 'package:cloud_firestore/cloud_firestore.dart';

class NoticeModel {
  final String id;
  final String volunteerId;
  final String taskId;
  final String taskTitle;
  final String reason;
  final DateTime createdAt;

  NoticeModel({
    required this.id,
    required this.volunteerId,
    required this.taskId,
    required this.taskTitle,
    required this.reason,
    required this.createdAt,
  });

  factory NoticeModel.fromMap(Map<String, dynamic> map, String id) {
    return NoticeModel(
      id: id,
      volunteerId: map['volunteerId'] ?? '',
      taskId: map['taskId'] ?? '',
      taskTitle: map['taskTitle'] ?? 'Unknown Task',
      reason: map['reason'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'volunteerId': volunteerId,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
