import 'package:hive/hive.dart';
import '../models/user_profile.dart';

class HiveAdapters {
  static Future<void> registerAdapters() async {
    // Register UserProfile adapter
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserProfileAdapter());
    }
  }
}

