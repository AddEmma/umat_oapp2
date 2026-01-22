// utils/validators.dart
class Validators {
  static String? email(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Please enter email address';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value!)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  static String? phone(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Please enter phone number';
    }

    // Remove all non-digit characters for validation
    final digitsOnly = value!.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }

    return null;
  }

  static String? required(String? value, String fieldName) {
    if (value?.trim().isEmpty ?? true) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  static String? password(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Please enter password';
    }

    if (value!.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }
}
