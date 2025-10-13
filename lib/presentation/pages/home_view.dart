// lib/views/home_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/services/sqlite_service.dart';
import '../viewmodels/image_analysis_viewmodel.dart';
import '../viewmodels/user_profile_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/food_analysis_card.dart';
import '../widgets/calorie_tracking_card.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/undo_delete_snackbar.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/guest_signin_banner.dart';
import '../widgets/connection_banner.dart';
import '../../data/models/food_analysis.dart';
import 'analyze_view.dart';
import 'profile_view.dart';
import 'barcode_scanner_view.dart';
import 'welcome_view.dart';
import '../../../core/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../config/routes/navigation_service.dart';
import '../../config/routes/app_routes.dart';

class HomeView extends StatefulWidget {
  final ConnectionBanner? connectionBanner;

  const HomeView({super.key, this.connectionBanner});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _HomeContent(),
    const AnalyzeView(),
    const ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.connectionBanner != null) widget.connectionBanner!,
          BottomNavigation(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
          ),
        ],
      ),
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

  @override
  void initState() {
    super.initState();
    _loadBannerState();

    // Listen for auth state changes to refresh data when user signs in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = Provider.of<AuthViewModel>(context, listen: false);
      final analysisVM =
          Provider.of<ImageAnalysisViewModel>(context, listen: false);

      // If user is authenticated and we have no data, try to reload
      if (authVM.isSignedIn && analysisVM.savedAnalyses.isEmpty) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            analysisVM.forceRefresh();
          }
        });
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

  @override
  Widget build(BuildContext context) {
    final profileVM = Provider.of<UserProfileViewModel>(context);
    final profile = profileVM.profile;
    final analysisVM = Provider.of<ImageAnalysisViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context);

    // Validate user state consistency only when needed (moved to didChangeDependencies)

    // Handle case where profile is null
    if (profile == null) {
      // If user is not signed in, redirect to welcome page
      if (!authVM.isSignedIn && !_hasNavigated) {
        _hasNavigated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            NavigationService.navigateToWelcome();
          }
        });
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
            NavigationService.navigateToWelcome();
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

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Home',
        icon: FontAwesomeIcons.house,
        showInfoButton: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: AppColors.transparent,
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final colorScheme = Theme.of(context).colorScheme;

              return Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.grey800 : AppColors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? AppColors.withOpacity(AppColors.black, 0.4)
                          : AppColors.withOpacity(AppColors.black, 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.grey600 : AppColors.grey300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                AppColors.withOpacity(colorScheme.primary, 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.camera,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          'Take Picture',
                          style: TextStyle(
                            color: isDark ? AppColors.white : AppColors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          final vm = Provider.of<ImageAnalysisViewModel>(
                              context,
                              listen: false);
                          vm.pickImage(ImageSource.camera).then((_) {
                            if (vm.selectedImage != null) vm.analyzeImage();
                          });
                        },
                      ),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.withOpacity(
                                colorScheme.secondary, 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: FaIcon(
                            FontAwesomeIcons.images,
                            color: colorScheme.secondary,
                          ),
                        ),
                        title: Text(
                          'Upload from Gallery',
                          style: TextStyle(
                            color: isDark ? AppColors.white : AppColors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          final vm = Provider.of<ImageAnalysisViewModel>(
                              context,
                              listen: false);
                          vm.pickImage(ImageSource.gallery).then((_) {
                            if (vm.selectedImage != null) vm.analyzeImage();
                          });
                        },
                      ),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.withOpacity(
                                colorScheme.tertiary, 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: FaIcon(
                            FontAwesomeIcons.barcode,
                            color: colorScheme.tertiary,
                          ),
                        ),
                        title: Text(
                          'Scan Barcode',
                          style: TextStyle(
                            color: isDark ? AppColors.white : AppColors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          NavigationService.navigateToBarcodeScanner();
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          );
        },
        child: const FaIcon(FontAwesomeIcons.plus),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Force refresh the food analyses when user pulls to refresh
          final analysisVM =
              Provider.of<ImageAnalysisViewModel>(context, listen: false);
          await analysisVM.forceRefresh();
        },
        child: SingleChildScrollView(
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
                      if (vm.error != null)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            vm.error!,
                            style: const TextStyle(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else if (vm.currentAnalysis != null)
                        FoodAnalysisCard(
                          analysis: vm.currentAnalysis!,
                        )
                      else if (vm.isLoading && vm.filteredAnalyses.isEmpty)
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
                      if (vm.filteredAnalyses.isNotEmpty) ...[
                        ...vm.filteredAnalyses.asMap().entries.map((entry) {
                          final index = entry.key;
                          final analysis = entry.value;
                          final isLastItem =
                              index == vm.filteredAnalyses.length - 1;
                          return Column(
                            children: [
                              Dismissible(
                                key: Key('analysis_${analysis.name}_$index'),
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
                                  return await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Confirm Delete'),
                                        content: Text(
                                            'Are you sure you want to delete ${analysis.name}?'),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(
                                                  color: AppColors.error),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                onDismissed: (direction) async {
                                  final analysisToRemove =
                                      vm.filteredAnalyses[index];
                                  final fullIndex = vm.savedAnalyses
                                      .indexOf(analysisToRemove);
                                  final removedAnalysis =
                                      await vm.removeAnalysis(fullIndex);
                                  if (removedAnalysis != null) {
                                    _showUndoSnackbar(removedAnalysis, vm);
                                  }
                                },
                                child: FoodAnalysisCard(
                                  analysis: analysis,
                                  onDelete: () => vm.removeAnalysis(index),
                                ),
                              ),
                              if (isLastItem && vm.isLoading)
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
                            ],
                          );
                        }).toList(),
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
            ],
          ),
        ),
      ),
    );
  }

  void _showUndoSnackbar(
      FoodAnalysis removedAnalysis, ImageAnalysisViewModel vm) {
    if (mounted) {
      UndoDeleteSnackbar.show(
        context: context,
        removedAnalysis: removedAnalysis,
        onUndo: () {
          vm.addAnalysis(removedAnalysis);
        },
      );
    }
  }
}
