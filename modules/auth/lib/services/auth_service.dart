import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user_profile.dart';
import 'email_config.dart';

// Custom exception for account linking
class AccountLinkingRequiredException implements Exception {
  final String message;
  final String email;
  
  AccountLinkingRequiredException(this.message, {required this.email});
  
  @override
  String toString() => message;
}

// Custom exception for Google-only accounts
class GoogleOnlyAccountException implements Exception {
  final String message;
  final String email;
  
  GoogleOnlyAccountException(this.message, {required this.email});
  
  @override
  String toString() => message;
}

class AuthService {
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';
  static const String _userProfileKey = 'user_profile';
  static const String _isOfflineUserKey = 'is_offline_user';
  static const String _resetCodesKey = 'reset_codes';
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Server client ID is required for Firebase to get idToken
    // This should be the Web client ID from Firebase Console
    serverClientId: '532332852814-83glcc2ulidg747sdgtv54eqhisop965.apps.googleusercontent.com',
  );
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  
  // Backend API URL
  String get _backendUrl => EmailConfig.backendApiUrl;

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
      // Check Firebase Auth first
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        return true;
      }
      
      // Fallback to local check (for offline users)
      final box = await Hive.openBox('user_profile');
      return box.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get current user profile
  Future<UserProfile?> getCurrentUser() async {
    try {
      // Check Firebase Auth first
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        // Try to load from backend
        try {
          final token = await firebaseUser.getIdToken();
          final response = await http.get(
            Uri.parse('$_backendUrl/api/users/me'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['success'] == true && data['user'] != null) {
              final user = UserProfile.fromJson(data['user']);
              await saveUserProfile(user);
              return user;
            }
          }
        } catch (e) {
          print('Error loading from backend: $e');
        }
      }
      
      // Fallback to local storage
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

  // Google Sign In with Firebase Auth + Backend API
  // ✅ Case 1: If email exists with password → Links Google to existing account
  // ✅ Case 2: If email exists with Google only → Normal login
  // ✅ Case 3: If new email → Creates new account
  Future<UserProfile?> signInWithGoogle() async {
    try {
      print('🔵 Starting Google Sign-In...');
      
      // First, sign out any existing Google Sign-In session to ensure a fresh start
      try {
        await _googleSignIn.signOut();
        print('🔵 Signed out from any existing Google Sign-In session');
      } catch (e) {
        print('⚠️ Warning: Could not sign out from Google Sign-In: $e');
        // Continue anyway
      }
      
      // 1. Authenticate with Google (client-side)
      print('🔵 Requesting Google Sign-In...');
      GoogleSignInAccount? googleUser;
      
      try {
        googleUser = await _googleSignIn.signIn();
        print('🔵 Google sign-in result: ${googleUser != null ? "Success" : "User cancelled"}');
      } catch (e) {
        print('❌ Error during Google Sign-In: $e');
        throw Exception('Google Sign-In failed: ${e.toString()}');
      }
      
      if (googleUser == null) {
        print('❌ Google sign-in was cancelled by user');
        return null; // User cancelled sign in
      }

      final googleEmail = googleUser.email?.toLowerCase();
      if (googleEmail == null) {
        print('❌ Google account does not have an email address');
        throw Exception('Google account does not have an email address');
      }
      
      print('✅ Google account email: $googleEmail');

      // 2. Check if email exists with password (before attempting sign-in)
      List<String> existingSignInMethods = [];
      try {
        existingSignInMethods = await _firebaseAuth.fetchSignInMethodsForEmail(googleEmail);
        print('🔵 Existing sign-in methods: $existingSignInMethods');
      } catch (e) {
        // Email doesn't exist yet, will create new account
        print('Email not found in Firebase, will create new account: $e');
      }

      // 3. Get Google authentication credentials
      print('🔵 Getting Google authentication credentials...');
      GoogleSignInAuthentication googleAuth;
      
      try {
        googleAuth = await googleUser.authentication;
        print('🔵 Authentication object received');
      } catch (e) {
        print('❌ Error getting Google authentication: $e');
        throw Exception('Failed to get Google authentication credentials: ${e.toString()}');
      }
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('❌ Google authentication tokens are null');
        print('   accessToken: ${googleAuth.accessToken != null ? "present" : "null"}');
        print('   idToken: ${googleAuth.idToken != null ? "present" : "null"}');
        throw Exception('Failed to get Google authentication tokens');
      }
      
      print('✅ Google authentication tokens received');
      
      // 4. Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      UserCredential userCredential;
      User? firebaseUser;
      
      // 5. Attempt Google sign-in (Firebase will handle linking if email matches)
      print('🔵 Signing in to Firebase with Google credential...');
      try {
        userCredential = await _firebaseAuth.signInWithCredential(credential);
        firebaseUser = userCredential.user;
        print('✅ Firebase sign-in successful. User ID: ${firebaseUser?.uid}');
      } on FirebaseAuthException catch (e) {
        print('❌ Firebase Auth error: ${e.code} - ${e.message}');
        if (e.code == 'account-exists-with-different-credential') {
          // Case 1: Email exists with password but not Google
          // Firebase requires user to sign in with password first, then link
          // We'll throw a special exception that the UI can handle
          throw AccountLinkingRequiredException(
            'An account with this email already exists with email/password. '
            'Please sign in with your password first, then you can link your Google account.',
            email: googleEmail,
          );
        }
        rethrow;
      } catch (e) {
        print('❌ Error signing in to Firebase: $e');
        rethrow;
      }
      
      if (firebaseUser == null) {
        print('❌ Firebase user is null after sign-in');
        throw Exception('Firebase authentication failed');
      }

      // 6. Get Firebase ID token for backend authentication
      print('🔵 Getting Firebase ID token...');
      final token = await firebaseUser.getIdToken();
      print('✅ Firebase ID token received');

      // 7. Check if user profile exists in backend, create if not
      UserProfile user;
      
      try {
        print('🔵 Checking backend for existing user profile...');
        // Try to get existing profile from backend
        final getResponse = await http.get(
          Uri.parse('$_backendUrl/api/users/me'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        
        print('🔵 Backend response status: ${getResponse.statusCode}');
        
        if (getResponse.statusCode == 200) {
          final data = json.decode(getResponse.body);
          if (data['success'] == true && data['user'] != null) {
            // Existing user - load from backend
            print('✅ Existing user found in backend');
            user = UserProfile.fromJson(data['user']);
          } else {
            print('⚠️ User not found in backend, will create new profile');
            throw Exception('User not found');
          }
        } else {
          print('⚠️ Backend returned status ${getResponse.statusCode}, will create new profile');
          throw Exception('Failed to get user');
        }
      } catch (e) {
        // User doesn't exist in backend - create new profile
        print('🔵 Creating new user profile...');
        user = UserProfile.fromGoogle(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? googleUser.displayName ?? 'User',
          email: firebaseUser.email ?? googleUser.email,
          profileImageUrl: firebaseUser.photoURL ?? googleUser.photoUrl,
        );
        
        // Save to backend
        try {
          print('🔵 Saving user profile to backend...');
          final createResponse = await http.post(
            Uri.parse('$_backendUrl/api/users'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(user.toJson()),
          );
          
          print('🔵 Backend create response status: ${createResponse.statusCode}');
          
          if (createResponse.statusCode != 200 && createResponse.statusCode != 201) {
            print('⚠️ Warning: Failed to save user to backend: ${createResponse.body}');
            // Continue anyway - will save locally
          } else {
            print('✅ User profile saved to backend');
          }
        } catch (e) {
          print('⚠️ Warning: Backend save failed: $e');
          // Continue - will save locally
        }
      }
      
      // 8. Save locally for offline access
      print('🔵 Saving user profile locally...');
      await saveUserProfile(user);
      print('✅ User profile saved locally');
      print('✅ Google Sign-In completed successfully!');
      
      return user;
    } on AccountLinkingRequiredException {
      print('⚠️ Account linking required');
      rethrow;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Google Sign-In error: ${e.code} - ${e.message}');
      throw Exception('Google Sign-In failed: ${e.message}');
    } catch (e) {
      print('❌ Google Sign-In error: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');
      throw Exception('Google Sign-In failed: ${e.toString()}');
    }
  }

  // Sign up with email and password (Firebase Auth + Backend)
  Future<UserProfile> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // 1. Create Firebase Auth account
      // ✅ Firebase Auth automatically prevents duplicate emails!
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.toLowerCase(),
        password: password,
      );
      
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to create user account');
      }

      // 2. Get Firebase ID token
      final token = await firebaseUser.getIdToken();

      // 3. Create user profile
      final user = UserProfile(
        id: firebaseUser.uid,
        name: name,
        email: email.toLowerCase(),
        course: 'Not specified',
        year: 'Not specified',
        isOfflineUser: false,
        createdAt: DateTime.now(),
      );

      // 4. Save to backend
      try {
        final response = await http.post(
          Uri.parse('$_backendUrl/api/users'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(user.toJson()),
        );
        
        if (response.statusCode != 200 && response.statusCode != 201) {
          print('Warning: Failed to save user to backend: ${response.body}');
          // Continue anyway - will save locally
        }
      } catch (e) {
        print('Warning: Backend save failed: $e');
        // Continue - will save locally
      }

      // 5. Save locally for offline access
      await saveUserProfile(user);

      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('An account with this email already exists');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email address');
      } else if (e.code == 'weak-password') {
        throw Exception('Password is too weak');
      }
      throw Exception('Sign up failed: ${e.message}');
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  // Sign in with email and password (Firebase Auth + Backend)
  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('🔵 Starting Email Sign-In for: ${email.toLowerCase()}');
      
      // 0. Check what sign-in methods are available for this email (optional check)
      // Note: fetchSignInMethodsForEmail may return empty array even for existing accounts
      // So we'll try sign-in first and handle errors appropriately
      try {
        print('🔵 Checking sign-in methods for email...');
        final signInMethods = await _firebaseAuth.fetchSignInMethodsForEmail(email.toLowerCase());
        print('🔵 Available sign-in methods: $signInMethods');
        
        // Only throw exception if we have sign-in methods AND password is not one of them
        if (signInMethods.isNotEmpty && !signInMethods.contains('password')) {
          // Case 2b: Account exists but only with Google (no password set)
          if (signInMethods.contains('google.com')) {
            print('⚠️ Account exists but only with Google Sign-In');
            throw GoogleOnlyAccountException(
              'This email is registered with Google Sign-In. Log in with Google, or set a password.',
              email: email.toLowerCase(),
            );
          } else {
            print('⚠️ Account exists with different sign-in method: $signInMethods');
            throw Exception('This account was created with a different sign-in method. Please use the original sign-in method.');
          }
        }
        
        // If signInMethods is empty, account might not exist OR it's a Google-only account
        // We'll let Firebase handle the sign-in attempt and catch errors appropriately
        if (signInMethods.isEmpty) {
          print('⚠️ No sign-in methods found - account may not exist or may be Google-only');
        } else {
          print('✅ Account has password sign-in method available');
        }
      } catch (e) {
        // If it's our custom exception, rethrow it
        if (e is GoogleOnlyAccountException) {
          rethrow;
        }
        // If it's a generic exception about sign-in methods, rethrow
        if (e.toString().contains('Google Sign-In') || e.toString().contains('different sign-in method')) {
          rethrow;
        }
        // Otherwise, continue with sign-in attempt (email might not exist yet)
        print('⚠️ Could not check sign-in methods, continuing with sign-in attempt: $e');
      }

      // 1. Sign in to Firebase Auth
      print('🔵 Attempting Firebase email/password sign-in...');
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.toLowerCase(),
        password: password,
      );
      print('✅ Firebase email/password sign-in successful');
      
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        print('❌ Firebase user is null after sign-in');
        throw Exception('Sign in failed');
      }
      print('✅ Firebase user obtained. User ID: ${firebaseUser.uid}');

      // 2. Get Firebase ID token
      print('🔵 Getting Firebase ID token...');
      final token = await firebaseUser.getIdToken();
      print('✅ Firebase ID token received');

      // 3. Load profile from backend
      print('🔵 Checking backend for existing user profile...');
      try {
        final response = await http.get(
          Uri.parse('$_backendUrl/api/users/me'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        
        print('🔵 Backend response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true && data['user'] != null) {
            print('✅ Existing user found in backend');
            final user = UserProfile.fromJson(data['user']);
            await saveUserProfile(user);
            print('✅ Email Sign-In completed successfully!');
            return user;
          }
        }
        print('⚠️ User not found in backend, will create new profile');
      } catch (e) {
        print('⚠️ Error loading from backend: $e');
        print('⚠️ Will create new profile');
      }

      // 4. Profile doesn't exist in backend - create basic one
      print('🔵 Creating new user profile...');
      final user = UserProfile(
        id: firebaseUser.uid,
        name: email.split('@')[0],
        email: email.toLowerCase(),
        course: 'Not specified',
        year: 'Not specified',
        isOfflineUser: false,
        createdAt: DateTime.now(),
      );
      
      // Try to save to backend
      try {
        print('🔵 Saving user profile to backend...');
        final createResponse = await http.post(
          Uri.parse('$_backendUrl/api/users'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(user.toJson()),
        );
        
        print('🔵 Backend create response status: ${createResponse.statusCode}');
        if (createResponse.statusCode == 200 || createResponse.statusCode == 201) {
          print('✅ User profile saved to backend');
        } else {
          print('⚠️ Warning: Failed to save user to backend: ${createResponse.body}');
        }
      } catch (e) {
        print('⚠️ Warning: Backend save failed: $e');
        // Continue - will save locally
      }
      
      print('🔵 Saving user profile locally...');
      await saveUserProfile(user);
      print('✅ User profile saved locally');
      print('✅ Email Sign-In completed successfully!');
      return user;
    } on GoogleOnlyAccountException {
      print('⚠️ Google-only account exception');
      rethrow;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error: ${e.code} - ${e.message}');
      
      if (e.code == 'user-not-found') {
        throw Exception('No account found with this email');
      } else if (e.code == 'wrong-password') {
        throw Exception('Incorrect password');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email address');
      } else if (e.code == 'user-disabled') {
        throw Exception('This account has been disabled');
      } else if (e.code == 'invalid-credential') {
        // This can happen if password is wrong OR account doesn't exist OR account is Google-only
        print('🔵 Invalid credential - checking if account exists with Google...');
        
        // Try to silently sign in with Google to check if account exists
        try {
          // First check sign-in methods
          final signInMethods = await _firebaseAuth.fetchSignInMethodsForEmail(email.toLowerCase());
          print('🔵 Sign-in methods found: $signInMethods');
          
          if (signInMethods.contains(GoogleAuthProvider.PROVIDER_ID) && !signInMethods.contains('password')) {
            // Account exists with Google only
            throw GoogleOnlyAccountException(
              'This email is registered with Google Sign-In. Log in with Google, or set a password.',
              email: email.toLowerCase(),
            );
          } else if (signInMethods.contains('password')) {
            // Account has password, so the password must be wrong
            throw Exception('Incorrect password');
          }
          
          // If sign-in methods is empty, it's likely a Google-only account
          // Firebase returns empty array for Google-only accounts (known quirk)
          // When we get invalid-credential with empty signInMethods, it's most likely:
          // 1. Google-only account (most common) - should show password setup dialog
          // 2. Account doesn't exist - but Firebase would return 'user-not-found' for that
          // 3. Account has password but Firebase returned empty (rare) - but Firebase would return 'wrong-password' for wrong password
          if (signInMethods.isEmpty) {
            print('🔵 Sign-in methods empty - likely Google-only account');
            // Try to verify by checking if account exists via silent Google sign-in
            try {
              final googleUser = await _googleSignIn.signInSilently();
              if (googleUser != null && googleUser.email?.toLowerCase() == email.toLowerCase()) {
                // User is signed in with Google and email matches - definitely Google-only
                print('✅ Verified: Account exists with Google Sign-In only');
                throw GoogleOnlyAccountException(
                  'This email is registered with Google Sign-In. Log in with Google, or set a password.',
                  email: email.toLowerCase(),
                );
              }
            } catch (googleError) {
              if (googleError is GoogleOnlyAccountException) {
                rethrow;
              }
              // Silent sign-in failed - user not signed in with Google
              // But since signInMethods is empty and we got invalid-credential (not user-not-found),
              // it's most likely a Google-only account
              print('⚠️ Silent Google sign-in failed, but empty signInMethods + invalid-credential suggests Google-only account');
            }
            
            // If we get here, silent sign-in didn't confirm, but empty signInMethods + invalid-credential
            // strongly suggests Google-only account (Firebase quirk)
            // However, to handle edge case where account has password but signInMethods is empty,
            // we'll show "Incorrect password" but the UI should also show "Forgot Password?" option
            // This way users can either try again or reset password if they have one
            print('⚠️ Could not definitively verify account type - showing incorrect password (user can use Forgot Password if needed)');
            throw Exception('Incorrect password');
          } else {
            // Account exists with other methods
            throw Exception('Incorrect password or email');
          }
        } catch (e2) {
          if (e2 is GoogleOnlyAccountException) {
            rethrow;
          }
          // If we can't check or got a different error, provide a generic message
          print('⚠️ Could not determine account type: $e2');
          throw Exception('Incorrect password or email. If you signed up with Google, please use Google Sign-In.');
        }
      } else if (e.code == 'account-exists-with-different-credential') {
        // Check if the email is registered with Google
        try {
          final signInMethods = await _firebaseAuth.fetchSignInMethodsForEmail(email.toLowerCase());
          if (signInMethods.contains(GoogleAuthProvider.PROVIDER_ID)) {
            throw Exception('This account was created with Google. Please sign in with Google.');
          }
        } catch (e2) {
          // Ignore errors from fetchSignInMethodsForEmail
        }
        throw Exception('Authentication failed: ${e.message}');
      }
      throw Exception('Sign in failed: ${e.message}');
    } catch (e) {
      if (e is GoogleOnlyAccountException) {
        rethrow;
      }
      print('❌ Email Sign-In error: $e');
      print('❌ Error type: ${e.runtimeType}');
      throw Exception('Sign in failed: ${e.toString()}');
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
    // Use regular email sign-in for now
    return await signInWithEmail(email: email, password: password);
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

  // Link Google credential to existing email/password account
  // Call this after user signs in with email/password
  Future<void> linkGoogleAccount() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('You must be signed in to link your Google account');
      }

      // Check if Google is already linked
      for (var provider in currentUser.providerData) {
        if (provider.providerId == 'google.com') {
          throw Exception('Google account is already linked to this account');
        }
      }

      // Authenticate with Google
      GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link the credential
      await currentUser.linkWithCredential(credential);
      print('✅ Google account linked successfully');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        throw Exception('This Google account is already linked to another account');
      } else if (e.code == 'provider-already-linked') {
        throw Exception('Google account is already linked to this account');
      }
      throw Exception('Failed to link Google account: ${e.message}');
    } catch (e) {
      throw Exception('Failed to link Google account: ${e.toString()}');
    }
  }

  // Generate password setup token for Google-only accounts
  // Sends email with setup link
  Future<String> generatePasswordSetupToken(String email) async {
    try {
      print('🔵 Generating password setup token for: ${email.toLowerCase()}');
      
      // Check if account exists and is Google-only
      final signInMethods = await _firebaseAuth.fetchSignInMethodsForEmail(email.toLowerCase());
      print('🔵 Sign-in methods found: $signInMethods');
      
      if (signInMethods.isNotEmpty) {
        // If we have sign-in methods, check them
        if (signInMethods.contains('password')) {
          throw Exception('This account already has a password set');
        }
        if (!signInMethods.contains('google.com')) {
          throw Exception('This account was not created with Google Sign-In');
        }
      } else {
        // Sign-in methods is empty - this is a known Firebase quirk for Google-only accounts
        // Try to verify account exists by attempting silent Google sign-in
        print('⚠️ Sign-in methods empty - attempting to verify account with Google...');
        try {
          final googleUser = await _googleSignIn.signInSilently();
          if (googleUser != null && googleUser.email?.toLowerCase() == email.toLowerCase()) {
            print('✅ Account verified - exists with Google Sign-In');
            // Account exists with Google, proceed with token generation
          } else {
            // Couldn't verify via silent sign-in, but since we got here from GoogleOnlyAccountException,
            // we'll assume it's a Google-only account and proceed
            print('⚠️ Could not verify via silent sign-in, but proceeding (likely Google-only account)');
          }
        } catch (e) {
          print('⚠️ Silent Google sign-in check failed: $e');
          // Since we got here from GoogleOnlyAccountException, we'll proceed anyway
          // The backend will verify the account exists when setting the password
          print('⚠️ Proceeding with token generation (account verification will happen on backend)');
        }
      }

      // Generate a secure token (similar to reset code)
      final token = _generateSecureToken();
      
      // Store token with expiration (24 hours for password setup)
      final prefs = await SharedPreferences.getInstance();
      final setupTokensKey = 'password_setup_tokens';
      final tokensJson = prefs.getString(setupTokensKey);
      Map<String, Map<String, dynamic>> tokens = {};
      if (tokensJson != null) {
        tokens = Map<String, Map<String, dynamic>>.from(json.decode(tokensJson));
      }
      
      tokens[email.toLowerCase()] = {
        'token': token,
        'expiresAt': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
      };
      await prefs.setString(setupTokensKey, json.encode(tokens));

      // Send password setup email via backend
      try {
        print('📧 Sending password setup email to: $email');
        print('📧 Backend URL: ${EmailConfig.backendApiUrl}/api/send-password-setup-email');
        
        final response = await http.post(
          Uri.parse('${EmailConfig.backendApiUrl}/api/send-password-setup-email'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': email.toLowerCase(),
            'token': token,
            'setupUrl': '${EmailConfig.backendApiUrl}/api/setup-password?token=$token&email=${Uri.encodeComponent(email.toLowerCase())}',
          }),
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Request timed out. The backend might be sleeping. Please try again.');
          },
        );

        print('📧 Response status: ${response.statusCode}');
        print('📧 Response body: ${response.body}');

        if (response.statusCode != 200) {
          String errorMessage = 'Failed to send password setup email';
          try {
            final errorBody = json.decode(response.body);
            errorMessage = errorBody['error'] ?? errorBody['message'] ?? errorMessage;
          } catch (e) {
            // If response is not JSON, use the raw body
            errorMessage = response.body.isNotEmpty 
                ? response.body 
                : 'Server returned status ${response.statusCode}';
          }
          print('❌ Failed to send password setup email: $errorMessage');
          throw Exception('Failed to send email: $errorMessage');
        }
        
        // Parse success response
        try {
          final responseBody = json.decode(response.body);
          if (responseBody['success'] == true) {
            print('✅ Password setup email sent successfully');
          } else {
            throw Exception(responseBody['error'] ?? 'Email sending failed');
          }
        } catch (e) {
          // If response is not JSON or doesn't have success field, assume it worked if status is 200
          print('✅ Password setup email sent (status 200)');
        }
      } on Exception catch (e) {
        // Check if it's a network/timeout error
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Failed host lookup') ||
            e.toString().contains('Connection refused') ||
            e.toString().contains('timed out')) {
          print('❌ Network error sending password setup email: $e');
          throw Exception('Network error: Could not reach the server. The backend might be sleeping (Render free tier). Please try again in a few seconds.');
        }
        // Re-throw if it's already our custom exception
        if (e.toString().contains('Failed to send email') || 
            e.toString().contains('Request timed out')) {
          rethrow;
        }
        throw Exception('Failed to send password setup email: ${e.toString()}');
      } catch (e) {
        print('❌ Unexpected error sending password setup email: $e');
        // Re-throw if it's already our custom exception
        if (e is Exception && 
            (e.toString().contains('Failed to send email') || 
             e.toString().contains('Network error') ||
             e.toString().contains('Request timed out'))) {
          rethrow;
        }
        throw Exception('Failed to send password setup email: ${e.toString()}');
      }

      return token;
    } catch (e) {
      throw Exception('Failed to generate password setup token: ${e.toString()}');
    }
  }

  // Set password for Google-only account using token
  Future<void> setPasswordForGoogleAccount({
    required String email,
    required String newPassword,
    required String token,
  }) async {
    try {
      // Verify token
      final prefs = await SharedPreferences.getInstance();
      final setupTokensKey = 'password_setup_tokens';
      final tokensJson = prefs.getString(setupTokensKey);
      if (tokensJson == null) {
        throw Exception('Invalid or expired setup token');
      }

      final tokens = Map<String, Map<String, dynamic>>.from(json.decode(tokensJson));
      final emailLower = email.toLowerCase();
      
      if (!tokens.containsKey(emailLower)) {
        throw Exception('Invalid or expired setup token');
      }

      final tokenData = tokens[emailLower]!;
      final storedToken = tokenData['token'] as String;
      final expiresAt = DateTime.parse(tokenData['expiresAt'] as String);

      if (storedToken != token) {
        throw Exception('Invalid setup token');
      }

      if (DateTime.now().isAfter(expiresAt)) {
        tokens.remove(emailLower);
        await prefs.setString(setupTokensKey, json.encode(tokens));
        throw Exception('Setup token has expired. Please request a new one.');
      }

      // Check if account exists and is Google-only
      final signInMethods = await _firebaseAuth.fetchSignInMethodsForEmail(emailLower);
      if (signInMethods.isEmpty) {
        throw Exception('No account found with this email');
      }
      if (signInMethods.contains('password')) {
        throw Exception('This account already has a password set');
      }

      // For Firebase Auth, we need the user to be signed in to set password
      // Since this is a Google-only account, we'll need to sign them in with Google first
      // Then update their password
      // Alternative: Use Firebase Admin SDK on backend to set password
      
      // For now, we'll use the backend API to set the password
      try {
        final response = await http.post(
          Uri.parse('${EmailConfig.backendApiUrl}/api/setup-password'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': emailLower,
            'password': newPassword,
            'token': token,
          }),
        );

        if (response.statusCode != 200) {
          final error = json.decode(response.body);
          throw Exception(error['error'] ?? 'Failed to set password');
        }

        // Remove used token
        tokens.remove(emailLower);
        await prefs.setString(setupTokensKey, json.encode(tokens));
      } catch (e) {
        throw Exception('Failed to set password: ${e.toString()}');
      }
    } catch (e) {
      throw Exception('Failed to set password: ${e.toString()}');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      print('🔵 Sending password reset email to: ${email.toLowerCase()}');
      
      // Check if account exists and has password
      final signInMethods = await _firebaseAuth.fetchSignInMethodsForEmail(email.toLowerCase());
      print('🔵 Sign-in methods found: $signInMethods');
      
      if (signInMethods.isEmpty) {
        // Account might not exist or might be Google-only
        // Try to check if it's Google-only
        try {
          final googleUser = await _googleSignIn.signInSilently();
          if (googleUser != null && googleUser.email?.toLowerCase() == email.toLowerCase()) {
            // It's a Google-only account
            throw Exception('This email is registered with Google Sign-In. Please sign in with Google, or set a password first.');
          }
        } catch (e) {
          if (e.toString().contains('Google Sign-In')) {
            rethrow;
          }
        }
        
        // Can't determine - might not exist or might be Google-only
        // Firebase sendPasswordResetEmail will handle this and return appropriate error
      } else if (!signInMethods.contains('password')) {
        // Account exists but doesn't have password
        throw Exception('This account does not have a password set. Please sign in with your original sign-in method.');
      }
      
      // Send password reset email using Firebase
      await _firebaseAuth.sendPasswordResetEmail(
        email: email.toLowerCase(),
      );
      
      print('✅ Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error: ${e.code} - ${e.message}');
      if (e.code == 'user-not-found') {
        throw Exception('No account found with this email');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email address');
      } else if (e.code == 'user-disabled') {
        throw Exception('This account has been disabled');
      }
      throw Exception('Failed to send password reset email: ${e.message}');
    } catch (e) {
      print('❌ Error sending password reset email: $e');
      // Re-throw if it's already our custom exception
      if (e.toString().contains('Google Sign-In') || 
          e.toString().contains('does not have a password') ||
          e.toString().contains('No account found')) {
        rethrow;
      }
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }

  // Generate secure token for password setup
  String _generateSecureToken() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final randomBytes = utf8.encode('$random${DateTime.now().toIso8601String()}');
    final digest = sha256.convert(randomBytes);
    return digest.toString().substring(0, 32); // 32 character token
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _firebaseAuth.signOut();
      
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

