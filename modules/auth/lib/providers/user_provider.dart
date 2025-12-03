import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserProfile? _currentUser;
  bool _isLoading = false;
  bool _hasSeenOnboarding = false;
  String? _error;
  String? _googleOnlyAccountEmail; // Store email for Google-only accounts

  // Getters
  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  String? get error => _error;
  String? get googleOnlyAccountEmail => _googleOnlyAccountEmail;
  bool get isLoggedIn => _currentUser != null;
  bool get isOfflineUser => _currentUser?.isOfflineUser ?? false;
  bool get isProfileComplete => _currentUser?.isComplete ?? false;

  // Initialize the provider
  Future<void> initialize() async {
    try {
      // Check if user has seen onboarding
      _hasSeenOnboarding = await _authService.hasSeenOnboarding();
      
      // Check if user is logged in
      if (await _authService.isLoggedIn()) {
        _currentUser = await _authService.getCurrentUser();
      }
      
      _clearError();
    } catch (e) {
      _setError('Failed to initialize: $e');
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      }
      _setError('Google sign in was cancelled');
      return false;
    } catch (e) {
      // Handle account linking required exception
      if (e.toString().contains('AccountLinkingRequiredException') || 
          e.toString().contains('account already exists with email/password')) {
        _setError('An account with this email already exists. Please sign in with your password first, then you can link your Google account.');
        return false;
      }
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      _setError('Google sign in failed: $errorMessage');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign up with email and password
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );
      _currentUser = user;
      notifyListeners();
      return true;
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      _setError('Sign up failed: $errorMessage');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with email and password
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      _currentUser = user;
      notifyListeners();
      return true;
    } catch (e) {
      // Handle Google-only account exception
      if (e is GoogleOnlyAccountException) {
        // Store the exception email so UI can access it
        _googleOnlyAccountEmail = e.email;
        _setError(e.message);
        notifyListeners();
        return false;
      }
      if (e.toString().contains('GoogleOnlyAccountException') || 
          e.toString().contains('registered with Google Sign-In')) {
        _setError('This email is registered with Google Sign-In. Log in with Google, or set a password.');
        return false;
      }
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      _setError('Sign in failed: $errorMessage');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Link Google account to existing email/password account
  Future<bool> linkGoogleAccount() async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.linkGoogleAccount();
      // Reload user profile after linking
      _currentUser = await _authService.getCurrentUser();
      notifyListeners();
      return true;
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      _setError('Failed to link Google account: $errorMessage');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      _setError('Failed to send password reset email: $errorMessage');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Generate password setup token for Google-only accounts
  Future<String?> generatePasswordSetupToken(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      final token = await _authService.generatePasswordSetupToken(email);
      return token;
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      _setError('Failed to generate password setup token: $errorMessage');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Set password for Google-only account
  Future<bool> setPasswordForGoogleAccount({
    required String email,
    required String password,
    required String token,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.setPasswordForGoogleAccount(
        email: email,
        newPassword: password,
        token: token,
      );
      return true;
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      _setError('Failed to set password: $errorMessage');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with Apple
  Future<bool> signInWithApple() async {
    _setLoading(true);
    _clearError();
    
    try {
      final user = await _authService.signInWithApple();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Apple sign in failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with University Email
  Future<bool> signInWithUniversityEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final user = await _authService.signInWithUniversityEmail(
        email: email,
        password: password,
      );
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('University email sign in failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Create offline user
  Future<bool> createOfflineUser({
    required String name,
    required String course,
    required String year,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final user = await _authService.createOfflineUser(
        name: name,
        course: course,
        year: year,
      );
      _currentUser = user;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create offline user: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(UserProfile updatedUser) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.updateUserProfile(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError('Sign out failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Mark onboarding as seen
  Future<void> markOnboardingSeen() async {
    try {
      await _authService.markOnboardingSeen();
      _hasSeenOnboarding = true;
      notifyListeners();
    } catch (e) {
      _setError('Failed to mark onboarding as seen: $e');
    }
  }

  // Reset onboarding (for testing)
  Future<void> resetOnboarding() async {
    try {
      await _authService.resetOnboarding();
      _hasSeenOnboarding = false;
      notifyListeners();
    } catch (e) {
      _setError('Failed to reset onboarding: $e');
    }
  }

  // Clear all data (for testing)
  Future<void> clearAllData() async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.clearAllData();
      _currentUser = null;
      _hasSeenOnboarding = false;
      notifyListeners();
    } catch (e) {
      _setError('Failed to clear data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    _googleOnlyAccountEmail = null;
    notifyListeners();
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }
}

