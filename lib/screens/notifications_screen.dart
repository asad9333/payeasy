
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/customer_model.dart';
import '../services/customer_service.dart';
import '../services/overdue_service.dart';
import '../services/profile_service.dart';
import '../utils/app_colors.dart';
import 'ledger_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,##0');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: ProfileService().profileStream(),
        builder: (context, profileSnapshot) {
          final limit =
              (profileSnapshot.data?['creditLimit'] ?? 5000).toDouble();

          return StreamBuilder<List<CustomerModel>>(
            stream: CustomerService().streamCustomers(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Unable to load notifications'),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final overdue = OverdueService().overdueList(
                snapshot.data!,
                limit,
              );

              if (overdue.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.notifications_off_outlined,
                          size: 65,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'All Caught Up!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'There are no overdue accounts right now.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Text(
                    '${overdue.length} Overdue Accounts',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final customer in overdue)
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(13),
                        leading: Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: AppColors.dangerLight,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.notifications_active_outlined,
                            color: AppColors.danger,
                          ),
                        ),
                        title: Text(
                          'Overdue Payment Reminder',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${customer.name} has an outstanding balance of Rs ${money.format(customer.balance)}.',
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.textGrey,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LedgerScreen(
                                customerId: customer.id,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
 