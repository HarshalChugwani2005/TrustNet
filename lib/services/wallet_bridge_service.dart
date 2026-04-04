import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web3dart/credentials.dart';

class UserWalletIdentity {
  final String uid;
  final String walletAddress;
  final String privateKeyHex;

  const UserWalletIdentity({
    required this.uid,
    required this.walletAddress,
    required this.privateKeyHex,
  });
}

class WalletBridgeService {
  WalletBridgeService({
    FlutterSecureStorage? secureStorage,
    FirebaseFirestore? firestore,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FlutterSecureStorage _secureStorage;
  final FirebaseFirestore _firestore;

  String _privateKeyKey(String uid) => 'trustnet_wallet_pk_$uid';

  Future<UserWalletIdentity> ensureWalletForUser(String uid) async {
    final key = _privateKeyKey(uid);
    var privateKey = await _secureStorage.read(key: key);

    if (privateKey == null || privateKey.isEmpty) {
      privateKey = _generatePrivateKeyHex();
      await _secureStorage.write(key: key, value: privateKey);
    }

    final credentials = EthPrivateKey.fromHex(privateKey);
    final address = credentials.address.hexEip55;

    await _firestore.collection('users').doc(uid).set(
      {
        'walletAddress': address,
        'walletLinkedAt': FieldValue.serverTimestamp(),
        'walletChain': 'base-sepolia',
      },
      SetOptions(merge: true),
    );

    return UserWalletIdentity(
      uid: uid,
      walletAddress: address,
      privateKeyHex: privateKey,
    );
  }

  String _generatePrivateKeyHex() {
    final random = Random.secure();
    final bytes = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
