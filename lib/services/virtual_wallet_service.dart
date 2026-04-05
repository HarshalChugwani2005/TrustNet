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

  Future<void> withdrawFunds({
    required String userId,
    required double amount,
  }) async {
    if (amount <= 0) {
      throw Exception('Amount should be greater than zero.');
    }

    final userRef = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);
      final data = userSnap.data() ?? <String, dynamic>{};
      final currentBalance = (data['wallet_balance'] ?? 0).toDouble();

      if (currentBalance < amount) {
        throw Exception('insufficient balance in wallet');
      }

      transaction.set(
        userRef,
        {
          'wallet_balance': currentBalance - amount,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }
}
