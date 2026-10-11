abstract final class Validators {
  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Введите email';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Введите корректный email';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Введите пароль';
    if (value.length < 8) return 'Пароль должен содержать минимум 8 символов';
    return null;
  }

  static String? loginPassword(String? value) =>
      value == null || value.isEmpty ? 'Введите пароль' : null;

  static String? repeatPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Повторите пароль';
    return value == password ? null : 'Пароли не совпадают';
  }

  static String? fullName(String? value) => _text(value, 'ФИО', 120);
  static String? city(String? value) => _text(value, 'город', 120);

  static String? _text(String? value, String label, int maxLength) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Укажите $label';
    if (text.length < 2) return 'Минимум 2 символа';
    if (text.length > maxLength) return 'Максимум $maxLength символов';
    return null;
  }

  static String? birthDate(DateTime? value, {DateTime? now}) {
    if (value == null) return 'Укажите дату рождения';
    final today = now ?? DateTime.now();
    final date = DateTime(value.year, value.month, value.day);
    if (date.isAfter(DateTime(today.year, today.month, today.day))) {
      return 'Дата рождения не может быть в будущем';
    }
    return null;
  }
}
