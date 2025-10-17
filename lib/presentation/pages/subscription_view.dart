import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../domain/entities/subscription_tier.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../config/routes/navigation_service.dart';

class SubscriptionView extends StatefulWidget {
  final String? returnRoute;

  const SubscriptionView({super.key, this.returnRoute});

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  // Mock data - In real app, this would come from a ViewModel
  UserSubscription currentSubscription = UserSubscription(
    tier: SubscriptionTier.free,
    scansUsedThisMonth: 3,
  );

  bool isYearly = true; // Default to yearly plan

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.white,
      appBar: CustomAppBar(
        title: 'Subscription',
        icon: FontAwesomeIcons.crown,
        showInfoButton: false,
        leadingIcon: null, // Remove back button
        actions: [
          IconButton(
            icon: FaIcon(
              FontAwesomeIcons.xmark,
              color: isDark ? AppColors.darkTextSecondary : AppColors.grey600,
            ),
            onPressed: () {
              if (widget.returnRoute != null) {
                // Handle specific return routes
                switch (widget.returnRoute) {
                  case '/profile':
                    // From profile page - go back to profile
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/profile',
                      (route) => false,
                    );
                    break;
                  case '/home':
                    // From home page - go back to home
                    NavigationService.navigateToHome();
                    break;
                  case '/analyze':
                    // From analyze page - go to home and clear all previous pages
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/home',
                      (route) => false,
                    );
                    break;
                  default:
                    // Default behavior for other routes
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      widget.returnRoute!,
                      (route) => false,
                    );
                }
              } else {
                // No return route specified - check navigation stack
                final navigator = Navigator.of(context);
                final canPop = navigator.canPop();

                if (canPop) {
                  // Check the previous route for special handling
                  final previousRoute = ModalRoute.of(context)?.settings.name;
                  print('Previous route: $previousRoute'); // Debug

                  switch (previousRoute) {
                    case '/analysis-loading':
                      // From analysis flow - go to home and clear all previous pages
                      print('Going to home from analysis-loading'); // Debug
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/home',
                        (route) => false,
                      );
                      break;
                    case '/analyze':
                      // From analyze page - go to home and clear all previous pages
                      print('Going to home from analyze'); // Debug
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/home',
                        (route) => false,
                      );
                      break;
                    default:
                      // From other pages - go back normally
                      print(
                          'Going back normally from: $previousRoute'); // Debug
                      navigator.pop();
                  }
                } else {
                  // No previous page - go to home (this happens when analysis loading was replaced)
                  print('No previous page, going to home'); // Debug
                  NavigationService.navigateToHome();
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // Current Plan Card with Glassmorphism
                  _buildCurrentPlanCard(context, isDark),

                  const SizedBox(height: 32),

                  // Subscription Plans
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'Choose Your Plan',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Unlock unlimited scans and premium features',
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Monthly/Yearly Toggle with Glassmorphism
                        _buildPlanToggle(context, isDark),

                        const SizedBox(height: 24),

                        // Pro Plan Card with Glassmorphism
                        _buildProPlanCard(context, isDark),

                        const SizedBox(height: 24),

                        // Features List with Glassmorphism
                        _buildFeaturesList(context, isDark),

                        const SizedBox(height: 89), // Space for fixed button
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Start Free Trial Button with Glassmorphism (Fixed at bottom)
          _buildTrialButton(context, isDark),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanCard(BuildContext context, bool isDark) {
    final tier = currentSubscription.tier;
    final scansRemaining = currentSubscription.scansRemaining;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Consumer<AuthViewModel>(
                      builder: (context, authViewModel, child) {
                        final photoUrl = authViewModel.userPhotoURL;
                        return CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          backgroundImage:
                              photoUrl != null ? NetworkImage(photoUrl) : null,
                          child: photoUrl == null
                              ? FaIcon(
                                  tier == SubscriptionTier.pro
                                      ? FontAwesomeIcons.crown
                                      : tier == SubscriptionTier.trial
                                          ? FontAwesomeIcons.clock
                                          : FontAwesomeIcons.user,
                                  color: AppColors.primary,
                                  size: 20,
                                )
                              : null,
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Plan',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tier.displayName,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          if (tier == SubscriptionTier.trial &&
                              currentSubscription.isTrialActive)
                            Row(
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.clock,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${currentSubscription.daysRemainingInTrial} days left in trial',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else if (tier.isUnlimited)
                            Row(
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.infinity,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Unlimited scans',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                Row(
                                  children: [
                                    FaIcon(
                                      FontAwesomeIcons.chartSimple,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '$scansRemaining/${tier.maxScansPerMonth} scans left this month',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: scansRemaining != null &&
                                            tier.maxScansPerMonth != null
                                        ? scansRemaining /
                                            tier.maxScansPerMonth!
                                        : 0,
                                    backgroundColor: isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.1),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      AppColors.primary,
                                    ),
                                    minHeight: 8,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanToggle(BuildContext context, bool isDark) {
    return Row(
      children: [
        // Monthly Button (50% width)
        Expanded(
          child: _buildToggleOption(
            context,
            isDark,
            'Monthly',
            '€2.99/mo',
            !isYearly,
            () => setState(() => isYearly = false),
            showBadge: false,
          ),
        ),
        const SizedBox(width: 12),
        // Yearly Button (50% width)
        Expanded(
          child: _buildToggleOption(
            context,
            isDark,
            'Yearly',
            '€29.99/yr',
            isYearly,
            () => setState(() => isYearly = true),
            showBadge: false,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleOption(
    BuildContext context,
    bool isDark,
    String title,
    String subtitle,
    bool isSelected,
    VoidCallback onTap, {
    bool showBadge = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: 80, // Fixed height for both buttons
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.3)),
              width: isSelected ? 2 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary),
                    ),
                  ),
                  if (showBadge) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.2)
                            : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.3)
                              : AppColors.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'RECOMMENDED',
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.primary,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10, // Reduced to match Pro plan card
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.9)
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProPlanCard(BuildContext context, bool isDark) {
    final price = isYearly ? '€29.99' : '€2.99';
    final period = isYearly ? 'year' : 'month';

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Pro Plan',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                if (isYearly) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      'RECOMMENDED',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Everything you need to succeed',
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 28, // Reduced from 56 to 28 (50% reduction)
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          '/$period',
                          style: TextStyle(
                            fontSize:
                                10, // Reduced from 20 to 10 (50% reduction)
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (isYearly) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Save 17%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesList(BuildContext context, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What You Get',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              _buildFeatureItem(
                  isDark, 'Unlimited food scans', FontAwesomeIcons.infinity),
              _buildFeatureItem(
                  isDark, 'Barcode scanner', FontAwesomeIcons.barcode),
              _buildFeatureItem(
                  isDark, 'Ad-free experience', FontAwesomeIcons.ban),
              _buildFeatureItem(isDark, 'Advanced nutrition insights',
                  FontAwesomeIcons.chartLine),
              _buildFeatureItem(
                  isDark, 'Priority support', FontAwesomeIcons.headset),
              _buildFeatureItem(
                  isDark, 'Early access to features', FontAwesomeIcons.rocket,
                  isLast: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(bool isDark, String title, IconData icon,
      {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: FaIcon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialButton(BuildContext context, bool isDark) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primaryDark,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _handleStartTrial(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: const Center(
                          child: Text(
                            'Start Free Trial',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '3 days free, then ${isYearly ? "€29.99/year" : "€2.99/month"}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleStartTrial() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Starting free trial...'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
