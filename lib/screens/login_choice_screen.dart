import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../providers/user_provider.dart';
import 'profile_setup_screen.dart';
import 'home_placeholder_screen.dart';
import 'main_screen.dart';

class LoginChoiceScreen extends StatefulWidget {
  const LoginChoiceScreen({super.key});

  @override
  State<LoginChoiceScreen> createState() => _LoginChoiceScreenState();
}

class _LoginChoiceScreenState extends State<LoginChoiceScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Header
              _buildHeader(),
              
              const SizedBox(height: 24),
              
              // Login Options
              Expanded(
                child: _buildLoginOptions(),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App Icon
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.school,
            size: 32,
            color: AppColors.primary,
          ),
        )
            .animate()
            .scale(
              duration: 600.ms,
              curve: Curves.elasticOut,
            )
            .fadeIn(duration: 800.ms),
        
        const SizedBox(height: 16),
        
        // Title
        Text(
          'Welcome to UniFlow',
          style: AppTheme.headingLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold, // Made text bolder
          ),
          textAlign: TextAlign.center,
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
        
        const SizedBox(height: 8),
        
        // Subtitle
        Text(
          'Choose how you\'d like to get started',
          style: AppTheme.bodyLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500, // Added medium weight
          ),
          textAlign: TextAlign.center,
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
      ],
    );
  }

  Widget _buildLoginOptions() {
    return SingleChildScrollView( // Added SingleChildScrollView
      child: Column(
        children: [
          // Continue without signing in
          _buildLoginOption(
            icon: Icons.person_outline,
            title: 'Continue without signing in',
            subtitle: 'Start using the app offline',
            color: AppColors.grey600,
            onTap: _continueOffline,
          ),
          
          const SizedBox(height: 12),
          
          // Google Sign In
          _buildLoginOption(
            icon: Icons.login,
            title: 'Sign in with Google',
            subtitle: 'Sync your data across devices',
            color: AppColors.primary,
            onTap: _signInWithGoogle,
          ),
          
          const SizedBox(height: 12),
          
          // Apple Sign In
          _buildLoginOption(
            icon: Icons.apple,
            title: 'Sign in with Apple',
            subtitle: 'Use your Apple ID',
            color: AppColors.textPrimary,
            onTap: _signInWithApple,
          ),
          
          const SizedBox(height: 12),
          
          // University Email Sign In
          _buildLoginOption(
            icon: Icons.email_outlined,
            title: 'Sign in with University Email',
            subtitle: 'Use your university credentials',
            color: AppColors.accent,
            onTap: _signInWithUniversityEmail,
          ),
          
          // Add extra padding at the bottom to prevent overflow
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLoginOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    // Determine background and text colors based on theme
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark ? Colors.white : AppColors.surface;
    final Color textColor = isDark ? Colors.black : Theme.of(context).colorScheme.onSurface;
    final Color subtitleColor = isDark ? Colors.black54 : Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
    final Color borderColor = isDark ? AppColors.grey300 : AppColors.grey200;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18.0),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 26,
                  ),
                ),
                
                const SizedBox(width: 15),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: AppTheme.bodySmall.copyWith(
                          color: subtitleColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (_isLoading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 15,
                    color: subtitleColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _continueOffline() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Navigate to profile setup for offline user
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ProfileSetupScreen(isOffline: true),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to continue offline: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final success = await userProvider.signInWithGoogle();
      
      if (mounted) {
        if (success) {
          // Check if profile is complete
          if (userProvider.isProfileComplete) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const MainScreen(),
              ),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const ProfileSetupScreen(isOffline: false),
              ),
            );
          }
        } else {
          _showErrorSnackBar('Google sign in was cancelled');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Google sign in failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _showErrorSnackBar('Apple Sign In is not implemented yet');
    } catch (e) {
      _showErrorSnackBar('Apple sign in failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithUniversityEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _showErrorSnackBar('University Email Sign In is not implemented yet');
    } catch (e) {
      _showErrorSnackBar('University email sign in failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

