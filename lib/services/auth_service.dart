import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'wallet_bridge_service.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  bool isEmail(String value) {
    final text = value.trim();
    return text.contains('@') && text.contains('.');
  }

  Future<UserCredential> signInWithEmailOrPhone({
    required String identifier,
    required String password,
  }) async {
    final trimmed = identifier.trim();
    if (!isEmail(trimmed)) {
      throw FirebaseAuthException(
        code: 'unsupported-phone-login',
        message:
            'Phone login is not enabled yet. Please use your email and password.',
      );
    }

    final userCredential = await _auth.signInWithEmailAndPassword(
      email: trimmed,
      password: password,
    );

    final user = userCredential.user;
    if (user != null) {
      await _upsertUserProfile(
        uid: user.uid,
        fullName: user.displayName ?? '',
        email: user.email,
      );
    }

    return userCredential;
  }

  Future<UserCredential> createAccountWithEmail({
    required String fullName,
    required String identifier,
    required String password,
    required String role,
  }) async {
    final trimmed = identifier.trim();
    if (!isEmail(trimmed)) {
      throw FirebaseAuthException(
        code: 'unsupported-phone-signup',
        message:
            'Phone signup is not enabled yet. Please use your email address.',
      );
    }

    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: trimmed,
      password: password,
    );

    final user = userCredential.user;
    if (user != null) {
      await user.updateDisplayName(fullName.trim());
      await _upsertUserProfile(
        uid: user.uid,
        fullName: fullName,
        role: role,
        email: user.email,
      );
    }

    return userCredential;
  }

  Future<UserCredential?> signInWithGoogle({
    String? role,
    String? fullName,
  }) async {
    late UserCredential userCredential;

    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      await _auth.signInWithRedirect(googleProvider);
      return null;
    } else {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'google-sign-in-cancelled',
          message: 'Google sign-in was cancelled.',
        );
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      userCredential = await _auth.signInWithCredential(credential);
    }

    final user = userCredential.user;
    if (user != null) {
      final isNew = userCredential.additionalUserInfo?.isNewUser ?? false;
      if (isNew || role != null || fullName != null) {
        await _upsertUserProfile(
          uid: user.uid,
          fullName: fullName ?? user.displayName ?? '',
          role: role,
          email: user.email,
        );
      }
    }

    return userCredential;
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sendSignupEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user found for verification.',
      );
    }
    await user.sendEmailVerification();
  }

  Future<bool> refreshAndCheckEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> _upsertUserProfile({
    required String uid,
    required String fullName,
    String? role,
    String? email,
  }) async {
    final payload = <String, dynamic>{
      'fullName': fullName,
      'email': email,
      'wallet_balance': FieldValue.increment(0),
      'locked_balance': FieldValue.increment(0),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (role != null && role.isNotEmpty) {
      payload['role'] = role;
    }

    await _firestore.collection('users').doc(uid).set(
          payload,
          SetOptions(merge: true),
        );

    try {
      await WalletBridgeService().ensureWalletForUser(uid);
    } catch (_) {
      // Wallet setup errors should not block auth flow.
    }
  }
}
