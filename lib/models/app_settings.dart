import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 4)
class AppSettings {
  @HiveField(0)
  bool isDarkMode;

  @HiveField(1)
  String language;

  @HiveField(2)
  bool autoSync;

  @HiveField(3)
  bool enableNotifications;

  @HiveField(4)
  String defaultViewMode; // 'grid' or 'list'

  @HiveField(5)
  int maxRecentFiles;

  @HiveField(6)
  bool showFilePreview;

  @HiveField(7)
  String themeColor;

  @HiveField(8)
  String primaryColor;

  @HiveField(9)
  String secondaryColor;

  @HiveField(10)
  bool autoSave;

  @HiveField(11)
  int autoSaveInterval;

  @HiveField(12)
  DateTime lastBackup;

  @HiveField(13)
  bool showMotivationalQuotes;

  @HiveField(14)
  bool showStorageSummary;

  AppSettings({
    this.isDarkMode = true, // Changed default to true for dark mode
    this.language = 'en',
    this.autoSync = false,
    this.enableNotifications = true,
    this.defaultViewMode = 'grid',
    this.maxRecentFiles = 10,
    this.showFilePreview = true,
    this.themeColor = 'blue',
    this.primaryColor = '#3F51B5',
    this.secondaryColor = '#FFB300',
    this.autoSave = true,
    this.autoSaveInterval = 30,
    DateTime? lastBackup,
    this.showMotivationalQuotes = false,
    this.showStorageSummary = false,
  }) : lastBackup = lastBackup ?? DateTime.now();

  AppSettings copyWith({
    bool? isDarkMode,
    String? language,
    bool? autoSync,
    bool? enableNotifications,
    String? defaultViewMode,
    int? maxRecentFiles,
    bool? showFilePreview,
    String? themeColor,
    String? primaryColor,
    String? secondaryColor,
    bool? autoSave,
    int? autoSaveInterval,
    DateTime? lastBackup,
    bool? showMotivationalQuotes,
    bool? showStorageSummary,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
      autoSync: autoSync ?? this.autoSync,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      defaultViewMode: defaultViewMode ?? this.defaultViewMode,
      maxRecentFiles: maxRecentFiles ?? this.maxRecentFiles,
      showFilePreview: showFilePreview ?? this.showFilePreview,
      themeColor: themeColor ?? this.themeColor,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      autoSave: autoSave ?? this.autoSave,
      autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
      lastBackup: lastBackup ?? this.lastBackup,
      showMotivationalQuotes: showMotivationalQuotes ?? this.showMotivationalQuotes,
      showStorageSummary: showStorageSummary ?? this.showStorageSummary,
    );
  }

  @override
  String toString() {
    return 'AppSettings(isDarkMode: $isDarkMode, language: $language, autoSync: $autoSync)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings && 
           other.isDarkMode == isDarkMode &&
           other.language == language &&
           other.autoSync == autoSync;
  }

  @override
  int get hashCode => Object.hash(isDarkMode, language, autoSync);
}
