import 'package:devcv/app/app.dart';
import 'package:devcv/core/config/app_features.dart';
import 'package:devcv/features/auth/presentation/auth_providers.dart';
import 'package:devcv/features/profile/presentation/profile_providers.dart';
import 'package:devcv/features/settings/data/preferences_settings_repository.dart';
import 'package:devcv/features/profile/presentation/entry_providers.dart';
import 'package:devcv/features/profile/presentation/details_providers.dart';
import 'package:devcv/features/resume/presentation/resume_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

Finder field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> pumpDevCv(
  WidgetTester tester,
  FakeAuthRepository auth,
  FakeProfileRepository profiles, {
  FakeEntryRepository? entries,
  FakeResumeRepository? resumes,
  FakeAvatarRepository? avatars,
  FakePdfGenerator? pdf,
  FakeResumeExporter? exporter,
  bool photosEnabled = false,
}) async {
  final entryRepo = entries ?? FakeEntryRepository();
  addTearDown(entryRepo.dispose);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
  SharedPreferences.setMockInitialValues({});
  final repository = PreferencesSettingsRepository(
    await SharedPreferences.getInstance(),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        profileRepositoryProvider.overrideWithValue(profiles),
        entryRepositoryProvider.overrideWithValue(entryRepo),
        profilePhotosEnabledProvider.overrideWithValue(photosEnabled),
        avatarRepositoryProvider.overrideWithValue(
          avatars ?? FakeAvatarRepository(),
        ),
        resumeConfigRepositoryProvider.overrideWithValue(
          resumes ?? FakeResumeRepository(),
        ),
        resumePdfGeneratorProvider.overrideWithValue(pdf ?? FakePdfGenerator()),
        resumeExporterProvider.overrideWithValue(
          exporter ?? FakeResumeExporter(),
        ),
      ],
      child: DevCvApp(settingsRepository: repository),
    ),
  );
}

Future<void> openBasic(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Основная информация'),
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(find.text('Основная информация'));
  await tester.pumpAndSettle();
}

Future<void> logIn(WidgetTester tester) async {
  await tester.enterText(field('Email'), 'dev@example.com');
  await tester.enterText(field('Пароль'), 'password123');
  await tester.tap(find.text('Войти'));
  await tester.pumpAndSettle();
}

Future<void> openTab(WidgetTester tester, String title) async {
  await tester.tap(find.widgetWithText(NavigationDestination, title));
  await tester.pumpAndSettle();
}
