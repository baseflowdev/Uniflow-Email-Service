import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:page_view_dot_indicator/page_view_dot_indicator.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import 'login_choice_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.school,
      title: 'Learn Effectively',
      description: 'Access your study materials, PDFs, and notes all in one place. Organize your learning journey with ease.',
      color: AppColors.primary,
    ),
    OnboardingPage(
      icon: Icons.folder_shared,
      title: 'Organize Everything',
      description: 'Keep your files, documents, and notes perfectly organized. Never lose track of important materials again.',
      color: AppColors.accent,
    ),
    OnboardingPage(
      icon: Icons.psychology,
      title: 'Study Smart',
      description: 'Take smart notes, create study plans, and track your progress. Make the most of your study time.',
      color: AppColors.success,
    ),
    OnboardingPage(
      icon: Icons.cloud_off,
      title: 'Works Offline',
      description: 'Access your materials even without internet. Your data is always available when you need it.',
      color: AppColors.info,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLoginChoice();
    }
  }

  void _goToLoginChoice() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginChoiceScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _goToLoginChoice,
                  child: Text(
                    'Skip',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            
            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: PageViewDotIndicator(
                currentItem: _currentPage,
                count: _pages.length,
                unselectedColor: AppColors.grey300,
                selectedColor: AppColors.primary,
                size: const Size(12, 12),
                unselectedSize: const Size(8, 8),
              ),
            ),
            
            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: page.color,
            ),
          )
              .animate()
              .scale(
                duration: 600.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 800.ms),
          
          const SizedBox(height: 48),
          
          // Title
          Text(
            page.title,
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
          
          const SizedBox(height: 24),
          
          // Description
          Text(
            page.description,
            style: AppTheme.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
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
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

