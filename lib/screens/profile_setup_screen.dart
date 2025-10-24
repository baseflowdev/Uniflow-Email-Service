import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../providers/user_provider.dart';
import 'home_placeholder_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final bool isOffline;
  
  const ProfileSetupScreen({
    super.key,
    required this.isOffline,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _courseController = TextEditingController();
  final _yearController = TextEditingController();
  final _universityController = TextEditingController();
  
  bool _isLoading = false;
  String? _selectedYear;

  final List<String> _yearOptions = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    '5th Year',
    'Graduate',
    'Post Graduate',
    'PhD',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    
    if (user != null) {
      _nameController.text = user.name;
      _courseController.text = user.course;
      _yearController.text = user.year;
      _universityController.text = user.university ?? '';
      _selectedYear = user.year;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _courseController.dispose();
    _yearController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isOffline ? 'Set Up Your Profile' : 'Complete Your Profile',
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                
                const SizedBox(height: 40),
                
                // Form Fields
                _buildFormFields(),
                
                const SizedBox(height: 40),
                
                // Save Button
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            widget.isOffline ? Icons.person_outline : Icons.person,
            size: 30,
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
          widget.isOffline 
              ? 'Let\'s set up your profile'
              : 'Complete your profile',
          style: AppTheme.headingLarge.copyWith(
            color: AppColors.textPrimary,
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
        
        // Subtitle
        Text(
          widget.isOffline
              ? 'This helps us personalize your experience'
              : 'Add some details to get started',
          style: AppTheme.bodyLarge.copyWith(
            color: AppColors.textSecondary,
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
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        // Name Field
        _buildTextField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'Enter your full name',
          icon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 20),
        
        // Course Field
        _buildTextField(
          controller: _courseController,
          label: 'Course/Program',
          hint: 'e.g., Computer Science, Medicine, Business',
          icon: Icons.school_outlined,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your course';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 20),
        
        // Year Dropdown
        _buildYearDropdown(),
        
        const SizedBox(height: 20),
        
        // University Field (Optional)
        _buildTextField(
          controller: _universityController,
          label: 'University (Optional)',
          hint: 'Enter your university name',
          icon: Icons.account_balance_outlined,
          isOptional: true,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isOptional = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${isOptional ? ' (Optional)' : ''}',
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYearDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Academic Year',
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedYear,
          decoration: InputDecoration(
            hintText: 'Select your academic year',
            prefixIcon: const Icon(Icons.calendar_today, color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          items: _yearOptions.map((year) {
            return DropdownMenuItem(
              value: year,
              child: Text(year),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedYear = value;
              _yearController.text = value ?? '';
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select your academic year';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textLight),
                ),
              )
            : Text(
                widget.isOffline ? 'Continue Offline' : 'Complete Profile',
              ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      if (widget.isOffline) {
        // Create offline user
        final success = await userProvider.createOfflineUser(
          name: _nameController.text.trim(),
          course: _courseController.text.trim(),
          year: _yearController.text.trim(),
        );
        
        if (success && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const HomePlaceholderScreen(),
            ),
          );
        }
      } else {
        // Update existing user profile
        final currentUser = userProvider.currentUser;
        if (currentUser != null) {
          final updatedUser = currentUser.copyWith(
            name: _nameController.text.trim(),
            course: _courseController.text.trim(),
            year: _yearController.text.trim(),
            university: _universityController.text.trim().isNotEmpty 
                ? _universityController.text.trim() 
                : null,
          );
          
          final success = await userProvider.updateUserProfile(updatedUser);
          
          if (success && mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const HomePlaceholderScreen(),
              ),
            );
          }
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save profile: $e');
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

