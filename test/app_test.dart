import 'package:devcv/app/app.dart';
import 'package:devcv/features/settings/data/preferences_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Splash opens Login and Home links open each screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repository = PreferencesSettingsRepository(
      await SharedPreferences.getInstance(),
    );
    await tester.pumpWidget(
      ProviderScope(child: DevCvApp(settingsRepository: repository)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
    await tester.tap(find.text('Explore DevCV'));
    await tester.pumpAndSettle();
    expect(find.text('Developer Profile & Resume Builder'), findsOneWidget);

    for (final title in ['Profile', 'Resume', 'Settings']) {
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, title), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
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

    Future<void> launch() async {
      await tester.pumpWidget(
        ProviderScope(child: DevCvApp(settingsRepository: repository)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Explore DevCV'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
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
