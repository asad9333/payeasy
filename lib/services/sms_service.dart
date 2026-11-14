import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Sends SMS from the phone's own SIM (Android only) through the native
/// code in MainActivity.kt.
class SmsService {
  static const MethodChannel _channel = MethodChannel('payeasy/sms');

  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> hasPermission() async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('hasPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestPermission() async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('requestPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> send(String phone, String message) async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>(
            'send',
            {'phone': phone, 'message': message},
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }
}
