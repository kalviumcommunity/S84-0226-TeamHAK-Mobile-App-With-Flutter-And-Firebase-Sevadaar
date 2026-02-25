import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an NGO registration request submitted by a user.
/// Stored in Firestore `ngo_requests` collection.
class NgoRequestModel {
  final String requestId;
  final String ngoName;
  final String registrationNumber;
  final String certificateUrl;
  final String contactEmail;
  final String address;
  final String description;
  final String requestedBy;
  final String status; // "pending", "approved", "rejected"
  final DateTime createdAt;

  const NgoRequestModel({
    required this.requestId,
    required this.ngoName,
    required this.registrationNumber,
    required this.certificateUrl,
    required this.contactEmail,
    required this.address,
    required this.description,
    required this.requestedBy,
    required this.status,
    required this.createdAt,
  });

  factory NgoRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return NgoRequestModel(
      requestId: id,
      ngoName: map['ngoName'] ?? '',
      registrationNumber: map['registrationNumber'] ?? '',
      certificateUrl: map['certificateUrl'] ?? '',
      contactEmail: map['contactEmail'] ?? '',
      address: map['address'] ?? '',
      description: map['description'] ?? '',
      requestedBy: map['requestedBy'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ngoName': ngoName,
      'registrationNumber': registrationNumber,
      'certificateUrl': certificateUrl,
      'contactEmail': contactEmail,
      'address': address,
      'description': description,
      'requestedBy': requestedBy,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
