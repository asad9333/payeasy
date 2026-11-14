
import 'dart:async';

import 'package:flutter/material.dart';

import '../services/profile_service.dart';
import '../services/reminder_service.dart';
import '../utils/app_colors.dart';

import 'dashboard_tab.dart';
import 'customers_tab.dart';
import 'reports_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final _reminders = ReminderService();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    ProfileService().ensureProfile();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkReminders());
    _timer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _checkReminders(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkReminders();
  }

  Future<void> _checkReminders() async {
    final sent = await _reminders.runDue();
    if (sent > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$sent SMS reminder${sent == 1 ? '' : 's'} sent to customers.',
          ),
        ),
      );
    }
  }

  void _navigate(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardTab(onNavigate: _navigate),
      const CustomersTab(),
      const ReportsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        backgroundColor: Colors.white,
        elevation: 3,
        selectedIndex: _selectedIndex,
        indicatorColor: AppColors.lightGreen,
        onDestinationSelected: _navigate,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
