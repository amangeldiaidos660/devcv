import '../../../core/errors/app_failure.dart';

AppFailure authFailure(String code) => AppFailure(switch (code) {
  'wrong-password' ||
  'invalid-credential' ||
  'user-not-found' => 'Неверный email или пароль',
  'email-already-in-use' => 'Аккаунт с таким email уже существует',
  'weak-password' => 'Пароль недостаточно надёжный',
  'invalid-email' => 'Введите корректный email',
  'network-request-failed' => 'Проверьте подключение к интернету',
  'too-many-requests' => 'Слишком много попыток. Попробуйте позже',
  'user-disabled' => 'Аккаунт отключён',
  'operation-not-allowed' => 'Этот способ входа пока не включён',
  'requires-recent-login' => 'Войдите в аккаунт повторно',
  'account-exists-with-different-credential' =>
    'Для этого email уже используется другой способ входа',
  'google-configuration' =>
    'Вход через Google пока не настроен. Используйте email и пароль',
  'google-unavailable' => 'Вход через Google сейчас недоступен',
  _ => 'Не удалось выполнить действие. Попробуйте ещё раз',
}, code: code);
