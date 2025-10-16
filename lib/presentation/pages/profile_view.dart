import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_profile_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/ai_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/profile_inputs.dart';
import '../widgets/google_signin_button.dart';
import '../widgets/sign_out_button.dart';
import '../../core/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'welcome_view.dart';
import '../../services/notification_service.dart';
import '../../services/aws_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    final profile = profileVM.profile;
    final colorScheme = Theme.of(context).colorScheme;

    // Handle case where profile is null
    if (profile == null) {
      final authVM = Provider.of<AuthViewModel>(context, listen: false);

      // If user is not signed in (after deletion), redirect to welcome page
      if (!authVM.isSignedIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            (route) => false,
          );
        });
        return const Scaffold(
          appBar: CustomAppBar(
            title: 'Profile',
            icon: FontAwesomeIcons.user,
          ),
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // If user is signed in but profile not loaded yet, show loading
      return const Scaffold(
        appBar: CustomAppBar(
          title: 'Profile',
          icon: FontAwesomeIcons.user,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
                    childAspectRatio:
                        1.1, // Reduced from 1.2 to 1.1 to give more height
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
          padding: const EdgeInsets.all(10), // Reduced from 12 to 10
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
              Flexible(
                child: FaIcon(
                  icon,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                  size: 24, // Reduced from 28 to 24
                ),
              ),
              const SizedBox(height: 4), // Reduced from 6 to 4
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13, // Reduced from 14 to 13
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 1), // Reduced from 2 to 1
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12, // Reduced from 13 to 12
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ProfileSettingOption<ActivityLevel>(
                        value: level,
                        selectedValue: profile.activityLevel,
                        colorScheme: colorScheme,
                        icon: _getActivityIcon(level),
                        title: level.displayName,
                        subtitle: _getActivityDescription(level),
                        categoryName: 'Activity Level',
                        onSelect: (selectedLevel) async {
                          try {
                            await profileVM.saveProfile(
                              gender: profile.gender,
                              age: profile.age,
                              weight: profileVM.displayWeight,
                              weightUnit: profileVM.weightUnit,
                              height: profileVM.displayHeight,
                              heightUnit: profileVM.heightUnit,
                              activityLevel: selectedLevel,
                              isMetric: profileVM.isMetric,
                              weightGoal: profile.weightGoal,
                              aiProvider: profile.aiProvider,
                            );
                            return true;
                          } catch (e) {
                            print('Error saving activity level: $e');
                            return false;
                          }
                        },
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
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ProfileSettingOption<WeightGoal>(
                        value: goal,
                        selectedValue: profile.weightGoal,
                        colorScheme: colorScheme,
                        icon: _getWeightGoalIcon(goal),
                        title: goal.displayName,
                        subtitle: _getWeightGoalDescription(goal),
                        categoryName: 'Weight Goal',
                        onSelect: (selectedGoal) async {
                          try {
                            await profileVM.saveProfile(
                              gender: profile.gender,
                              age: profile.age,
                              weight: profileVM.displayWeight,
                              weightUnit: profileVM.weightUnit,
                              height: profileVM.displayHeight,
                              heightUnit: profileVM.heightUnit,
                              activityLevel: profile.activityLevel,
                              isMetric: profileVM.isMetric,
                              weightGoal: selectedGoal,
                              aiProvider: profile.aiProvider,
                            );
                            return true;
                          } catch (e) {
                            return false;
                          }
                        },
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
    final profile = profileVM.profile;
    final authVM = Provider.of<AuthViewModel>(context);

    // Handle case where profile is not yet loaded
    if (profile == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Account Section
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

                  // Show user details if signed in, otherwise show guest benefits
                  if (authVM.isSignedIn) ...[
                    // User Details Section
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
                          // User Profile Info
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: authVM.userPhotoURL != null
                                    ? NetworkImage(authVM.userPhotoURL!)
                                    : null,
                                child: authVM.userPhotoURL == null
                                    ? FaIcon(
                                        FontAwesomeIcons.user,
                                        size: 24,
                                        color: colorScheme.primary,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // User Name - Dynamic text size to fit content
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        authVM.userDisplayName ?? 'User',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface,
                                        ),
                                        maxLines: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // User Email - Dynamic text size to fit content
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        authVM.userEmail ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: colorScheme.onSurface
                                              .withOpacity(0.7),
                                        ),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Sign Out Button
                          const SignOutButtonWithAuth(
                            isFullWidth: true,
                          ),
                          const SizedBox(height: 12),
                          // Delete Account Button
                          _buildDeleteAccountButton(context, authVM),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Guest Benefits Section
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
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
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
                      child: _ProfileSettingOption<AIProvider>(
                        value: provider,
                        selectedValue: profile.aiProvider,
                        colorScheme: colorScheme,
                        icon: _getAIProviderIcon(provider),
                        title: provider.displayName,
                        subtitle: provider.pricing,
                        categoryName: 'AI Provider',
                        onSelect: (selectedProvider) async {
                          try {
                            await profileVM.saveProfile(
                              gender: profile.gender,
                              age: profile.age,
                              weight: profileVM.displayWeight,
                              weightUnit: profileVM.weightUnit,
                              height: profileVM.displayHeight,
                              heightUnit: profileVM.heightUnit,
                              activityLevel: profile.activityLevel,
                              isMetric: profileVM.isMetric,
                              weightGoal: profile.weightGoal,
                              aiProvider: selectedProvider,
                            );
                            return true;
                          } catch (e) {
                            return false;
                          }
                        },
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
                  _ProfileSettingOption<bool>(
                    value: true,
                    selectedValue: profileVM.isMetric,
                    colorScheme: colorScheme,
                    icon: FontAwesomeIcons.globe,
                    title: 'Metric (kg, cm)',
                    subtitle: 'Use kilograms and centimeters',
                    categoryName: 'Measurement Units',
                    onSelect: (isMetric) async {
                      try {
                        final newWeight = profileVM.displayWeight * 0.453592;
                        final newHeight = profileVM.displayHeight * 2.54;
                        await profileVM.saveProfile(
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
                        return true;
                      } catch (e) {
                        return false;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _ProfileSettingOption<bool>(
                    value: false,
                    selectedValue: profileVM.isMetric,
                    colorScheme: colorScheme,
                    icon: FontAwesomeIcons.flag,
                    title: 'Imperial (lbs, ft)',
                    subtitle: 'Use pounds and feet/inches',
                    categoryName: 'Measurement Units',
                    onSelect: (isMetric) async {
                      try {
                        final newWeight = profileVM.displayWeight * 2.20462;
                        final newHeight = profileVM.displayHeight / 2.54;
                        await profileVM.saveProfile(
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
                        return true;
                      } catch (e) {
                        return false;
                      }
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
          const SizedBox(height: 16),
          // Notification Settings Section
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
                        FontAwesomeIcons.bell,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Notifications',
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
                    'Manage your notification preferences',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildNotificationSettings(context, authVM),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings(
      BuildContext context, AuthViewModel authVM) {
    return _buildNotificationToggle(context, authVM);
  }

  Widget _buildNotificationToggle(BuildContext context, AuthViewModel authVM) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.5),
          ),
        ),
        child: Text(
          'Please sign in to manage notifications',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserNotificationStatus(user.uid),
      builder: (context, snapshot) {
        final initialValue = snapshot.hasData && snapshot.data != null
            ? snapshot.data!['notifications_enabled'] ?? true
            : true;

        return _NotificationToggleWidget(
          initialValue: initialValue,
          colorScheme: colorScheme,
          onToggle: (value) async {
            final notificationService = NotificationService();
            final success = await notificationService.updateNotificationPreferences(
              userId: user.uid,
              notificationsEnabled: value,
            );
            return success;
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _getUserNotificationStatus(
      String userId) async {
    try {
      final awsService = AWSService();
      return await awsService.getUserProfile(userId);
    } catch (e) {
      print('Error getting user notification status: $e');
      return null;
    }
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
    final profile = vm.profile;

    if (profile == null) return;

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
                profile.gender == 'Male'
                    ? FontAwesomeIcons.circleCheck
                    : FontAwesomeIcons.circle,
                color: profile.gender == 'Male'
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.5),
              ),
              onTap: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                navigator.pop();
                try {
                  await vm.saveProfile(
                    gender: 'Male',
                    age: profile.age,
                    weight: vm.displayWeight,
                    weightUnit: vm.weightUnit,
                    height: vm.displayHeight,
                    heightUnit: vm.heightUnit,
                    activityLevel: profile.activityLevel,
                    isMetric: vm.isMetric,
                    weightGoal: profile.weightGoal,
                    aiProvider: profile.aiProvider,
                  );
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('Gender updated successfully'),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('Failed to update gender'),
                      backgroundColor: AppColors.error,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
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
                profile.gender == 'Female'
                    ? FontAwesomeIcons.circleCheck
                    : FontAwesomeIcons.circle,
                color: profile.gender == 'Female'
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.5),
              ),
              onTap: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                navigator.pop();
                try {
                  await vm.saveProfile(
                    gender: 'Female',
                    age: profile.age,
                    weight: vm.displayWeight,
                    weightUnit: vm.weightUnit,
                    height: vm.displayHeight,
                    heightUnit: vm.heightUnit,
                    activityLevel: profile.activityLevel,
                    isMetric: vm.isMetric,
                    weightGoal: profile.weightGoal,
                    aiProvider: profile.aiProvider,
                  );
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('Gender updated successfully'),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('Failed to update gender'),
                      backgroundColor: AppColors.error,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAgeDialog(BuildContext context, UserProfileViewModel vm) {
    final colorScheme = Theme.of(context).colorScheme;
    final profile = vm.profile;

    if (profile == null) return;

    int selectedAge = profile.age;

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
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              try {
                await vm.saveProfile(
                  gender: profile.gender,
                  age: selectedAge,
                  weight: vm.displayWeight,
                  weightUnit: vm.weightUnit,
                  height: vm.displayHeight,
                  heightUnit: vm.heightUnit,
                  activityLevel: profile.activityLevel,
                  isMetric: vm.isMetric,
                  weightGoal: profile.weightGoal,
                  aiProvider: profile.aiProvider,
                );
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Age updated successfully'),
                    backgroundColor: AppColors.success,
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Failed to update age'),
                    backgroundColor: AppColors.error,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
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
    final profile = vm.profile;

    if (profile == null) return;

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
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              try {
                await vm.saveProfile(
                  gender: profile.gender,
                  age: profile.age,
                  weight: selectedWeight,
                  weightUnit: vm.weightUnit,
                  height: vm.displayHeight,
                  heightUnit: vm.heightUnit,
                  activityLevel: profile.activityLevel,
                  isMetric: vm.isMetric,
                  weightGoal: profile.weightGoal,
                  aiProvider: profile.aiProvider,
                );
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Weight updated successfully'),
                    backgroundColor: AppColors.success,
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Failed to update weight'),
                    backgroundColor: AppColors.error,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
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
    final profile = vm.profile;

    if (profile == null) return;

    // HeightInput widget expects height in cm for both metric and imperial
    // For imperial, it will convert cm to feet/inches internally
    double selectedHeight =
        vm.isMetric ? vm.displayHeight : vm.displayHeight * 2.54;

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
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              try {
                // Convert back to the correct unit for saving
                double heightToSave =
                    vm.isMetric ? selectedHeight : selectedHeight / 2.54;
                await vm.saveProfile(
                  gender: profile.gender,
                  age: profile.age,
                  weight: vm.displayWeight,
                  weightUnit: vm.weightUnit,
                  height: heightToSave,
                  heightUnit: vm.heightUnit,
                  activityLevel: profile.activityLevel,
                  isMetric: vm.isMetric,
                  weightGoal: profile.weightGoal,
                  aiProvider: profile.aiProvider,
                );
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Height updated successfully'),
                    backgroundColor: AppColors.success,
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Failed to update height'),
                    backgroundColor: AppColors.error,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
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

  Widget _buildDeleteAccountButton(BuildContext context, AuthViewModel authVM) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: authVM.isLoading
            ? null
            : () => _showDeleteAccountDialog(context, authVM),
        icon: authVM.isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.red.shade300,
                  ),
                ),
              )
            : const FaIcon(
                FontAwesomeIcons.trash,
                size: 16,
              ),
        label: Text(
          authVM.isLoading ? 'Deleting Account...' : 'Delete Account',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthViewModel authVM) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              FaIcon(
                FontAwesomeIcons.triangleExclamation,
                color: Colors.red.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text('Delete Account'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to delete your account?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This action will permanently delete:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildDeleteWarningItem('Your profile and personal information'),
              _buildDeleteWarningItem('All your food analysis history'),
              _buildDeleteWarningItem('Your account settings and preferences'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.circleExclamation,
                      color: Colors.red.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'This action cannot be undone!',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _handleDeleteAccount(context, authVM);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Delete Account',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeleteWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.solidCircle,
            size: 6,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount(
      BuildContext context, AuthViewModel authVM) async {
    try {
      // Use the new context-aware deleteUser method
      final success = await authVM.deleteUser(context);

      if (!success && context.mounted) {
        // Deletion failed - show error message
        // (Success case is now handled by AuthViewModel + AuthenticationFlow)
        final errorMessage = authVM.errorMessage ??
            'Failed to delete account. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: AppColors.white,
              onPressed: () => _handleDeleteAccount(context, authVM),
            ),
          ),
        );
      }
      // Note: Success case (success == true) is handled automatically by AuthViewModel
      // which shows success message and navigates to welcome screen
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: AppColors.white,
              onPressed: () => _handleDeleteAccount(context, authVM),
            ),
          ),
        );
      }
    }
  }
}

/// Generic stateful widget for profile setting options with optimistic updates
class _ProfileSettingOption<T> extends StatefulWidget {
  final T value;
  final T selectedValue;
  final ColorScheme colorScheme;
  final IconData icon;
  final String title;
  final String subtitle;
  final String categoryName; // Main category name for success message
  final Future<bool> Function(T value) onSelect;

  const _ProfileSettingOption({
    required this.value,
    required this.selectedValue,
    required this.colorScheme,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.categoryName,
    required this.onSelect,
  });

  @override
  State<_ProfileSettingOption<T>> createState() =>
      _ProfileSettingOptionState<T>();
}

class _ProfileSettingOptionState<T> extends State<_ProfileSettingOption<T>> {
  bool _isLoading = false;
  T? _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.selectedValue;
  }

  @override
  void didUpdateWidget(_ProfileSettingOption<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedValue != oldWidget.selectedValue) {
      _currentValue = widget.selectedValue;
    }
  }

  Future<void> _handleSelection() async {
    if (_isLoading) return;
    if (_currentValue == widget.value) return; // Already selected

    setState(() {
      _isLoading = true;
      _currentValue = widget.value; // Optimistic update
    });

    try {
      final success = await widget.onSelect(widget.value);

      if (success) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.categoryName} updated successfully'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } else {
        // Revert on failure
        setState(() {
          _currentValue = widget.selectedValue;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update ${widget.categoryName}'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              action: SnackBarAction(
                label: 'Retry',
                textColor: AppColors.white,
                onPressed: _handleSelection,
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _currentValue = widget.selectedValue;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = _currentValue == widget.value;

    return InkWell(
      onTap: _isLoading ? null : _handleSelection,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? widget.colorScheme.primary.withOpacity(0.1)
              : widget.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? widget.colorScheme.primary
                : widget.colorScheme.outline.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            if (_isLoading && isSelected)
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.colorScheme.primary,
                  ),
                ),
              )
            else
              FaIcon(
                widget.icon,
                color:
                    isSelected ? widget.colorScheme.primary : widget.colorScheme.onSurface,
                size: 32,
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? widget.colorScheme.primary
                          : widget.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected && !_isLoading)
              FaIcon(
                FontAwesomeIcons.circleCheck,
                color: widget.colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

/// Stateful widget to manage notification toggle state
class _NotificationToggleWidget extends StatefulWidget {
  final bool initialValue;
  final ColorScheme colorScheme;
  final Future<bool> Function(bool value) onToggle;

  const _NotificationToggleWidget({
    required this.initialValue,
    required this.colorScheme,
    required this.onToggle,
  });

  @override
  State<_NotificationToggleWidget> createState() =>
      _NotificationToggleWidgetState();
}

class _NotificationToggleWidgetState extends State<_NotificationToggleWidget> {
  late bool _notificationsEnabled;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = widget.initialValue;
  }

  Future<void> _handleToggle(bool value) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await widget.onToggle(value);

      if (success) {
        setState(() {
          _notificationsEnabled = value;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                value
                    ? 'Notifications enabled successfully'
                    : 'Notifications disabled successfully',
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to update notification preferences'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              action: SnackBarAction(
                label: 'Retry',
                textColor: AppColors.white,
                onPressed: () => _handleToggle(value),
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.bell,
            color: widget.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Notifications',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Receive notifications from Foody',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.colorScheme.primary,
                ),
              ),
            )
          else
            Switch(
              value: _notificationsEnabled,
              onChanged: _handleToggle,
              activeColor: widget.colorScheme.primary,
            ),
        ],
      ),
    );
  }
}
