import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uniflow/models/app_settings.dart';
import 'package:uniflow/models/app_file.dart';
import 'package:uniflow/models/note_model.dart';
import 'package:uniflow/models/pdf_annotation.dart';

class SettingsProvider extends ChangeNotifier {
  Box<AppSettings>? _settingsBox;
  AppSettings _settings = AppSettings();
  bool _isInitialized = false;

  AppSettings get settings => _settings;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    _settingsBox = Hive.box<AppSettings>('settings');
    _settings = _settingsBox!.get('app_settings') ?? AppSettings();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    if (!_isInitialized || _settingsBox == null) {
      await initialize();
    }
    _settings = newSettings;
    await _settingsBox?.put('app_settings', _settings);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    if (!_isInitialized) await initialize();
    final newSettings = _settings.copyWith(isDarkMode: !_settings.isDarkMode);
    await updateSettings(newSettings);
  }

  Future<void> updatePrimaryColor(String color) async {
    if (!_isInitialized) await initialize();
    final newSettings = _settings.copyWith(primaryColor: color);
    await updateSettings(newSettings);
  }

  Future<void> updateSecondaryColor(String color) async {
    if (!_isInitialized) await initialize();
    final newSettings = _settings.copyWith(secondaryColor: color);
    await updateSettings(newSettings);
  }

  Future<void> toggleAutoSave() async {
    if (!_isInitialized) await initialize();
    final newSettings = _settings.copyWith(autoSave: !_settings.autoSave);
    await updateSettings(newSettings);
  }

  Future<void> updateAutoSaveInterval(int interval) async {
    if (!_isInitialized) await initialize();
    final newSettings = _settings.copyWith(autoSaveInterval: interval);
    await updateSettings(newSettings);
  }

  Future<void> toggleFilePreview() async {
    if (!_isInitialized) await initialize();
    final newSettings = _settings.copyWith(showFilePreview: !_settings.showFilePreview);
    await updateSettings(newSettings);
  }

  Future<void> updateDefaultViewMode(String mode) async {
    final newSettings = _settings.copyWith(defaultViewMode: mode);
    await updateSettings(newSettings);
  }

  Future<void> toggleNotifications() async {
    final newSettings = _settings.copyWith(enableNotifications: !_settings.enableNotifications);
    await updateSettings(newSettings);
  }

  Future<void> toggleMotivationalQuotes() async {
    if (!_isInitialized) await initialize();
    final newSettings = _settings.copyWith(showMotivationalQuotes: !_settings.showMotivationalQuotes);
    await updateSettings(newSettings);
  }

  Future<void> toggleStorageSummary() async {
    if (!_isInitialized) await initialize();
    final newSettings = _settings.copyWith(showStorageSummary: !_settings.showStorageSummary);
    await updateSettings(newSettings);
  }

  Future<void> updateLanguage(String language) async {
    final newSettings = _settings.copyWith(language: language);
    await updateSettings(newSettings);
  }

  Future<void> clearAllData() async {
    try {
      // Clear all boxes
      await Hive.box<AppFile>('files').clear();
      await Hive.box<NoteModel>('notes').clear();
      await Hive.box<PdfAnnotation>('annotations').clear();
      
      // Reset settings to default
      _settings = AppSettings();
      await _settingsBox?.put('app_settings', _settings);
      notifyListeners();
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  @override
  void dispose() {
    _settingsBox?.close();
    super.dispose();
  }
}

