import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/user_profile_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../domain/entities/user_profile.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/profile_inputs.dart';
import '../widgets/google_signin_button.dart';
import '../widgets/sign_out_button.dart';
import '../widgets/auth_loading_overlay.dart';
import '../widgets/reauth_dialog.dart';
import '../../core/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'welcome_view.dart';
import '../../services/aws_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/routes/navigation_service.dart';
import '../../core/services/connection_service.dart';
import '../../core/services/sync_service.dart';

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

  /// Helper method to build glassmorphic cards
  Widget _buildGlassmorphicCard({
    required BuildContext context,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(20),
    EdgeInsets margin = const EdgeInsets.only(bottom: 14),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        // Solid background to prevent flickering during scroll
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.grey[850]!.withOpacity(0.95),
                  Colors.grey[900]!.withOpacity(0.95),
                ]
              : [
                  Colors.white.withOpacity(0.90),
                  Colors.white.withOpacity(0.85),
                ],
        ),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.2) 
              : Colors.white.withOpacity(0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
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
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: Theme.of(context).brightness == Brightness.dark
                          ? [
                              Colors.white.withOpacity(0.12),
                              Colors.white.withOpacity(0.06),
                            ]
                          : [
                              Colors.white.withOpacity(0.90),
                              Colors.white.withOpacity(0.80),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.white.withOpacity(0.7),
                      width: 1.5,
                    ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                    unselectedLabelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    indicator: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(
                        icon: FaIcon(FontAwesomeIcons.user, size: 18),
                  text: 'Personal',
                        height: 65,
                ),
                Tab(
                        icon: FaIcon(FontAwesomeIcons.dumbbell, size: 18),
                  text: 'Activity',
                        height: 65,
                ),
                Tab(
                        icon: FaIcon(FontAwesomeIcons.bullseye, size: 18),
                  text: 'Goals',
                        height: 65,
                ),
                Tab(
                        icon: FaIcon(FontAwesomeIcons.gear, size: 18),
                  text: 'Settings',
                        height: 65,
                ),
              ],
                  ),
                ),
              ),
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
          _buildGlassmorphicCard(
            context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                const SizedBox(height: 6),
                  Text(
                    'Manage your personal details and preferences',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.05,
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
          // Add bottom padding to prevent content from being hidden behind bottom nav bar
          const SizedBox(height: 100),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.15),
            blurRadius: isDark ? 12 : 20,
            offset: isDark ? const Offset(0, 4) : const Offset(0, 10),
            spreadRadius: isDark ? 0 : 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: isDark ? 12 : 16, sigmaY: isDark ? 12 : 16),
          child: Material(
            color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
              borderRadius: BorderRadius.circular(20),
        child: Container(
                padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.white.withOpacity(0.10),
                            Colors.white.withOpacity(0.05),
                          ]
                        : [
                            Colors.white.withOpacity(0.95),
                            Colors.white.withOpacity(0.85),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(20),
            border: Border.all(
                    color: isDark 
                        ? Colors.white.withOpacity(0.15) 
                        : Colors.white.withOpacity(0.8),
                    width: isDark ? 1.2 : 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                child: FaIcon(
                  icon,
                        color: color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                  title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                    fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                    const SizedBox(height: 3),
                    Text(
                  value,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: color,
                        fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
              ),
            ],
                ),
              ),
            ),
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
          _buildGlassmorphicCard(
            context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activity Level',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                const SizedBox(height: 6),
                  Text(
                    'How active are you in your daily life?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                const SizedBox(height: 20),
                  ...ActivityLevel.values.map((level) {
                    return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
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
          // Add bottom padding to prevent content from being hidden behind bottom nav bar
          const SizedBox(height: 100),
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
          _buildGlassmorphicCard(
            context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weight Goal',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                const SizedBox(height: 6),
                  Text(
                    'What would you like to achieve?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                const SizedBox(height: 20),
                  ...WeightGoal.values.map((goal) {
                    return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
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
          // Add bottom padding to prevent content from being hidden behind bottom nav bar
          const SizedBox(height: 100),
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
          _buildGlassmorphicCard(
            context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: FaIcon(
                        FontAwesomeIcons.user,
                        color: colorScheme.primary,
                        size: 18,
                      ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Account',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),

                  // Show user details if signed in, otherwise show guest benefits
                  if (authVM.isSignedIn) ...[
                    // User Details Section
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.20),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        children: [
                          // User Profile Info
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundImage: authVM.userPhotoURL != null
                                    ? NetworkImage(authVM.userPhotoURL!)
                                    : null,
                                backgroundColor: colorScheme.primary.withOpacity(0.12),
                                child: authVM.userPhotoURL == null
                                    ? FaIcon(
                                        FontAwesomeIcons.user,
                                        size: 20,
                                        color: colorScheme.primary,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // User Name - Dynamic text size to fit content
                                    Text(
                                        authVM.userDisplayName ?? 'User',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                        maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: 3),
                                    // User Email - Dynamic text size to fit content
                                    Text(
                                        authVM.userEmail ?? '',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                        maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Sign Out Button
                          const SignOutButtonWithAuth(
                            isFullWidth: true,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Guest Benefits Section
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.20),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildAccountBenefit(
                            context,
                            FontAwesomeIcons.cloudArrowUp,
                            'Sync across devices',
                          ),
                          const SizedBox(height: 10),
                          _buildAccountBenefit(
                            context,
                            FontAwesomeIcons.shieldHalved,
                            'Backup your history',
                          ),
                          const SizedBox(height: 10),
                          _buildAccountBenefit(
                            context,
                            FontAwesomeIcons.chartLine,
                            'Advanced analytics',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const GoogleSignInButton(
                      isFullWidth: true,
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 14),
          // Subscription Section
          _buildGlassmorphicCard(
            context: context,
            padding: const EdgeInsets.all(16),
            child: Material(
              color: Colors.transparent,
            child: InkWell(
              onTap: () {
                NavigationService.navigateToSubscription(
                    returnRoute: '/profile');
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                  padding: const EdgeInsets.all(2),
                child: Row(
                  children: [
                    Container(
                        padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            AppColors.primaryDark,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.crown,
                        color: Colors.white,
                          size: 18,
                      ),
                    ),
                      const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subscription',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                            const SizedBox(height: 2),
                          Text(
                            'Manage your plan & usage',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: colorScheme.onSurface.withOpacity(0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    FaIcon(
                      FontAwesomeIcons.chevronRight,
                        color: colorScheme.onSurface.withOpacity(0.35),
                        size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
          ),
          const SizedBox(height: 14),
          // Measurement Units Section
          _buildGlassmorphicCard(
            context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: FaIcon(
                        FontAwesomeIcons.ruler,
                        color: colorScheme.primary,
                        size: 18,
                      ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Measurement Units',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 6),
                  Text(
                    'Choose your preferred measurement system',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                const SizedBox(height: 16),
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
                  const SizedBox(height: 12),
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
          const SizedBox(height: 14),
          // Appearance Section
          _buildGlassmorphicCard(
            context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: FaIcon(
                        FontAwesomeIcons.palette,
                        color: colorScheme.primary,
                        size: 18,
                      ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Appearance',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 6),
                  Text(
                    'Customize your app experience',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                const SizedBox(height: 16),
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
                            () async {
                              // Optimistic UI: Show immediate feedback
                              await themeVM.setThemeMode(ThemeMode.light);

                              // Show success message
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Theme updated successfully'),
                                    backgroundColor: AppColors.success,
                                    duration: Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildThemeOption(
                            context,
                            FontAwesomeIcons.moon,
                            'Dark Theme',
                            'Use dark colors',
                            themeVM.themeMode == ThemeMode.dark,
                            () async {
                              // Optimistic UI: Show immediate feedback
                              await themeVM.setThemeMode(ThemeMode.dark);

                              // Show success message
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Theme updated successfully'),
                                    backgroundColor: AppColors.success,
                                    duration: Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildThemeOption(
                            context,
                            FontAwesomeIcons.circleHalfStroke,
                            'System Theme',
                            'Follow system settings',
                            themeVM.themeMode == ThemeMode.system,
                            () async {
                              // Optimistic UI: Show immediate feedback
                              await themeVM.setThemeMode(ThemeMode.system);

                              // Show success message
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Theme updated successfully'),
                                    backgroundColor: AppColors.success,
                                    duration: Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          // Notification Settings Section
          _buildGlassmorphicCard(
            context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: FaIcon(
                        FontAwesomeIcons.bell,
                        color: colorScheme.primary,
                        size: 18,
                      ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Notifications',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 6),
                  Text(
                    'Manage your notification preferences',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                const SizedBox(height: 16),
                  _buildNotificationSettings(context, authVM),
                ],
            ),
          ),
          const SizedBox(height: 16),
          // Danger Zone Section - Only show if user is signed in
          if (authVM.isSignedIn) ...[
            _buildDangerZoneCard(context, authVM, colorScheme),
          ],
          // Add bottom padding to prevent content from being hidden behind bottom nav bar
          const SizedBox(height: 100),
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
            // Use SyncService to try sync immediately (if online) or mark for later (if offline)
            final syncService = SyncService();
            final success = await syncService.trySyncNotificationSettings(
              user.uid,
              value,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
      onTap: onTap,
        borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            colorScheme.primary.withOpacity(0.20),
                            colorScheme.primary.withOpacity(0.10),
                          ]
                        : [
                            colorScheme.primary.withOpacity(0.15),
                            colorScheme.primary.withOpacity(0.08),
                          ],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                  : colorScheme.outline.withOpacity(0.3),
              width: 1.5,
            ),
        ),
        child: Row(
          children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? colorScheme.primary.withOpacity(0.15)
                      : colorScheme.onSurface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FaIcon(
              icon,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.7),
                  size: 20,
            ),
              ),
              const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colorScheme.onSurface.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              FaIcon(
                FontAwesomeIcons.circleCheck,
                color: colorScheme.primary,
                  size: 18,
              ),
          ],
          ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FaIcon(
          icon,
            size: 14,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZoneCard(
      BuildContext context, AuthViewModel authVM, ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _buildGlassmorphicCard(
      context: context,
      margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.red.shade400.withOpacity(0.15)
                      : Colors.red.shade100.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FaIcon(
                    FontAwesomeIcons.triangleExclamation,
                    color: isDark ? Colors.red.shade400 : Colors.red.shade600,
                  size: 18,
                ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Danger Zone',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.red.shade400 : Colors.red.shade600,
                    ),
                  ),
                ],
              ),
          const SizedBox(height: 6),
              Text(
                'Irreversible and destructive actions',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
              // Delete Account Button
              _buildDeleteAccountButton(context, authVM),
            ],
      ),
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context, AuthViewModel authVM) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: authVM.isLoading
            ? null
            : () {
                // Check network connection FIRST before any UI actions
                final connectionService = ConnectionService();
                if (!connectionService.isConnected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.wifi_off, color: Colors.white),
                          SizedBox(width: 12),
                          Text('No internet connection'),
                        ],
                      ),
                      backgroundColor: Colors.red[700],
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return; // Block delete account dialog
                }
                _showDeleteAccountDialog(context, authVM);
              },
        icon: const FaIcon(
          FontAwesomeIcons.trash,
          size: 16,
        ),
        label: const Text(
          'Delete Account',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
          foregroundColor: AppColors.error,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppColors.error.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthViewModel authVM) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              FaIcon(
                FontAwesomeIcons.triangleExclamation,
                color: isDark ? Colors.red.shade400 : Colors.red.shade600,
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
                  color: isDark
                      ? Colors.red.shade900.withOpacity(0.3)
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? Colors.red.shade400.withOpacity(0.3)
                        : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.circleExclamation,
                      color: isDark ? Colors.red.shade400 : Colors.red.shade600,
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
                backgroundColor:
                    isDark ? Colors.red.shade700 : Colors.red.shade600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: isDark ? 4 : 2,
                shadowColor: isDark
                    ? Colors.red.shade400.withOpacity(0.3)
                    : Colors.red.shade600.withOpacity(0.3),
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

  static Future<void> _handleDeleteAccount(
      BuildContext context, AuthViewModel authVM) async {
    // Show loading overlay immediately after confirmation
    AuthLoadingOverlay.showLoading(
      context,
      message: 'Deleting your account...',
    );

    try {
      // Use the new context-aware deleteUser method
      final success = await authVM.deleteUser(context);

      // Hide loading overlay
      if (context.mounted) {
        AuthLoadingOverlay.hideLoading(context);
      }

      if (!success && context.mounted) {
        // Check if re-authentication is needed
        final errorMessage = authVM.errorMessage ?? '';

        if (errorMessage.contains('sign in again') ||
            errorMessage.contains('cancelled')) {
          // Show re-authentication dialog with better UX
          final shouldReauth = await ReauthDialog.showForAccountDeletion(
            context,
            () async {
              // Re-attempt deletion after user confirms with reauthentication
              await _handleDeleteAccountWithReauth(context, authVM);
            },
          );

          if (shouldReauth != true) {
            // User cancelled re-authentication
            return;
          }
        } else {
          // Show generic error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage.isNotEmpty
                  ? errorMessage
                  : 'Failed to delete account. Please try again.'),
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
      // Note: Success case (success == true) is handled automatically by AuthViewModel
      // which shows success message and navigates to welcome screen
    } catch (e) {
      // Hide loading overlay on error
      if (context.mounted) {
        AuthLoadingOverlay.hideLoading(context);
      }

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

  /// Handle delete account with reauthentication after user confirms
  static Future<void> _handleDeleteAccountWithReauth(
    BuildContext context,
    AuthViewModel authVM,
  ) async {
    // Show loading overlay immediately after confirmation
    AuthLoadingOverlay.showLoading(
      context,
      message: 'Deleting your account...',
    );

    try {
      // Use the new reauthentication method
      final success = await authVM.deleteUserWithReauth();

      // Hide loading overlay
      if (context.mounted) {
        AuthLoadingOverlay.hideLoading(context);
      }

      if (!success && context.mounted) {
        // Show error message
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
      // Note: Success case is handled automatically by AuthViewModel
    } catch (e) {
      // Hide loading overlay on error
      if (context.mounted) {
        AuthLoadingOverlay.hideLoading(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: widget.colorScheme.primary.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
      onTap: _isLoading ? null : _handleSelection,
              borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  widget.colorScheme.primary.withOpacity(0.20),
                                  widget.colorScheme.primary.withOpacity(0.10),
                                ]
                              : [
                                  widget.colorScheme.primary.withOpacity(0.15),
                                  widget.colorScheme.primary.withOpacity(0.08),
                                ],
                        )
                      : null,
          color: isSelected
                      ? null
                      : isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.white.withOpacity(0.50),
                  borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? widget.colorScheme.primary
                        : isDark
                            ? Colors.white.withOpacity(0.10)
                            : Colors.white.withOpacity(0.40),
                    width: 1.5,
          ),
        ),
        child: Row(
          children: [
            if (_isLoading && isSelected)
              SizedBox(
                        width: 28,
                        height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.colorScheme.primary,
                  ),
                ),
              )
            else
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? widget.colorScheme.primary.withOpacity(0.15)
                              : widget.colorScheme.onSurface.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: FaIcon(
                widget.icon,
                color: isSelected
                    ? widget.colorScheme.primary
                              : widget.colorScheme.onSurface.withOpacity(0.7),
                          size: 20,
              ),
                      ),
                    const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                      color: isSelected
                          ? widget.colorScheme.primary
                          : widget.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    widget.subtitle,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: widget.colorScheme.onSurface.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected && !_isLoading)
              FaIcon(
                FontAwesomeIcons.circleCheck,
                color: widget.colorScheme.primary,
                        size: 18,
              ),
          ],
                ),
              ),
            ),
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.50),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.10)
              : Colors.white.withOpacity(0.40),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FaIcon(
            FontAwesomeIcons.bell,
            color: widget.colorScheme.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Notifications',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Receive notifications from Foody',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: widget.colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.colorScheme.primary,
                ),
              ),
            )
          else
            Transform.scale(
              scale: 0.85,
              child: Switch(
              value: _notificationsEnabled,
              onChanged: _handleToggle,
              activeColor: widget.colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}
