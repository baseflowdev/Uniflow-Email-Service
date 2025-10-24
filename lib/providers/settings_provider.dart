import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uniflow/models/app_settings.dart';
import 'package:uniflow/models/file_model.dart';
import 'package:uniflow/models/note_model.dart';
import 'package:uniflow/models/pdf_annotation.dart';

class SettingsProvider extends ChangeNotifier {
  late Box<AppSettings> _settingsBox;
  AppSettings _settings = AppSettings();

  AppSettings get settings => _settings;

  Future<void> initialize() async {
    _settingsBox = Hive.box<AppSettings>('settings');
    _settings = _settingsBox.get('app_settings') ?? AppSettings();
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await _settingsBox.put('app_settings', _settings);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    final newSettings = _settings.copyWith(isDarkMode: !_settings.isDarkMode);
    await updateSettings(newSettings);
  }

  Future<void> updatePrimaryColor(String color) async {
    final newSettings = _settings.copyWith(primaryColor: color);
    await updateSettings(newSettings);
  }

  Future<void> updateSecondaryColor(String color) async {
    final newSettings = _settings.copyWith(secondaryColor: color);
    await updateSettings(newSettings);
  }

  Future<void> toggleAutoSave() async {
    final newSettings = _settings.copyWith(autoSave: !_settings.autoSave);
    await updateSettings(newSettings);
  }

  Future<void> updateAutoSaveInterval(int interval) async {
    final newSettings = _settings.copyWith(autoSaveInterval: interval);
    await updateSettings(newSettings);
  }

  Future<void> toggleFilePreview() async {
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

  Future<void> updateLanguage(String language) async {
    final newSettings = _settings.copyWith(language: language);
    await updateSettings(newSettings);
  }

  Future<void> clearAllData() async {
    try {
      // Clear all boxes
      await Hive.box<FileModel>('files').clear();
      await Hive.box<NoteModel>('notes').clear();
      await Hive.box<PdfAnnotation>('annotations').clear();
      
      // Reset settings to default
      _settings = AppSettings();
      await _settingsBox.put('app_settings', _settings);
      notifyListeners();
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  @override
  void dispose() {
    _settingsBox.close();
    super.dispose();
  }
}

