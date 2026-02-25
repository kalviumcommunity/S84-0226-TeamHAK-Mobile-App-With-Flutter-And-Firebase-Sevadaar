/// Mirrors Firestore `task_assignments` collection.
/// Tracks an individual volunteer's progress on a specific task.
class TaskAssignmentModel {
  final String assignmentId;
  final String taskId;
  final String volunteerId;
  final double individualProgress; // 0.0 – 100.0

  const TaskAssignmentModel({
    required this.assignmentId,
    required this.taskId,
    required this.volunteerId,
    required this.individualProgress,
  });

  factory TaskAssignmentModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskAssignmentModel(
      assignmentId: id,
      taskId: map['taskId'] ?? '',
      volunteerId: map['volunteerId'] ?? '',
      individualProgress: (map['individualProgress'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'taskId': taskId,
        'volunteerId': volunteerId,
        'individualProgress': individualProgress,
      };
}
