import 'package:devcv/app/app.dart';
import 'package:devcv/features/auth/presentation/auth_providers.dart';
import 'package:devcv/features/profile/presentation/profile_providers.dart';
import 'package:devcv/features/settings/data/preferences_settings_repository.dart';
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
  FakeProfileRepository profiles,
) async {
  SharedPreferences.setMockInitialValues({});
  final repository = PreferencesSettingsRepository(
    await SharedPreferences.getInstance(),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        profileRepositoryProvider.overrideWithValue(profiles),
      ],
      child: DevCvApp(settingsRepository: repository),
    ),
  );
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
