import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final _db = FirebaseFirestore.instance;
  User get _user => FirebaseAuth.instance.currentUser!;
  DocumentReference<Map<String, dynamic>> get _ref =>
      _db.collection('users').doc(_user.uid);

  // Create the profile document if it does not exist (Google / older users)
  Future<void> ensureProfile() async {
    final snap = await _ref.get();
    if (!snap.exists) {
      final parts = (_user.displayName ?? '').split(' ');
      await _ref.set({
        'firstName': parts.isNotEmpty ? parts.first : '',
        'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : '',
        'shopName': '',
        'email': _user.email ?? '',
        'creditLimit': 5000.0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else if (snap.data()?['creditLimit'] == null) {
      await _ref.set({'creditLimit': 5000.0}, SetOptions(merge: true));
    }
  }

  Stream<Map<String, dynamic>> profileStream() =>
      _ref.snapshots().map((s) => s.data() ?? {});

  Future<void> setAutoSms(bool enabled, int hour) {
    return _ref.set({
      'autoSms': enabled,
      'smsHour': hour,
    }, SetOptions(merge: true));
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String shopName,
    required double creditLimit,
  }) {
    return _ref.set({
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'shopName': shopName.trim(),
      'creditLimit': creditLimit,
    }, SetOptions(merge: true));
  }
}