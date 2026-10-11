import 'package:flutter/material.dart';

import '../domain/settings_repository.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._repository) : _isDarkMode = _repository.isDarkMode;

  final SettingsRepository _repository;
  bool _isDarkMode;
  bool _isSaving = false;

  bool get isDarkMode => _isDarkMode;
  bool get isSaving => _isSaving;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> setDarkMode(bool value) async {
    if (_isSaving || value == _isDarkMode) return;
    _isSaving = true;
    notifyListeners();
    try {
      await _repository.setDarkMode(value);
      _isDarkMode = value;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
