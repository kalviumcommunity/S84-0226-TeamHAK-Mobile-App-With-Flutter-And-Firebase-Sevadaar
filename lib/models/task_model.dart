import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors the Firestore `tasks` collection schema.
/// Status values: "inviting" | "active" | "completed"
class TaskModel {
  final String taskId;
  final String title;
  final String description;
  final String adminId;
  final String ngoId;
  final int maxVolunteers;
  final List<String> assignedVolunteers;
  final List<String> pendingInvites;
  final List<String> declinedBy;
  final String status; // 'inviting', 'active', 'completed'
  final double mainProgress; // 0.0 – 100.0
  final DateTime createdAt;
  final DateTime deadline;
  final DateTime inviteDeadline;
  final String adminFinalNote;

  const TaskModel({
    required this.taskId,
    required this.title,
    required this.description,
    required this.adminId,
    required this.ngoId,
    required this.maxVolunteers,
    required this.assignedVolunteers,
    required this.pendingInvites,
    required this.declinedBy,
    required this.status,
    required this.mainProgress,
    required this.createdAt,
    required this.deadline,
    required this.inviteDeadline,
    this.adminFinalNote = '',
  });

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    List<String> toStringList(dynamic v) =>
        v == null ? [] : List<String>.from(v as List);

    return TaskModel(
      taskId: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      adminId: map['adminId'] ?? '',
      ngoId: map['ngoId'] ?? '',
      maxVolunteers: (map['maxVolunteers'] ?? 1) as int,
      assignedVolunteers: toStringList(map['assignedVolunteers']),
      pendingInvites: toStringList(map['pendingInvites']),
      declinedBy: toStringList(map['declinedBy']),
      status: map['status'] ?? 'inviting',
      mainProgress: (map['mainProgress'] ?? 0.0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deadline: (map['deadline'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 7)),
      inviteDeadline: (map['inviteDeadline'] as Timestamp?)?.toDate() ??
          ((map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now())
              .add(const Duration(hours: 24)),
      adminFinalNote: map['adminFinalNote'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'adminId': adminId,
        'ngoId': ngoId,
        'maxVolunteers': maxVolunteers,
        'assignedVolunteers': assignedVolunteers,
        'pendingInvites': pendingInvites,
        'declinedBy': declinedBy,
        'status': status,
        'mainProgress': mainProgress,
        'createdAt': Timestamp.fromDate(createdAt),
        'deadline': Timestamp.fromDate(deadline),
        'inviteDeadline': Timestamp.fromDate(inviteDeadline),
        'adminFinalNote': adminFinalNote,
      };
}
