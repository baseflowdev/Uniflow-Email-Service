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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Welcome Section
              _buildWelcomeSection(),
              
              const SizedBox(height: 40),
              
              // Features Grid
              Expanded(
                child: _buildFeaturesGrid(),
              ),
              
              const SizedBox(height: 40),
              
              // Action Buttons
              _buildActionButtons(),
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
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Text
              Text(
                'Welcome back!',
                style: AppTheme.headingMedium.copyWith(
                  color: AppColors.textLight,
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
              
              const SizedBox(height: 8),
              
              Text(
                user?.displayName ?? 'Student',
                style: AppTheme.headingLarge.copyWith(
                  color: AppColors.textLight,
                  fontSize: 28,
                ),
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
              
              const SizedBox(height: 16),
              
              // User Info
              if (user != null) ...[
                _buildUserInfo(user),
              ],
              
              const SizedBox(height: 16),
              
              // Status Badge
              _buildStatusBadge(user),
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

  Widget _buildStatusBadge(user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: user?.isOfflineUser == true 
            ? AppColors.warning.withOpacity(0.2)
            : AppColors.success.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: user?.isOfflineUser == true 
              ? AppColors.warning
              : AppColors.success,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            user?.isOfflineUser == true ? Icons.cloud_off : Icons.cloud_done,
            size: 16,
            color: user?.isOfflineUser == true 
                ? AppColors.warning
                : AppColors.success,
          ),
          const SizedBox(width: 6),
          Text(
            user?.isOfflineUser == true ? 'Offline Mode' : 'Online Mode',
            style: AppTheme.bodySmall.copyWith(
              color: user?.isOfflineUser == true 
                  ? AppColors.warning
                  : AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        return features[index]
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: 100 * index),
              duration: 600.ms,
            )
            .slideY(
              begin: 0.3,
              end: 0,
              delay: Duration(milliseconds: 100 * index),
              duration: 600.ms,
              curve: Curves.easeOut,
            );
      },
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
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showComingSoon('New Note'),
                icon: const Icon(Icons.add),
                label: const Text('New Note'),
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

