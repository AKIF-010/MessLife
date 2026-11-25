// File: lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/validators.dart';

/// Version of the Terms/Privacy text the user agreed to (plan section 4.6).
const String kTermsVersion = '1.0';

class RegistrationData {
  RegistrationData({
    required this.fullName,
    required this.gender,
    required this.phone,
    required this.birthDay,
    required this.birthMonth,
    required this.birthYear,
    required this.occupationType,
    required this.occupationLabel,
    this.bloodGroup,
    this.religion,
    this.emergency,
    this.verificationDocPath,
  });

  final String fullName;
  final String gender; // "male" | "female"
  final String phone; // E.164
  final int birthDay;
  final int birthMonth;
  final int birthYear;
  final String occupationType; // student | job | business | freelance | other
  final String occupationLabel;
  final String? bloodGroup;
  final String? religion;
  final Map<String, String>? emergency; // {name, phone, relation}
  final String? verificationDocPath; // Firebase Storage path (optional)
}

/// Reads/writes users/{uid} (private) and public_profiles/{uid}.
class UserService {
  UserService._();
  static final UserService instance = UserService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection('users').doc(uid);
  DocumentReference<Map<String, dynamic>> _public(String uid) =>
      _db.collection('public_profiles').doc(uid);

  /// ISO8601 UTC with Z (plan section 3 rule).
  static String nowIso() => DateTime.now().toUtc().toIso8601String();

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final snap = await _user(uid).get();
    return snap.data();
  }

  /// Returns the existing profile, or creates the base profile
  /// (onboarding_complete = false) from whatever we already know.
  Future<Map<String, dynamic>> ensureProfile(
      User user, {
        String? fullName,
        String? phone,
        String? gender,
        required String provider,
        required String locale,
      }) async {
    final existing = await getUser(user.uid);
    if (existing != null) return existing;

    final now = nowIso();
    final name = splitFullName(fullName ?? user.displayName ?? '');
    final lastName = name.last.isEmpty ? null : name.last;

    final data = <String, dynamic>{
      'first_name': name.first,
      'last_name': lastName,
      'name_lower': '${name.first} ${name.last}'.trim().toLowerCase(),
      'photo_url': null,
      'email': user.email,
      'phone': phone,
      'gender': gender,
      'gender_updated_at': gender == null ? null : now,
      'auth_provider': provider,
      'current_mess_id': null,
      'joined_messes': <Map<String, dynamic>>[],
      'notification_prefs': {
        'meal_reminder': true,
        'bazar_reminder': true,
        'notice_board': true,
        'payment_due': true,
        'join_request_update': true,
        'chat_message': true,
        'join_request': true,
      },
      'created_at': now,
      'last_active_at': now,
      'pending_request_id': null,
      'account_status': 'active',
      'app_locale': locale,
      'onboarding_complete': false,
      'ui_preferences': {
        'theme': 'system',
        'location_discovery_enabled': true,
      },
      'schema_version': 1.0,
    };

    final batch = _db.batch();
    batch.set(_user(user.uid), data);
    batch.set(_public(user.uid), {
      'uid': user.uid,
      'first_name': name.first,
      'last_name': lastName,
      'photo_url': null,
      'updated_at': now,
    });
    await batch.commit();
    return data;
  }

  /// Final registration step: saves everything and marks onboarding complete.
  Future<void> completeRegistration(
      User user,
      RegistrationData d, {
        required String locale,
      }) async {
    final now = nowIso();
    final existing = await getUser(user.uid);
    final name = splitFullName(d.fullName);
    final lastName = name.last.isEmpty ? null : name.last;

    final userData = <String, dynamic>{
      'first_name': name.first,
      'last_name': lastName,
      'name_lower': '${name.first} ${name.last}'.trim().toLowerCase(),
      'gender': d.gender,
      'phone': d.phone,
      'birth_day': d.birthDay,
      'birth_month': d.birthMonth,
      'birth_year': d.birthYear,
      'blood_group': d.bloodGroup,
      'religion': d.religion,
      'emergency_contact': d.emergency,
      'occupation': d.occupationLabel,
      'occupation_type': d.occupationType,
      'terms_version': kTermsVersion,
      'terms_accepted_at': now,
      'app_locale': locale,
      'last_active_at': now,
      'onboarding_complete': true,
      'schema_version': 1.0,
    };
    if (d.verificationDocPath != null) {
      userData['verification_doc_path'] = d.verificationDocPath;
      userData['verification_status'] = 'pending';
    }
    if (existing?['gender'] != d.gender) {
      userData['gender_updated_at'] = now;
    }

    final batch = _db.batch();
    batch.set(_user(user.uid), userData, SetOptions(merge: true));
    batch.set(
      _public(user.uid),
      {
        'uid': user.uid,
        'first_name': name.first,
        'last_name': lastName,
        'updated_at': now,
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }
}