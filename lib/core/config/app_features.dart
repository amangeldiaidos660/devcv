import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class AppFeatures {
  static const firebaseStorageEnabled = bool.fromEnvironment(
    'ENABLE_FIREBASE_STORAGE',
    defaultValue: false,
  );
  static const photoUnavailableMessage =
      'Фото необязательно. Сейчас приложение работает без загрузки фото.';
}

final profilePhotosEnabledProvider = Provider<bool>(
  (ref) => AppFeatures.firebaseStorageEnabled,
);
