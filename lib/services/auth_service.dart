import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';

class AuthService {
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';
  static const String _userProfileKey = 'user_profile';
  static const String _isOfflineUserKey = 'is_offline_user';
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Check if user has seen onboarding
  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenOnboardingKey) ?? false;
  }

  // Mark onboarding as seen
  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, true);
  }

  // Check if user is logged in (online or offline)
  Future<bool> isLoggedIn() async {
    try {
      final box = await Hive.openBox('user_profile');
      return box.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get current user profile
  Future<UserProfile?> getCurrentUser() async {
    try {
      final box = await Hive.openBox('user_profile');
      final userData = box.get(_userProfileKey);
      if (userData != null) {
        return UserProfile.fromJson(Map<String, dynamic>.from(userData));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Save user profile locally
  Future<void> saveUserProfile(UserProfile user) async {
    try {
      final box = await Hive.openBox('user_profile');
      await box.put(_userProfileKey, user.toJson());
      
      // Also save in SharedPreferences for quick access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isOfflineUserKey, user.isOfflineUser);
    } catch (e) {
      throw Exception('Failed to save user profile: $e');
    }
  }

  // Google Sign In
  Future<UserProfile?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User cancelled sign in
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final user = UserProfile.fromGoogle(
        id: googleUser.id,
        name: googleUser.displayName ?? 'User',
        email: googleUser.email,
        profileImageUrl: googleUser.photoUrl,
      );

      await saveUserProfile(user);
      return user;
    } catch (e) {
      // Return null instead of throwing to handle gracefully
      return null;
    }
  }

  // Apple Sign In (placeholder for future implementation)
  Future<UserProfile?> signInWithApple() async {
    // TODO: Implement Apple Sign In
    // For now, return null to indicate not implemented
    throw UnimplementedError('Apple Sign In not implemented yet');
  }

  // University Email Sign In (placeholder for future implementation)
  Future<UserProfile?> signInWithUniversityEmail({
    required String email,
    required String password,
  }) async {
    // TODO: Implement University Email Sign In
    // For now, return null to indicate not implemented
    throw UnimplementedError('University Email Sign In not implemented yet');
  }

  // Create offline user
  Future<UserProfile> createOfflineUser({
    required String name,
    required String course,
    required String year,
  }) async {
    final user = UserProfile.offline(
      name: name,
      course: course,
      year: year,
    );

    await saveUserProfile(user);
    return user;
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Clear local data
      final box = await Hive.openBox('user_profile');
      await box.clear();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isOfflineUserKey);
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Check if user is offline
  Future<bool> isOfflineUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isOfflineUserKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserProfile updatedUser) async {
    await saveUserProfile(updatedUser);
  }

  // Check if user profile is complete
  Future<bool> isProfileComplete() async {
    final user = await getCurrentUser();
    return user?.isComplete ?? false;
  }

  // Reset onboarding (for testing)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasSeenOnboardingKey);
  }

  // Clear all user data (for testing)
  Future<void> clearAllData() async {
    await signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

