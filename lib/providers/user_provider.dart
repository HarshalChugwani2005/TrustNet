import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  UserProvider() {
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _listenToUserDoc(user.uid);
      } else {
        _userSubscription?.cancel();
        _userSubscription = null;
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
      }
    }, onError: (Object error, StackTrace stackTrace) {
      debugPrint('Auth state listener error: $error');
    });
  }

  void _listenToUserDoc(String uid) {
    _userSubscription?.cancel();
    _userSubscription = _firestore.collection('users').doc(uid).snapshots().listen((doc) {
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      } else {
        final fallbackUser = _auth.currentUser;
        _currentUser = fallbackUser == null
            ? null
            : UserModel(
                uid: fallbackUser.uid,
                email: fallbackUser.email ?? '',
                fullName: fallbackUser.displayName ?? 'User',
                role: 'borrower',
                walletAddress: null,
              );
      }
      _isLoading = false;
      notifyListeners();
    }, onError: (Object error, StackTrace stackTrace) {
      debugPrint('User document listener error: $error');
      final fallbackUser = _auth.currentUser;
      _currentUser = fallbackUser == null
          ? null
          : UserModel(
              uid: fallbackUser.uid,
              email: fallbackUser.email ?? '',
              fullName: fallbackUser.displayName ?? 'User',
              role: 'borrower',
              walletAddress: null,
            );
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }
}
