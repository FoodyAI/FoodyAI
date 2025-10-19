import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../../../config/onboarding/onboarding_config.dart';
import '../../../config/onboarding/onboarding_page_model.dart';
import '../../widgets/onboarding/animated_page_indicator.dart';

/// Beautiful full-screen onboarding with immersive images
/// Displays introduction pages before the main app onboarding
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
  
  // Video player controller for page 2
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoPlaying = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadConfiguration();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.removeListener(_videoListener);
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
      
      // Initialize video for page 2 if needed
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
          _videoController = VideoPlayerController.asset(page.backgroundVideoUrl!);
        } else {
          _videoController = VideoPlayerController.networkUrl(
            Uri.parse(page.backgroundVideoUrl!),
          );
        }
        
        _videoController!.initialize().then((_) {
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
              _isVideoPlaying = false;
            });
            // Set video to loop
            _videoController!.setLooping(true);
            // Add listener to track video state
            _videoController!.addListener(_videoListener);
          }
        }).catchError((error) {
          print('Video initialization error: $error');
          if (mounted) {
            setState(() {
              _isVideoInitialized = false;
            });
          }
        });
      } else {
        _videoController?.removeListener(_videoListener);
        _videoController?.dispose();
        _videoController = null;
        _isVideoInitialized = false;
        _isVideoPlaying = false;
      }
    }
  }
  
  /// Listener to track video playing state
  void _videoListener() {
    if (_videoController != null && mounted) {
      final isPlaying = _videoController!.value.isPlaying;
      if (isPlaying != _isVideoPlaying) {
        setState(() {
          _isVideoPlaying = isPlaying;
        });
      }
    }
  }
  
  /// Toggle video play/pause
  void _toggleVideoPlayback() {
    if (_videoController != null && _isVideoInitialized) {
      if (_isVideoPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
      // State will update via listener
    }
  }

  /// Navigate to the next page
  void _nextPage() {
    if (_currentPage < _config.pages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: Duration(milliseconds: _config.animations.pageTransitionDurationMs),
        curve: _config.animations.getCurve(),
      );
    } else {
      _completeOnboarding();
    }
  }

  /// Navigate to the previous page
  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: Duration(milliseconds: _config.animations.pageTransitionDurationMs),
        curve: _config.animations.getCurve(),
      );
    }
  }

  /// Skip the onboarding
  Future<void> _skipOnboarding() async {
    // Mark intro as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_completed', true);

    if (!mounted) return;

    // Navigate to welcome/sign-in screen
    Navigator.of(context).pushReplacementNamed(_config.navigation.onSkipRoute);
  }

  /// Complete the onboarding
  Future<void> _completeOnboarding() async {
    // Mark intro as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_completed', true);

    if (!mounted) return;

    // Navigate to welcome/sign-in screen
    Navigator.of(context).pushReplacementNamed(_config.navigation.onCompleteRoute);
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
      body: Stack(
        children: [
          // PageView with full-screen pages
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              // Initialize video for the new page
              _initializeVideoForPage(index);
            },
            itemCount: _config.pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_config.pages[index]);
            },
          ),

          // Bottom section with indicators and buttons
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _buildBottomSection(),
            ),
          ),
        ],
      ),
    );
  }

  /// Build loading screen
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: const Color(0xFFFF1744),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error screen
  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFFF1744),
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
                  backgroundColor: const Color(0xFFFF1744),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build image background
  Widget _buildImageBackground(OnboardingPageModel page) {
    return CachedNetworkImage(
      imageUrl: page.backgroundImageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: _config.theme.backgroundDark,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: _config.theme.backgroundDark,
        child: const Center(
          child: Icon(Icons.error, color: Colors.white, size: 48),
        ),
      ),
    );
  }

  /// Build video background with play button
  Widget _buildVideoBackground(OnboardingPageModel page) {
    if (_videoController == null || !_isVideoInitialized) {
      return Container(
        color: _config.theme.backgroundDark,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Stack(
      children: [
        // Video player
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
        ),
        
        // Play button overlay (only show when paused)
        if (!_isVideoPlaying)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleVideoPlayback,
                splashColor: Colors.white.withOpacity(0.2),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Center(
                  child: AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 100),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 65,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
        // Tap to pause overlay (when playing)
        if (_isVideoPlaying)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleVideoPlayback,
              behavior: HitTestBehavior.translucent,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
      ],
    );
  }

  /// Build a single onboarding page
  Widget _buildPage(OnboardingPageModel page) {
    return Stack(
      children: [
        // Full-screen background (video or image)
        Positioned.fill(
          child: page.useVideo && page.backgroundVideoUrl != null
              ? _buildVideoBackground(page)
              : _buildImageBackground(page),
        ),

        // Dark gradient overlay from top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 150,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),

        // Extended bottom gradient for better text visibility
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 400,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.0),
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.85),
                  Colors.black.withOpacity(0.95),
                ],
              ),
            ),
          ),
        ),

        // Bottom text content (moved up to avoid button overlap)
        Positioned(
          left: 0,
          right: 0,
          bottom: 140,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  page.title,
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                // Description
                Text(
                  page.description,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                    color: Colors.white.withOpacity(0.88),
                    height: 1.55,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Skip button at top right (moved down to avoid overflow)
        if (_config.uiElements.skipButton.show)
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: _skipOnboarding,
              style: TextButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.25),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                _config.uiElements.skipButton.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Build bottom section with page indicators and navigation buttons
  Widget _buildBottomSection() {
    final isFirstPage = _currentPage == 0;
    final isLastPage = _currentPage == _config.pages.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page indicators
          PageIndicatorFactory.create(
            pageCount: _config.pages.length,
            currentPage: _currentPage,
            config: _config.uiElements.pageIndicators,
          ),

          const SizedBox(height: 24),

          // Navigation buttons
          Row(
            children: [
              // Back button (only show if not first page)
              if (!isFirstPage && _config.navigation.allowBackNavigation) ...[
                Expanded(
                  child: _buildBackButton(),
                ),
                const SizedBox(width: 16),
              ],

              // Continue/Get Started button (wider on first page)
              Expanded(
                flex: isFirstPage ? 1 : 2,
                child: isLastPage ? _buildGetStartedButton() : _buildContinueButton(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build back button
  Widget _buildBackButton() {
    return ElevatedButton(
      onPressed: _previousPage,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        _config.uiElements.backButton.text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  /// Build continue button
  Widget _buildContinueButton() {
    return ElevatedButton(
      onPressed: _nextPage,
      style: ElevatedButton.styleFrom(
        backgroundColor: _config.theme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        _config.uiElements.continueButton.text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// Build get started button
  Widget _buildGetStartedButton() {
    return ElevatedButton(
      onPressed: _completeOnboarding,
      style: ElevatedButton.styleFrom(
        backgroundColor: _config.theme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        _config.uiElements.getStartedButton.text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
