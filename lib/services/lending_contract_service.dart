import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

import 'web3_config.dart';

class OnChainBorrowResult {
  final String txHash;
  final int? blockNumber;

  const OnChainBorrowResult({
    required this.txHash,
    this.blockNumber,
  });
}

class LendingContractService {
  LendingContractService()
      : _client = Web3Client(
          Web3Config.rpcUrl,
          http.Client(),
        );

  final Web3Client _client;

  static const String _abi = '''
[
  {
    "inputs": [
      {"internalType": "uint256", "name": "amountWei", "type": "uint256"},
      {"internalType": "uint32", "name": "durationDays", "type": "uint32"},
      {"internalType": "bytes32", "name": "purposeHash", "type": "bytes32"},
      {"internalType": "string", "name": "firebaseUid", "type": "string"}
    ],
    "name": "requestLoan",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "uint256", "name": "loanId", "type": "uint256"},
      {"internalType": "uint8", "name": "status", "type": "uint8"}
    ],
    "name": "setLoanStatus",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
]
''';

  Future<OnChainBorrowResult> requestLoan({
    required String privateKeyHex,
    required String firebaseUid,
    required double amount,
    required String duration,
    required String purpose,
  }) async {
    if (!Web3Config.isConfigured) {
      throw StateError(
        'Missing BASE_SEPOLIA_RPC_URL or TRUSTNET_LENDING_CONTRACT build define.',
      );
    }

    final credentials = EthPrivateKey.fromHex(privateKeyHex);
    final contract = DeployedContract(
      ContractAbi.fromJson(_abi, 'TrustNetLendingPool'),
      EthereumAddress.fromHex(Web3Config.lendingContractAddress),
    );
    final requestLoanFn = contract.function('requestLoan');

    final amountWei = BigInt.from(amount * 1e18);
    final durationDays = _parseDurationDays(duration);
    final purposeHash = _keccakToBytes32(purpose);

    final txHash = await _client.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: requestLoanFn,
        parameters: [
          amountWei,
          durationDays,
          purposeHash,
          firebaseUid,
        ],
        maxGas: 350000,
      ),
      chainId: Web3Config.chainId,
      fetchChainIdFromNetworkId: false,
    );

    return OnChainBorrowResult(txHash: txHash, blockNumber: null);
  }

  Future<OnChainBorrowResult> updateLoanStatus({
    required String privateKeyHex,
    required int onChainLoanId,
    required String status, // 'approved', 'repaid', 'rejected'
  }) async {
    if (!Web3Config.isConfigured) {
      throw StateError('Web3 not configured');
    }

    final credentials = EthPrivateKey.fromHex(privateKeyHex);
    final contract = DeployedContract(
      ContractAbi.fromJson(_abi, 'TrustNetLendingPool'),
      EthereumAddress.fromHex(Web3Config.lendingContractAddress),
    );
    final setStatusFn = contract.function('setLoanStatus');

    int statusInt = 0; // Requested
    if (status == 'approved') statusInt = 1;
    if (status == 'repaid') statusInt = 2;
    if (status == 'rejected') statusInt = 3;

    final txHash = await _client.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: setStatusFn,
        parameters: [
          BigInt.from(onChainLoanId),
          BigInt.from(statusInt),
        ],
        maxGas: 150000,
      ),
      chainId: Web3Config.chainId,
      fetchChainIdFromNetworkId: false,
    );

    return OnChainBorrowResult(txHash: txHash);
  }

  int _parseDurationDays(String duration) {
    final match = RegExp(r'\d+').firstMatch(duration);
    final value = match != null ? int.parse(match.group(0)!) : 1;

    final lower = duration.toLowerCase();
    if (lower.contains('month')) {
      return value * 30;
    }
    if (lower.contains('week')) {
      return value * 7;
    }
    return value;
  }

  Uint8List _keccakToBytes32(String input) {
    final hash = keccakUtf8(input);
    return Uint8List.fromList(hash);
  }
}
