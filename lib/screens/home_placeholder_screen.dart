import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../providers/user_provider.dart';

class HomePlaceholderScreen extends StatefulWidget {
  const HomePlaceholderScreen({super.key});

  @override
  State<HomePlaceholderScreen> createState() => _HomePlaceholderScreenState();
}

class _HomePlaceholderScreenState extends State<HomePlaceholderScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UniFlow'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Welcome Section
                  _buildWelcomeSection(),

                  const SizedBox(height: 40),

                  // Features Grid
                  _buildFeaturesGrid(),

                  const SizedBox(height: 40),

                  // Action Buttons
                  _buildActionButtons(),
                  
                  // Add extra padding at the bottom to prevent overflow
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildWelcomeSection() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0), // Reduced padding
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16), // Reduced border radius
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 8, // Reduced blur
                offset: const Offset(0, 2), // Reduced offset
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Added this to prevent overflow
            children: [
              // Welcome Text - More compact
              Text(
                'Welcome back!',
                style: AppTheme.bodyLarge.copyWith( // Changed from headingMedium
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w600,
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideX(
                    begin: -0.3,
                    end: 0,
                    duration: 600.ms,
                    curve: Curves.easeOut,
                  ),
              
              const SizedBox(height: 4), // Reduced spacing
              
              Text(
                user?.name ?? 'Student', // Changed from displayName to name
                style: AppTheme.headingMedium.copyWith( // Changed from headingLarge
                  color: AppColors.textLight,
                  fontSize: 22, // Reduced font size
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1, // Prevent text overflow
                overflow: TextOverflow.ellipsis,
              )
                  .animate()
                  .fadeIn(
                    delay: 200.ms,
                    duration: 600.ms,
                  )
                  .slideX(
                    begin: -0.3,
                    end: 0,
                    delay: 200.ms,
                    duration: 600.ms,
                    curve: Curves.easeOut,
                  ),
              
              const SizedBox(height: 8), // Reduced spacing
              
              // Status Badge - More compact
              _buildCompactStatusBadge(user),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserInfo(user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (user.course.isNotEmpty && user.course != 'Not specified') ...[
          _buildInfoRow(Icons.school, user.displayCourse),
          const SizedBox(height: 8),
        ],
        if (user.year.isNotEmpty && user.year != 'Not specified') ...[
          _buildInfoRow(Icons.calendar_today, user.displayYear),
          const SizedBox(height: 8),
        ],
        if (user.university != null && user.university!.isNotEmpty) ...[
          _buildInfoRow(Icons.account_balance, user.university!),
        ],
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textLight.withOpacity(0.8),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTheme.bodyMedium.copyWith(
            color: AppColors.textLight.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStatusBadge(user) {
    return Row(
      children: [
        Icon(
          user?.isOfflineUser == true 
              ? Icons.cloud_off 
              : Icons.cloud_done,
          color: AppColors.textLight,
          size: 16, // Reduced icon size
        ),
        const SizedBox(width: 6), // Reduced spacing
        Expanded( // Added Expanded to prevent overflow
          child: Text(
            user?.isOfflineUser == true 
                ? 'Offline Mode' 
                : 'Online & Synced',
            style: AppTheme.bodySmall.copyWith( // Changed from bodyMedium
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1, // Prevent text overflow
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(
          delay: 400.ms,
          duration: 600.ms,
        )
        .slideX(
          begin: -0.3,
          end: 0,
          delay: 400.ms,
          duration: 600.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildFeaturesGrid() {
    final features = [
      FeatureCard(
        icon: Icons.folder_outlined,
        title: 'Files',
        description: 'Manage your documents and PDFs',
        color: AppColors.primary,
        onTap: () => _showComingSoon('Files'),
      ),
      FeatureCard(
        icon: Icons.note_outlined,
        title: 'Notes',
        description: 'Take and organize your notes',
        color: AppColors.accent,
        onTap: () => _showComingSoon('Notes'),
      ),
      FeatureCard(
        icon: Icons.analytics_outlined,
        title: 'Analytics',
        description: 'Track your study progress',
        color: AppColors.success,
        onTap: () => _showComingSoon('Analytics'),
      ),
      FeatureCard(
        icon: Icons.settings_outlined,
        title: 'Settings',
        description: 'Customize your experience',
        color: AppColors.info,
        onTap: () => _showComingSoon('Settings'),
      ),
    ];

    return Column(
      children: [
        // First row
        Row(
          children: [
            Expanded(
              child: features[0]
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0, delay: 100.ms, duration: 600.ms, curve: Curves.easeOut),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: features[1]
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0, delay: 200.ms, duration: 600.ms, curve: Curves.easeOut),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Second row
        Row(
          children: [
            Expanded(
              child: features[2]
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0, delay: 300.ms, duration: 600.ms, curve: Curves.easeOut),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: features[3]
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0, delay: 400.ms, duration: 600.ms, curve: Curves.easeOut),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Quick Actions
        Text(
          'Quick Actions',
          style: AppTheme.headingSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showComingSoon('Upload File'),
                icon: const Icon(Icons.upload),
                label: const Text('Upload File'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showComingSoon('New Note'),
                icon: const Icon(Icons.add),
                label: const Text('New Note'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: AppColors.info,
        action: SnackBarAction(
          label: 'OK',
          textColor: AppColors.textLight,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.signOut();
    
    if (mounted) {
      // Navigate back to login choice
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login-choice',
        (route) => false,
      );
    }
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
              
              const SizedBox(height: 12),
              
              Text(
                title,
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 4),
              
              Text(
                description,
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

