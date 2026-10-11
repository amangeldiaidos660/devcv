# DevCV

Developer Profile & Resume Builder для Android и iOS.
Application ID: `kz.aidos.devcv`. Firebase project: `devcv-ac143`.
Минимальные версии: Android API 24 и iOS 15.

## Реализованный MVP

Существующие Email/Password, verification, Google Sign-In, password reset, logout и auth guards сохранены.
Home показывает приветствие, заполнение профиля, статистику и переход к созданию резюме.
Profile содержит карточки основной информации, контактов, опыта, образования,
проектов, сертификатов, навыков, языков, предпочтений и текста «О себе».

- Контакты: email из Auth, телефон, GitHub, LinkedIn, Telegram, сайт; видимость в резюме и максимум два preferred contacts.
- Фото необязательно: в текущем режиме Spark показываются инициалы, загрузка отключена, Profile → Resume → PDF работает без Storage.
- CRUD шести типов записей: отдельные формы, подтверждение удаления, loading/error/empty/data.
- Рабочий проект требует существующий опыт. Удаление связанного опыта через приложение блокируется до изменения/удаления проектов.
- Навыки вводятся вручную, отображаются chips и группируются по семи категориям. Языки: A1–C2 и Native.
- Предпочтения: формат и занятость, зарплата, валюта KZT по умолчанию, переезд, командировки.
- «О себе»: максимум 500 символов.
- Resume Builder: позиция → разделы → конкретные элементы → A4 Preview → сохранение PDF.
- Последнюю конфигурацию можно продолжить; PDF использует актуальные записи профиля, сохраняя выбор ID.

Общие AppCard, SectionCard, кнопки, поля, chips, loading/empty states и карточки заполнения
находятся в `lib/core/widgets/app_components.dart`. Material 3 использует палитру
`#0C0C0D`, `#3F3F41`, `#F3F3F6`, `#868081`, `#FA4D2B`, `#DAB9AF`.
Provider + SharedPreferences сохраняют тему; обе темы доступны в Settings.
Wizard использует AnimatedSwitcher, Preview — fade/scale.

## Архитектура и модели

Clean Architecture и существующие GetIt, Riverpod, Provider, Hive и Dio переиспользуются.
Domain не импортирует Firebase, Flutter или Hive. Firebase вызывается в data layer.

| Часть | Ответственность |
| --- | --- |
| profile/domain | DeveloperProfile, ProfileContacts, CareerPreferences, WorkExperience, Education, Project, Certificate, Skill, Language; валидация и заполнение |
| profile/data | ProfileMapper/DetailsMapper/EntryMapper; FirestoreProfileRepository, FirestoreEntryRepository, FirebaseAvatarRepository |
| profile/presentation | Riverpod streams/actions; обзор, формы и списки |
| resume/domain | ResumeConfig, ResumeDocument; контракты конфигурации, генерации и сохранения PDF |
| resume/data | FirestoreResumeRepository, ResumePdfService, NativeResumeExporter |
| resume/presentation | Riverpod draft/config/preview/actions; wizard, Preview и export |
| app/di | GetIt регистрации Repository, image picker, PDF generator и exporter |

Один EntryRepository обслуживает шесть типизированных списков без шести одинаковых реализаций.
ProfileRepository расширен updateDetails; сохранение основной информации не стирает новые разделы.
Потоки Firestore автоматически обновляют списки после add/edit/delete.
Двойное сохранение блокируется; при выходе из изменённой формы требуется подтверждение.

## Firestore и Storage

```text
users/{uid}
  uid, fullName, birthDate, city, email, createdAt, updatedAt
  contacts: phone, githubUrl, linkedinUrl, telegram, website, visible[], preferred[]
  preferences: workModes[], employmentTypes[], salaryEnabled, minimumSalary,
               currency, relocation, businessTrips
  aboutMe, avatarUrl, avatarPath
  experiences/{id}
  education/{id}
  projects/{id}
  certificates/{id}
  skills/{id}
  languages/{id}
  resumeConfigs/default
```

Повторяющиеся записи находятся в subcollections. ID берётся из document ID;
createdAt/updatedAt задаются сервером. Данные изолированы по UID.
ResumeConfig хранит position, includedSections, шесть списков выбранных ID, showPhoto, showSalary и updatedAt.
PDF в Firestore/Storage не загружается.

