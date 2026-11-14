import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

class ReportSummary {
  final double totalCredit, totalPayments;
  final Map<int, double> creditByDay, paymentByDay;
  ReportSummary(this.totalCredit, this.totalPayments, this.creditByDay,
      this.paymentByDay);
}

class ReportService {
  final _db = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<ReportSummary> daily() {
    final n = DateTime.now();
    final start = DateTime(n.year, n.month, n.day);
    return _summarize(start, start.add(const Duration(days: 1)));
  }

  Future<ReportSummary> monthly() {
    final n = DateTime.now();
    return _summarize(DateTime(n.year, n.month, 1), DateTime(n.year, n.month + 1, 1));
  }

  Future<ReportSummary> _summarize(DateTime from, DateTime to) async {
    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThan: Timestamp.fromDate(to))
        .get();

    double credit = 0, paid = 0;
    final cByDay = <int, double>{}, pByDay = <int, double>{};
    for (final d in snap.docs) {
      final t = TransactionModel.fromMap(d.id, d.data());
      if (t.type == TxType.credit) {
        credit += t.amount;
        cByDay[t.date.day] = (cByDay[t.date.day] ?? 0) + t.amount;
      } else {
        paid += t.amount;
        pByDay[t.date.day] = (pByDay[t.date.day] ?? 0) + t.amount;
      }
    }
    return ReportSummary(credit, paid, cByDay, pByDay);
  }
}