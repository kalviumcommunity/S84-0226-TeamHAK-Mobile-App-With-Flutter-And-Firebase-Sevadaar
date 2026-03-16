import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'firestore_notification_service.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreNotificationService _notifService =
      FirestoreNotificationService();

  // ── CREATE GROUP CHAT (For Tasks) ──────────────────────────────────────────
  Future<String> createGroupChat({
    required String taskId,
    required String title,
    required String ngoId,
    required List<String> participantIds,
  }) async {
    final ref = _db.collection('chats').doc(taskId);
    await ref.set({
      'type': 'group',
      'taskId': taskId,
      'title': title,
      'ngoId': ngoId,
      'participants': participantIds,
      'lastMessage': 'Group formed.',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'isArchived': false,
      'isLocked': false,
      'unreadCounts': {for (var pid in participantIds) pid: 1},
      'archivedBy': [],
      'deletedBy': [],
    });
    return ref.id;
  }

  // ── CREATE OR GET DIRECT CHAT ──────────────────────────────────────────────
  Future<String> createOrGetDirectChat({
    required String currentUserUid,
    required String targetUserUid,
    required String ngoId,
  }) async {
    final uids = [currentUserUid, targetUserUid]..sort();
    final chatId = '${uids[0]}_${uids[1]}';

    final docSnap = await _db.collection('chats').doc(chatId).get();
    if (!docSnap.exists) {
      await _db.collection('chats').doc(chatId).set({
        'type': 'direct',
        'ngoId': ngoId,
        'participants': uids,
        'lastMessage': 'Say hi!',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'isArchived': false,
        'isLocked': false,
        'unreadCounts': {targetUserUid: 1, currentUserUid: 0},
        'archivedBy': [],
        'deletedBy': [],
      });
    } else {
      await _db.collection('chats').doc(chatId).update({
        'deletedBy': FieldValue.arrayRemove([currentUserUid]),
      });
    }
    return chatId;
  }

  // ── ADD USER TO GROUP CHAT ─────────────────────────────────────────────────
  Future<void> addUserToGroupChat(
    String taskId,
    String newParticipantId,
  ) async {
    await _db.collection('chats').doc(taskId).update({
      'participants': FieldValue.arrayUnion([newParticipantId]),
      'unreadCounts.$newParticipantId': 0,
    });
  }

  // ── REMOVE USER FROM GROUP CHAT ────────────────────────────────────────────
  Future<void> removeUserFromGroupChat(
    String taskId,
    String participantId,
  ) async {
    await _db.collection('chats').doc(taskId).update({
      'participants': FieldValue.arrayRemove([participantId]),
    });
  }

  // ── SEND MESSAGE ───────────────────────────────────────────────────────────
  Future<void> sendMessage({
    required String chatId,
    required UserModel sender,
    required String text,
  }) async {
    final chatRef = _db.collection('chats').doc(chatId);
    final chatDoc = await chatRef.get();

    if (!chatDoc.exists) return;

    final chatData = chatDoc.data()!;
    if (chatData['isLocked'] == true) {
      throw Exception('This chat is locked.');
    }

    List<String> participants = List<String>.from(
      chatData['participants'] ?? [],
    );

    final messageRef = chatRef.collection('messages').doc();
    final batch = _db.batch();

    batch.set(messageRef, {
      'senderId': sender.uid,
      'senderName': sender.name,
      'senderRole': sender.role,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [sender.uid],
    });

    Map<String, dynamic> unreadUpdates = {};
    for (String p in participants) {
      if (p != sender.uid) {
        unreadUpdates['unreadCounts.$p'] = FieldValue.increment(1);
      }
    }

    batch.update(chatRef, {
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'archivedBy': [],
      ...unreadUpdates,
    });

    await batch.commit();

    participants.remove(sender.uid);
    if (participants.isNotEmpty) {
      final chatTitle = chatData['type'] == 'group'
          ? chatData['title']
          : sender.name;
      final taskId = chatData['taskId'];
      await _notifService.sendToMultiple(
        recipientUids: participants,
        title: 'New message from $chatTitle',
        body: text,
        type: 'chat',
        taskId: taskId,
      );
    }
  }

  // ── MARK CHAT AS READ ──────────────────────────────────────────────────────
  Future<void> markChatAsRead(String chatId, String userId) async {
    await _db.collection('chats').doc(chatId).update({
      'unreadCounts.$userId': 0,
    });
  }

  // ── ARCHIVE CHAT ───────────────────────────────────────────────────────────
  Future<void> archiveChat(String chatId, String userId) async {
    await _db.collection('chats').doc(chatId).update({
      'archivedBy': FieldValue.arrayUnion([userId]),
    });
  }

  // ── UNARCHIVE CHAT ─────────────────────────────────────────────────────────
  Future<void> unarchiveChat(String chatId, String userId) async {
    await _db.collection('chats').doc(chatId).update({
      'archivedBy': FieldValue.arrayRemove([userId]),
    });
  }

  // ── DELETE/HIDE CHAT ───────────────────────────────────────────────────────
  Future<void> deleteChat(String chatId, String userId) async {
    await _db.collection('chats').doc(chatId).update({
      'deletedBy': FieldValue.arrayUnion([userId]),
    });
  }

  // ── LOCK GROUP CHAT (When Task Completed) ──────────────────────────────────
  Future<void> lockGroupChat(String taskId) async {
    await _db.collection('chats').doc(taskId).update({'isLocked': true});
  }

  // ── STREAM CHATS FOR USER ──────────────────────────────────────────────────
  Stream<List<ChatModel>> streamChatsForUser(String uid, String ngoId) {
    return _db
        .collection('chats')
        .where('ngoId', isEqualTo: ngoId)
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) {
          final chats = snap.docs
              .map((d) => ChatModel.fromMap(d.data(), d.id))
              .toList();
          return chats.where((c) => !c.deletedBy.contains(uid)).toList();
        });
  }

  // ── STREAM MESSAGES FOR CHAT ───────────────────────────────────────────────
  Stream<List<MessageModel>> streamMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => MessageModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  // ── FETCH CHAT PARTICIPANTS ────────────────────────────────────────────────
  /// Loads the chat document to get participant UIDs, then batch-fetches
  /// each user from the `users` collection and returns them as [UserModel]s.
  Future<List<UserModel>> fetchChatParticipants(String chatId) async {
    // 1. Load the chat to get the participants UID list
    final chatDoc = await _db.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) return [];

    final data = chatDoc.data()!;
    final uids = List<String>.from(data['participants'] ?? []);
    if (uids.isEmpty) return [];

    // 2. Batch-fetch all user documents in parallel
    final snapshots = await Future.wait(
      uids.map((uid) => _db.collection('users').doc(uid).get()),
    );

    // 3. Map to UserModel, skipping any docs that no longer exist
    return snapshots
        .where((doc) => doc.exists)
        .map((doc) => UserModel.fromMap(doc.data()!, doc.id))
        .toList();
  }
}


// this code is done 