Фото: `users/{uid}/profile/avatar_{timestamp}.jpg` или `.png` в Firebase Storage.
Будущая поддержка сохранена, но отключена по умолчанию через `ENABLE_FIREBASE_STORAGE=false`.
В этом режиме GetIt использует DisabledAvatarRepository без обращения к FirebaseStorage.instance.
Home/Profile игнорируют старые avatarUrl, Builder отключает фото с пояснением,
а Preview игнорирует старый showPhoto и не создаёт Storage repository.
Даже после включения Storage ошибка чтения фото не блокирует PDF: документ создаётся без фотографии.
Включение позже, после настройки bucket и правил: `flutter run --dart-define=ENABLE_FIREBASE_STORAGE=true`.
При замене сначала загружается новое, затем обновляется профиль и удаляется старое.
Если обновление профиля не удалось, новое фото удаляется по возможности.
URL и Storage path сохраняются в собственном документе пользователя.

Hive general_cache хранит `profile:{uid}` и `resume:{uid}`.
Последняя конфигурация доступна из кэша при временной сетевой ошибке;
ошибка кэша не отменяет успешное серверное сохранение.
Firestore offline support сохранён. Полная offline-first синхронизация не реализована.
Пароли и OAuth tokens в Firestore/Hive не сохраняются.

## Заполнение и длительность опыта

| Раздел | Вес |
| --- | --- |
| Основная информация: имя, дата рождения, город | 20% |
| Контакты | 10% |
| Опыт | 20% |
| Образование | 10% |
| Навыки | 15% |
| Проекты | 10% |
| Языки | 5% |
| Предпочтения: формат и занятость | 5% |
| О себе | 5% |

Фото и сертификаты не обязательны для 100%. Заполнение меньше 100% не блокирует PDF.
Минимум для резюме: ФИО, позиция и один непустой контакт, видимый в резюме.

Периоды опыта отображаются с месяцем и годом, длительность — годами и месяцами.
Закрытый период включает последний месяц: август 2023 — январь 2024 = 6 месяцев.
Текущий опыт показывает прошедшие месяцы: май 2024 — октябрь 2025 = 1 год 5 месяцев.

## Маршруты

Public/auth и protected routes сохранены; нижняя навигация остаётся Home/Profile/Resume/Settings.
Новые формы и wizard открываются поверх shell без нижней навигации.

| Путь | Имя |
| --- | --- |
| /profile/basic | profileBasic |
| /profile/details/:section | profileDetails |
| /profile/entries/:kind | profileEntries |
| /profile/entries/:kind/add | entryAdd |
| /profile/entries/:kind/:id/edit | entryEdit |
| /resume/create | resumeCreate |
| /resume/preview | resumePreview |

`section`: contacts/preferences/about. `kind`: experience/education/project/certificate/skill/language.
Edit открывается из списка с записью в extra; внешние deep links в edit не предусмотрены.

## PDF и сохранение на Android

ResumePdfService локально создаёт один светлый A4-шаблон: белый фон, тёмный текст, акцент `#FA4D2B`.
Встроенные Noto Sans Regular/Bold поддерживают кириллицу и казахские символы; сеть для шрифтов не требуется.
Лицензия OFL приложена в `assets/fonts/LICENSE.txt`.

Порядок: Header → О себе → Предпочтения/зарплата → Опыт → Проекты → Навыки → Образование → Сертификаты → Языки.
Пустые значения и исключённые записи пропускаются. Длинные описания переносятся на следующие страницы.
Preview использует те же PDF bytes, которые передаются на сохранение.

NativeResumeExporter вызывает `FilePicker.saveFile` с bytes и MIME `application/pdf`.
На Android пользователь выбирает Downloads/Documents или другого доступного провайдера в системном диалоге.
После записи показывается «Резюме сохранено» и возвращённый URI; отмена не считается успехом.
URI может иметь вид `content://...`. Файл доступен в выбранной пользователем папке.
Имя: `DevCV_Имя_Фамилия_Позиция.pdf`, недопустимые символы удаляются.

Добавленные зависимости: image_picker 1.2.4, pdf 3.13.1, printing 5.15.1, file_picker 13.1.0.
В iOS Info.plist добавлено описание доступа к фотогалерее.

## Firebase: действия пользователя

