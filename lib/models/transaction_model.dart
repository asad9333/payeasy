import 'package:cloud_firestore/cloud_firestore.dart';

enum TxType { credit, payment }

class TransactionModel {
  final String id, customerId, description;
  final TxType type;
  final double amount;
  final DateTime date;

  const TransactionModel({
    required this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
  });

  factory TransactionModel.fromMap(String id, Map<String, dynamic> m) =>
      TransactionModel(
        id: id,
        customerId: m['customerId'] ?? '',
        type: m['type'] == 'payment' ? TxType.payment : TxType.credit,
        amount: (m['amount'] ?? 0).toDouble(),
        description: m['description'] ?? '',
        date: (m['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
} 