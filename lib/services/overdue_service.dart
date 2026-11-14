import '../models/customer_model.dart';

class OverdueService {
  /// A customer is overdue when the balance is positive and either
  /// exceeds the credit limit or the due date has passed.
  bool isOverdue(CustomerModel customer, double creditLimit) {
    if (customer.balance <= 0) return false;
    final overLimit = customer.balance > creditLimit;
    final pastDue = customer.dueDate != null &&
        customer.dueDate!.isBefore(DateTime.now());
    return overLimit || pastDue;
  }

  List<CustomerModel> overdueList(
          List<CustomerModel> customers, double creditLimit) =>
      customers.where((c) => isOverdue(c, creditLimit)).toList();

  String reminderText(CustomerModel customer) =>
      '${customer.name} has an overdue balance of Rs ${customer.balance.toStringAsFixed(0)}';
}