
enum IdentifierType { email, phone, username }

class CountryCode {
  final String name;
  final String code;

  const CountryCode(this.name, this.code);
}

class Validators {
  static const List<CountryCode> countryCodes = [
    CountryCode('PK', '+92'),
    CountryCode('IN', '+91'),
    CountryCode('AE', '+971'),
    CountryCode('SA', '+966'),
    CountryCode('GB', '+44'),
    CountryCode('US', '+1'),
  ];

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  static String? personName(String? value) {
    final error = required(value);
    if (error != null) return error;

    final v = value!.trim();

    if (v.length < 2) return 'Must be at least 2 characters';

    if (!RegExp(r"^[a-zA-Z .']+$").hasMatch(v)) {
      return 'Use letters only';
    }

    return null;
  }

  static String? email(String? value) {
    final error = required(value);
    if (error != null) return error;

    final v = value!.trim();

    if (!RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)*\.[a-zA-Z]{2,}$',
    ).hasMatch(v)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  static String? phoneNumber(String? value, String countryCode) {
    final error = required(value);
    if (error != null) return error;

    final v = value!.trim();

    if (!RegExp(r'^\d+$').hasMatch(v)) {
      return 'Enter digits only';
    }

    if (countryCode == '+92') {
      if (v.length != 11) {
        return 'Phone number must be exactly 11 digits';
      }

      if (!RegExp(r'^03\d{9}$').hasMatch(v)) {
        return 'Enter a valid Pakistani mobile number';
      }
    } else if (v.length < 6 || v.length > 14) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  static String? password(String? value) {
    final error = required(value);
    if (error != null) return error;

    final v = value!;

    if (v.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!RegExp(r'[A-Z]').hasMatch(v)) {
      return 'Add at least one uppercase letter';
    }

    if (!RegExp(r'[a-z]').hasMatch(v)) {
      return 'Add at least one lowercase letter';
    }

    if (!RegExp(r'\d').hasMatch(v)) {
      return 'Add at least one number';
    }

    return null;
  }

  static String? confirmPassword(String? value, String original) {
    final error = required(value);
    if (error != null) return error;

    if (value != original) return 'Passwords do not match';

    return null;
  }

  static String _digitsOnly(String input) {
    return input.replaceAll(RegExp(r'\D'), '');
  }

  static String buildFullPhone(String countryCode, String input) {
    var digits = _digitsOnly(input);

    if (countryCode == '+92' && digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    return '$countryCode$digits';
  }

  static String normalizePhone(String input) {
    final p = input.replaceAll(RegExp(r'[\s\-()]'), '');

    if (p.startsWith('+')) return p;

    if (p.startsWith('00')) return '+${p.substring(2)}';

    if (p.startsWith('92') && p.length == 12) return '+$p';

    if (p.startsWith('0') && p.length == 11) {
      return '+92${p.substring(1)}';
    }

    if (p.startsWith('3') && p.length == 10) return '+92$p';

    return p;
  }

  static IdentifierType detectType(String input) {
    final v = input.trim();

    if (v.contains('@')) return IdentifierType.email;

    final digits = v.replaceAll(RegExp(r'[\s\-()+]'), '');

    if (RegExp(r'^\d{10,13}$').hasMatch(digits)) {
      return IdentifierType.phone;
    }

    return IdentifierType.username;
  }
}
 