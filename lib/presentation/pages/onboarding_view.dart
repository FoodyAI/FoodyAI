// lib/views/onboarding_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_profile_viewmodel.dart';
import '../../domain/entities/user_profile.dart';
import '../widgets/profile_inputs.dart';
import 'analysis_loading_view.dart';
import '../../../core/constants/app_colors.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({Key? key}) : super(key: key);

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;

  late String _gender;
  late int _age;
  late double _weight;
  late String _weightUnit;
  late double _height;
  late String _heightUnit;
  late bool _isMetric;
  late ActivityLevel _activityLevel;

  @override
  void initState() {
    super.initState();
    final profileVM = Provider.of<UserProfileViewModel>(context, listen: false);
    if (profileVM.profile != null) {
      final profile = profileVM.profile!;
      _gender = profile.gender;
      _age = profile.age;
      _isMetric = profileVM.isMetric;
      _weightUnit = profileVM.weightUnit;
      _heightUnit = profileVM.heightUnit;
      _weight = profileVM.displayWeight;
      _height = profileVM.displayHeight;
      _activityLevel = profile.activityLevel;
    } else {
      _gender = 'Male';
      _age = 25;
      _weight = 70;
      _weightUnit = 'kg';
      _height = 170;
      _heightUnit = 'cm';
      _isMetric = true;
      _activityLevel = ActivityLevel.sedentary;
    }
  }

  void _toggleUnit() {
    setState(() {
      _isMetric = !_isMetric;
      _weightUnit = _isMetric ? 'kg' : 'lbs';
      _heightUnit = _isMetric ? 'cm' : 'inch';
      if (_isMetric) {
        _weight = _weight * 0.453592;
        _height = _height * 2.54;
      } else {
        _weight = _weight * 2.20462;
        _height = _height / 2.54;
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

    await vm.saveProfile(
      gender: _gender,
      age: _age,
      weight: _weight,
      weightUnit: _weightUnit,
      height: _height,
      heightUnit: _heightUnit,
      activityLevel: _activityLevel,
      isMetric: _isMetric,
    );

    // Mark onboarding as completed
    await vm.completeOnboarding();

    if (!ctx.mounted) return;
    Navigator.pushReplacement(
      ctx,
      MaterialPageRoute(builder: (_) => const AnalysisLoadingView()),
    );
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
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back'),
                      )
                    else
                      const SizedBox(width: 100),
                    ElevatedButton.icon(
                      onPressed: _nextPage,
                      icon: Icon(_currentPage == 3
                          ? Icons.check
                          : Icons.arrow_forward),
                      label: Text(_currentPage == 3 ? 'Submit' : 'Next'),
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
          Text(
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
                  Icons.male,
                  AppColors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGenderOption(
                  'Female',
                  Icons.female,
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
      onTap: () => setState(() => _gender = gender),
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
            Icon(
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
          Text(
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
            Icons.cake,
            'Age',
            '$_age years',
            onEdit: () => _showAgeDialog(context),
          ),
          _buildInfoRow(
            context,
            Icons.monitor_weight,
            'Weight',
            '${_weight.toStringAsFixed(1)} $_weightUnit',
            onEdit: () => _showWeightDialog(context),
          ),
          _buildInfoRow(
            context,
            Icons.height,
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
              Icon(
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
              Icon(
                Icons.edit,
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
          age: _age,
          onChanged: (age) => setState(() => _age = age),
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
          weight: _weight,
          unit: _weightUnit,
          onChanged: (weight) => setState(() => _weight = weight),
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
          height: _height,
          isMetric: _isMetric,
          onChanged: (height) => setState(() => _height = height),
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
            'Activity Level',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How active are you in your daily life?',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 32),
          ...ActivityLevel.values.map((level) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildActivityOption(level),
              )),
        ],
      ),
    );
  }

  Widget _buildActivityOption(ActivityLevel level) {
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
            Icon(
              Icons.directions_run,
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
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
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
          Text(
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.grey600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
