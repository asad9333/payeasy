import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'customer_service.dart';
import 'profile_service.dart';
import 'sms_service.dart';

/// Sends the automatic SMS reminders for customers who promised to pay.
///
/// Rules (per customer, at most one SMS per day):
///  - the day before the promise date
///  - on the promise date
///  - once, up to 7 days after the promise date if it was missed
/// SMS go out only after the hour chosen in Profile, when this runs
/// (app start, app resume, and every 15 minutes while the app is open).
class ReminderService {
  final _customers = CustomerService();
  final _profile = ProfileService();
  final _sms = SmsService();

  static bool _running = false;

  String _key(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  /// 0300 1234567 -> +923001234567
  String? _pkNumber(String phone) {
    var d = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.startsWith('0')) d = '92${d.substring(1)}';
    return d.length >= 11 ? '+$d' : null;
  }

  /// Returns how many SMS were sent.
  Future<int> runDue() async {
    if (_running || !SmsService.supported) return 0;
    if (FirebaseAuth.instance.currentUser == null) return 0;
    _running = true;

    try {
      final profile = await _profile.profileStream().first;
      if (profile['autoSms'] != true) return 0;

      final hour = ((profile['smsHour'] ?? 10) as num).toInt();
      final now = DateTime.now();
      if (now.hour < hour) return 0;
      if (!await _sms.hasPermission()) return 0;

      final shop = (profile['shopName'] ?? '').toString().trim();
      final today = DateTime(now.year, now.month, now.day);
      final todayKey = _key(today);
      final money = NumberFormat('#,##0');
      final dateFmt = DateFormat('d MMM yyyy');

      final customers = await _customers.getAll();
      var sent = 0;

      for (final c in customers) {
        final promise = c.promiseDate;
        if (promise == null || c.balance <= 0) continue;
        if (c.lastSmsOn == todayKey) continue;

        final day = DateTime(promise.year, promise.month, promise.day);
        final days = day.difference(today).inDays;

        String? tail;
        if (days == 1) {
          tail = ', which is tomorrow.';
        } else if (days == 0) {
          tail = ', which is today.';
        } else if (days < 0 &&
            days >= -7 &&
            (c.lastSmsOn == null || c.lastSmsOn!.compareTo(_key(day)) < 0)) {
          tail = '. Please pay at your earliest convenience.';
        }
        if (tail == null) continue;

        final number = _pkNumber(c.phone);
        if (number == null) continue;

        final amount = money.format(c.promiseAmount ?? c.balance);
        final from = shop.isEmpty ? '' : ' from $shop';
        final text = 'Hello ${c.name}, a reminder$from: you promised to pay '
            'Rs $amount on ${dateFmt.format(day)}$tail Thank you.';

        final ok = await _sms.send(number, text);
        if (ok) {
          await _customers.markSmsSent(c.id, todayKey);
          sent++;
          await Future.delayed(const Duration(seconds: 1));
        }
      }
      return sent;
    } catch (_) {
      return 0;
    } finally {
      _running = false;
    }
  }
}
