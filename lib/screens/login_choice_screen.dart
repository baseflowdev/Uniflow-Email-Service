import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../providers/user_provider.dart';
import 'profile_setup_screen.dart';
import 'home_placeholder_screen.dart';

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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Header
              _buildHeader(),
              
              const SizedBox(height: 60),
              
              // Login Options
              Expanded(
                child: _buildLoginOptions(),
              ),
              
              const SizedBox(height: 40),
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
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.school,
            size: 40,
            color: AppColors.primary,
          ),
        )
            .animate()
            .scale(
              duration: 600.ms,
              curve: Curves.elasticOut,
            )
            .fadeIn(duration: 800.ms),
        
        const SizedBox(height: 24),
        
        // Title
        Text(
          'Welcome to UniFlow',
          style: AppTheme.headingLarge.copyWith(
            color: AppColors.textPrimary,
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
        
        const SizedBox(height: 16),
        
        // Subtitle
        Text(
          'Choose how you\'d like to get started',
          style: AppTheme.bodyLarge.copyWith(
            color: AppColors.textSecondary,
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
    return Column(
      children: [
        // Continue without signing in
        _buildLoginOption(
          icon: Icons.person_outline,
          title: 'Continue without signing in',
          subtitle: 'Start using the app offline',
          color: AppColors.grey600,
          onTap: _continueOffline,
        ),
        
        const SizedBox(height: 16),
        
        // Google Sign In
        _buildLoginOption(
          icon: Icons.login,
          title: 'Sign in with Google',
          subtitle: 'Sync your data across devices',
          color: AppColors.primary,
          onTap: _signInWithGoogle,
        ),
        
        const SizedBox(height: 16),
        
        // Apple Sign In
        _buildLoginOption(
          icon: Icons.apple,
          title: 'Sign in with Apple',
          subtitle: 'Use your Apple ID',
          color: AppColors.textPrimary,
          onTap: _signInWithApple,
        ),
        
        const SizedBox(height: 16),
        
        // University Email Sign In
        _buildLoginOption(
          icon: Icons.email_outlined,
          title: 'Sign in with University Email',
          subtitle: 'Use your university credentials',
          color: AppColors.accent,
          onTap: _signInWithUniversityEmail,
        ),
      ],
    );
  }

  Widget _buildLoginOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.grey200,
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
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textSecondary,
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
                builder: (context) => const HomePlaceholderScreen(),
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

