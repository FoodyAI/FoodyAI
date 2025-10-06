import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_profile_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/ai_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/profile_inputs.dart';
import '../widgets/google_signin_button.dart';
import '../../core/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'auth_test_page.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileVM = Provider.of<UserProfileViewModel>(context);
    final profile = profileVM.profile!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Profile',
        icon: FontAwesomeIcons.user,
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkBackground
                  : colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
              indicatorColor: colorScheme.primary,
              tabs: const [
                Tab(
                  icon: FaIcon(FontAwesomeIcons.user),
                  text: 'Personal',
                ),
                Tab(
                  icon: FaIcon(FontAwesomeIcons.dumbbell),
                  text: 'Activity',
                ),
                Tab(
                  icon: FaIcon(FontAwesomeIcons.bullseye),
                  text: 'Goals',
                ),
                Tab(
                  icon: FaIcon(FontAwesomeIcons.gear),
                  text: 'Settings',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPersonalTab(context, profileVM, profile),
                _buildActivityTab(context, profileVM, profile),
                _buildGoalsTab(context, profileVM, profile),
                _buildSettingsTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalTab(BuildContext context, UserProfileViewModel profileVM,
      UserProfile profile) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your personal details and preferences',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildInfoCard(
                        context,
                        FontAwesomeIcons.user,
                        'Gender',
                        profile.gender,
                        colorScheme.primary,
                        () => _showGenderDialog(context, profileVM),
                      ),
                      _buildInfoCard(
                        context,
                        FontAwesomeIcons.cakeCandles,
                        'Age',
                        '${profile.age} years',
                        colorScheme.secondary,
                        () => _showAgeDialog(context, profileVM),
                      ),
                      _buildInfoCard(
                        context,
                        FontAwesomeIcons.weightScale,
                        'Weight',
                        '${profileVM.displayWeight.toStringAsFixed(1)} ${profileVM.weightUnit}',
                        colorScheme.tertiary,
                        () => _showWeightDialog(context, profileVM),
                      ),
                      _buildInfoCard(
                        context,
                        FontAwesomeIcons.rulerVertical,
                        'Height',
                        profileVM.isMetric
                            ? '${profileVM.displayHeight.toStringAsFixed(1)} cm'
                            : '${(profileVM.displayHeight / 12).floor()}′${(profileVM.displayHeight % 12).round()}″',
                        colorScheme.error,
                        () => _showHeightDialog(context, profileVM),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Theme.of(context).colorScheme.surface
                : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkDivider
                  : AppColors.grey300,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                icon,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTab(BuildContext context, UserProfileViewModel profileVM,
      UserProfile profile) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activity Level',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How active are you in your daily life?',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ...ActivityLevel.values.map((level) {
                    final isSelected = profile.activityLevel == level;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () {
                          profileVM.saveProfile(
                            gender: profile.gender,
                            age: profile.age,
                            weight: profileVM.displayWeight,
                            weightUnit: profileVM.weightUnit,
                            height: profileVM.displayHeight,
                            heightUnit: profileVM.heightUnit,
                            activityLevel: level,
                            isMetric: profileVM.isMetric,
                            weightGoal: profile.weightGoal,
                            aiProvider: profile.aiProvider,
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primary.withOpacity(0.1)
                                : colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outline.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              FaIcon(
                                _getActivityIcon(level),
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      level.displayName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? colorScheme.primary
                                            : colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      _getActivityDescription(level),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colorScheme.onSurface
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                FaIcon(
                                  FontAwesomeIcons.circleCheck,
                                  color: colorScheme.primary,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsTab(BuildContext context, UserProfileViewModel profileVM,
      UserProfile profile) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weight Goal',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'What would you like to achieve?',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ...WeightGoal.values.map((goal) {
                    final isSelected = profile.weightGoal == goal;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () {
                          profileVM.saveProfile(
                            gender: profile.gender,
                            age: profile.age,
                            weight: profileVM.displayWeight,
                            weightUnit: profileVM.weightUnit,
                            height: profileVM.displayHeight,
                            heightUnit: profileVM.heightUnit,
                            activityLevel: profile.activityLevel,
                            isMetric: profileVM.isMetric,
                            weightGoal: goal,
                            aiProvider: profile.aiProvider,
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primary.withOpacity(0.1)
                                : colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outline.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              FaIcon(
                                _getWeightGoalIcon(goal),
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
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
                                        color: isSelected
                                            ? colorScheme.primary
                                            : colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      _getWeightGoalDescription(goal),
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                                0.035,
                                        color: colorScheme.onSurface
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                FaIcon(
                                  FontAwesomeIcons.circleCheck,
                                  color: colorScheme.primary,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final profileVM = Provider.of<UserProfileViewModel>(context);
    final profile = profileVM.profile!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Account Section (Guest Mode)
          if (profileVM.isGuest)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.user,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Account',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.withOpacity(colorScheme.primary, 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              AppColors.withOpacity(colorScheme.primary, 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildAccountBenefit(
                            context,
                            FontAwesomeIcons.cloudArrowUp,
                            'Sync across devices',
                          ),
                          const SizedBox(height: 12),
                          _buildAccountBenefit(
                            context,
                            FontAwesomeIcons.shieldHalved,
                            'Backup your history',
                          ),
                          const SizedBox(height: 12),
                          _buildAccountBenefit(
                            context,
                            FontAwesomeIcons.chartLine,
                            'Advanced analytics',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const GoogleSignInButton(
                      isFullWidth: true,
                    ),
                    const SizedBox(height: 16),
                    // Test Authentication Button
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AuthTestPage(),
                          ),
                        );
                      },
                      icon: const FaIcon(FontAwesomeIcons.flask),
                      label: const Text('Test Authentication'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.info,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (profileVM.isGuest) const SizedBox(height: 16),
          // AI Provider Section
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.brain,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'AI Provider',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose the AI model for food analysis',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...AIProvider.values.map((provider) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildAIProviderOption(
                        context,
                        profileVM,
                        profile,
                        provider,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Measurement Units Section
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.ruler,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Measurement Units',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose your preferred measurement system',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildMeasurementOption(
                    context,
                    FontAwesomeIcons.globe,
                    'Metric (kg, cm)',
                    'Use kilograms and centimeters',
                    profileVM.isMetric,
                    () {
                      final newWeight = profileVM.displayWeight * 0.453592;
                      final newHeight = profileVM.displayHeight * 2.54;
                      profileVM.saveProfile(
                        gender: profileVM.profile!.gender,
                        age: profileVM.profile!.age,
                        weight: newWeight,
                        weightUnit: 'kg',
                        height: newHeight,
                        heightUnit: 'cm',
                        activityLevel: profileVM.profile!.activityLevel,
                        isMetric: true,
                        weightGoal: profileVM.profile!.weightGoal,
                        aiProvider: profileVM.profile!.aiProvider,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildMeasurementOption(
                    context,
                    FontAwesomeIcons.flag,
                    'Imperial (lbs, ft)',
                    'Use pounds and feet/inches',
                    !profileVM.isMetric,
                    () {
                      final newWeight = profileVM.displayWeight * 2.20462;
                      final newHeight = profileVM.displayHeight / 2.54;
                      profileVM.saveProfile(
                        gender: profileVM.profile!.gender,
                        age: profileVM.profile!.age,
                        weight: newWeight,
                        weightUnit: 'lbs',
                        height: newHeight,
                        heightUnit: 'inch',
                        activityLevel: profileVM.profile!.activityLevel,
                        isMetric: false,
                        weightGoal: profileVM.profile!.weightGoal,
                        aiProvider: profileVM.profile!.aiProvider,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Appearance Section
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.palette,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Appearance',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customize your app experience',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Consumer<ThemeViewModel>(
                    builder: (context, themeVM, _) {
                      return Column(
                        children: [
                          _buildThemeOption(
                            context,
                            FontAwesomeIcons.sun,
                            'Light Theme',
                            'Use light colors',
                            themeVM.themeMode == ThemeMode.light,
                            () {
                              themeVM.setThemeMode(ThemeMode.light);
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildThemeOption(
                            context,
                            FontAwesomeIcons.moon,
                            'Dark Theme',
                            'Use dark colors',
                            themeVM.themeMode == ThemeMode.dark,
                            () {
                              themeVM.setThemeMode(ThemeMode.dark);
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildThemeOption(
                            context,
                            FontAwesomeIcons.circleHalfStroke,
                            'System Theme',
                            'Follow system settings',
                            themeVM.themeMode == ThemeMode.system,
                            () {
                              themeVM.setThemeMode(ThemeMode.system);
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.1)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            FaIcon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              FaIcon(
                FontAwesomeIcons.circleCheck,
                color: colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.1)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            FaIcon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              FaIcon(
                FontAwesomeIcons.circleCheck,
                color: colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getActivityIcon(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return FontAwesomeIcons.couch;
      case ActivityLevel.lightlyActive:
        return FontAwesomeIcons.personWalking;
      case ActivityLevel.moderatelyActive:
        return FontAwesomeIcons.personRunning;
      case ActivityLevel.veryActive:
        return FontAwesomeIcons.dumbbell;
      case ActivityLevel.extraActive:
        return FontAwesomeIcons.personBiking;
    }
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

  String _getWeightGoalDescription(WeightGoal goal) {
    switch (goal) {
      case WeightGoal.lose:
        return 'Reduce body weight';
      case WeightGoal.maintain:
        return 'Keep current weight';
      case WeightGoal.gain:
        return 'Increase body weight';
    }
  }

  void _showGenderDialog(BuildContext context, UserProfileViewModel vm) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select Gender',
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: FaIcon(
                FontAwesomeIcons.mars,
                color: colorScheme.primary,
              ),
              title: Text(
                'Male',
                style: TextStyle(
                  color: colorScheme.onSurface,
                ),
              ),
              trailing: FaIcon(
                vm.profile!.gender == 'Male'
                    ? FontAwesomeIcons.circleCheck
                    : FontAwesomeIcons.circle,
                color: vm.profile!.gender == 'Male'
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.5),
              ),
              onTap: () {
                vm.saveProfile(
                  gender: 'Male',
                  age: vm.profile!.age,
                  weight: vm.displayWeight,
                  weightUnit: vm.weightUnit,
                  height: vm.displayHeight,
                  heightUnit: vm.heightUnit,
                  activityLevel: vm.profile!.activityLevel,
                  isMetric: vm.isMetric,
                  weightGoal: vm.profile!.weightGoal,
                  aiProvider: vm.profile!.aiProvider,
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: FaIcon(
                FontAwesomeIcons.venus,
                color: colorScheme.primary,
              ),
              title: Text(
                'Female',
                style: TextStyle(
                  color: colorScheme.onSurface,
                ),
              ),
              trailing: FaIcon(
                vm.profile!.gender == 'Female'
                    ? FontAwesomeIcons.circleCheck
                    : FontAwesomeIcons.circle,
                color: vm.profile!.gender == 'Female'
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.5),
              ),
              onTap: () {
                vm.saveProfile(
                  gender: 'Female',
                  age: vm.profile!.age,
                  weight: vm.displayWeight,
                  weightUnit: vm.weightUnit,
                  height: vm.displayHeight,
                  heightUnit: vm.heightUnit,
                  activityLevel: vm.profile!.activityLevel,
                  isMetric: vm.isMetric,
                  weightGoal: vm.profile!.weightGoal,
                  aiProvider: vm.profile!.aiProvider,
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAgeDialog(BuildContext context, UserProfileViewModel vm) {
    final colorScheme = Theme.of(context).colorScheme;
    int selectedAge = vm.profile!.age;

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
          age: selectedAge,
          onChanged: (age) {
            selectedAge = age;
          },
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
              vm.saveProfile(
                gender: vm.profile!.gender,
                age: selectedAge,
                weight: vm.displayWeight,
                weightUnit: vm.weightUnit,
                height: vm.displayHeight,
                heightUnit: vm.heightUnit,
                activityLevel: vm.profile!.activityLevel,
                isMetric: vm.isMetric,
                weightGoal: vm.profile!.weightGoal,
                aiProvider: vm.profile!.aiProvider,
              );
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

  void _showWeightDialog(BuildContext context, UserProfileViewModel vm) {
    final colorScheme = Theme.of(context).colorScheme;
    double selectedWeight = vm.displayWeight;

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
          weight: selectedWeight,
          unit: vm.weightUnit,
          onChanged: (weight) {
            selectedWeight = weight;
          },
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
              vm.saveProfile(
                gender: vm.profile!.gender,
                age: vm.profile!.age,
                weight: selectedWeight,
                weightUnit: vm.weightUnit,
                height: vm.displayHeight,
                heightUnit: vm.heightUnit,
                activityLevel: vm.profile!.activityLevel,
                isMetric: vm.isMetric,
                weightGoal: vm.profile!.weightGoal,
                aiProvider: vm.profile!.aiProvider,
              );
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

  void _showHeightDialog(BuildContext context, UserProfileViewModel vm) {
    final colorScheme = Theme.of(context).colorScheme;
    // HeightInput widget expects height in cm for both metric and imperial
    // For imperial, it will convert cm to feet/inches internally
    double selectedHeight = vm.isMetric ? vm.displayHeight : vm.displayHeight * 2.54;

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
          height: selectedHeight,
          isMetric: vm.isMetric,
          onChanged: (height) {
            selectedHeight = height;
          },
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
              // Convert back to the correct unit for saving
              double heightToSave = vm.isMetric ? selectedHeight : selectedHeight / 2.54;
              vm.saveProfile(
                gender: vm.profile!.gender,
                age: vm.profile!.age,
                weight: vm.displayWeight,
                weightUnit: vm.weightUnit,
                height: heightToSave,
                heightUnit: vm.heightUnit,
                activityLevel: vm.profile!.activityLevel,
                isMetric: vm.isMetric,
                weightGoal: vm.profile!.weightGoal,
                aiProvider: vm.profile!.aiProvider,
              );
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

  Widget _buildAccountBenefit(
      BuildContext context, IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        FaIcon(
          icon,
          size: 16,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAIProviderOption(
    BuildContext context,
    UserProfileViewModel profileVM,
    UserProfile profile,
    AIProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = profile.aiProvider == provider;

    return InkWell(
      onTap: () {
        profileVM.saveProfile(
          gender: profile.gender,
          age: profile.age,
          weight: profileVM.displayWeight,
          weightUnit: profileVM.weightUnit,
          height: profileVM.displayHeight,
          heightUnit: profileVM.heightUnit,
          activityLevel: profile.activityLevel,
          isMetric: profileVM.isMetric,
          weightGoal: profile.weightGoal,
          aiProvider: provider,
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.1)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            FaIcon(
              _getAIProviderIcon(provider),
              color: isSelected
                  ? colorScheme.primary
                  : (isDark
                      ? AppColors.darkTextPrimary
                      : colorScheme.onSurface),
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          provider.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? colorScheme.primary
                                : (isDark
                                    ? AppColors.darkTextPrimary
                                    : colorScheme.onSurface),
                          ),
                        ),
                      ),
                      if (provider.isRecommended) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'RECOMMENDED',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.pricing,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: provider.isFree
                          ? AppColors.success
                          : AppColors.orange,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              FaIcon(
                FontAwesomeIcons.circleCheck,
                color: colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getAIProviderIcon(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return FontAwesomeIcons.brain;
      case AIProvider.gemini:
        return FontAwesomeIcons.gem;
      case AIProvider.claude:
        return FontAwesomeIcons.robot;
      case AIProvider.huggingface:
        return FontAwesomeIcons.code;
    }
  }
}
