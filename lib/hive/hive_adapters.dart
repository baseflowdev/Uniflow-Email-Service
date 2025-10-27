import 'package:hive/hive.dart';
import '../models/user_profile.dart';
import '../models/app_file.dart';
import '../models/app_folder.dart';
import '../models/note_model.dart';
import '../models/app_settings.dart';
import '../models/pdf_annotation.dart';

class HiveAdapters {
  static Future<void> registerAdapters() async {
    // Register UserProfile adapter
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserProfileAdapter());
    }
    
    // Register AppFile adapter
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(AppFileAdapter());
    }
    
    // Register AppFolder adapter
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(AppFolderAdapter());
    }
    
    // Register NoteModel adapter
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(NoteModelAdapter());
    }
    
    // Register AppSettings adapter
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }
    
    // Register PdfAnnotation adapter
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(PdfAnnotationAdapter());
    }
    
    // Open all required boxes
    await Hive.openBox<AppFile>('files');
    await Hive.openBox<AppFolder>('folders');
    await Hive.openBox<NoteModel>('notes');
    await Hive.openBox<AppSettings>('settings');
    await Hive.openBox<PdfAnnotation>('annotations');
  }
}

