import 'package:cloud_firestore/cloud_firestore.dart';

class VirtualWalletService {
  VirtualWalletService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> addFunds({
    required String userId,
    required double amount,
  }) async {
    if (amount <= 0) {
      throw Exception('Amount should be greater than zero.');
    }

    await _firestore.collection('users').doc(userId).set({
      'wallet_balance': FieldValue.increment(amount),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
