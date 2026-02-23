import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors the Firestore `users` collection schema from the LLD.
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // "super_admin", "admin", "volunteer"
  final String status; // "active", "inactive"
  final String fcmToken;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.role = 'volunteer',
    this.status = 'active',
    this.fcmToken = '',
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
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? role,
    String? status,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }
}
