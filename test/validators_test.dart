import 'package:devcv/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Email is required, trimmed and checked for basic format', () {
    expect(Validators.email(' '), isNotNull);
    expect(Validators.email('invalid@'), isNotNull);
    expect(Validators.email('dev @example.com'), isNotNull);
    expect(Validators.email(' dev@example.com '), isNull);
  });
  test('Registration password has minimum length and matching repeat', () {
    expect(Validators.password(''), isNotNull);
    expect(Validators.password('1234567'), isNotNull);
    expect(Validators.password('12345678'), isNull);
    expect(Validators.repeatPassword('different', '12345678'), isNotNull);
    expect(Validators.repeatPassword('12345678', '12345678'), isNull);
  });
  test('Profile rejects blanks, overlong text and future birth dates', () {
    expect(Validators.fullName('   '), isNotNull);
    expect(Validators.city(' '), isNotNull);
    expect(Validators.fullName('x' * 121), isNotNull);
    expect(Validators.fullName(' Айдос '), isNull);
    expect(Validators.city(' Алматы '), isNull);
    expect(Validators.birthDate(null), isNotNull);
    expect(
      Validators.birthDate(DateTime(2024, 1, 2), now: DateTime(2024, 1, 1)),
      isNotNull,
    );
    expect(
      Validators.birthDate(DateTime(2024, 1, 1), now: DateTime(2024, 1, 1, 12)),
      isNull,
    );
  });
}
