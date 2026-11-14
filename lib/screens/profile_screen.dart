
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_screen.dart';
import '../services/profile_service.dart';
import '../utils/app_colors.dart';
import '../widgets/auto_sms_card.dart';
import '../widgets/ui.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = ProfileService();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _shopName = TextEditingController();
  final _creditLimit = TextEditingController();

  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _service.profileStream().first;

      if (!mounted) return;

      _firstName.text = (profile['firstName'] ?? '').toString();
      _lastName.text = (profile['lastName'] ?? '').toString();
      _shopName.text = (profile['shopName'] ?? '').toString();

      _creditLimit.text =
          ((profile['creditLimit'] ?? 5000).toDouble())
              .toStringAsFixed(0);

      setState(() => _loaded = true);
    } catch (e) {
      if (mounted) {
        setState(() => _loaded = true);
        _message('Unable to load profile: $e');
      }
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _shopName.dispose();
    _creditLimit.dispose();
    super.dispose();
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveProfile() async {
    final limit = double.tryParse(_creditLimit.text.trim());

    if (_firstName.text.trim().isEmpty ||
        _lastName.text.trim().isEmpty ||
        _shopName.text.trim().isEmpty ||
        limit == null ||
        limit <= 0) {
      _message('Please enter valid profile details.');
      return;
    }

    setState(() => _saving = true);

    try {
      await _service.updateProfile(
        firstName: _firstName.text,
        lastName: _lastName.text,
        shopName: _shopName.text,
        creditLimit: limit,
      );

      if (mounted) {
        _message('Profile updated successfully.');
      }
    } catch (e) {
      if (mounted) {
        _message('Unable to update profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
          (route) => false,
        );
      } catch (e) {
        if (mounted) {
          _message('Unable to logout: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    final name =
        '${_firstName.text.trim()} ${_lastName.text.trim()}'.trim();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 24),

        HeroCard(
          child: Row(
            children: [
              SquareAvatar(
                name: name.isEmpty ? 'A' : name,
                size: 58,
                background: AppColors.accent,
                foreground: AppColors.primaryDark,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Account Owner' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (_shopName.text.isNotEmpty)
                      Text(
                        _shopName.text,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 25),

        const Text(
          'Personal Information',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        TextField(
          controller: _firstName,
          decoration: const InputDecoration(
            labelText: 'First Name',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),

        const SizedBox(height: 14),

        TextField(
          controller: _lastName,
          decoration: const InputDecoration(
            labelText: 'Last Name',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),

        const SizedBox(height: 14),

        TextField(
          controller: _shopName,
          decoration: const InputDecoration(
            labelText: 'Shop Name',
            prefixIcon: Icon(Icons.store_outlined),
          ),
        ),

        const SizedBox(height: 25),

        const Text(
          'Business Settings',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        TextField(
          controller: _creditLimit,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Credit Limit (Rs)',
            prefixIcon: Icon(
              Icons.account_balance_wallet_outlined,
            ),
          ),
        ),

        const SizedBox(height: 22),

        const AutoSmsCard(),

        const SizedBox(height: 22),

        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _saving ? null : _saveProfile,
            child: _saving
                ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                : const Text('Save Changes'),
          ),
        ),

        const SizedBox(height: 15),

        ElevatedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }
}
