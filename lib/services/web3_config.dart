class Web3Config {
  static const String rpcUrl = String.fromEnvironment(
    'BASE_SEPOLIA_RPC_URL',
    defaultValue: '',
  );

  static const String lendingContractAddress = String.fromEnvironment(
    'TRUSTNET_LENDING_CONTRACT',
    defaultValue: '',
  );

  static const int chainId = int.fromEnvironment(
    'BASE_SEPOLIA_CHAIN_ID',
    defaultValue: 84532,
  );

  static bool get isConfigured =>
      rpcUrl.isNotEmpty && lendingContractAddress.isNotEmpty;
}
