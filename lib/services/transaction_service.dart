import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get _userRef =>
      _db.collection('users').doc(_uid);

  /// Real-time transaction history of a customer, newest first.
  Stream<List<TransactionModel>> streamLedger(String customerId) {
    return _userRef
        .collection('transactions')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((s) {
      final list =
          s.docs.map((d) => TransactionModel.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  /// Saves the transaction and updates the customer balance atomically.
  Future<void> addTransaction({
    required String customerId,
    required TxType type,
    required double amount,
    String description = '',
    DateTime? dueDate,
  }) async {
    if (amount <= 0) {
      throw Exception('Amount must be greater than zero.');
    }

    final customerRef = _userRef.collection('customers').doc(customerId);
    final txRef = _userRef.collection('transactions').doc();
    final isCredit = type == TxType.credit;

    await _db.runTransaction((t) async {
      final snap = await t.get(customerRef);
      if (!snap.exists) throw Exception('Customer not found.');

      final current = (snap.data()!['balance'] ?? 0).toDouble();
      if (!isCredit && amount > current) {
        throw Exception(
            'Payment cannot exceed the outstanding balance (Rs ${current.toStringAsFixed(0)}).');
      }
      final newBalance = isCredit ? current + amount : current - amount;

      t.set(txRef, {
        'customerId': customerId,
        'type': isCredit ? 'credit' : 'payment',
        'amount': amount,
        'description': description.trim(),
        'date': FieldValue.serverTimestamp(),
      });

      final update = <String, dynamic>{
        'balance': newBalance,
        'lastTransactionAt': FieldValue.serverTimestamp(),
      };
      if (isCredit && dueDate != null) {
        update['dueDate'] = Timestamp.fromDate(dueDate);
      }
      if (newBalance <= 0) update['dueDate'] = FieldValue.delete();
      t.update(customerRef, update);
    });
  }
} 