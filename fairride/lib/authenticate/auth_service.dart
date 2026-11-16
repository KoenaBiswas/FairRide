import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../utils/license_number.dart';

/// Error with a message that is safe to show to the user.
class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authChanges => _auth.userChanges();

  /// Live stream of users/{uid}.
  Stream<DocumentSnapshot<Map<String, dynamic>>> userDoc(String uid) =>
      _db.collection('users').doc(uid).snapshots();

  Future<void> createProfileForCurrentUser(String role) async {
    if (role != 'rider' && role != 'driver') {
      throw AuthFailure('Choose Rider or Driver to continue.');
    }
    final user = _auth.currentUser;
    if (user == null) throw AuthFailure('Please sign in again.');
    final ref = _db.collection('users').doc(user.uid);
    final existing = await ref.get();
    final old = existing.data() ?? <String, dynamic>{};
    final displayName = user.displayName?.trim();
    final email = user.email?.trim() ?? '';
    final fallbackName = email.contains('@')
        ? email.split('@').first
        : 'FareRide user';
    await ref.set({
      'uid': user.uid,
      'name': displayName?.isNotEmpty == true ? displayName : fallbackName,
      'email': email,
      'phone': old['phone'] ?? '',
      'role': role,
      'verificationStatus': role == 'driver'
          ? 'pending_documents'
          : 'not_required',
      'createdAt': old['createdAt'] ?? FieldValue.serverTimestamp(),
      'isAdmin': old['isAdmin'] == true,
      if (role == 'driver') ...{
        'licenseNumber': old['licenseNumber'] ?? '',
        'vehicleNumber': old['vehicleNumber'] ?? '',
        'vehicleModel': old['vehicleModel'] ?? '',
        'licenseExpiry': old['licenseExpiry'] ?? '',
        'upiId': old['upiId'] ?? '',
      },
    }, SetOptions(merge: true));
  }

  /// Creates the Auth account and the Firestore profile.
  /// If the profile write fails, the new Auth account is removed again so
  /// the user is never left half-registered.
  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role, // 'rider' or 'driver'
    String licenseNumber = '',
    String vehicleNumber = '',
    String vehicleModel = '',
    String licenseExpiry = '',
    String upiId = '',
    Map<String, String> documentsBase64 = const {},
  }) async {
    UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e));
    }

    final user = cred.user!;
    try {
      await user.updateDisplayName(name.trim());
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'role': role,
        'verificationStatus': role == 'driver'
            ? 'pending_documents'
            : 'not_required',
        'createdAt': FieldValue.serverTimestamp(),
        if (role == 'driver') ...{
          'licenseNumber': normalizeIndianLicenseNumber(licenseNumber),
          'vehicleNumber': vehicleNumber.trim(),
          'vehicleModel': vehicleModel.trim(),
          'licenseExpiry': licenseExpiry,
          'upiId': upiId.trim(),
          'isAdmin': false,
          'driverOnboardingComplete': false,
        },
      });
      if (role == 'driver') {
        for (final entry in documentsBase64.entries) {
          if (entry.value.length > 900000) {
            throw StateError(
              'Encoded driver document is too large for a Firestore document.',
            );
          }
          await _db
              .collection('users')
              .doc(user.uid)
              .collection('documents')
              .doc(entry.key)
              .set({
                'imageBase64': entry.value,
                'uploadedAt': FieldValue.serverTimestamp(),
              });
        }
        await _db.collection('users').doc(user.uid).update({
          'verificationStatus': 'pending_review',
        });
      }
      await user.sendEmailVerification();
    } catch (e) {
      debugPrint('Profile write failed: $e');
      try {
        await _db.collection('users').doc(user.uid).delete();
      } catch (_) {}
      try {
        await user.delete();
      } catch (_) {}
      final code = e is FirebaseException ? e.code : 'unknown';
      throw AuthFailure(
        'Could not save your profile ($code). '
        'Check that Firestore is created and its rules allow writes.',
      );
    }
  }

  /// Signs in, then checks the account really has the chosen role.
  Future<void> signIn({
    required String email,
    required String password,
    required String expectedRole,
  }) async {
    UserCredential cred;
    try {
      cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e));
    }

    try {
      final snap = await _db.collection('users').doc(cred.user!.uid).get();
      final role = snap.data()?['role'] as String?;
      if (role == null) {
        await _auth.signOut();
        throw AuthFailure('Account profile not found. Please sign up again.');
      }
      if (role != expectedRole) {
        await _auth.signOut();
        throw AuthFailure(
          'This account is registered as a $role. '
          'Switch to "${role[0].toUpperCase()}${role.substring(1)}" to log in.',
        );
      }
    } on FirebaseException {
      await _auth.signOut();
      throw AuthFailure('Could not load your profile. Check your connection.');
    }
  }

  Future<void> signOut() async {
    Object? firebaseError;
    StackTrace? firebaseStack;
    try {
      await _auth.signOut();
    } catch (error, stackTrace) {
      firebaseError = error;
      firebaseStack = stackTrace;
    }
    try {
      await _googleSignIn.signOut();
    } catch (error) {
      debugPrint('Google sign-out failed: $error');
    }
    try {
      await _googleSignIn.disconnect();
    } catch (error) {
      debugPrint('Google disconnect skipped: $error');
    }
    if (firebaseError != null) {
      Error.throwWithStackTrace(firebaseError, firebaseStack!);
    }
  }

  Future<void> reloadUser() async => _auth.currentUser?.reload();

  Future<void> resendVerification() async =>
      _auth.currentUser?.sendEmailVerification();

  /// The auth gate collects a role for Google accounts without a complete
  /// FareRide profile.
  Future<String?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      final user = result.user!;
      final profile = await _db.collection('users').doc(user.uid).get();
      return profile.data()?['role'] as String?;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        throw AuthFailure(
          'Google sign-in is not enabled in Firebase Authentication > Sign-in method.',
        );
      }
      throw AuthFailure(_message(e));
    } on PlatformException catch (e) {
      debugPrint('Google Sign-In failed: ${e.code} ${e.message}');
      final detail = '${e.code} ${e.message}'.toLowerCase();
      if (detail.contains('10') ||
          detail.contains('developer_error') ||
          detail.contains('sign_in_failed')) {
        throw AuthFailure(
          'Google Sign-In is missing Android OAuth setup. Add the Android app SHA-1 in Firebase Project settings, enable Google sign-in, then replace google-services.json with the newly downloaded file.',
        );
      }
      if (detail.contains('network')) {
        throw AuthFailure(
          'Google Sign-In could not reach the network. Try again.',
        );
      }
      throw AuthFailure('Google Sign-In failed (${e.code}). Please try again.');
    } catch (_) {
      await _auth.signOut();
      throw AuthFailure(
        'Could not create your Google profile. Check your connection and Firestore rules.',
      );
    }
  }

  String _message(FirebaseAuthException e) {
    debugPrint('FirebaseAuthException: ${e.code} ${e.message}');
    switch (e.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a few minutes.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Turn it on in Firebase Authentication > Sign-in method.';
      case 'configuration-not-found':
      case 'api-key-not-valid':
      case 'internal-error':
        return 'Firebase is not set up correctly for this app (${e.code}). '
            'Re-run flutterfire configure and check google-services.json.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'Something went wrong (${e.code}).';
    }
  }
}
