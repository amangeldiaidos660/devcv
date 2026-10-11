# DevCV

Developer Profile & Resume Builder для Android и iOS.
Application ID: `kz.aidos.devcv`. Firebase project: `devcv-ac143`.
Минимальные версии: Android API 24 и iOS 15.

## Архитектура

Существующие Firebase initialization, GetIt, DioClient, Hive cache и тема переиспользуются.

- `features/auth/domain`: AuthUser и контракт AuthRepository.
- `features/auth/data`: FirebaseAuthRepository, Google Sign-In 7 и преобразование ошибок.
- `features/auth/presentation`: Riverpod auth session/actions и формы входа, регистрации, сброса пароля и подтверждения email.
- `features/profile/domain`: DeveloperProfile, ProfileRepository и расчёт заполнения.
- `features/profile/data`: FirestoreProfileRepository и ProfileMapper для Firestore/Hive.
- `features/profile/presentation`: Riverpod profile/actions, форма и состояния loading/error/new/data.
- `app/router`: один GoRouter, auth redirect и StatefulShellRoute.indexedStack.
- `app/di`: регистрации существующих сервисов и новых Repository через GetIt.
- Provider + SharedPreferences продолжают управлять темой. Riverpod управляет Auth/Profile.

Domain не импортирует Firebase, Flutter или Hive. UI вызывает Repository через Riverpod.
Пароли и Google tokens не сохраняются в Firestore/Hive.

## Маршруты

| Доступ | Путь | Имя RouteNames |
| --- | --- | --- |
| Public | /splash | splash |
| Public | /login | login |
| Public | /register | register |
| Public | /forgot-password | forgotPassword |
| Неподтверждённый аккаунт | /verify-email | verifyEmail |
| Private | /home | home |
| Private | /profile | profile |
| Private | /resume | resume |
| Private | /settings | settings |

Splash использует поток Firebase userChanges без искусственной задержки.
Без сессии private routes перенаправляются на Login; неподтверждённый email — на Verify Email.
Подтверждённый аккаунт перенаправляется с public screens на Home.
Нижняя навигация сохраняет состояние четырёх private разделов и не показывается на public screens.
При уходе из изменённой формы показывается предупреждение; черновик сохраняется при переключении вкладок.
Resume остаётся заглушкой.

## Профиль и хранение

Коллекция: `users/{firebaseUid}`.
Поля: uid, fullName, birthDate, city, email, createdAt, updatedAt.
Документ создаётся при первом сохранении; фиктивные имя/город не добавляются.
Email берётся из Firebase Auth и не редактируется в форме.
Дата рождения — Firestore Timestamp; createdAt/updatedAt — server timestamp.
Сохранение выполняется транзакцией, createdAt сохраняется при обновлении.

Заполнение текущего базового профиля: имя, дата рождения, город и подтверждённый email,
по 25% за каждый элемент. Формула вынесена в ProfileCompletion для последующего расширения.

После серверного чтения профиль сохраняется в существующий general_cache box с ключом
`profile:{uid}`. При временной сетевой ошибке допускается чтение этого кэша.
Профили разных UID изолированы. Сложная offline-синхронизация не добавляется;
обычные offline capabilities Firestore сохраняются. Настройки темы хранятся в SharedPreferences.

DioClient остаётся без реальных запросов: connect timeout 15 секунд, receive timeout 20 секунд.
Base URL задаётся через `--dart-define=API_BASE_URL=...`; по умолчанию https://example.com/api/.
Debug логирование не пишет пароли, тела, заголовки или query-параметры.

## Firebase Console: обязательная настройка

В проекте devcv-ac143:

1. Authentication → Sign-in method: включить Email/Password и Google, указать support email.
2. Создать базу Cloud Firestore `(default)`, если она ещё не создана.
3. Применить подготовленные `firestore.rules` через Firebase Console → Firestore → Rules
   или выполнить из корня проекта:

```powershell
firebase deploy --only firestore:rules --project devcv-ac143
```

Правила разрешают только get/create/update собственного `users/{uid}` для подтверждённого аккаунта.
Они проверяют UID, email из auth token, допустимые поля, даты и server timestamps.
Чтение всей коллекции, удаление и доступ к чужому профилю не разрешены.
Правила подготовлены локально; деплой и проверка против реального backend в этом этапе не выполнялись.

Core/Auth/Firestore/Messaging/Storage/Crashlytics уже подключены. Push и загрузка фото не реализованы.
Автоматические FCM initialization и сбор Crashlytics по-прежнему отключены.

## Google Sign-In: Android

Текущий google-services.json не содержит OAuth-клиентов. Google Sign-In требует обновления конфигурации.
В Project settings → Android app kz.aidos.devcv добавьте отпечатки существующего debug keystore:

```text
SHA-1: 4A:DA:21:93:94:0C:CE:B1:95:85:75:9A:20:BD:FE:90:F7:9C:33:2A
SHA-256: 71:5A:5F:E2:8E:62:6B:CD:34:08:AA:D5:FF:71:8B:DC:57:EC:35:B2:FB:63:2B:D2:36:F4:AD:84:5F:F1:BB:0F
```

