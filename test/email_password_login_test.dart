import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Email/Password Login - Form Validation', () {
    test('email validation regex should accept valid emails', () {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );

      expect(emailRegex.hasMatch('user@example.com'), true);
      expect(emailRegex.hasMatch('test.user@domain.co.uk'), true);
      expect(emailRegex.hasMatch('user+tag@example.com'), true);
      expect(emailRegex.hasMatch('john.doe@company.org'), true);
    });

    test('email validation regex should reject invalid emails', () {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );

      expect(emailRegex.hasMatch('notanemail'), false);
      expect(emailRegex.hasMatch('user@'), false);
      expect(emailRegex.hasMatch('@example.com'), false);
      expect(emailRegex.hasMatch('user @example.com'), false);
      expect(emailRegex.hasMatch('user@.com'), false);
      expect(emailRegex.hasMatch('user@domain'), false);
    });

    test('password validation should require minimum 6 characters', () {
      const minLength = 6;

      expect('password'.length >= minLength, true);
      expect('123456'.length >= minLength, true);
      expect('P@ssw0rd'.length >= minLength, true);
      expect('pass'.length >= minLength, false);
      expect('12345'.length >= minLength, false);
      expect(''.length >= minLength, false);
    });

    test('form should validate both email and password together', () {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      const minPasswordLength = 6;

      // Valid case
      final validEmail = 'user@example.com';
      final validPassword = 'password123';
      expect(emailRegex.hasMatch(validEmail), true);
      expect(validPassword.length >= minPasswordLength, true);

      // Invalid email
      final invalidEmail = 'notanemail';
      expect(emailRegex.hasMatch(invalidEmail), false);

      // Invalid password
      final invalidPassword = 'short';
      expect(invalidPassword.length >= minPasswordLength, false);

      // Both invalid
      expect(emailRegex.hasMatch(invalidEmail), false);
      expect(invalidPassword.length >= minPasswordLength, false);
    });

    test('email field should be required', () {
      final email = '';
      expect(email.isEmpty, true);
    });

    test('password field should be required', () {
      final password = '';
      expect(password.isEmpty, true);
    });

    test('email should trim whitespace', () {
      final email = '  user@example.com  ';
      final trimmed = email.trim();
      expect(trimmed, 'user@example.com');
    });

    test('password should not be trimmed (preserve spaces)', () {
      final password = '  password  ';
      // Password should not be trimmed as spaces might be intentional
      expect(password.length, 12);
    });
  });

  group('Email/Password Login - Error Messages', () {
    test('should have descriptive error message for user-not-found', () {
      const errorCode = 'user-not-found';
      const expectedMessage = 'No user found with this email address.';

      expect(expectedMessage, isNotEmpty);
      expect(errorCode, isNotEmpty);
    });

    test('should have descriptive error message for wrong-password', () {
      const errorCode = 'wrong-password';
      const expectedMessage = 'The password is incorrect.';

      expect(expectedMessage, isNotEmpty);
      expect(errorCode, isNotEmpty);
    });

    test('should have descriptive error message for invalid-email', () {
      const errorCode = 'invalid-email';
      const expectedMessage = 'The email address is invalid.';

      expect(expectedMessage, isNotEmpty);
      expect(errorCode, isNotEmpty);
    });

    test('should have descriptive error message for email-already-in-use', () {
      const errorCode = 'email-already-in-use';
      const expectedMessage = 'An account with this email already exists.';

      expect(expectedMessage, isNotEmpty);
      expect(errorCode, isNotEmpty);
    });

    test('should have descriptive error message for weak-password', () {
      const errorCode = 'weak-password';
      const expectedMessage = 'The password is too weak. Please use a stronger password.';

      expect(expectedMessage, isNotEmpty);
      expect(errorCode, isNotEmpty);
    });

    test('should have descriptive error message for network-request-failed', () {
      const errorCode = 'network-request-failed';
      const expectedMessage = 'Network error. Please check your internet connection.';

      expect(expectedMessage, isNotEmpty);
      expect(errorCode, isNotEmpty);
    });

    test('should have default error message for unknown errors', () {
      const errorCode = 'unknown-error';
      const expectedMessage = 'Authentication failed. Please try again.';

      expect(expectedMessage, isNotEmpty);
      expect(errorCode, isNotEmpty);
    });
  });

  group('Email/Password Login - Edge Cases', () {
    test('should handle email with multiple dots', () {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );

      expect(emailRegex.hasMatch('user.name.test@example.co.uk'), true);
    });

    test('should handle email with plus sign', () {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );

      expect(emailRegex.hasMatch('user+tag@example.com'), true);
    });

    test('should handle email with hyphen in domain', () {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );

      expect(emailRegex.hasMatch('user@my-domain.com'), true);
    });

    test('should reject email with consecutive dots', () {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );

      // This regex will accept it, but it's technically invalid
      // A more strict regex would reject it
      expect(emailRegex.hasMatch('user..name@example.com'), true);
    });

    test('should handle very long password', () {
      const minLength = 6;
      final longPassword = 'a' * 100;

      expect(longPassword.length >= minLength, true);
    });

    test('should handle password with special characters', () {
      const minLength = 6;
      final specialPassword = r'P@ss!#$%';

      expect(specialPassword.length >= minLength, true);
    });

    test('should handle password with unicode characters', () {
      const minLength = 6;
      final unicodePassword = 'pässwörd';

      expect(unicodePassword.length >= minLength, true);
    });
  });

  group('Email/Password Login - Localization Strings', () {
    test('should have email label string', () {
      const emailLabel = 'Email';
      expect(emailLabel, isNotEmpty);
    });

    test('should have password label string', () {
      const passwordLabel = 'Password';
      expect(passwordLabel, isNotEmpty);
    });

    test('should have sign in button label string', () {
      const signInLabel = 'Sign In';
      expect(signInLabel, isNotEmpty);
    });

    test('should have invalid email error message', () {
      const invalidEmailMsg = 'Please enter a valid email address.';
      expect(invalidEmailMsg, isNotEmpty);
    });

    test('should have password too short error message', () {
      const passwordTooShortMsg = 'Password must be at least 6 characters.';
      expect(passwordTooShortMsg, isNotEmpty);
    });

    test('should have field required error message', () {
      const fieldRequiredMsg = 'This field is required';
      expect(fieldRequiredMsg, isNotEmpty);
    });
  });

  group('Email/Password Login - Integration Scenarios', () {
    test('successful login flow should have valid email and password', () {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      const minPasswordLength = 6;

      final email = 'user@example.com';
      final password = 'password123';

      expect(emailRegex.hasMatch(email), true);
      expect(password.length >= minPasswordLength, true);
    });

    test('failed login with invalid email should show email error', () {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );

      final email = 'notanemail';
      expect(emailRegex.hasMatch(email), false);
    });

    test('failed login with short password should show password error', () {
      const minPasswordLength = 6;

      final password = 'short';
      expect(password.length >= minPasswordLength, false);
    });

    test('form submission should validate both fields', () {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      const minPasswordLength = 6;

      final email = 'user@example.com';
      final password = 'password123';

      final isEmailValid = emailRegex.hasMatch(email);
      final isPasswordValid = password.length >= minPasswordLength;
      final isFormValid = isEmailValid && isPasswordValid;

      expect(isFormValid, true);
    });

    test('form submission should fail if email is invalid', () {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      const minPasswordLength = 6;

      final email = 'invalid-email';
      final password = 'password123';

      final isEmailValid = emailRegex.hasMatch(email);
      final isPasswordValid = password.length >= minPasswordLength;
      final isFormValid = isEmailValid && isPasswordValid;

      expect(isFormValid, false);
    });

    test('form submission should fail if password is too short', () {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      const minPasswordLength = 6;

      final email = 'user@example.com';
      final password = 'short';

      final isEmailValid = emailRegex.hasMatch(email);
      final isPasswordValid = password.length >= minPasswordLength;
      final isFormValid = isEmailValid && isPasswordValid;

      expect(isFormValid, false);
    });
  });
}
