
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../utils/app_colors.dart';

Future<void> showAddTransactionSheet(
  BuildContext context,
  String customerId,
  TxType type,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => _TransactionSheet(
      customerId: customerId,
      type: type,
    ),
  );
}

class _TransactionSheet extends StatefulWidget {
  final String customerId;
  final TxType type;

  const _TransactionSheet({
    required this.customerId,
    required this.type,
  });

  @override
  State<_TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends State<_TransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _dueDate;
  bool _loading = false;

  bool get _isCredit => widget.type == TxType.credit;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final today = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: 7)),
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await TransactionService().addTransaction(
        customerId: widget.customerId,
        type: widget.type,
        amount: double.parse(_amountController.text.trim()),
        description: _descriptionController.text.trim(),
        dueDate: _isCredit ? _dueDate : null,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          22,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 23),

              Text(
                _isCredit ? 'Record Credit Entry' : 'Record Payment',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 7),

              const Text(
                'Enter the transaction details below.',
                style: TextStyle(color: AppColors.textGrey),
              ),

              const SizedBox(height: 22),

              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount (Rs)',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                validator: (value) {
                  final amount = double.tryParse((value ?? '').trim());

                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 17),

              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: _isCredit
                      ? 'Description'
                      : 'Payment Note (Optional)',
                  prefixIcon: const Icon(Icons.description_outlined),
                ),
                validator: (value) {
                  if (_isCredit &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Enter a description';
                  }
                  return null;
                },
              ),

              if (_isCredit) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _pickDueDate,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    _dueDate == null
                        ? 'Select Due Date (Optional)'
                        : 'Due: ${DateFormat.yMMMd().format(_dueDate!)}',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isCredit ? AppColors.danger : AppColors.primary,
                  ),
                  onPressed: _loading ? null : _saveTransaction,
                  child: _loading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : Text(
                          _isCredit ? 'Save Credit Entry' : 'Save Payment',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
