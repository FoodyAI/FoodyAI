import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../../config/onboarding/onboarding_config.dart';
import '../../../config/onboarding/onboarding_page_model.dart';
import '../../widgets/google_signin_button.dart';
import '../legal/privacy_policy_page.dart';
import '../legal/terms_of_service_page.dart';
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

class _IntroOnboardingScreenState extends State<IntroOnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late OnboardingConfig _config;
  int _currentPage = 0;
  bool _isLoading = true;
  String? _errorMessage;

  // Video player controller
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  // Animation controllers
  late AnimationController _scanningAnimationController;
  late AnimationController _macroAnimationController;
  late AnimationController _fireAnimationController;
  late AnimationController _utensilsAnimationController;

  // Animations
  late Animation<double> _scanningScaleAnimation;
  late Animation<double> _scanningOpacityAnimation;
  late Animation<double> _fireScaleAnimation;
  late Animation<double> _fireRotationAnimation;
  late Animation<double> _utensilsSlideAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeAnimations();
    _loadConfiguration();
  }

  /// Initialize all animation controllers
  void _initializeAnimations() {
    // Scanning animation (Page 1) - pulsating effect
    _scanningAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scanningScaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _scanningAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _scanningOpacityAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _scanningAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Macro cards animation (Page 2) - will be triggered per card
    _macroAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Fire animation (Page 3) - scale and rotate
    _fireAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fireScaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _fireAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _fireRotationAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(
        parent: _fireAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Utensils animation (Page 4) - slide in from sides
    _utensilsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _utensilsSlideAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(
        parent: _utensilsAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    _scanningAnimationController.dispose();
    _macroAnimationController.dispose();
    _fireAnimationController.dispose();
    _utensilsAnimationController.dispose();
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

  /// Skip to welcome page (last slide)
  void _skipOnboarding() {
    _pageController.animateToPage(
      _config.pages.length, // Jump to welcome page (last page)
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Navigate to next page (total pages includes welcome page)
  void _handleNext() {
    // Total pages = config pages + welcome page
    if (_currentPage < _config.pages.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    // Welcome page is the last page, no completion action needed
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
        if (index == 3) _buildLoginOverlay(),
      ],
    );
  }

  /// Build image background
  Widget _buildImageBackground(OnboardingPageModel page) {
    // Check if the image is a local asset
    final isLocalAsset = page.backgroundImageUrl.startsWith('assets/');

    if (isLocalAsset) {
      return Image.asset(
        page.backgroundImageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.black,
          child: const Center(
            child: Icon(Icons.error, color: Colors.white, size: 48),
          ),
        ),
      );
    }

    // Fallback to network image for backward compatibility
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

  /// Build scanning frame overlay (Page 1) - centered with bottom margin and animation
  Widget _buildScanningOverlay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80), // Add bottom margin
        child: AnimatedBuilder(
          animation: _scanningAnimationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scanningScaleAnimation.value,
              child: Opacity(
                opacity: _scanningOpacityAnimation.value,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white
                            .withOpacity(_scanningOpacityAnimation.value * 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Corner brackets
                      _buildCornerBracket(Alignment.topLeft, true, true),
                      _buildCornerBracket(Alignment.topRight, true, false),
                      _buildCornerBracket(Alignment.bottomLeft, false, true),
                      _buildCornerBracket(Alignment.bottomRight, false, false),

                      // Scanning line animation
                      _buildScanningLine(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build animated scanning line that moves up and down
  Widget _buildScanningLine() {
    return AnimatedBuilder(
      animation: _scanningAnimationController,
      builder: (context, child) {
        return Positioned(
          top: 280 * _scanningAnimationController.value,
          left: 20,
          right: 20,
          child: Opacity(
            opacity: 0.8,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFFFF6B6B),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B6B).withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

  /// Build macro nutrition cards overlay (Page 2) - responsive for all devices
  Widget _buildMacroCardsOverlay() {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.06; // 6% of screen width
    final cardSpacing =
        screenWidth * 0.03; // 3% of screen width (min 8, max 16)
    final spacing = cardSpacing.clamp(8.0, 16.0);

    return Positioned(
      left: 0,
      right: 0,
      top: MediaQuery.of(context).size.height * 0.45,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: _buildMacroCard(
                  'Protein', '45g', const Color(0xFFB8A0FF), 0.75),
            ),
            SizedBox(width: spacing),
            Flexible(
              child: _buildMacroCard(
                  'Carbs', '120g', const Color(0xFFC4E17F), 0.60),
            ),
            SizedBox(width: spacing),
            Flexible(
              child:
                  _buildMacroCard('Fat', '28g', const Color(0xFFFFC876), 0.85),
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual macro card - responsive for all screen sizes with animation
  Widget _buildMacroCard(
      String label, String value, Color color, double progress) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Dynamic sizing based on screen size
    // Card width: 26-30% of screen width, ensuring good fit on all devices
    final cardWidth = (screenWidth * 0.26).clamp(85.0, 110.0);
    final cardHeight = (screenHeight * 0.15).clamp(100.0, 130.0);

    // Dynamic font sizes
    final labelFontSize = (screenWidth * 0.035).clamp(12.0, 15.0);
    final valueFontSize = (screenWidth * 0.04).clamp(14.0, 17.0);

    // Dynamic circle size
    final circleSize = (cardWidth * 0.45).clamp(40.0, 55.0);
    final strokeWidth = (circleSize * 0.08).clamp(3.0, 5.0);

    // Dynamic spacing
    final verticalSpacing = (cardHeight * 0.06).clamp(6.0, 10.0);
    final borderRadius = (cardWidth * 0.18).clamp(16.0, 22.0);

    return AnimatedBuilder(
      animation: _macroAnimationController,
      builder: (context, child) {
        return Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.black.withOpacity(0.7),
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: verticalSpacing),
              // Animated circular progress indicator
              SizedBox(
                width: circleSize,
                height: circleSize,
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        width: circleSize,
                        height: circleSize,
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1500),
                          curve: Curves.easeInOut,
                          tween: Tween<double>(
                            begin: 0,
                            end: progress,
                          ),
                          builder: (context, value, _) =>
                              CircularProgressIndicator(
                            value: value,
                            strokeWidth: strokeWidth,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.6 + (value * 0.4)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeInOut,
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, opacity, _) => Opacity(
                          opacity: opacity,
                          child: Text(
                            value,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: valueFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
                        '2600',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Animated fire icon on the right
                  AnimatedBuilder(
                    animation: _fireAnimationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _fireScaleAnimation.value,
                        child: Transform.rotate(
                          angle: _fireRotationAnimation.value,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF6B6B).withOpacity(
                                      _fireScaleAnimation.value - 0.7),
                                  blurRadius: 20,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.local_fire_department,
                              color: Color.lerp(
                                Colors.white,
                                const Color(0xFFFF6B6B),
                                (_fireScaleAnimation.value - 0.9) * 5,
                              ),
                              size: 30,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build login icon overlay (Page 4) - animated restaurant icon
  Widget _buildLoginOverlay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _utensilsAnimationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _utensilsSlideAnimation.value * 0.02,
                  child: Transform.scale(
                    scale: 1.0 + (_utensilsSlideAnimation.value.abs() * 0.008),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFF6B6B),
                            Color(0xFFFF8E8E),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B6B).withOpacity(
                                0.4 + (_utensilsSlideAnimation.value.abs() * 0.02)),
                            blurRadius:
                                20 + (_utensilsSlideAnimation.value.abs() * 2),
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Foody',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build bottom content card with glassmorphism - FIXED HEIGHT
  Widget _buildBottomCard() {
    // Safety check to prevent index out of range
    if (_currentPage >= _config.pages.length) {
      return const SizedBox.shrink();
    }

    final page = _config.pages[_currentPage];
    final isLastPage = _currentPage == _config.pages.length - 1;
    final isLoginPage = page.icon == 'login';

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
                      // Main button (Next/Get Started or Google Sign-In)
                      if (isLoginPage)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: GoogleSignInButton(isFullWidth: true),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _handleNext,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6B6B),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
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
                        ),

                      // Bottom text/link
                      const SizedBox(height: 4),
                      if (isLoginPage)
                        // Privacy text on login page
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          child: _buildPrivacyTermsText(context),
                        )
                      else
                        // "Already have an account?" text on other pages
                        TextButton(
                          onPressed: _skipOnboarding,
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

  /// Build clickable Privacy Policy and Terms of Service text
  Widget _buildPrivacyTermsText(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: 11,
          color: Colors.white.withOpacity(0.6),
          height: 1.4,
        ),
        children: [
          const TextSpan(text: 'By signing in, you agree to our '),
          TextSpan(
            text: 'Privacy Policy',
            style: const TextStyle(
              color: Color(0xFFFF6B6B),
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyPage(),
                  ),
                );
              },
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Terms of Service',
            style: const TextStyle(
              color: Color(0xFFFF6B6B),
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TermsOfServicePage(),
                  ),
                );
              },
          ),
        ],
      ),
    );
  }
}
