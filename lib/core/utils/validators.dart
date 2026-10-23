/// Centralized input validation functions with polite, user-friendly error messages.
class Validators {
  Validators._();

  /// Validates full name: 2 to 50 characters.
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name.';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Name must be at least 2 characters.';
    }
    if (trimmed.length > 50) {
      return 'Name must not exceed 50 characters.';
    }
    return null;
  }

  /// Validates email address format.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address.';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  /// Validates Rwandan phone number:
  /// Examples: +250 788 123 456, +250788123456, 0788123456, 078 123 4567.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number.';
    }
    final cleanPhone = value.replaceAll(RegExp(r'\s+'), '');
    final rwandanPhoneRegex = RegExp(r'^(\+2507[2389]\d{7}|07[2389]\d{7})$');
    if (!rwandanPhoneRegex.hasMatch(cleanPhone)) {
      return 'Please enter a valid phone number (e.g. +250 78X XXX XXX or 078X XXX XXX).';
    }
    return null;
  }

  /// Validates password for Sign Up:
  /// At least 8 characters with at least one letter and one number.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please create a password.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);
    if (!hasLetter || !hasNumber) {
      return 'Password must contain at least one letter and one number.';
    }
    return null;
  }

  /// Validates password for Login: simply non-empty.
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password.';
    }
    return null;
  }

  /// Validates household 6-digit PIN.
  static String? pin(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the 6-digit PIN.';
    }
    final pinRegex = RegExp(r'^\d{6}$');
    if (!pinRegex.hasMatch(value.trim())) {
      return 'PIN must be exactly 6 digits.';
    }
    return null;
  }

  /// Validates amount: greater than 0 and at most 100,000,000 RWF.
  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an amount.';
    }
    final clean = value.replaceAll(',', '').replaceAll(' ', '').trim();
    final parsed = int.tryParse(clean);
    if (parsed == null || parsed <= 0) {
      return 'Amount must be greater than 0.';
    }
    if (parsed > 100000000) {
      return 'Amount must not exceed 100,000,000 RWF.';
    }
    return null;
  }

  /// Validates title: 3 to 60 characters.
  static String? title(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a title.';
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'Title must be at least 3 characters.';
    }
    if (trimmed.length > 60) {
      return 'Title must not exceed 60 characters.';
    }
    return null;
  }
}
