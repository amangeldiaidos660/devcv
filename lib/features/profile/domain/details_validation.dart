import 'profile_details.dart';
import 'profile_entries.dart';

abstract final class DetailsValidation {
  static String? contacts(ProfileContacts value, String email) {
    if (email.trim().isEmpty &&
        ContactType.values.every((e) => value.value(e, email).trim().isEmpty)) {
      return 'Укажите хотя бы один контакт';
    }
    if (value.preferred.length > 2) {
      return 'Выберите не больше двух предпочтительных контактов';
    }
    for (final type in value.preferred) {
      if (value.value(type, email).trim().isEmpty) {
        return 'Заполните предпочтительный контакт: ${type.label}';
      }
    }
    for (final url in [value.githubUrl, value.linkedinUrl, value.website]) {
      final error = optionalUrl(url);
      if (error != null) return error;
    }
    if (value.phone.isNotEmpty &&
        !RegExp(r'^\+?[0-9()\s-]{7,25}$').hasMatch(value.phone)) {
      return 'Проверьте номер телефона';
    }
    if (value.telegram.isNotEmpty &&
        !RegExp(r'^@?[a-zA-Z0-9_]{5,32}$').hasMatch(value.telegram)) {
      return 'Telegram: username или @username, 5–32 символа';
    }
    return null;
  }

  static String? salary(bool enabled, int? amount) =>
      enabled && (amount == null || amount <= 0 || amount > 1000000000)
      ? 'Укажите ожидаемую зарплату от 1 до 1 000 000 000'
      : null;
  static String? about(String text) =>
      text.runes.length > 500 ? 'Максимум 500 символов' : null;
}
