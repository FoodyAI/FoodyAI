import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../../../config/onboarding/onboarding_config.dart';
import '../../../config/onboarding/onboarding_page_model.dart';
import 'dart:ui';

/// Modern full-screen onboarding with immersive design
/// Based on reference designs with bottom card layout
class IntroOnboardingScreen extends StatefulWidget {
  final String configPath;

  const IntroOnboardingScreen({
    super.key,
    this.configPath = 'assets/config/onboarding_config.json',
  });

  @override
  State<IntroOnboardingScreen> createState() => _IntroOnboardingScreenState();
}

class _IntroOnboardingScreenState extends State<IntroOnboardingScreen> {
  late PageController _pageController;
  late OnboardingConfig _config;
  int _currentPage = 0;
  bool _isLoading = true;
  String? _errorMessage;

  // Video player controller
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadConfiguration();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  /// Load the onboarding configuration from JSON
  Future<void> _loadConfiguration() async {
    try {
      final config = await OnboardingConfig.loadFromAssets(widget.configPath);
      setState(() {
        _config = config;
        _isLoading = false;
      });

      // Initialize video for first page if needed
      _initializeVideoForPage(0);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load onboarding configuration: $e';
        _isLoading = false;
      });
    }
  }

  /// Initialize video for a specific page if it uses video
  void _initializeVideoForPage(int pageIndex) {
    if (pageIndex >= 0 && pageIndex < _config.pages.length) {
      final page = _config.pages[pageIndex];
      if (page.useVideo && page.backgroundVideoUrl != null) {
        _videoController?.dispose();

        // Check if it's a local asset or network URL
        if (page.backgroundVideoUrl!.startsWith('assets/')) {
          _videoController =
              VideoPlayerController.asset(page.backgroundVideoUrl!);
        } else {
          _videoController = VideoPlayerController.networkUrl(
            Uri.parse(page.backgroundVideoUrl!),
          );
        }

        _videoController!.initialize().then((_) {
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
            });
            _videoController!.setLooping(true);
            // Auto-play video with small delay
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted && _videoController != null) {
                _videoController!.play();
              }
            });
          }
        });
      } else {
        _videoController?.dispose();
        _videoController = null;
        _isVideoInitialized = false;
      }
    }
  }

  /// Skip the onboarding
  Future<void> _skipOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_completed', true);

    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(_config.navigation.onSkipRoute);
  }

  /// Complete the onboarding
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_completed', true);

    if (!mounted) return;

    Navigator.of(context)
        .pushReplacementNamed(_config.navigation.onCompleteRoute);
  }

  /// Navigate to next page or complete
  void _handleNext() {
    if (_currentPage < _config.pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  /// Navigate to welcome page
  void _navigateToWelcome() {
    Navigator.of(context).pushReplacementNamed('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // PageView with full-screen pages
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              _initializeVideoForPage(index);
            },
            itemCount: _config.pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_config.pages[index], index);
            },
          ),

          // Skip button (top right)
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: _buildSkipButton(),
              ),
            ),
          ),

          // Bottom content card with proper spacing
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: _buildBottomCard(),
            ),
          ),
        ],
      ),
    );
  }

  /// Build loading screen
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(
          color: const Color(0xFFFF6B6B),
        ),
      ),
    );
  }

  /// Build error screen
  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFFF6B6B),
              ),
              const SizedBox(height: 24),
              Text(
                _errorMessage ?? 'An error occurred',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _loadConfiguration();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a single onboarding page
  Widget _buildPage(OnboardingPageModel page, int index) {
    return Stack(
      children: [
        // Full-screen background (video or image)
        Positioned.fill(
          child: page.useVideo && page.backgroundVideoUrl != null
              ? _buildVideoBackground(page)
              : _buildImageBackground(page),
        ),

        // Dark gradient overlay for better contrast
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.6),
                ],
                stops: const [0.4, 1.0],
              ),
            ),
          ),
        ),

        // Optional overlay content (like scanning frame, macro cards, etc.)
        if (index == 0) _buildScanningOverlay(),
        if (index == 1) _buildMacroCardsOverlay(),
        if (index == 2) _buildDailyCalorieOverlay(),
      ],
    );
  }

  /// Build image background
  Widget _buildImageBackground(OnboardingPageModel page) {
    return CachedNetworkImage(
      imageUrl: page.backgroundImageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.error, color: Colors.white, size: 48),
        ),
      ),
    );
  }

  /// Build video background
  Widget _buildVideoBackground(OnboardingPageModel page) {
    if (_videoController == null || !_isVideoInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      ),
    );
  }

  /// Build scanning frame overlay (Page 1) - centered with bottom margin
  Widget _buildScanningOverlay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80), // Add bottom margin
        child: Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
          ),
          child: Stack(
            children: [
              // Corner brackets
              _buildCornerBracket(Alignment.topLeft, true, true),
              _buildCornerBracket(Alignment.topRight, true, false),
              _buildCornerBracket(Alignment.bottomLeft, false, true),
              _buildCornerBracket(Alignment.bottomRight, false, false),
            ],
          ),
        ),
      ),
    );
  }

  /// Build corner bracket for scanning frame
  Widget _buildCornerBracket(Alignment alignment, bool isTop, bool isLeft) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(32) : Radius.zero,
            topRight:
                isTop && !isLeft ? const Radius.circular(32) : Radius.zero,
            bottomLeft:
                !isTop && isLeft ? const Radius.circular(32) : Radius.zero,
            bottomRight:
                !isTop && !isLeft ? const Radius.circular(32) : Radius.zero,
          ),
        ),
      ),
    );
  }

  /// Build macro nutrition cards overlay (Page 2) - positioned better
  Widget _buildMacroCardsOverlay() {
    return Positioned(
      left: 0,
      right: 0,
      top: MediaQuery.of(context).size.height * 0.45,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMacroCard('Protein', '45g', const Color(0xFFB8A0FF), 0.75),
            const SizedBox(width: 12),
            _buildMacroCard('Carbs', '120g', const Color(0xFFC4E17F), 0.60),
            const SizedBox(width: 12),
            _buildMacroCard('Fat', '28g', const Color(0xFFFFC876), 0.85),
          ],
        ),
      ),
    );
  }

  /// Build individual macro card
  Widget _buildMacroCard(
      String label, String value, Color color, double progress) {
    return Container(
      width: 100,
      height: 120,
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // Circular progress indicator
          SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build daily calorie goal overlay (Page 3) - glassmorphism card design
  Widget _buildDailyCalorieOverlay() {
    return Positioned(
      left: 0,
      right: 0,
      top: MediaQuery.of(context).size.height * 0.45,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Text content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Calorie',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '2000',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Fire icon on the right
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_fire_department,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build skip button
  Widget _buildSkipButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _skipOnboarding,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: const Text(
            'Skip',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /// Build bottom content card with glassmorphism - FIXED HEIGHT
  Widget _buildBottomCard() {
    final page = _config.pages[_currentPage];
    final isLastPage = _currentPage == _config.pages.length - 1;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      constraints:
          const BoxConstraints(maxHeight: 300), // Max height with constraints
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      // Page indicators
                      _buildPageIndicators(),
                      const SizedBox(height: 16),

                      // Title - fixed height
                      SizedBox(
                        height: 58,
                        child: Center(
                          child: Text(
                            page.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description - fixed height
                      SizedBox(
                        height: 42,
                        child: Center(
                          child: Text(
                            page.description,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Bottom section with button and link
                  Column(
                    children: [
                      // Next button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B6B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isLastPage ? 'Get Started' : 'Next',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                      // "Already have an account?" text (on all pages)
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: _navigateToWelcome,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFF6B6B),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          minimumSize: const Size(0, 32),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Already have an account?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Sign in',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF6B6B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build page indicators (dots)
  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _config.pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == _currentPage ? 8 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: index == _currentPage
                ? const Color(0xFFFF6B6B)
                : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
