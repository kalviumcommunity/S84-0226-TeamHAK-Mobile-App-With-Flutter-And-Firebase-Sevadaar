import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an application from someone who wants Super Admin access.
/// Stored in Firestore `ngo_applications` collection.
class NgoApplicationModel {
  final String applicationId;
  final String applicantName;
  final String applicantEmail;
  final String ngoName;
  final String ngoDescription;
  final String ngoAddress;
  final String ngoPhone;
  final String status; // "pending", "approved", "rejected"
  final DateTime submittedAt;

  const NgoApplicationModel({
    required this.applicationId,
    required this.applicantName,
    required this.applicantEmail,
    required this.ngoName,
    required this.ngoDescription,
    required this.ngoAddress,
    required this.ngoPhone,
    this.status = 'pending',
    required this.submittedAt,
  });

  factory NgoApplicationModel.fromMap(Map<String, dynamic> map, String id) {
    return NgoApplicationModel(
      applicationId: id,
      applicantName: map['applicantName'] ?? '',
      applicantEmail: map['applicantEmail'] ?? '',
      ngoName: map['ngoName'] ?? '',
      ngoDescription: map['ngoDescription'] ?? '',
      ngoAddress: map['ngoAddress'] ?? '',
      ngoPhone: map['ngoPhone'] ?? '',
      status: map['status'] ?? 'pending',
      submittedAt:
          (map['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'applicantName': applicantName,
      'applicantEmail': applicantEmail,
      'ngoName': ngoName,
      'ngoDescription': ngoDescription,
      'ngoAddress': ngoAddress,
      'ngoPhone': ngoPhone,
      'status': status,
      'submittedAt': Timestamp.fromDate(submittedAt),
    };
  }
}
