// lib/views/home_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:ui';
import '../../data/services/sqlite_service.dart';
import '../viewmodels/image_analysis_viewmodel.dart';
import '../viewmodels/user_profile_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../domain/entities/user_profile.dart';
import '../widgets/food_analysis_card.dart';
import '../widgets/calorie_tracking_card.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/guest_signin_banner.dart';
import '../widgets/connection_banner.dart';
import '../../data/models/food_analysis.dart';
import 'analyze_view.dart';
import 'profile_view.dart';
import '../../../core/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../config/routes/navigation_service.dart';
import '../../core/services/connection_service.dart';
import '../../core/services/sync_service.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final ConnectionService _connectionService = ConnectionService();
  final SyncService _syncService = SyncService();
  StreamSubscription<bool>? _connectionSubscription;
  bool _wasOffline = false;

  // Animation controller for rotating plus button
  late AnimationController _rotationController;
  bool _wasLoading = false;

  final List<Widget> _pages = [
    const _HomeContent(),      // Index 0: Home
    const AnalyzeView(),       // Index 1: Analyze
    const ProfileView(),       // Index 2: Settings/Profile
  ];

  Widget _buildGlassmorphismFAB(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<ImageAnalysisViewModel>(
      builder: (context, analysisVM, _) {
        final isLoading = analysisVM.isLoading;

        // Start/stop rotation based on loading state
        if (isLoading && !_wasLoading) {
          // Just started loading - start rotation
          _rotationController.repeat();
        } else if (!isLoading && _wasLoading) {
          // Just stopped loading - stop rotation
          _rotationController.stop();
          _rotationController.reset();
        }
        _wasLoading = isLoading;

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  // Exact same glassmorphism as calendar
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    // Lock button during loading
                    onTap: isLoading ? null : () => _showAddOptionsBottomSheet(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: RotationTransition(
                        turns: _rotationController,
                        child: FaIcon(
                          FontAwesomeIcons.plus,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    // Initialize rotation animation controller
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Listen to connection changes and trigger sync when coming back online
    _connectionSubscription =
        _connectionService.connectionStream.listen((isConnected) {
      print('🌐 HomeView: Connection changed to: $isConnected');

      // If transitioning from offline to online, trigger sync
      if (isConnected && _wasOffline) {
        print('📡 HomeView: Connection restored, triggering sync...');
        _syncService.syncPendingChanges();
      }

      // Update offline status
      _wasOffline = !isConnected;
    });

    // Also sync on startup if there are pending changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_connectionService.isConnected) {
        print('🚀 HomeView: App started online, checking for pending syncs...');
        _syncService.syncOnStartup();
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _connectionSubscription?.cancel();
    super.dispose();
  }

  void _showAddOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final colorScheme = Theme.of(context).colorScheme;

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    // Drag handle with glassmorphism
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildGlassmorphismOption(
                      context: context,
                      icon: FontAwesomeIcons.camera,
                      iconColor: AppColors.primary,
                      title: 'Take Picture',
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        final vm = Provider.of<ImageAnalysisViewModel>(
                            context,
                            listen: false);
                        vm.pickImage(ImageSource.camera, context);
                      },
                    ),
                    _buildGlassmorphismOption(
                      context: context,
                      icon: FontAwesomeIcons.images,
                      iconColor: colorScheme.secondary,
                      title: 'Upload from Gallery',
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        final vm = Provider.of<ImageAnalysisViewModel>(
                            context,
                            listen: false);
                        vm.pickImage(ImageSource.gallery, context);
                      },
                    ),
                    _buildGlassmorphismOption(
                      context: context,
                      icon: FontAwesomeIcons.barcode,
                      iconColor: colorScheme.tertiary,
                      title: 'Scan Barcode',
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);

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
                          return;
                        }

                        NavigationService.navigateToBarcodeScanner();
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassmorphismOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: FaIcon(
                      icon,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _connectionService.connectionStream,
      initialData: _connectionService.isConnected,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? true;
        print(
            '🏠 HomeView: StreamBuilder rebuilt with isConnected = $isConnected');

        return Scaffold(
          extendBody: true,
          body: _pages[_currentIndex],
          floatingActionButton: _currentIndex == 0 ? _buildGlassmorphismFAB(context) : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConnectionBanner(isConnected: isConnected),
              BottomNavigation(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  bool _bannerDismissed = false;
  bool _hasNavigated = false;
  final SQLiteService _sqliteService = SQLiteService();
  final ScrollController _scrollController = ScrollController();
  bool _wasLoading = false;
  bool _shouldScrollAfterLoad = false;

  @override
  void initState() {
    super.initState();
    _loadBannerState();

    // 🔧 FIX #4: Trigger background sync AFTER routing to home screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = Provider.of<AuthViewModel>(context, listen: false);
      final analysisVM =
          Provider.of<ImageAnalysisViewModel>(context, listen: false);

      if (authVM.isSignedIn) {
        // Trigger background AWS sync now that we're on the home screen
        // This syncs data without blocking initial routing
        print('🏠 HomeView: Triggering background sync after routing...');
        authVM.syncAfterRouting();

        // If we have no data loaded yet, force refresh from SQLite
        if (analysisVM.savedAnalyses.isEmpty) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              print(
                  '🏠 HomeView: No data found, forcing refresh from SQLite...');
              analysisVM.forceRefresh();
            }
          });
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Validate user state consistency only when dependencies change
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    authVM.validateUserState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBannerState() async {
    final dismissed = await _sqliteService.getGuestBannerDismissed();
    setState(() {
      _bannerDismissed = dismissed;
    });
  }

  Future<void> _dismissBanner() async {
    // Save the dismissal state
    await _sqliteService.setGuestBannerDismissed(true);

    if (mounted) {
      setState(() {
        _bannerDismissed = true;
      });

      // Inform user where to find sign-in later
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              FaIcon(
                FontAwesomeIcons.circleInfo,
                size: 16,
                color: AppColors.white,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text('You can sign in anytime from Profile → Settings'),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _resetBanner() async {
    // Reset the dismissal state when user signs out
    await _sqliteService.setGuestBannerDismissed(false);

    if (mounted) {
      setState(() {
        _bannerDismissed = false;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning,';
    } else if (hour < 17) {
      return 'Good Afternoon,';
    } else if (hour < 21) {
      return 'Good Evening,';
    } else {
      return 'Good Night,';
    }
  }

  PreferredSizeWidget _buildCustomAppBar(
    BuildContext context,
    AuthViewModel authVM,
    UserProfile profile,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      toolbarHeight: 64,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
          child: Row(
            children: [
              // Profile Picture with Gender-based Avatar
              CircleAvatar(
                radius: 22,
                backgroundImage: (authVM.userPhotoURL != null && authVM.userPhotoURL!.isNotEmpty)
                    ? NetworkImage(authVM.userPhotoURL!)
                    : null,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: (authVM.userPhotoURL == null || authVM.userPhotoURL!.isEmpty)
                    ? FaIcon(
                        profile.gender.toLowerCase() == 'male' 
                            ? FontAwesomeIcons.person
                            : FontAwesomeIcons.personDress,
                        size: 20,
                        color: AppColors.primary,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Greeting and Name
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi ${authVM.userDisplayName?.split(' ').first ?? profile.gender}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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

  @override
  Widget build(BuildContext context) {
    final profileVM = Provider.of<UserProfileViewModel>(context);
    final profile = profileVM.profile;
    final analysisVM = Provider.of<ImageAnalysisViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context);

    // Validate user state consistency only when needed (moved to didChangeDependencies)

    // Handle case where profile is null
    if (profile == null) {
      // NOTE: Don't navigate here - AuthViewModel already handles navigation during sign-out
      // This prevents duplicate navigation calls

      // Just show loading screen - the app will be navigated away by AuthViewModel
      if (!authVM.isSignedIn) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // If user is signed in but profile is null, check if user exists in AWS
      if (authVM.isSignedIn && !_hasNavigated) {
        _hasNavigated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final shouldRedirect = await authVM.shouldRedirectToWelcome();
          if (context.mounted && shouldRedirect) {
            NavigationService.navigateToIntro();
          }
        });
      }

      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Reset banner when user signs out
    if (!authVM.isSignedIn && _bannerDismissed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resetBanner();
      });
    }

    // Calculate total calories consumed today
    final totalCaloriesConsumed = analysisVM.filteredAnalyses.fold<double>(
      0,
      (sum, analysis) => sum + analysis.calories,
    );

    // Get recommended daily calories
    final recommendedCalories = profile.dailyCalories;

    // Auto-scroll to top: both while adding and after item is added
    final isLoading = analysisVM.isLoading;

    // Case 1: Just started loading - scroll while item is being added
    if (isLoading && !_wasLoading) {
      _shouldScrollAfterLoad = true;
      // Scroll to top after a small delay
      // This ensures the shimmer card is rendered first, creating a smooth "scroll while adding" effect
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients && mounted) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        });
      });
    }

    // Case 2: Loading just finished - scroll again to ensure new item is visible at top
    if (!isLoading && _wasLoading && _shouldScrollAfterLoad) {
      _shouldScrollAfterLoad = false;
      // Scroll to top after item is completely added
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (_scrollController.hasClients && mounted) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            );
          }
        });
      });
    }

    _wasLoading = isLoading;

    return Scaffold(
      appBar: _buildCustomAppBar(context, authVM, profile),
      body: RefreshIndicator(
        onRefresh: () async {
          // Force refresh the food analyses when user pulls to refresh
          final analysisVM =
              Provider.of<ImageAnalysisViewModel>(context, listen: false);
          await analysisVM.forceRefresh();
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Guest Sign-In Banner (Top) - Show if user is not signed in with Firebase and banner not dismissed
              if (!authVM.isSignedIn && !_bannerDismissed)
                GuestSignInBanner(
                  onDismiss: _dismissBanner,
                ),
              // Calorie Tracking Section
              CalorieTrackingCard(
                totalCaloriesConsumed: totalCaloriesConsumed,
                recommendedCalories: recommendedCalories,
                savedAnalyses: analysisVM.filteredAnalyses,
                selectedDate: analysisVM.selectedDate,
                onDateSelected: (date) => analysisVM.setSelectedDate(date),
              ),
              // Image Analysis Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Consumer<ImageAnalysisViewModel>(
                  builder: (ctx, vm, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (vm.currentAnalysis != null)
                        FoodAnalysisCard(
                          analysis: vm.currentAnalysis!,
                        ),
                      if (vm.filteredAnalyses.isNotEmpty) ...[
                        // Show shimmer as first card when loading
                        if (vm.isLoading)
                          FoodAnalysisCard(
                            analysis: FoodAnalysis(
                              name: 'Loading...',
                              protein: 0,
                              carbs: 0,
                              fat: 0,
                              calories: 0,
                              healthScore: 0,
                              date: DateTime(2024),
                            ),
                            isLoading: true,
                          ),
                        ...vm.filteredAnalyses.map((analysis) {
                          return Dismissible(
                            key: Key(
                                'analysis_${analysis.id ?? analysis.name}_${analysis.date.millisecondsSinceEpoch}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: AppColors.error,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              child: const FaIcon(
                                FontAwesomeIcons.trash,
                                color: AppColors.white,
                              ),
                            ),
                            confirmDismiss: (_) async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Confirm Delete'),
                                    content: Text(
                                        'Are you sure you want to delete ${analysis.name}?'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text(
                                          'Delete',
                                          style:
                                              TextStyle(color: AppColors.error),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );

                              // If user confirmed, check network before proceeding
                              if (confirmed == true) {
                                final connectionService = ConnectionService();
                                if (!connectionService.isConnected) {
                                  // Show network error snackbar
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: const [
                                            Icon(
                                              Icons.wifi_off,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'No internet connection',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: Colors.red[700],
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        margin: const EdgeInsets.all(16),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 14),
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                  return false; // Don't dismiss
                                }
                                return true; // Network available, allow dismiss
                              }

                              return false; // User cancelled
                            },
                            onDismissed: (direction) async {
                              // Find the analysis in the full list using unique identifier
                              final fullIndex = vm.savedAnalyses.indexWhere(
                                  (item) =>
                                      item.id == analysis.id ||
                                      (item.id == null &&
                                          item.name == analysis.name &&
                                          item.date.millisecondsSinceEpoch ==
                                              analysis.date
                                                  .millisecondsSinceEpoch));

                              if (fullIndex != -1) {
                                await vm.removeAnalysis(fullIndex);
                              }
                            },
                            child: FoodAnalysisCard(
                              analysis: analysis,
                              onDelete: () async {
                                // Find the analysis in the full list using unique identifier
                                final fullIndex = vm.savedAnalyses.indexWhere(
                                    (item) =>
                                        item.id == analysis.id ||
                                        (item.id == null &&
                                            item.name == analysis.name &&
                                            item.date.millisecondsSinceEpoch ==
                                                analysis.date
                                                    .millisecondsSinceEpoch));

                                if (fullIndex != -1) {
                                  await vm.removeAnalysis(fullIndex);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ] else if (vm.isLoading) ...[
                        // Show shimmer when loading and no analyses
                        FoodAnalysisCard(
                          analysis: FoodAnalysis(
                            name: 'Loading...',
                            protein: 0,
                            carbs: 0,
                            fat: 0,
                            calories: 0,
                            healthScore: 0,
                            date: DateTime(2024),
                          ),
                          isLoading: true,
                        ),
                      ] else if (!vm.isLoading) ...[
                        const SizedBox(height: 32),
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FaIcon(
                                FontAwesomeIcons.utensils,
                                size: 64,
                                color: AppColors.grey400,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No food added yet',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.grey600,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap the + button to add your first meal',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.grey500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Add bottom padding to prevent content from being hidden behind bottom nav bar
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
