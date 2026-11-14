import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/customer_model.dart';
import '../utils/app_colors.dart';

final NumberFormat _moneyFmt = NumberFormat('#,##0');

/// "Rs 12,500" (sign is dropped, same as the prototype)
String rs(num n) => 'Rs ${_moneyFmt.format(n.abs())}';

/// White rounded card with thin border + soft shadow.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = EdgeInsets.zero,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.fieldBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Rounded-square avatar with the first letter.
class SquareAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? background;
  final Color? foreground;
  final IconData? icon;

  const SquareAvatar({
    super.key,
    required this.name,
    this.size = 42,
    this.background,
    this.foreground,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? AppColors.primary;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? AppColors.lightGreen,
        borderRadius: BorderRadius.circular(size * 0.33),
      ),
      child: icon != null
          ? Icon(icon, color: fg, size: size * 0.5)
          : Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.4,
              ),
            ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final bool ok;

  const StatusPill({super.key, required this.label, this.ok = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: ok ? AppColors.lightGreen : AppColors.dangerLight,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: ok ? AppColors.primary : AppColors.danger,
        ),
      ),
    );
  }
}

/// Dark emerald gradient card with the gold circle in the corner.
class HeroCard extends StatelessWidget {
  final Widget child;

  const HeroCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.18),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(22), child: child),
        ],
      ),
    );
  }
}

/// One customer line used on Dashboard and Customers tab.
class CustomerRow extends StatelessWidget {
  final CustomerModel customer;
  final bool overdue;
  final VoidCallback onTap;

  const CustomerRow({
    super.key,
    required this.customer,
    required this.overdue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final b = customer.balance;
    return SoftCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          SquareAvatar(name: customer.name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  customer.phone,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rs(b),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: b > 0 ? AppColors.danger : AppColors.primary,
                ),
              ),
              const SizedBox(height: 3),
              if (overdue)
                const StatusPill(label: 'Overdue')
              else if (b <= 0)
                const StatusPill(label: 'Clear', ok: true),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small stat card: grey label, bold value.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: valueColor ?? AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
