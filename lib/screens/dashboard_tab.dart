import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/customer_model.dart';
import '../services/customer_service.dart';
import '../services/overdue_service.dart';
import '../services/profile_service.dart';
import '../utils/app_colors.dart';
import '../widgets/ui.dart';
import 'ledger_screen.dart';
import 'notifications_screen.dart';

class DashboardTab extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  const DashboardTab({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<Map<String, dynamic>>(
      stream: ProfileService().profileStream(),
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data ?? {};
        final name =
            (profile['firstName'] ?? user?.displayName ?? 'User').toString();
        final shop = (profile['shopName'] ?? '').toString();
        final limit = (profile['creditLimit'] ?? 5000).toDouble();

        return StreamBuilder<List<CustomerModel>>(
          stream: CustomerService().streamCustomers(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Unable to load dashboard'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final customers = snapshot.data!;
            final total = customers.fold<double>(0, (s, c) => s + c.balance);
            final active = customers.where((c) => c.balance > 0).length;
            final overdue = OverdueService().overdueList(customers, limit);
            final top = customers.where((c) => c.balance > 0).toList()
              ..sort((a, b) => b.balance.compareTo(a.balance));

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
              children: [
                // ---------- header ----------
                Row(
                  children: [
                    SquareAvatar(
                      name: name.isEmpty ? 'U' : name,
                      size: 44,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $name',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            shop.isEmpty ? 'Digital Ledger' : shop,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      ),
                      icon: Badge(
                        isLabelVisible: overdue.isNotEmpty,
                        smallSize: 9,
                        backgroundColor: AppColors.danger,
                        child: const Icon(Icons.notifications_none_rounded),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ---------- hero ----------
                HeroCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Outstanding',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rs(total),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${customers.length} customers · $active active balances',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Active balances',
                        value: '$active',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Overdue',
                        value: '${overdue.length}',
                        valueColor: AppColors.danger,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _action('Add Customer', Icons.person_add_alt_1_rounded,
                        () => onNavigate(1)),
                    const SizedBox(width: 10),
                    _action('Customers', Icons.groups_rounded,
                        () => onNavigate(1)),
                    const SizedBox(width: 10),
                    _action('Reports', Icons.bar_chart_rounded,
                        () => onNavigate(2)),
                  ],
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Top Customers',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => onNavigate(1),
                      child: const Text(
                        'View all',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (top.isEmpty)
                  const SoftCard(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No outstanding balances yet.',
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                    ),
                  ),

                for (final c in top.take(4))
                  CustomerRow(
                    customer: c,
                    overdue: OverdueService().isOverdue(c, limit),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LedgerScreen(customerId: c.id),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _action(String title, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: SoftCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 26),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
