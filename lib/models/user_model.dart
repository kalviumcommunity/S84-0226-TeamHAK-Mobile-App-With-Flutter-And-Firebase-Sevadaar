import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors the Firestore `users` collection schema.
/// Roles: "developer_admin", "super_admin", "admin", "volunteer"
/// ngoRequestStatus: "none", "pending", "approved", "rejected"
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // "developer_admin", "super_admin", "admin", "volunteer"
  final String status; // "active", "inactive"
  final String fcmToken;
  final String? orgId; // Legacy field — alias for ngoId
  final String? ngoId; // The NGO this user belongs to
  final String ngoRequestStatus; // "none", "pending", "approved", "rejected"
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.role = 'volunteer',
    this.status = 'active',
    this.fcmToken = '',
    this.orgId,
    this.ngoId,
    this.ngoRequestStatus = 'none',
    required this.createdAt,
  });

  /// Create from Firestore document snapshot.
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'volunteer',
      status: map['status'] ?? 'active',
      fcmToken: map['fcmToken'] ?? '',
      orgId: map['orgId'] ?? map['ngoId'],
      ngoId: map['ngoId'] ?? map['orgId'],
      ngoRequestStatus: map['ngoRequestStatus'] ?? 'none',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Serialise to Firestore-friendly map.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      'fcmToken': fcmToken,
      'orgId': ngoId ?? orgId,
      'ngoId': ngoId ?? orgId,
      'ngoRequestStatus': ngoRequestStatus,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? role,
    String? status,
    String? fcmToken,
    String? orgId,
    String? ngoId,
    String? ngoRequestStatus,
    bool clearNgoId = false,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      fcmToken: fcmToken ?? this.fcmToken,
      orgId: clearNgoId ? null : (orgId ?? this.orgId),
      ngoId: clearNgoId ? null : (ngoId ?? this.ngoId),
      ngoRequestStatus: ngoRequestStatus ?? this.ngoRequestStatus,
      createdAt: createdAt,
    );
  }
}
