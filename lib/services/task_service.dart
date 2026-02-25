import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/task_assignment_model.dart';
import '../models/progress_request_model.dart';
import '../models/user_model.dart';

class TaskService {
  FirebaseFirestore? _dbInstance;
  FirebaseFirestore get _db {
    try {
      return _dbInstance ??= FirebaseFirestore.instance;
    } catch (e) {
      throw Exception('Firebase not initialized.');
    }
  }

  // ── CREATE TASK ───────────────────────────────────────────────
  Future<String> createTask({
    required String title,
    required String description,
    required String adminId,
    required String ngoId,
    required int maxVolunteers,
    required DateTime deadline,
  }) async {
    final ref = _db.collection('tasks').doc();
    await ref.set({
      'title': title,
      'description': description,
      'adminId': adminId,
      'ngoId': ngoId,
      'maxVolunteers': maxVolunteers,
      'assignedVolunteers': [],
      'pendingInvites': [],
      'declinedBy': [],
      'status': 'inviting',
      'mainProgress': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
      'deadline': Timestamp.fromDate(deadline),
      'adminFinalNote': '',
    });
    return ref.id;
  }

  // ── STREAMS ───────────────────────────────────────────────────
  Stream<List<TaskModel>> streamAdminTasks(String adminId) {
    return _db
        .collection('tasks')
        .where('adminId', isEqualTo: adminId)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => TaskModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  Stream<List<ProgressRequestModel>> streamPendingRequestsForAdmin(
    String adminId,
  ) {
    return _db
        .collection('progress_requests')
        .where('adminId', isEqualTo: adminId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ProgressRequestModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  Stream<List<TaskAssignmentModel>> streamTaskAssignments(String taskId) {
    return _db
        .collection('task_assignments')
        .where('taskId', isEqualTo: taskId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => TaskAssignmentModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  Stream<TaskModel?> streamTask(String taskId) {
    return _db.collection('tasks').doc(taskId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return TaskModel.fromMap(doc.data()!, doc.id);
    });
  }

  Stream<List<UserModel>> streamNgoVolunteers(String ngoId) {
    return _db
        .collection('users')
        .where('ngoId', isEqualTo: ngoId)
        .where('role', isEqualTo: 'volunteer')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  // ── INVITE VOLUNTEERS ─────────────────────────────────────────
  Future<void> inviteVolunteers(
    String taskId,
    List<String> volunteerIds,
  ) async {
    await _db.collection('tasks').doc(taskId).update({
      'pendingInvites': FieldValue.arrayUnion(volunteerIds),
    });
  }

  Future<void> cancelInvite(String taskId, String volunteerId) async {
    await _db.collection('tasks').doc(taskId).update({
      'pendingInvites': FieldValue.arrayRemove([volunteerId]),
    });
  }

  // ── APPROVE PROGRESS REQUEST ──────────────────────────────────
  Future<void> approveProgressRequest(ProgressRequestModel request) async {
    final assignSnap = await _db
        .collection('task_assignments')
        .where('taskId', isEqualTo: request.taskId)
        .where('volunteerId', isEqualTo: request.volunteerId)
        .limit(1)
        .get();

    if (assignSnap.docs.isEmpty) {
      throw Exception('Assignment not found for this volunteer.');
    }

    final assignmentRef = assignSnap.docs.first.reference;

    final batch = _db.batch();
    batch.update(assignmentRef, {
      'individualProgress': request.requestedProgress,
    });
    batch.update(_db.collection('progress_requests').doc(request.requestId), {
      'status': 'approved',
    });
    await batch.commit();

    await _recalculateMainProgress(request.taskId);
  }

  // ── REJECT PROGRESS REQUEST ───────────────────────────────────
  Future<void> rejectProgressRequest(ProgressRequestModel request) async {
    await _db.collection('progress_requests').doc(request.requestId).update({
      'status': 'rejected',
    });
  }

  // ── REMOVE VOLUNTEER FROM TASK ────────────────────────────────
  Future<void> removeVolunteer(String taskId, String volunteerId) async {
    final assignSnap = await _db
        .collection('task_assignments')
        .where('taskId', isEqualTo: taskId)
        .where('volunteerId', isEqualTo: volunteerId)
        .limit(1)
        .get();

    final batch = _db.batch();

    if (assignSnap.docs.isNotEmpty) {
      batch.delete(assignSnap.docs.first.reference);
    }

    batch.update(_db.collection('tasks').doc(taskId), {
      'assignedVolunteers': FieldValue.arrayRemove([volunteerId]),
    });

    final pendingReqs = await _db
        .collection('progress_requests')
        .where('taskId', isEqualTo: taskId)
        .where('volunteerId', isEqualTo: volunteerId)
        .where('status', isEqualTo: 'pending')
        .get();

    for (final doc in pendingReqs.docs) {
      batch.update(doc.reference, {'status': 'rejected'});
    }

    await batch.commit();
    await _recalculateMainProgress(taskId);
  }

  // ── COMPLETE TASK ─────────────────────────────────────────────
  Future<void> completeTask(String taskId, String finalNote) async {
    final batch = _db.batch();
    batch.update(_db.collection('tasks').doc(taskId), {
      'status': 'completed',
      'adminFinalNote': finalNote,
      'mainProgress': 100.0,
    });

    final chatSnap = await _db
        .collection('chats')
        .where('taskId', isEqualTo: taskId)
        .limit(1)
        .get();

    if (chatSnap.docs.isNotEmpty) {
      batch.update(chatSnap.docs.first.reference, {'isArchived': true});
    }

    await batch.commit();
  }

  // ── INTERNAL: Recalculate mainProgress ───────────────────────
  Future<void> _recalculateMainProgress(String taskId) async {
    final taskDoc = await _db.collection('tasks').doc(taskId).get();
    if (!taskDoc.exists) return;

    final task = TaskModel.fromMap(taskDoc.data()!, taskDoc.id);
    final assignedCount = task.assignedVolunteers.length;

    if (assignedCount == 0) {
      await _db.collection('tasks').doc(taskId).update({'mainProgress': 0.0});
      return;
    }

    final assignSnap = await _db
        .collection('task_assignments')
        .where('taskId', isEqualTo: taskId)
        .get();

    double sum = 0;
    for (final doc in assignSnap.docs) {
      sum += (doc.data()['individualProgress'] ?? 0.0).toDouble();
    }

    final mainProgress = sum / assignedCount;
    final updates = <String, dynamic>{'mainProgress': mainProgress};

    if (mainProgress >= 100.0 && task.status != 'completed') {
      updates['status'] = 'completed';
    }

    await _db.collection('tasks').doc(taskId).update(updates);
  }
}
