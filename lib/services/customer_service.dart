import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/customer_model.dart';

class CustomerService {
  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get _userRef =>
      _db.collection('users').doc(_uid);

  CollectionReference<Map<String, dynamic>> get _customers =>
      _userRef.collection('customers');

  /// Real-time list of the shopkeeper's customers, sorted by name.
  Stream<List<CustomerModel>> streamCustomers() => _customers
      .orderBy('name')
      .snapshots()
      .map((s) =>
          s.docs.map((d) => CustomerModel.fromMap(d.id, d.data())).toList());

  Stream<CustomerModel?> streamCustomer(String id) =>
      _customers.doc(id).snapshots().map(
          (d) => d.exists ? CustomerModel.fromMap(d.id, d.data()!) : null);

  /// Filters customers by name or phone number.
  List<CustomerModel> search(List<CustomerModel> all, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((c) => c.name.toLowerCase().contains(q) || c.phone.contains(q))
        .toList();
  }

  Future<void> addCustomer({
    required String name,
    required String phone,
  }) async {
    final duplicate =
        await _customers.where('phone', isEqualTo: phone.trim()).limit(1).get();
    if (duplicate.docs.isNotEmpty) {
      throw Exception('A customer with this phone number already exists.');
    }
    await _customers.add({
      'name': name.trim(),
      'phone': phone.trim(),
      'balance': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<CustomerModel>> getAll() async {
    final s = await _customers.get();
    return s.docs.map((d) => CustomerModel.fromMap(d.id, d.data())).toList();
  }

  /// Saves the date (and amount) the customer promised to pay.
  Future<void> setPromise(String id, DateTime date, double amount) {
    return _customers.doc(id).set({
      'promiseDate': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'promiseAmount': amount,
      'lastSmsOn': FieldValue.delete(), // new promise = reminders start fresh
    }, SetOptions(merge: true));
  }

  Future<void> clearPromise(String id) {
    return _customers.doc(id).set({
      'promiseDate': FieldValue.delete(),
      'promiseAmount': FieldValue.delete(),
      'lastSmsOn': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  Future<void> markSmsSent(String id, String dayKey) {
    return _customers.doc(id).set({
      'lastSmsOn': dayKey,
      'lastSmsAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Deletes the customer together with all of their transactions.
  Future<void> deleteCustomer(String customerId) async {
    final transactions = await _userRef
        .collection('transactions')
        .where('customerId', isEqualTo: customerId)
        .get();

    final batch = _db.batch();
    for (final doc in transactions.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_customers.doc(customerId));
    await batch.commit();
  }
} 