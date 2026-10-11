import 'package:devcv/features/settings/domain/settings_repository.dart';
import 'package:devcv/features/settings/presentation/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FailingSettingsRepository implements SettingsRepository {
  @override
  bool get isDarkMode => false;

  @override
  Future<void> setDarkMode(bool value) async {
    throw StateError('Storage unavailable');
  }
}

void main() {
  test('Failed persistence keeps the current theme and allows retry', () async {
    final controller = ThemeController(FailingSettingsRepository());
    addTearDown(controller.dispose);

    await expectLater(controller.setDarkMode(true), throwsStateError);
    expect(controller.themeMode, ThemeMode.light);
    expect(controller.isSaving, isFalse);
    await expectLater(controller.setDarkMode(true), throwsStateError);
  });
}
