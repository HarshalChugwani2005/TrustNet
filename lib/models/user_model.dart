class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String role;
  final int trustScore;
  final String? walletAddress;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.trustScore = 50,
    this.walletAddress,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      role: data['role'] ?? 'borrower',
      trustScore: data['trustScore'] ?? 50,
      walletAddress: data['walletAddress'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'role': role,
      'trustScore': trustScore,
      'walletAddress': walletAddress,
    };
  }
}
