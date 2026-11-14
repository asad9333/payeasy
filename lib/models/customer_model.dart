import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id, name, phone;
  final double balance;
  final DateTime? dueDate;
  final DateTime? promiseDate;
  final double? promiseAmount;
  final String? lastSmsOn; // yyyy-MM-dd of the last automatic SMS

  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.balance = 0,
    this.dueDate,
    this.promiseDate,
    this.promiseAmount,
    this.lastSmsOn,
  });

  factory CustomerModel.fromMap(String id, Map<String, dynamic> m) =>
      CustomerModel(
        id: id,
        name: m['name'] ?? '',
        phone: m['phone'] ?? '',
        balance: (m['balance'] ?? 0).toDouble(),
        dueDate: (m['dueDate'] as Timestamp?)?.toDate(),
        promiseDate: (m['promiseDate'] as Timestamp?)?.toDate(),
        promiseAmount: (m['promiseAmount'] as num?)?.toDouble(),
        lastSmsOn: m['lastSmsOn'] as String?,
      );
} 