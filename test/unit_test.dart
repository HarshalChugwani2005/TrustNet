import 'package:flutter_test/flutter_test.dart';
import 'package:trustnet/models/user_model.dart';
import 'package:trustnet/models/loan_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel Tests', () {
    test('UserModel.fromMap creates correct object', () {
      final data = {
        'email': 'test@example.com',
        'fullName': 'Test User',
        'role': 'borrower',
        'trustScore': 85,
      };
      final user = UserModel.fromMap(data, 'user123');

      expect(user.uid, 'user123');
      expect(user.email, 'test@example.com');
      expect(user.fullName, 'Test User');
      expect(user.role, 'borrower');
      expect(user.trustScore, 85);
    });

    test('UserModel.toMap returns correct map', () {
      final user = UserModel(
        uid: 'user123',
        email: 'test@example.com',
        fullName: 'Test User',
        role: 'borrower',
        trustScore: 85,
      );
      final map = user.toMap();

      expect(map['email'], 'test@example.com');
      expect(map['fullName'], 'Test User');
      expect(map['role'], 'borrower');
      expect(map['trustScore'], 85);
    });
  });

  group('LoanModel Tests', () {
    test('LoanModel.fromMap creates correct object', () {
      final now = DateTime.now();
      final data = {
        'borrowerId': 'b123',
        'borrowerName': 'Borrower Name',
        'borrowerTrustScore': 80,
        'amount': 5000.0,
        'duration': '3 months',
        'purpose': 'Business',
        'status': 'pending',
        'lenderId': 'l456',
        'createdAt': Timestamp.fromDate(now),
      };
      final loan = LoanModel.fromMap(data, 'loan789');

      expect(loan.id, 'loan789');
      expect(loan.borrowerId, 'b123');
      expect(loan.amount, 5000.0);
      expect(loan.status, 'pending');
      expect(loan.createdAt, isNotNull);
    });

    test('LoanModel.toMap returns correct map', () {
      final loan = LoanModel(
        id: 'loan789',
        borrowerId: 'b123',
        borrowerName: 'Borrower Name',
        borrowerTrustScore: 80,
        amount: 5000.0,
        duration: '3 months',
        purpose: 'Business',
        status: 'pending',
      );
      final map = loan.toMap();

      expect(map['borrowerId'], 'b123');
      expect(map['amount'], 5000.0);
      expect(map['status'], 'pending');
      expect(map['createdAt'], isA<FieldValue>());
    });
  });
}
