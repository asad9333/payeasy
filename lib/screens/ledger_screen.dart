
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../models/customer_model.dart';
import '../models/transaction_model.dart';
import '../services/customer_service.dart';
import '../services/overdue_service.dart';
import '../services/profile_service.dart';
import '../services/transaction_service.dart';
import '../utils/app_colors.dart';
import '../widgets/ui.dart';
import 'add_transaction_sheet.dart';

class LedgerScreen extends StatelessWidget {
  final String customerId;

  const LedgerScreen({
    super.key,
    required this.customerId,
  });

  Future<void> _deleteCustomer(
    BuildContext context,
    CustomerModel customer,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text(
          'This will permanently delete this customer and their transaction history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await CustomerService().deleteCustomer(customer.id);

      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to delete customer: $e')),
        );
      }
    }
  }

  String _reminderText(CustomerModel c, String shop) {
    final from = shop.isEmpty ? '' : ' from $shop';
    return 'Hello ${c.name}, this is a friendly reminder$from. '
        'Your outstanding balance is Rs ${c.balance.toStringAsFixed(0)}. '
        'Please clear it at your earliest convenience. Thank you.';
  }

  /// 0300 1234567 -> 923001234567 (digits only, country code 92)
  String? _pkNumber(String phone) {
    var d = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.startsWith('0')) d = '92${d.substring(1)}';
    return d.length >= 11 ? d : null;
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _sendWhatsApp(
    BuildContext context,
    CustomerModel c,
    String shop,
  ) async {
    final n = _pkNumber(c.phone);
    if (n == null) {
      return _snack(context, 'The customer phone number is not valid.');
    }
    final uri = Uri.parse(
      'https://wa.me/$n?text=${Uri.encodeComponent(_reminderText(c, shop))}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      _snack(context, 'Could not open WhatsApp.');
    }
  }

  Future<void> _editPromise(BuildContext context, CustomerModel c) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var date = c.promiseDate ?? today.add(const Duration(days: 3));
    final amountCtrl = TextEditingController(
      text: (c.promiseAmount ?? c.balance).toStringAsFixed(0),
    );
    String? error;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                20,
                18,
                20 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Promise to Pay',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${c.name} said they will pay on this date.',
                    style: const TextStyle(color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final first = date.isBefore(today) ? date : today;
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: date,
                        firstDate: first,
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setSheet(() => date = picked);
                    },
                    icon: const Icon(Icons.event),
                    label: Text(DateFormat.yMMMd().format(date)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount (Rs)',
                      prefixIcon: const Icon(Icons.payments_outlined),
                      errorText: error,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      if (c.promiseDate != null) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await CustomerService().clearPromise(c.id);
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 50),
                            ),
                            child: const Text('Remove'),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final amount =
                                double.tryParse(amountCtrl.text.trim());
                            if (amount == null || amount <= 0) {
                              setSheet(() => error = 'Enter a valid amount');
                              return;
                            }
                            await CustomerService()
                                .setPromise(c.id, date, amount);
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    // amountCtrl is intentionally not disposed (sheet is still animating out).
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CustomerModel?>(
      stream: CustomerService().streamCustomer(customerId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Unable to load customer')),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final customer = snapshot.data;
        if (customer == null) {
          return const Scaffold(
            body: Center(child: Text('Customer not found')),
          );
        }

        return StreamBuilder<Map<String, dynamic>>(
          stream: ProfileService().profileStream(),
          builder: (context, profileSnap) {
            final limit =
                (profileSnap.data?['creditLimit'] ?? 5000).toDouble();
            final isOverdue = OverdueService().isOverdue(customer, limit);
            final shop = (profileSnap.data?['shopName'] ?? '').toString();

            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: const Text('Customer Ledger'),
                actions: [
                  IconButton(
                    tooltip: 'Delete customer',
                    onPressed: () => _deleteCustomer(context, customer),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                    child: HeroCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SquareAvatar(
                                name: customer.name,
                                size: 46,
                                background: AppColors.accent,
                                foreground: AppColors.primaryDark,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customer.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      customer.phone,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Current Outstanding Balance',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rs(customer.balance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (isOverdue) const StatusPill(label: 'Overdue'),
                              if (isOverdue && customer.dueDate != null)
                                const SizedBox(width: 10),
                              if (customer.dueDate != null)
                                Text(
                                  'Due ${DateFormat.yMMMd().format(customer.dueDate!)}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => showAddTransactionSheet(
                              context,
                              customer.id,
                              TxType.credit,
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Credit Entry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => showAddTransactionSheet(
                              context,
                              customer.id,
                              TxType.payment,
                            ),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Payment'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (customer.balance > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _sendWhatsApp(context, customer, shop),
                          icon: const Icon(Icons.chat_outlined),
                          label: const Text('Send WhatsApp Reminder'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: const Color(0xFF3A2A00),
                          ),
                        ),
                      ),
                    ),

                  if (customer.balance > 0 || customer.promiseDate != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                      child: SoftCard(
                        onTap: () => _editPromise(context, customer),
                        child: Row(
                          children: [
                            const SquareAvatar(
                              name: '',
                              size: 40,
                              icon: Icons.event_available_outlined,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer.promiseDate == null
                                        ? 'Promise to Pay'
                                        : 'Promised: ${DateFormat.yMMMd().format(customer.promiseDate!)} · ${rs(customer.promiseAmount ?? customer.balance)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    customer.promiseDate == null
                                        ? 'Tap to set a date. An SMS reminder is sent automatically.'
                                        : (customer.lastSmsOn == null
                                            ? 'No SMS reminder sent yet'
                                            : 'Last SMS reminder: ${customer.lastSmsOn}'),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.textGrey,
                            ),
                          ],
                        ),
                      ),
                    ),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(18, 22, 18, 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Transaction History',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: StreamBuilder<List<TransactionModel>>(
                      stream: TransactionService().streamLedger(customer.id),
                      builder: (context, txSnapshot) {
                        if (txSnapshot.hasError) {
                          return const Center(
                            child: Text('Unable to load transaction history'),
                          );
                        }
                        if (!txSnapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final transactions = txSnapshot.data!;
                        if (transactions.isEmpty) {
                          return const Center(
                            child: Text(
                              'No transactions recorded yet.',
                              style: TextStyle(color: AppColors.textGrey),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            final isCredit = tx.type == TxType.credit;

                            return SoftCard(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  SquareAvatar(
                                    name: '',
                                    icon: isCredit
                                        ? Icons.arrow_upward_rounded
                                        : Icons.arrow_downward_rounded,
                                    background: isCredit
                                        ? AppColors.dangerLight
                                        : AppColors.lightGreen,
                                    foreground: isCredit
                                        ? AppColors.danger
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isCredit
                                              ? 'Credit Entry'
                                              : 'Payment Received',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          '${tx.description.isEmpty ? 'No description' : tx.description} · ${DateFormat.MMMd().add_jm().format(tx.date)}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: AppColors.textGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${isCredit ? '+' : '-'}${rs(tx.amount)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: isCredit
                                          ? AppColors.danger
                                          : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
