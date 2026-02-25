import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/ngo_model.dart';
import '../models/ngo_application_model.dart';

/// Handles NGO-related Firestore operations.
class NgoService {
  FirebaseFirestore? _dbInstance;

  /// Lazily initialize Firestore, handling cases where it's not available
  FirebaseFirestore get _db {
    try {
      return _dbInstance ??= FirebaseFirestore.instance;
    } catch (e) {
      throw Exception('Firebase not initialized. Feature unavailable on this platform.');
    }
  }

  // ── Generate Unique 8-Digit Numeric Code ────────────────────────
  /// Generates a random 8-digit numeric code and ensures it doesn't
  /// already exist in Firestore `ngos` collection.
  Future<String> generateUniqueCode() async {
    final rng = Random.secure();
    String code;

    while (true) {
      // Generate 8-digit numeric code (10000000–99999999)
      code = (10000000 + rng.nextInt(90000000)).toString();

      // Check for collisions
      final existing = await _db
          .collection('ngos')
          .where('joinCode', isEqualTo: code)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) break;
    }

    return code;
  }

  // ── Validate Join Code ──────────────────────────────────────────
  /// Returns the NGO doc ID if a valid join code exists, null otherwise.
  Future<NgoModel?> validateJoinCode(String code) async {
    final snap = await _db
        .collection('ngos')
        .where('joinCode', isEqualTo: code.trim())
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;

    final doc = snap.docs.first;
    return NgoModel.fromMap(doc.data(), doc.id);
  }

  // ── Create NGO ──────────────────────────────────────────────────
  /// Creates an NGO document with an auto-generated unique join code.
  /// Called from the Super Admin dashboard.
  Future<NgoModel> createNgo({
    required String name,
    required String description,
    required String address,
    required String contactEmail,
    required String superAdminId,
  }) async {
    final joinCode = await generateUniqueCode();
    final docRef = _db.collection('ngos').doc();

    final ngo = NgoModel(
      ngoId: docRef.id,
      name: name.trim(),
      description: description.trim(),
      address: address.trim(),
      contactEmail: contactEmail.trim(),
      joinCode: joinCode,
      superAdminId: superAdminId,
      createdAt: DateTime.now(),
    );

    await docRef.set(ngo.toMap());
    return ngo;
  }

  // ── Submit NGO Application ──────────────────────────────────────
  /// Stores the application in Firestore and sends an email notification
  /// to the developer team via EmailJS.
  Future<void> submitApplication({
    required String applicantName,
    required String applicantEmail,
    required String ngoName,
    required String ngoDescription,
    required String ngoAddress,
    required String ngoPhone,
  }) async {
    final docRef = _db.collection('ngo_applications').doc();

    final application = NgoApplicationModel(
      applicationId: docRef.id,
      applicantName: applicantName.trim(),
      applicantEmail: applicantEmail.trim(),
      ngoName: ngoName.trim(),
      ngoDescription: ngoDescription.trim(),
      ngoAddress: ngoAddress.trim(),
      ngoPhone: ngoPhone.trim(),
      status: 'pending',
      submittedAt: DateTime.now(),
    );

    await docRef.set(application.toMap());

    // Fire email via EmailJS (optional — fails silently if keys not set)
    await _sendEmailNotification(application);
  }

  /// Sends email via EmailJS REST API.
  /// Configure EMAILJS_SERVICE_ID, EMAILJS_TEMPLATE_ID, EMAILJS_PUBLIC_KEY
  /// in your .env file.
  Future<void> _sendEmailNotification(NgoApplicationModel app) async {
    try {
      const serviceId = String.fromEnvironment('EMAILJS_SERVICE_ID',
          defaultValue: '');
      const templateId = String.fromEnvironment('EMAILJS_TEMPLATE_ID',
          defaultValue: '');
      const publicKey = String.fromEnvironment('EMAILJS_PUBLIC_KEY',
          defaultValue: '');

      if (serviceId.isEmpty || templateId.isEmpty || publicKey.isEmpty) return;

      await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'applicant_name': app.applicantName,
            'applicant_email': app.applicantEmail,
            'ngo_name': app.ngoName,
            'ngo_description': app.ngoDescription,
            'ngo_address': app.ngoAddress,
            'ngo_phone': app.ngoPhone,
          },
        }),
      );
    } catch (_) {
      // Email notification is best-effort; don't block the app flow.
    }
  }

  // ── Get NGOs for Super Admin ────────────────────────────────────
  /// Returns all NGOs created by a specific super admin.
  Stream<List<NgoModel>> getNgosForSuperAdmin(String superAdminId) {
    return _db
        .collection('ngos')
        .where('superAdminId', isEqualTo: superAdminId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => NgoModel.fromMap(d.data(), d.id)).toList());
  }

  // ── Validate NGO Code ───────────────────────────────────────────
  /// Looks up an NGO by join code (alias for validateJoinCode).
  Future<NgoModel?> validateNgoCode(String code) async {
    return validateJoinCode(code);
  }

  // ── Create NGO from Developer Admin Approval ────────────────────
  /// Creates an NGO when a developer admin approves an NGO request.
  /// Uses a simplified model with just name + registration number.
  Future<NgoModel> createNgoFromRequest({
    required String name,
    required String registrationNumber,
    required String superAdminId,
  }) async {
    final joinCode = await generateUniqueCode();
    final docRef = _db.collection('ngos').doc();

    final ngo = NgoModel(
      ngoId: docRef.id,
      name: name.trim(),
      description: '',
      address: '',
      contactEmail: '',
      joinCode: joinCode,
      superAdminId: superAdminId,
      createdAt: DateTime.now(),
    );

    await docRef.set(ngo.toMap());
    return ngo;
  }

  // ── Get NGO by ID ──────────────────────────────────────────────
  Future<NgoModel?> getNgoById(String ngoId) async {
    final doc = await _db.collection('ngos').doc(ngoId).get();
    if (!doc.exists) return null;
    return NgoModel.fromMap(doc.data()!, doc.id);
  }
}
