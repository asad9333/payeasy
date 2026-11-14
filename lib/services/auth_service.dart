
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../utils/validators.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _invalidLogin =
      'Incorrect email/phone number or password.';

  User? get currentUser => _auth.currentUser;

  Future<String?> signUp({
    required String firstName,
    required String lastName,
    required String shopName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final phoneKey = Validators.normalizePhone(phone);
    final emailClean = email.trim().toLowerCase();
    final fullName = '${firstName.trim()} ${lastName.trim()}';

    User? createdUser;

    try {
      final phoneDoc = await _db.collection('phones').doc(phoneKey).get();

      if (phoneDoc.exists) {
        return 'This phone number is already registered.';
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: emailClean,
        password: password,
      );

      createdUser = credential.user;

      if (createdUser == null) {
        return 'Account could not be created. Please try again.';
      }

      final uid = createdUser.uid;
      final batch = _db.batch();

      batch.set(_db.collection('users').doc(uid), {
        'uid': uid,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'fullName': fullName,
        'shopName': shopName.trim(),
        'email': emailClean,
        'phone': phoneKey,
        'authProvider': 'password',
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(_db.collection('phones').doc(phoneKey), {
        'uid': uid,
        'email': emailClean,
      });

      await batch.commit();
      await createdUser.updateDisplayName(fullName);

      return null;
    } on FirebaseAuthException catch (e) {
      await _rollback(createdUser);
      return _authMessage(e);
    } on FirebaseException catch (e) {
      await _rollback(createdUser);

      if (e.code == 'permission-denied') {
        return 'Database permission denied. Check Firestore rules.';
      }

      return 'Database error: ${e.message}';
    } catch (_) {
      await _rollback(createdUser);
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> signIn({
    required String identifier,
    required String password,
  }) async {
    try {
      final id = identifier.trim();
      String? email;

      if (id.contains('@')) {
        email = id.toLowerCase();
      } else {
        final phoneKey = Validators.normalizePhone(id);
        final doc = await _db.collection('phones').doc(phoneKey).get();
        email = doc.data()?['email'] as String?;
      }

      if (email == null || email.isEmpty) {
        return _invalidLogin;
      }

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return null;
    } on FirebaseAuthException catch (e) {
      return _authMessage(e);
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      if (!kIsWeb) {
        return 'Google sign-in is configured for Web only.';
      }

      final provider = GoogleAuthProvider()..addScope('email');

      final result = await _auth.signInWithPopup(provider);
      final user = result.user;

      if (user == null) {
        return 'Google sign-in could not be completed.';
      }

      final ref = _db.collection('users').doc(user.uid);
      final oldDoc = await ref.get();

      final profile = <String, dynamic>{
        'uid': user.uid,
        'email': user.email ?? '',
        'fullName': user.displayName ?? '',
        'authProvider': 'google',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!oldDoc.exists) {
        profile['createdAt'] = FieldValue.serverTimestamp();
      }

      await ref.set(profile, SetOptions(merge: true));

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user') {
        return 'Google sign-in was cancelled.';
      }

      return _authMessage(e);
    } catch (e) {
      return 'Google sign-in failed: $e';
    }
  }

  Future<String?> sendPasswordReset(String identifier) async {
    try {
      final id = identifier.trim();
      String? email;

      if (id.contains('@')) {
        email = id.toLowerCase();
      } else {
        final phoneKey = Validators.normalizePhone(id);
        final doc = await _db.collection('phones').doc(phoneKey).get();
        email = doc.data()?['email'] as String?;
      }

      if (email != null && email.isNotEmpty) {
        await _auth.sendPasswordResetEmail(email: email);
      }

      return null;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> _rollback(User? user) async {
    try {
      await user?.delete();
    } catch (_) {}
  }

  String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return _invalidLogin;
      default:
        return e.message ?? 'Authentication error';
    }
  }
}
 