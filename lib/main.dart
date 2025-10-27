import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/user_provider.dart';
import 'providers/app_provider.dart';
import 'providers/file_provider.dart';
import 'providers/note_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_choice_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/home_placeholder_screen.dart';
import 'utils/app_theme.dart';
import 'hive/hive_adapters.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Hive adapters
  await HiveAdapters.registerAdapters();
  
  // Initialize SharedPreferences
  await SharedPreferences.getInstance();
  
  runApp(const UniFlowApp());
}

class UniFlowApp extends StatelessWidget {
  const UniFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => FileProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer2<UserProvider, SettingsProvider>(
        builder: (context, userProvider, settingsProvider, child) {
          // Get theme mode from settings (default to dark mode if not initialized yet)
          final isDarkMode = settingsProvider.isInitialized 
              ? settingsProvider.settings.isDarkMode 
              : true;
          
          return MaterialApp(
            title: 'UniFlow',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AppNavigator(),
            routes: {
              '/onboarding': (context) => const OnboardingScreen(),
              '/login-choice': (context) => const LoginChoiceScreen(),
              '/profile-setup': (context) => const ProfileSetupScreen(isOffline: true),
              '/home': (context) => const HomePlaceholderScreen(),
            },
          );
        },
      ),
    );
  }
}

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait a bit to ensure the widget tree is built
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (mounted) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final fileProvider = Provider.of<FileProvider>(context, listen: false);
      final noteProvider = Provider.of<NoteProvider>(context, listen: false);
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      
      // Initialize providers in parallel to speed up initialization
      // and run heavy operations in the background
      await Future.wait([
        userProvider.initialize(),
        fileProvider.initialize(),
        noteProvider.initialize(),
        settingsProvider.initialize(),
      ]);
      
      if (mounted) {
        _navigateToNextScreen(userProvider);
      }
    }
  }

  void _navigateToNextScreen(UserProvider userProvider) {
    // Wait for 2 seconds to show splash screen
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      if (!userProvider.hasSeenOnboarding) {
        // First time user - show onboarding
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const OnboardingScreen(),
          ),
        );
      } else if (userProvider.isLoggedIn) {
        // User is logged in - go to home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomePlaceholderScreen(),
          ),
        );
      } else {
        // User has seen onboarding but not logged in - go to login choice
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginChoiceScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}