import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ngo_request_model.dart';
import '../models/ngo_model.dart';
import 'ngo_service.dart';
import 'user_service.dart';
import 'firestore_notification_service.dart';

class NgoRequestService {
  FirebaseFirestore? _dbInstance;
  final _ngoService = NgoService();
  final _userService = UserService();
  final _notifService = FirestoreNotificationService();

  FirebaseFirestore get _db {
    try {
      return _dbInstance ??= FirebaseFirestore.instance;
    } catch (e) {
      throw Exception('Firebase not initialized.');
    }
  }

  Future<NgoRequestModel> submitRequest({
    required String ngoName,
    required String registrationNumber,
    required String certificateUrl,
    required String contactEmail,
    required String address,
    required String description,
    required String requestedBy,
  }) async {
    final docRef = _db.collection('ngo_requests').doc();
    final request = NgoRequestModel(
      requestId: docRef.id,
      ngoName: ngoName.trim(),
      registrationNumber: registrationNumber.trim(),
      certificateUrl: certificateUrl,
      contactEmail: contactEmail.trim(),
      address: address.trim(),
      description: description.trim(),
      requestedBy: requestedBy,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    await docRef.set(request.toMap());
    await _userService.updateNgoRequestStatus(requestedBy, 'pending');
    
    // Notify the user that their request is submitted
    await _notifService.sendNotification(
      recipientUid: requestedBy,
      title: 'NGO Request Submitted',
      body: 'Your NGO "${ngoName.trim()}" is now pending approval by Dev Admin.',
      type: 'ngo_request',
      taskId: '',
    );
    
    return request;
  }

  Stream<List<NgoRequestModel>> streamAllRequests() {
    return _db
        .collection('ngo_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => NgoRequestModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<NgoRequestModel>> streamRequestsByStatus(String status) {
    return _db
        .collection('ngo_requests')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => NgoRequestModel.fromMap(d.data(), d.id))
            .toList());
  }

  /// Approve: 1. Create NGO  2. Promote user to super_admin  3. Update request status
  Future<NgoModel> approveRequest(NgoRequestModel request) async {
    final ngo = await _ngoService.createNgoFromRequest(
      name: request.ngoName,
      registrationNumber: request.registrationNumber,
      superAdminId: request.requestedBy,
    );
    await _userService.promoteToSuperAdmin(request.requestedBy, ngo.ngoId);
    await _db
        .collection('ngo_requests')
        .doc(request.requestId)
        .update({'status': 'approved'});
        
    // Notify the user of approval
    await _notifService.sendNotification(
      recipientUid: request.requestedBy,
      title: 'NGO Request Approved',
      body: 'Your NGO "${request.ngoName}" has been approved! Please sign in again to access the Super Admin Dashboard.',
      type: 'ngo_request',
      taskId: '',
    );
    
    return ngo;
  }

  Future<void> rejectRequest(NgoRequestModel request) async {
    await _db
        .collection('ngo_requests')
        .doc(request.requestId)
        .update({'status': 'rejected'});
    await _userService.updateNgoRequestStatus(request.requestedBy, 'rejected');
    
    // Notify the user of rejection
    await _notifService.sendNotification(
      recipientUid: request.requestedBy,
      title: 'NGO Request Rejected',
      body: 'Your NGO request for "${request.ngoName}" was unfortunately rejected.',
      type: 'ngo_request',
      taskId: '',
    );
  }

  Future<NgoRequestModel?> getRequestByUser(String userId) async {
    final snap = await _db
        .collection('ngo_requests')
        .where('requestedBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return NgoRequestModel.fromMap(doc.data(), doc.id);
  }

  Future<void> resubmitRequest({
    required String requestId,
    required String userId,
    required String ngoName,
    required String registrationNumber,
    required String certificateUrl,
    required String contactEmail,
    required String address,
    required String description,
  }) async {
    await _db.collection('ngo_requests').doc(requestId).update({
      'ngoName': ngoName.trim(),
      'registrationNumber': registrationNumber.trim(),
      'certificateUrl': certificateUrl,
      'contactEmail': contactEmail.trim(),
      'address': address.trim(),
      'description': description.trim(),
      'status': 'pending',
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
    await _userService.updateNgoRequestStatus(userId, 'pending');
  }
}
