/// Centralized form validator functions to replace the 22 repeated
/// `if (v == null || v.trim().isEmpty) return '...'` patterns
/// found across 7 form-heavy files.
///
/// Usage with [CustomTextField]:
///   validator: AppValidators.required('Name'),
///   validator: AppValidators.email,
///   validator: AppValidators.phone,
///   validator: AppValidators.password,
///   validator: AppValidators.nid,
///
/// Chaining (required + pattern check):
///   validator: (v) => AppValidators.required('Email')(v) ?? AppValidators.email(v),
class AppValidators {
  AppValidators._();

  /// Returns a validator that rejects null or blank input.
  static String? Function(String?) required(String fieldName) {
    return (v) {
      if (v == null || v.trim().isEmpty) return '$fieldName is required';
      return null;
    };
  }

  /// Validates standard email address format.
  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(v.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates a Bangladeshi phone number (11 digits, starts with 01).
  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    final t = v.trim().replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^01[3-9]\d{8}$').hasMatch(t)) {
      return 'Enter a valid 11-digit BD phone number (e.g. 01XXXXXXXXX)';
    }
    return null;
  }

  /// Validates minimum password strength (8+ chars).
  static String? password(String? v) {
    if (v == null || v.trim().isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  /// Validates that a confirm-password field matches the original.
  static String? Function(String?) confirmPassword(String original) {
    return (v) {
      if (v == null || v.isEmpty) return 'Please confirm your password';
      if (v != original) return 'Passwords do not match';
      return null;
    };
  }

  /// Validates a 6-digit OTP code.
  static String? otp(String? v) {
    if (v == null || v.trim().isEmpty) return 'Code is required';
    if (v.trim().length != 6) return 'Enter the 6-digit code';
    return null;
  }

  /// Validates NID format (10 or 17 digits).
  static String? nid(String? v) {
    if (v == null || v.trim().isEmpty) return null; // NID is optional
    final t = v.trim();
    if (!RegExp(r'^\d{10}$|^\d{17}$').hasMatch(t)) {
      return 'NID must be 10 or 17 digits';
    }
    return null;
  }

  /// Returns a min-length validator for any field.
  static String? Function(String?) minLength(int length, {String? fieldName}) {
    return (v) {
      if (v == null || v.trim().length < length) {
        return '${fieldName ?? 'Field'} must be at least $length characters';
      }
      return null;
    };
  }
}
