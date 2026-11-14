
import 'package:flutter/material.dart';

import '../models/customer_model.dart';
import '../services/customer_service.dart';
import '../services/overdue_service.dart';
import '../services/profile_service.dart';
import '../utils/app_colors.dart';
import '../widgets/ui.dart';
import 'ledger_screen.dart';

class CustomersTab extends StatefulWidget {
  const CustomersTab({super.key});

  @override
  State<CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<CustomersTab> {
  final _service = CustomerService();
  final _searchController = TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addCustomer() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Customer'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          v == null || v.trim().length < 2
                              ? 'Enter a valid name'
                              : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (v) {
                        final digits =
                            (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                        return digits.length < 10
                            ? 'Enter a valid phone number'
                            : null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() => saving = true);

                          try {
                            await _service.addCustomer(
                              name: name.text.trim(),
                              phone: phone.text.trim(),
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          } catch (e) {
                            setDialogState(() => saving = false);
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.toString().replaceFirst(
                                          'Exception: ',
                                          '',
                                        ),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save Customer'),
                ),
              ],
            );
          },
        );
      },
    );

    // controllers intentionally not disposed here (dialog still animating out)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Customers',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addCustomer,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search by name or phone...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<Map<String, dynamic>>(
                  stream: ProfileService().profileStream(),
                  builder: (context, profileSnap) {
                    final limit =
                        (profileSnap.data?['creditLimit'] ?? 5000).toDouble();

                    return StreamBuilder<List<CustomerModel>>(
                      stream: _service.streamCustomers(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('Unable to load customers'),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final customers =
                            _service.search(snapshot.data!, _query);

                        if (customers.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.people_outline,
                                  size: 55,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _query.isEmpty
                                      ? 'No customers added yet'
                                      : 'No matching customers',
                                  style: const TextStyle(
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: customers.length,
                          itemBuilder: (context, index) {
                            final c = customers[index];
                            return CustomerRow(
                              customer: c,
                              overdue: OverdueService().isOverdue(c, limit),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      LedgerScreen(customerId: c.id),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