1. В devcv-ac143 оставить настроенные Authentication и Firestore `(default)`.
2. На текущем Spark Storage настраивать не требуется: фото отключено.
3. Опубликовать правила Firestore из корня проекта:

```powershell
firebase deploy --only firestore:rules --project devcv-ac143
```

Можно вместо CLI вставить правила в соответствующие вкладки Rules Firebase Console.
Firestore Rules разрешают подтверждённому пользователю доступ только к своему документу и перечисленным subcollections,
проверяют поля, даты, timestamps, preferred contacts, зарплату и связь рабочего проекта с опытом.
Storage Rules разрешают собственные JPEG/PNG avatar-файлы меньше 5 МБ. Публичного allow true нет.
Эти правила сохранены для будущего включения Storage; сейчас их публикация не требуется.
После перехода на поддерживаемый план и настройки bucket их можно опубликовать через
`firebase deploy --only storage --project devcv-ac143`.
Публикация и проверка на реальном Firebase backend пользователем ещё требуются.
Без новых правил старые rules могут блокировать новые разделы.

Core/Auth/Firestore/Messaging/Storage/Crashlytics остаются подключены.
Автоматические FCM initialization и сбор Crashlytics по-прежнему отключены.
Работающая Android Firebase/Auth конфигурация не заменялась.

Google Sign-In на iOS требует CLIENT_ID/REVERSED_CLIENT_ID в plist,
URL scheme в Info.plist и реальный CLIENT_ID через `--dart-define=GOOGLE_IOS_CLIENT_ID=...`.
iOS native flow проверяется на macOS с Xcode и подписью; Windows не позволяет подтвердить iOS сборку.

## Проверки и запуск пользователем

Проверки analyze/test выполняются после изменений; запуск на телефоне выполняет пользователь.
Переменные задают кэши на D для текущего окна PowerShell.

```powershell
Set-Location 'D:\Workspace\DevCV'
$env:PUB_CACHE = 'D:\Tools\Caches\pub'
$env:GRADLE_USER_HOME = 'D:\Tools\Caches\gradle'
flutter pub get
dart format .
flutter analyze
flutter test
flutter run -d RFGYB1HX2PV
```

Существующие тесты сохранены и адаптированы к отдельному экрану основной информации.
Новые mvp_domain_test, mvp_widget_test и resume_pdf_test проверяют длительность,
валидацию, зарплату, 500 символов, ссылку рабочего проекта на опыт, контакты,
weighted completion, ResumeConfig, актуальные записи, пустой список, форму опыта,
выбор записей, Preview, отмену сохранения и генерацию PDF bytes.
Widget tests используют fake repositories и fake printing platform без прямых запросов в Firebase.

После отключения Storage flutter analyze --no-pub завершился без замечаний.
Полный flutter test --no-pub прошёл: 40 тестов.
storage_optional_test и сценарий Spark в mvp_widget_test проверяют отсутствие Storage-вызовов,
отключённый пункт фото, старую конфигурацию showPhoto=true, Preview и export без фотографии.
resume_pdf_test дополнительно проверяет реальную генерацию PDF при выбранном, но отсутствующем фото.
Нативная сборка, Firebase CRUD и сохранение PDF на телефоне требуют ручной проверки.

Для демонстрационного PDF с фиктивными данными:

```powershell
flutter test test/resume_pdf_test.dart --dart-define=WRITE_PDF_SAMPLE=true
```

Результат: `output/pdf/DevCV-sample.pdf`. Контрольный A4-пример был визуально проверен на трёх страницах,
включая кириллицу, казахские символы и длинное описание опыта.

## Сценарий демонстрации и границы

Войти → Profile → основная информация → контакты → опыт/образование/проект/навыки/язык
→ предпочтения/о себе → Home → Создать резюме → позиция → разделы → элементы → Preview
→ Скачать PDF → выбрать папку → открыть файл через файловый менеджер.
Затем проверить данные собственного UID в Firebase Console и продолжение последней конфигурации.

Не добавлены AI, внешние API, Maps, push logic, DOCX, SMS verification, camera requirement,
файлы сертификатов, картинки проектов, несколько фото/шаблонов, cloud PDF, analytics и offline-синхронизация.
Release подпись Android остаётся существующей debug-подписью; публикация приложения в этом этапе не выполняется.
