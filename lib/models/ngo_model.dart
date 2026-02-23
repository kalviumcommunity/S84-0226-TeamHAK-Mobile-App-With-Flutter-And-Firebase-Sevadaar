import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an NGO / Organisation in Firestore `ngos` collection.
class NgoModel {
  final String ngoId;
  final String name;
  final String description;
  final String address;
  final String contactEmail;
  final String joinCode; // 8-digit numeric unique code
  final String superAdminId;
  final DateTime createdAt;

  const NgoModel({
    required this.ngoId,
    required this.name,
    required this.description,
    required this.address,
    required this.contactEmail,
    required this.joinCode,
    required this.superAdminId,
    required this.createdAt,
  });

  factory NgoModel.fromMap(Map<String, dynamic> map, String id) {
    return NgoModel(
      ngoId: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      address: map['address'] ?? '',
      contactEmail: map['contactEmail'] ?? '',
      joinCode: map['joinCode'] ?? '',
      superAdminId: map['superAdminId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'address': address,
      'contactEmail': contactEmail,
      'joinCode': joinCode,
      'superAdminId': superAdminId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
