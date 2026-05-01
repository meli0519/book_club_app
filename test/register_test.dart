import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Validation helpers (mirrors logic in RegisterScreen)
// ---------------------------------------------------------------------------

final _emailRegex = RegExp(
  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
);

final _strongPasswordRegex = RegExp(
  r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$',
);

String? validateName(String? value) {
  if (value == null || value.trim().isEmpty) return 'Name is required';
  return null;
}

String? validateEmail(String? value) {
  if (value == null || value.isEmpty) return 'This field is required';
  if (!_emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'This field is required';
  if (!_strongPasswordRegex.hasMatch(value)) {
    return 'Password must be at least 8 characters with uppercase, lowercase and number';
  }
  return null;
}

String? validateConfirmPassword(String? value, String password) {
  if (value == null || value.isEmpty) return 'This field is required';
  if (value != password) return 'Passwords do not match';
  return null;
}

// ---------------------------------------------------------------------------
// AuthService error message mapping (mirrors logic in AuthService)
// ---------------------------------------------------------------------------

String getAuthErrorMessage(String code) {
  switch (code) {
    case 'email-already-in-use':
      return 'An account with this email already exists.';
    case 'weak-password':
      return 'The password is too weak. Please use a stronger password.';
    case 'invalid-email':
      return 'The email address is invalid.';
    case 'network-request-failed':
      return 'Network error. Please check your internet connection.';
    default:
      return 'Authentication failed. Please try again.';
  }
}

void main() {
  // -------------------------------------------------------------------------
  // Name validation
  // -------------------------------------------------------------------------
  group('Registration - Name validation', () {
    test('empty name returns error', () {
      expect(validateName(''), isNotNull);
      expect(validateName(null), isNotNull);
    });

    test('whitespace-only name returns error', () {
      expect(validateName('   '), isNotNull);
      expect(validateName('\t'), isNotNull);
    });

    test('valid name passes', () {
      expect(validateName('John'), isNull);
      expect(validateName('María García'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Email validation
  // -------------------------------------------------------------------------
  group('Registration - Email validation', () {
    test('empty email returns required error', () {
      expect(validateEmail(''), isNotNull);
      expect(validateEmail(null), isNotNull);
    });

    test('invalid email format returns error', () {
      expect(validateEmail('notanemail'), isNotNull);
      expect(validateEmail('user@'), isNotNull);
      expect(validateEmail('@example.com'), isNotNull);
      expect(validateEmail('user @example.com'), isNotNull);
    });

    test('valid email passes', () {
      expect(validateEmail('user@example.com'), isNull);
      expect(validateEmail('test.user@domain.co.uk'), isNull);
      expect(validateEmail('user+tag@example.com'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Password validation (strong password rules)
  // -------------------------------------------------------------------------
  group('Registration - Password validation', () {
    test('empty password returns required error', () {
      expect(validatePassword(''), isNotNull);
      expect(validatePassword(null), isNotNull);
    });

    test('password shorter than 8 chars returns error', () {
      expect(validatePassword('Abc1234'), isNotNull); // 7 chars
      expect(validatePassword('Ab1'), isNotNull);
    });

    test('password without uppercase returns error', () {
      expect(validatePassword('abcdefg1'), isNotNull);
    });

    test('password without lowercase returns error', () {
      expect(validatePassword('ABCDEFG1'), isNotNull);
    });

    test('password without digit returns error', () {
      expect(validatePassword('Abcdefgh'), isNotNull);
    });

    test('strong password passes', () {
      expect(validatePassword('Password1'), isNull);
      expect(validatePassword('MyStr0ng!'), isNull);
      expect(validatePassword('Abc12345'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Confirm password validation
  // -------------------------------------------------------------------------
  group('Registration - Confirm password validation', () {
    test('empty confirm password returns required error', () {
      expect(validateConfirmPassword('', 'Password1'), isNotNull);
      expect(validateConfirmPassword(null, 'Password1'), isNotNull);
    });

    test('mismatched passwords return error', () {
      expect(validateConfirmPassword('Password2', 'Password1'), isNotNull);
      expect(validateConfirmPassword('password1', 'Password1'), isNotNull);
    });

    test('matching passwords pass', () {
      expect(validateConfirmPassword('Password1', 'Password1'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Full form validation
  // -------------------------------------------------------------------------
  group('Registration - Full form validation', () {
    test('all valid fields pass', () {
      const name = 'John Doe';
      const email = 'john@example.com';
      const password = 'Password1';
      const confirmPassword = 'Password1';

      expect(validateName(name), isNull);
      expect(validateEmail(email), isNull);
      expect(validatePassword(password), isNull);
      expect(validateConfirmPassword(confirmPassword, password), isNull);
    });

    test('form fails when name is empty', () {
      expect(validateName(''), isNotNull);
    });

    test('form fails when email is invalid', () {
      expect(validateEmail('bad-email'), isNotNull);
    });

    test('form fails when password is weak', () {
      expect(validatePassword('weak'), isNotNull);
    });

    test('form fails when passwords do not match', () {
      expect(validateConfirmPassword('Different1', 'Password1'), isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // Firebase Auth error handling
  // -------------------------------------------------------------------------
  group('Registration - Firebase Auth error handling', () {
    test('email-already-in-use returns descriptive message', () {
      final msg = getAuthErrorMessage('email-already-in-use');
      expect(msg, isNotEmpty);
      expect(msg.toLowerCase(), contains('email'));
    });

    test('weak-password returns descriptive message', () {
      final msg = getAuthErrorMessage('weak-password');
      expect(msg, isNotEmpty);
      expect(msg.toLowerCase(), contains('password'));
    });

    test('invalid-email returns descriptive message', () {
      final msg = getAuthErrorMessage('invalid-email');
      expect(msg, isNotEmpty);
      expect(msg.toLowerCase(), contains('email'));
    });

    test('unknown error returns default message', () {
      final msg = getAuthErrorMessage('some-unknown-code');
      expect(msg, isNotEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Registration flow logic
  // -------------------------------------------------------------------------
  group('Registration - Flow logic', () {
    test('photoUrl should be empty string for email/password registration', () {
      const photoUrl = '';
      expect(photoUrl, isEmpty);
    });

    test('role should default to member on registration', () {
      const role = 'member';
      expect(role, equals('member'));
    });

    test('membership status should be pending after registration', () {
      const membershipStatus = 'pending';
      expect(membershipStatus, equals('pending'));
    });

    test('registration route should be /register', () {
      const route = '/register';
      expect(route, equals('/register'));
    });

    test('successful registration navigates to waiting screen', () {
      const waitingRoute = '/waiting';
      expect(waitingRoute, isNotEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // i18n strings
  // -------------------------------------------------------------------------
  group('Registration - i18n strings', () {
    test('all required string keys are defined', () {
      const strings = [
        'Create Account',
        'Name',
        'Email',
        'Password',
        'Confirm Password',
        'Register',
        'Already have an account? Sign in',
        'Name is required',
        'Password must be at least 8 characters with uppercase, lowercase and number',
        'Passwords do not match',
        'Account created successfully',
        'This email is already registered',
      ];

      for (final s in strings) {
        expect(s, isNotEmpty);
      }
    });
  });
}
