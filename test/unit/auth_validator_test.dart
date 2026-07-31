import 'package:flutter_test/flutter_test.dart';
import 'package:gezayo_app/core/utils/auth_validator.dart';

void main() {
  group('AuthValidator Unit Tests', () {
    test('validateEmail rejects empty and invalid formats', () {
      expect(AuthValidator.validateEmail(''), 'Email address is required.');
      expect(AuthValidator.validateEmail('invalid-email'),
          'Please enter a valid email address (e.g., user@gezayo.rw).');
      expect(AuthValidator.validateEmail('  user@gezayo.rw  '), null);
    });

    test('validatePassword checks minimum length and complexity', () {
      expect(AuthValidator.validatePassword(''), 'Password is required.');
      expect(AuthValidator.validatePassword('123'),
          'Password must be at least 6 characters.');
      expect(AuthValidator.validatePassword('abcdef'),
          'Password must contain at least one letter and one number.');
      expect(AuthValidator.validatePassword('password123'), null);
    });

    test('validateConfirmPassword checks matching passwords', () {
      expect(AuthValidator.validateConfirmPassword('pass123', 'pass999'),
          'Passwords do not match.');
      expect(AuthValidator.validateConfirmPassword('pass123', 'pass123'), null);
    });

    test('validateFullName enforces minimum length', () {
      expect(AuthValidator.validateFullName(''), 'Full name is required.');
      expect(AuthValidator.validateFullName('Logger IRADUKUNDA'), null);
    });

    test('sanitizers trim and clean inputs', () {
      expect(
          AuthValidator.sanitizeEmail('  USER@Gezayo.RW  '), 'user@gezayo.rw');
      expect(AuthValidator.sanitizeName('  Logger IRADUKUNDA  '),
          'Logger IRADUKUNDA');
    });
  });
}
