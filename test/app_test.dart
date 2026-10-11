import 'package:devcv/app/app.dart';
import 'package:devcv/features/auth/presentation/auth_providers.dart';
import 'package:devcv/features/profile/presentation/profile_providers.dart';
import 'package:devcv/features/settings/data/preferences_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/app_harness.dart';
import 'support/fakes.dart';

void main() {
  testWidgets('Splash opens Login and Home links open each screen', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    final profiles = FakeProfileRepository();
    addTearDown(auth.dispose);
    addTearDown(profiles.dispose);
    await pumpDevCv(tester, auth, profiles);
    await tester.pumpAndSettle();
    expect(find.text('Войти в DevCV'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await logIn(tester);
    expect(find.text('Developer Profile & Resume Builder'), findsOneWidget);
    for (final title in ['Профиль', 'Резюме', 'Настройки']) {
      await openTab(tester, title);
      expect(find.byType(NavigationBar), findsOneWidget);
      await openTab(tester, 'Главная');
      expect(find.text('Developer Profile & Resume Builder'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings changes theme and restores it after app recreation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = PreferencesSettingsRepository(preferences);
    final auth = FakeAuthRepository(user: verifiedUser);
    final profiles = FakeProfileRepository();
    addTearDown(auth.dispose);
    addTearDown(profiles.dispose);
    Future<void> launch() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
            profileRepositoryProvider.overrideWithValue(profiles),
          ],
          child: DevCvApp(settingsRepository: repository),
        ),
      );
      await tester.pumpAndSettle();
      await openTab(tester, 'Настройки');
    }

    await launch();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    await preferences.reload();
    expect(repository.isDarkMode, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await launch();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(repository.isDarkMode, isFalse);
    expect(tester.takeException(), isNull);
  });
}
