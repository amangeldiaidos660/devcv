import 'package:shared_preferences/shared_preferences.dart';

import '../domain/settings_repository.dart';

class PreferencesSettingsRepository implements SettingsRepository {
  PreferencesSettingsRepository(this._preferences);

  static const _darkModeKey = 'dark_mode';
  final SharedPreferences _preferences;

  @override
  bool get isDarkMode => _preferences.getBool(_darkModeKey) ?? false;

  @override
  Future<void> setDarkMode(bool value) async {
    final saved = await _preferences.setBool(_darkModeKey, value);
    if (!saved) {
      throw StateError('Could not save theme preference.');
    }
  }
}
