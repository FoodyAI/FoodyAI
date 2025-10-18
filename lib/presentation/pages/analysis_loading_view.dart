import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/health_info_card.dart';
import '../widgets/custom_app_bar.dart';
import '../../../core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_profile_viewmodel.dart';
import '../../config/routes/navigation_service.dart';

class AnalysisLoadingView extends StatefulWidget {
  const AnalysisLoadingView({super.key});

  @override
  State<AnalysisLoadingView> createState() => _AnalysisLoadingViewState();
}

class _AnalysisLoadingViewState extends State<AnalysisLoadingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _showHealthChart = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();

    // Show health chart dynamically when profile data is ready
    _checkProfileDataAndShowChart();
  }

  /// Dynamically check if profile data is ready and show chart
  /// Ensures minimum display time so users see the analyzing animation
  void _checkProfileDataAndShowChart() async {
    final profileVM = Provider.of<UserProfileViewModel>(context, listen: false);
    final startTime = DateTime.now();

    // Wait for profile to be loaded
    while (profileVM.profile == null && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Calculate elapsed time
    final elapsedTime = DateTime.now().difference(startTime);

    // Ensure minimum display time of 2.5 seconds so users see the animation
    const minDisplayTime = Duration(milliseconds: 4000);
    if (elapsedTime < minDisplayTime) {
      final remainingTime = minDisplayTime - elapsedTime;
      await Future.delayed(remainingTime);
    }

    if (mounted) {
      setState(() {
        _showHealthChart = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: _showHealthChart ? 'Health Analysis' : '',
        icon: _showHealthChart ? FontAwesomeIcons.chartLine : null,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _showHealthChart
              ? Builder(
                  builder: (context) {
                    final profileVM =
                        Provider.of<UserProfileViewModel>(context);
                    final profile = profileVM.profile;
                    final isMetric = profileVM.isMetric;
                    if (profile == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HealthInfoCard(profile: profile, isMetric: isMetric),
                          const SizedBox(height: 24),
                          Center(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context)
                                    .pushReplacementNamed('/subscription');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                "Let's rock it",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final screenHeight = MediaQuery.of(context).size.height;

                      // Dynamic sizing based on screen dimensions
                      final iconSize = screenWidth * 0.3; // 30% of screen width
                      final titleFontSize =
                          screenWidth * 0.055; // ~5.5% of width
                      final subtitleFontSize =
                          screenWidth * 0.04; // ~4% of width
                      final horizontalPadding =
                          screenWidth * 0.1; // 10% padding on sides

                      return Opacity(
                        opacity: _opacityAnimation.value,
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: iconSize.clamp(100.0, 150.0),
                                  height: iconSize.clamp(100.0, 150.0),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: FaIcon(
                                      FontAwesomeIcons.chartLine,
                                      size: (iconSize * 0.4).clamp(40.0, 60.0),
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.03),
                                Text(
                                  'Setting up your profile...',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: titleFontSize.clamp(18.0, 24.0),
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                Text(
                                  'Saving your health information and analyzing your data',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize:
                                        subtitleFontSize.clamp(14.0, 18.0),
                                    color: isDark
                                        ? AppColors.white.withValues(alpha: 0.7)
                                        : AppColors.grey600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}
