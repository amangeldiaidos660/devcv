abstract interface class SettingsRepository {
  bool get isDarkMode;

  Future<void> setDarkMode(bool value);
}
