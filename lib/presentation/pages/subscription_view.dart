import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../domain/entities/subscription_tier.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../../config/routes/navigation_service.dart';
import '../viewmodels/auth_viewmodel.dart';

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

  bool isYearly = false; // Default to monthly plan

  /// Helper method to build glassmorphic cards (matching profile_view.dart style)
  Widget _buildGlassmorphicCard({
    required BuildContext context,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(14),
    EdgeInsets margin = const EdgeInsets.only(bottom: 10),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      appBar: CustomAppBar(
        title: 'Subscription',
        icon: FontAwesomeIcons.crown,
        showInfoButton: false,
        leadingIcon: null,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: FaIcon(
                FontAwesomeIcons.xmark,
                color: isDark ? AppColors.darkTextSecondary : AppColors.grey600,
                size: 18,
              ),
              onPressed: () => _handleClose(context),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Premium Hero Section
                  _buildHeroSection(context, isDark, colorScheme),

                  const SizedBox(height: 12),

                  // Pricing Toggle
                  _buildPricingHeader(context, isDark, colorScheme),

                  const SizedBox(height: 12),

                  // Feature Highlights
                  _buildFeatureHighlights(context, isDark, colorScheme),

                  const SizedBox(height: 12),

                  // Comparison Section removed as requested

                  const SizedBox(height: 60), // Reduced space for fixed button
                ],
              ),
            ),
          ),

          // Start Free Trial Button (Fixed at bottom)
          _buildTrialButton(context, isDark, colorScheme),
        ],
      ),
    );
  }

  void _handleClose(BuildContext context) {
    if (widget.returnRoute != null) {
      switch (widget.returnRoute) {
        case '/profile':
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/profile', (route) => false);
          break;
        case '/home':
          NavigationService.navigateToHome();
          break;
        case '/analyze':
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/home', (route) => false);
          break;
        default:
          Navigator.of(context)
              .pushNamedAndRemoveUntil(widget.returnRoute!, (route) => false);
      }
    } else {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      } else {
        NavigationService.navigateToHome();
      }
    }
  }

  // Premium Hero Section inspired by Apple/Calm
  Widget _buildHeroSection(
      BuildContext context, bool isDark, ColorScheme colorScheme) {
    final tier = currentSubscription.tier;
    final authVM = Provider.of<AuthViewModel>(context, listen: false);

    return _buildGlassmorphicCard(
      context: context,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            tier == SubscriptionTier.free
                ? 'Transform Your Health Journey'
                : 'You\'re a Pro!',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            tier == SubscriptionTier.free
                ? 'Join thousands who\'ve discovered the power of smart nutrition tracking'
                : 'Enjoy unlimited access to all features',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: colorScheme.onSurface.withOpacity(0.7),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (tier != SubscriptionTier.free) ...[
            const SizedBox(height: 16),
            _buildCurrentPlanBadge(context, isDark, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentPlanBadge(
      BuildContext context, bool isDark, ColorScheme colorScheme) {
    final tier = currentSubscription.tier;
    final scansRemaining = currentSubscription.scansRemaining;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: tier == SubscriptionTier.trial && currentSubscription.isTrialActive
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons.clock,
                  color: colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 10),
                Text(
                  '${currentSubscription.daysRemainingInTrial} days left in trial',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            )
          : tier.isUnlimited
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.infinity,
                      color: colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Unlimited scans',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.chartSimple,
                          color: colorScheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$scansRemaining/${tier.maxScansPerMonth} scans remaining',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: scansRemaining != null &&
                                tier.maxScansPerMonth != null
                            ? scansRemaining / tier.maxScansPerMonth!
                            : 0,
                        backgroundColor:
                            colorScheme.onSurface.withOpacity(0.15),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
    );
  }

  // Pricing Header Section
  Widget _buildPricingHeader(
      BuildContext context, bool isDark, ColorScheme colorScheme) {
    final price = isYearly ? '€2.50' : '€2.99';
    final period = 'month';
    final billingNote = isYearly ? 'billed annually as €29.99' : null;

    return Column(
      children: [
        // Toggle Buttons (moved to top)
        _buildGlassmorphicCard(
          context: context,
          padding: const EdgeInsets.all(6),
          margin: EdgeInsets.zero,
          child: Row(
            children: [
              Expanded(
                child: _buildToggleOption(
                  context,
                  isDark,
                  colorScheme,
                  'Monthly',
                  !isYearly,
                  () => setState(() => isYearly = false),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildToggleOption(
                  context,
                  isDark,
                  colorScheme,
                  'Yearly',
                  isYearly,
                  () => setState(() => isYearly = true),
                  showBadge: false, // Remove badge from button
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        // Price Display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              price,
              style: GoogleFonts.poppins(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                height: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 3),
              child: Text(
                '/$period',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
        // Fixed height space for billing note to prevent button movement
        SizedBox(
          height: 24, // Reduced height
          child: billingNote != null
              ? Column(
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      billingNote,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : null,
        ),
      ],
    );
  }

  Widget _buildToggleOption(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
    String title,
    bool isSelected,
    VoidCallback onTap, {
    bool showBadge = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : colorScheme.onSurface.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : colorScheme.onSurface,
                ),
              ),
              if (showBadge) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.25)
                        : AppColors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '€2.50/month',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.green,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Feature Highlights Section
  Widget _buildFeatureHighlights(
      BuildContext context, bool isDark, ColorScheme colorScheme) {
    return _buildGlassmorphicCard(
      context: context,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Everything Included',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            context,
            icon: FontAwesomeIcons.infinity,
            title: 'Unlimited Scans',
            description: 'Analyze as many foods as you want',
            color: colorScheme.primary,
          ),
          _buildFeatureItem(
            context,
            icon: FontAwesomeIcons.barcode,
            title: 'Barcode Scanner',
            description: 'Instant nutrition info from barcodes',
            color: colorScheme.secondary,
          ),
          _buildFeatureItem(
            context,
            icon: FontAwesomeIcons.chartLine,
            title: 'Advanced Insights',
            description: 'Detailed nutrition analysis & trends',
            color: AppColors.orange,
          ),
          _buildFeatureItem(
            context,
            icon: FontAwesomeIcons.eyeSlash,
            title: 'Ad-Free Experience',
            description: 'Focus on your health without distractions',
            color: colorScheme.tertiary,
          ),
          _buildFeatureItem(
            context,
            icon: FontAwesomeIcons.headset,
            title: 'Priority Support',
            description: 'Get help when you need it',
            color: AppColors.blue,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    bool isLast = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.20),
                  color.withOpacity(0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: FaIcon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colorScheme.onSurface.withOpacity(0.65),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialButton(
      BuildContext context, bool isDark, ColorScheme colorScheme) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.grey[900]!.withOpacity(0.95),
                      Colors.grey[850]!.withOpacity(0.95),
                    ]
                  : [
                      Colors.white.withOpacity(0.95),
                      Colors.white.withOpacity(0.90),
                    ],
            ),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.grey.withOpacity(0.3),
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
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _handleStartTrial(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.rocket,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Start Free Trial',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '3 days free, then ${isYearly ? "€29.99/year" : "€2.99/month"}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.65),
                  ),
                  textAlign: TextAlign.center,
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
