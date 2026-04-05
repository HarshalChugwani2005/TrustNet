class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String role;
  final String phone;
  final List<String>? _referralIds;
  final int trustScore;
  final double walletBalance;
  final double lockedBalance;
  final String? walletAddress;

  List<String> get referralIds => _referralIds ?? const [];

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone = '',
    List<String>? referralIds,
    this.trustScore = 50,
    this.walletBalance = 0,
    this.lockedBalance = 0,
    this.walletAddress,
  }) : _referralIds = referralIds;

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    int parseInt(dynamic value, int fallback) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ??
            double.tryParse(value)?.toInt() ??
            fallback;
      }
      return fallback;
    }

    double parseDouble(dynamic value, double fallback) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    return UserModel(
      uid: documentId,
      email: (data['email'] ?? '').toString(),
      fullName: (data['fullName'] ?? '').toString(),
      role: (data['role'] ?? 'borrower').toString(),
      phone: (data['phone'] ?? '').toString(),
        referralIds: ((data['referralIds'] ?? data['referrals']) is List)
          ? ((data['referralIds'] ?? data['referrals']) as List)
            .map((id) => id.toString())
            .where((id) => id.isNotEmpty)
            .toList()
          : const [],
      trustScore: parseInt(data['trustScore'], 50),
      walletBalance:
          parseDouble(data['wallet_balance'] ?? data['walletBalance'], 0),
      lockedBalance:
          parseDouble(data['locked_balance'] ?? data['lockedBalance'], 0),
      walletAddress: data['walletAddress']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'role': role,
      'phone': phone,
      'referralIds': referralIds,
      'trustScore': trustScore,
      'wallet_balance': walletBalance,
      'locked_balance': lockedBalance,
      'walletAddress': walletAddress,
    };
  }
}
