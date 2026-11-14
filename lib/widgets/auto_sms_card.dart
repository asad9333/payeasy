import 'package:flutter/material.dart';

import '../services/profile_service.dart';
import '../services/sms_service.dart';
import '../utils/app_colors.dart';
import 'ui.dart';

/// Profile card: switch for automatic SMS reminders + time of day.
class AutoSmsCard extends StatelessWidget {
  const AutoSmsCard({super.key});

  String _label(int h) {
    if (h == 12) return '12:00 PM';
    return h > 12 ? '${h - 12}:00 PM' : '$h:00 AM';
  }

  Future<void> _toggle(BuildContext context, bool value, int hour) async {
    if (value) {
      final ok = await SmsService().requestPermission();
      if (!ok) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SMS permission is needed to send reminders.'),
            ),
          );
        }
        return;
      }
    }
    await ProfileService().setAutoSms(value, hour);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: ProfileService().profileStream(),
      builder: (context, snap) {
        final p = snap.data ?? {};
        final on = p['autoSms'] == true;
        final hour = ((p['smsHour'] ?? 10) as num).toInt();
        final supported = SmsService.supported;

        return SoftCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sms_outlined, color: AppColors.primary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Auto SMS Reminders',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Switch(
                    value: on && supported,
                    onChanged:
                        supported ? (v) => _toggle(context, v, hour) : null,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                supported
                    ? 'Customers with a promise date get an SMS from this '
                        "phone's SIM, one day before and on the promised day. "
                        'Messages are sent when the app is opened after the '
                        'chosen time.'
                    : 'Available on Android phones only.',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textGrey,
                ),
              ),
              if (on && supported) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Send after',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    DropdownButton<int>(
                      value: hour,
                      items: [
                        for (var h = 8; h <= 20; h++)
                          DropdownMenuItem(value: h, child: Text(_label(h))),
                      ],
                      onChanged: (h) {
                        if (h != null) ProfileService().setAutoSms(true, h);
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