Значения получены из `C:\Users\amang\.android\debug.keystore`; для release нужна отдельная подпись
и её отпечатки. После включения Google и добавления SHA скачайте новый google-services.json
и замените `android/app/google-services.json`. В нём должен появиться OAuth client типа 3 (Web).
Android Google Sign-In использует этот client ID автоматически. При необходимости можно передать
реальный Web client ID через `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`.

Обновление основной FlutterFire-конфигурации при установленных CLI:

```powershell
dart pub global run flutterfire_cli:flutterfire configure --project=devcv-ac143 --platforms=android,ios --android-package-name=kz.aidos.devcv --ios-bundle-id=kz.aidos.devcv
```

## Google Sign-In: iOS

Текущий GoogleService-Info.plist не содержит CLIENT_ID/REVERSED_CLIENT_ID.
После включения Google скачайте новый plist для iOS app kz.aidos.devcv
и замените `ios/Runner/GoogleService-Info.plist`.

В `ios/Runner/Info.plist` добавьте CFBundleURLTypes → CFBundleURLSchemes с реальным
REVERSED_CLIENT_ID из нового plist. На macOS передайте реальный CLIENT_ID при запуске:
`--dart-define=GOOGLE_IOS_CLIENT_ID=...`.
Если требуется serverClientId, используйте Web OAuth client через GOOGLE_SERVER_CLIENT_ID.
Идентификаторы не выдуманы и не вставлены в нативные файлы. До завершения настройки
Google Sign-In на iOS возвращает понятную ошибку конфигурации.
iOS сборка и проверка native Google flow выполняются на macOS с Xcode и настроенной подписью.

## Проверки и запуск

Кэши разработки можно хранить на D, даже если системный профиль находится на C:

```powershell
$env:PUB_CACHE = 'D:\Tools\Caches\pub'
$env:GRADLE_USER_HOME = 'D:\Tools\Caches\gradle'
flutter pub get
dart format .
flutter analyze
flutter test
```

Unit/widget tests используют fake Repository без Firebase backend. Они проверяют validators,
сериализацию, заполнение профиля, auth/profile providers, защиту маршрутов, формы,
loading/error/new/data, сохранение вкладок, тему и адаптацию к трём размерам экрана.

Сборку APK и запуск на USB-устройстве выполняет пользователь:

```powershell
flutter run -d RFGYB1HX2PV
```

После настройки Firebase проверьте регистрацию → письмо → подтверждение → вход,
Google → выход, сброс пароля, создание/обновление собственного профиля и восстановление темы.
Release подпись Android пока использует debug key шаблона; перед публикацией нужен свой keystore.

Документация:
- https://firebase.google.com/docs/auth/flutter/password-auth
- https://firebase.google.com/docs/auth/flutter/federated-auth
- https://pub.dev/packages/google_sign_in
- https://firebase.google.com/docs/firestore/security/rules-conditions

## Файлы этого этапа

Созданы:

- `lib/app/router/app_shell.dart`.
- `lib/core/errors/app_failure.dart`, `lib/core/utils/validators.dart`,
  `lib/core/widgets/form_page.dart`, `lib/core/widgets/error_message.dart`.
- `lib/features/auth/domain/auth_user.dart`, `auth_repository.dart`;
  `lib/features/auth/data/firebase_auth_repository.dart`, `auth_error_mapper.dart`;
  `lib/features/auth/presentation/auth_providers.dart`, `auth_fields.dart`,
  `register_screen.dart`, `forgot_password_screen.dart`, `email_verification_screen.dart`.
- `lib/features/profile/domain/developer_profile.dart`, `profile_repository.dart`, `profile_completion.dart`;
  `lib/features/profile/data/firestore_profile_repository.dart`, `profile_mapper.dart`;
  `lib/features/profile/presentation/profile_providers.dart`, `profile_form.dart`, `unsaved_profile_dialog.dart`.
- `firestore.rules`.
- `test/validators_test.dart`, `profile_model_test.dart`, `auth_provider_test.dart`,
  `profile_provider_test.dart`, `route_guard_test.dart`, `auth_widget_test.dart`,
  `profile_widget_test.dart`, `test/support/fakes.dart`, `test/support/app_harness.dart`.

Изменены:

- `lib/app/app.dart`, `lib/app/di/dependencies.dart`,
  `lib/app/router/app_router.dart`, `lib/app/router/route_names.dart`.
- `lib/features/auth/presentation/login_screen.dart`, `splash_screen.dart`;
  `lib/features/home/presentation/home_screen.dart`;
  `lib/features/profile/presentation/profile_screen.dart`;
  `lib/features/settings/presentation/settings_screen.dart`.
- `pubspec.yaml`, `pubspec.lock`, `firebase.json`, `README.md`, `test/app_test.dart`.

Остальные существующие тесты сохранены. Firebase options, main.dart, DioClient,
LocalCacheService и ThemeController не дублируются и не переписываются.
