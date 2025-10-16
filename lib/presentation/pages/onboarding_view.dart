// lib/views/onboarding_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_profile_viewmodel.dart';
import '../../domain/entities/user_profile.dart';
import '../widgets/profile_inputs.dart';
import '../../../core/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../config/routes/navigation_service.dart';

class OnboardingView extends StatefulWidget {
  final bool isFirstTimeUser;

  const OnboardingView({Key? key, this.isFirstTimeUser = false})
      : super(key: key);

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;
  bool _hasSelectedGender = false;

  late String _gender;
  late int _age;
  late double _weight;
  late String _weightUnit;
  late double _height;
  late String _heightUnit;
  late bool _isMetric;
  late ActivityLevel _activityLevel;
  late WeightGoal _weightGoal;

  @override
  void initState() {
    super.initState();
    _initializeOnboarding();
  }

  void _initializeOnboarding() {
    final profileVM = Provider.of<UserProfileViewModel>(context, listen: false);

    // If explicitly marked as first-time user, ignore any existing profile data
    if (widget.isFirstTimeUser) {
      print(
          '📋 OnboardingView: Explicitly marked as first-time user - starting fresh');
      _startFreshOnboarding();
      return;
    }

    if (profileVM.profile != null) {
      // Resuming onboarding - load existing data
      final profile = profileVM.profile!;
      _gender = profile.gender;
      _age = profile.age;
      _isMetric = profileVM.isMetric;
      _weightUnit = profileVM.weightUnit;
      _heightUnit = profileVM.heightUnit;
      _weight = profileVM.displayWeight;
      _height = profileVM.displayHeight;
      _activityLevel = profile.activityLevel;
      _weightGoal = profile.weightGoal;
      _hasSelectedGender = true; // Profile exists, so gender was selected

      // Determine which page to start from based on completeness
      _currentPage = _determineStartingPage(profile);

      print('📋 OnboardingView: Resuming onboarding from page $_currentPage');

      // Show resume message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Continuing where you left off...'),
              backgroundColor: AppColors.primary,
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
    } else {
      // First time onboarding - set defaults
      _startFreshOnboarding();
    }

    // Navigate to the determined starting page after widget is built
    if (_currentPage > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _startFreshOnboarding() {
    _gender = 'Male';
    _hasSelectedGender = true;
    _age = 25;
    _weight = 70;
    _weightUnit = 'kg';
    _height = 170;
    _heightUnit = 'cm';
    _isMetric = true;
    _activityLevel = ActivityLevel.moderatelyActive;
    _weightGoal = WeightGoal.maintain;
    _currentPage = 0;

    print(
        '📋 OnboardingView: Starting fresh onboarding from page 0 (gender selection)');
  }

  /// Determine which page to start from based on profile completeness
  int _determineStartingPage(UserProfile profile) {
    // Check basic info (gender, age) - Page 0
    if (profile.gender.isEmpty || profile.age <= 0) {
      return 0;
    }

    // Check measurements (weight, height) - Page 1
    if (profile.weightKg <= 0 || profile.heightCm <= 0) {
      return 1;
    }

    // Check activity level and goals - Page 2
    // Activity level and weight goal always have defaults, so check if they seem intentionally set
    // For now, assume if we got this far, we should go to the summary page
    return 3; // Go to summary page to review and complete
  }

  void _toggleUnit() {
    setState(() {
      _isMetric = !_isMetric;
      _weightUnit = _isMetric ? 'kg' : 'lbs';
      _heightUnit = _isMetric ? 'cm' : 'inch';
      if (_isMetric) {
        // Converting from imperial to metric
        _weight = _weight * 0.453592; // lbs to kg
        _height = _height * 2.54; // inches to cm
      } else {
        // Converting from metric to imperial
        _weight = _weight * 2.20462; // kg to lbs
        _height = _height / 2.54; // cm to inches
      }
    });
  }

  void _nextPage() {
    if (_currentPage < 3) {
      if (_currentPage == 0) {
        // Save gender page
        if (!_formKey.currentState!.validate()) return;
        _formKey.currentState!.save();
      } else if (_currentPage == 1) {
        // Save measurements page
        if (!_formKey.currentState!.validate()) return;
        _formKey.currentState!.save();
      } else if (_currentPage == 2) {
        // Save activity page
        if (!_formKey.currentState!.validate()) return;
        _formKey.currentState!.save();
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitForm();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitForm() async {
    final vm = Provider.of<UserProfileViewModel>(context, listen: false);
    final ctx = context;

    try {
      print('📝 OnboardingView: Saving profile...');

      await vm.saveProfile(
        gender: _gender,
        age: _age,
        weight: _weight,
        weightUnit: _weightUnit,
        height: _height,
        heightUnit: _heightUnit,
        activityLevel: _activityLevel,
        isMetric: _isMetric,
        weightGoal: _weightGoal,
      );

      // Mark onboarding as completed
      await vm.completeOnboarding();

      print('✅ OnboardingView: Profile saved and onboarding completed');

      if (!ctx.mounted) return;

      // Navigate to analysis loading (now with dynamic timing)
      NavigationService.navigateToAnalysisLoading();
    } catch (e) {
      print('❌ OnboardingView: Error saving profile: $e');

      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _submitForm(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Progress Indicator
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: List.generate(
                    4,
                    (index) => Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: index <= _currentPage
                              ? AppColors.primary
                              : AppColors.grey300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Page Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildGenderPage(),
                    _buildMeasurementsPage(),
                    _buildActivityPage(),
                    _buildSummaryPage(),
                  ],
                ),
              ),
              // Navigation Buttons
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      TextButton.icon(
                        onPressed: _previousPage,
                        icon: const FaIcon(FontAwesomeIcons.arrowLeft),
                        label: const Text('Back'),
                      )
                    else
                      const SizedBox(width: 100),
                    ElevatedButton.icon(
                      onPressed: (_currentPage == 0 && !_hasSelectedGender)
                          ? null
                          : _nextPage,
                      icon: Icon(_currentPage == 4
                          ? FontAwesomeIcons.check
                          : FontAwesomeIcons.arrowRight),
                      label: Text(_currentPage == 4 ? 'Submit' : 'Next'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What\'s your gender?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This helps us calculate your daily calorie needs',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildGenderOption(
                  'Male',
                  FontAwesomeIcons.mars,
                  AppColors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGenderOption(
                  'Female',
                  FontAwesomeIcons.venus,
                  AppColors.profile,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String gender, IconData icon, Color color) {
    final isSelected = _gender == gender;
    return InkWell(
      onTap: () => setState(() {
        _gender = gender;
        _hasSelectedGender = true;
      }),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.withOpacity(color, 0.1)
              : AppColors.grey100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            FaIcon(
              icon,
              size: 48,
              color: isSelected ? color : AppColors.grey500,
            ),
            const SizedBox(height: 16),
            Text(
              gender,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Measurements',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Let\'s get to know your body better',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 32),
          // Unit Toggle
          Center(
            child: UnitSwitchButton(
              isMetric: _isMetric,
              onChanged: (_) => _toggleUnit(),
            ),
          ),
          const SizedBox(height: 24),
          // Measurements
          _buildInfoRow(
            context,
            FontAwesomeIcons.cakeCandles,
            'Age',
            '$_age years',
            onEdit: () => _showAgeDialog(context),
          ),
          _buildInfoRow(
            context,
            FontAwesomeIcons.weightScale,
            'Weight',
            '${_weight.toStringAsFixed(1)} $_weightUnit',
            onEdit: () => _showWeightDialog(context),
          ),
          _buildInfoRow(
            context,
            FontAwesomeIcons.rulerVertical,
            'Height',
            _isMetric
                ? '${_height.toStringAsFixed(1)} cm'
                : '${(_height / 12).floor()}′${(_height % 12).round()}″',
            onEdit: () => _showHeightDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    required VoidCallback onEdit,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.withOpacity(colorScheme.primary, 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              FaIcon(
                icon,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              FaIcon(
                FontAwesomeIcons.pencil,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAgeDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    int tempAge = _age;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select Age',
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
        ),
        content: AgeInput(
          age: tempAge,
          onChanged: (age) => tempAge = age,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: colorScheme.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _age = tempAge);
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: TextStyle(
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWeightDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    double tempWeight = _weight;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Weight',
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
        ),
        content: WeightInput(
          weight: tempWeight,
          unit: _weightUnit,
          onChanged: (weight) => tempWeight = weight,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: colorScheme.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _weight = tempWeight);
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: TextStyle(
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHeightDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    double tempHeight = _height;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Height',
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
        ),
        content: HeightInput(
          height: tempHeight,
          isMetric: _isMetric,
          onChanged: (height) => tempHeight = height,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: colorScheme.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _height = tempHeight);
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: TextStyle(
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Activity Level',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'How active are you in your daily life?',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 32),
          ...ActivityLevel.values.map((level) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildActivityLevelTile(level),
            );
          }),
          const SizedBox(height: 32),
          const Text(
            'Your Weight Goal',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'What would you like to achieve?',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 32),
          ...WeightGoal.values.map((goal) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildWeightGoalTile(goal),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActivityLevelTile(ActivityLevel level) {
    final isSelected = _activityLevel == level;
    return InkWell(
      onTap: () => setState(() => _activityLevel = level),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.withOpacity(AppColors.primary, 0.1)
              : AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.personRunning,
              color: isSelected ? AppColors.primary : AppColors.grey500,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _getActivityDescription(level),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const FaIcon(
                FontAwesomeIcons.circleCheck,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  String _getActivityDescription(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Little or no exercise';
      case ActivityLevel.lightlyActive:
        return 'Light exercise 1-3 days/week';
      case ActivityLevel.moderatelyActive:
        return 'Moderate exercise 3-5 days/week';
      case ActivityLevel.veryActive:
        return 'Hard exercise 6-7 days/week';
      case ActivityLevel.extraActive:
        return 'Very hard exercise & physical job';
    }
  }

  Widget _buildWeightGoalTile(WeightGoal goal) {
    return InkWell(
      onTap: () {
        setState(() {
          _weightGoal = goal;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _weightGoal == goal
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _weightGoal == goal ? AppColors.primary : AppColors.grey300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            FaIcon(
              _getWeightGoalIcon(goal),
              color:
                  _weightGoal == goal ? AppColors.primary : AppColors.grey600,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.displayName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _weightGoal == goal
                          ? AppColors.primary
                          : AppColors.grey800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getWeightGoalDescription(goal),
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.035,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            if (_weightGoal == goal)
              const FaIcon(
                FontAwesomeIcons.circleCheck,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getWeightGoalIcon(WeightGoal goal) {
    switch (goal) {
      case WeightGoal.lose:
        return FontAwesomeIcons.arrowDown;
      case WeightGoal.maintain:
        return FontAwesomeIcons.arrowRight;
      case WeightGoal.gain:
        return FontAwesomeIcons.arrowUp;
    }
  }

  String _getWeightGoalDescription(WeightGoal goal) {
    switch (goal) {
      case WeightGoal.lose:
        return 'Create a calorie deficit to lose weight';
      case WeightGoal.maintain:
        return 'Maintain your current weight';
      case WeightGoal.gain:
        return 'Create a calorie surplus to gain weight';
    }
  }

  Widget _buildSummaryPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Review your information before submitting',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 32),
          _buildSummaryCard(
            'Personal Information',
            [
              _buildSummaryRow('Gender', _gender),
              _buildSummaryRow('Age', '$_age years'),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            'Measurements',
            [
              _buildSummaryRow(
                  'Weight', '${_weight.toStringAsFixed(1)} $_weightUnit'),
              _buildSummaryRow(
                  'Height', '${_height.toStringAsFixed(1)} $_heightUnit'),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            'Activity Level',
            [
              _buildSummaryRow('Level', _activityLevel.displayName),
              _buildSummaryRow(
                  'Description', _getActivityDescription(_activityLevel)),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            'Weight Goal',
            [
              _buildSummaryRow('Goal', _weightGoal.displayName),
              _buildSummaryRow(
                  'Description', _getWeightGoalDescription(_weightGoal)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, List<Widget> rows) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: MediaQuery.of(context).size.width * 0.035,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
