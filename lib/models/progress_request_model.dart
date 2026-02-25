import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors Firestore `progress_requests` collection.
/// Volunteer submits this; Admin approves/rejects.
class ProgressRequestModel {
  final String requestId;
  final String taskId;
  final String taskTitle; // Denormalised for quick display
  final String volunteerId;
  final String adminId; // Denormalised for efficient admin queries
  final double currentProgress; // Individual progress before this request
  final double requestedProgress; // Desired new progress
  final String mandatoryNote;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;

  const ProgressRequestModel({
    required this.requestId,
    required this.taskId,
    required this.taskTitle,
    required this.volunteerId,
    required this.adminId,
    required this.currentProgress,
    required this.requestedProgress,
    required this.mandatoryNote,
    required this.status,
    required this.createdAt,
  });

  factory ProgressRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return ProgressRequestModel(
      requestId: id,
      taskId: map['taskId'] ?? '',
      taskTitle: map['taskTitle'] ?? '',
      volunteerId: map['volunteerId'] ?? '',
      adminId: map['adminId'] ?? '',
      currentProgress: (map['currentProgress'] ?? 0.0).toDouble(),
      requestedProgress: (map['requestedProgress'] ?? 0.0).toDouble(),
      mandatoryNote: map['mandatoryNote'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'taskId': taskId,
        'taskTitle': taskTitle,
        'volunteerId': volunteerId,
        'adminId': adminId,
        'currentProgress': currentProgress,
        'requestedProgress': requestedProgress,
        'mandatoryNote': mandatoryNote,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
