
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Material (not ColoredBox) so ListTile/CheckboxListTile can paint ink.
    return Material(
      color: AppColors.background,
      child: SizedBox.expand(
        child: SafeArea(
          child: child,
        ),
      ),
    );
  }
}

class PayEasyLogo extends StatelessWidget {
  final double size;

  const PayEasyLogo({
    super.key,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.account_balance_wallet_rounded,
          size: size + 10,
          color: AppColors.primary,
        ),
        const SizedBox(width: 9),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Pay',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: size,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: 'Easy',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: size,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
