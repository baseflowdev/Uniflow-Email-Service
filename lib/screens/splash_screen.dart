import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Wait for 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      // Navigation will be handled by the main app based on onboarding status
      // This screen will be replaced by the appropriate next screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowMedium,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school,
                  size: 60,
                  color: AppColors.primary,
                ),
              )
                  .animate()
                  .scale(
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 800.ms),
              
              const SizedBox(height: 32),
              
              // App Name
              Text(
                'UniFlow',
                style: AppTheme.headingLarge.copyWith(
                  color: AppColors.textLight,
                  fontSize: 36,
                ),
              )
                  .animate()
                  .fadeIn(
                    delay: 300.ms,
                    duration: 600.ms,
                  )
                  .slideY(
                    begin: 0.3,
                    end: 0,
                    delay: 300.ms,
                    duration: 600.ms,
                    curve: Curves.easeOut,
                  ),
              
              const SizedBox(height: 16),
              
              // Tagline
              Text(
                'Learn • Organize • Study Smart',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppColors.textLight.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              )
                  .animate()
                  .fadeIn(
                    delay: 600.ms,
                    duration: 600.ms,
                  )
                  .slideY(
                    begin: 0.3,
                    end: 0,
                    delay: 600.ms,
                    duration: 600.ms,
                    curve: Curves.easeOut,
                  ),
              
              const SizedBox(height: 80),
              
              // Loading Indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.textLight.withOpacity(0.8),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(
                    delay: 1000.ms,
                    duration: 400.ms,
                  )
                  .scale(
                    delay: 1000.ms,
                    duration: 400.ms,
                    curve: Curves.easeOut,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

