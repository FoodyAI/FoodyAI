// lib/views/home_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../viewmodels/image_analysis_viewmodel.dart';
import '../viewmodels/user_profile_viewmodel.dart';
import '../widgets/food_analysis_card.dart';
import '../widgets/calorie_tracking_card.dart';
import '../widgets/bottom_navigation.dart';
import '../../data/models/food_analysis.dart';
import 'analyze_view.dart';
import 'profile_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

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
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final profileVM = Provider.of<UserProfileViewModel>(context);
    final profile = profileVM.profile!;
    final analysisVM = Provider.of<ImageAnalysisViewModel>(context);

    // Calculate total calories consumed today
    final totalCaloriesConsumed = analysisVM.savedAnalyses.fold<double>(
      0,
      (sum, analysis) => sum + analysis.calories,
    );

    // Get recommended daily calories
    final recommendedCalories = profile.dailyCalories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Foody'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.blue),
                      ),
                      title: const Text('Take Picture'),
                      onTap: () {
                        Navigator.pop(context);
                        final vm = Provider.of<ImageAnalysisViewModel>(context,
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
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.photo_library,
                            color: Colors.green),
                      ),
                      title: const Text('Upload from Gallery'),
                      onTap: () {
                        Navigator.pop(context);
                        final vm = Provider.of<ImageAnalysisViewModel>(context,
                            listen: false);
                        vm.pickImage(ImageSource.gallery).then((_) {
                          if (vm.selectedImage != null) vm.analyzeImage();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Calorie Tracking Section
            CalorieTrackingCard(
              totalCaloriesConsumed: totalCaloriesConsumed,
              recommendedCalories: recommendedCalories,
              savedAnalyses: analysisVM.savedAnalyses,
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
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else if (vm.currentAnalysis != null)
                      FoodAnalysisCard(
                        analysis: vm.currentAnalysis!,
                      )
                    else if (vm.isLoading && vm.savedAnalyses.isEmpty)
                      const FoodAnalysisCard(
                        analysis: FoodAnalysis(
                          name: 'Loading...',
                          protein: 0,
                          carbs: 0,
                          fat: 0,
                          calories: 0,
                          healthScore: 0,
                        ),
                        isLoading: true,
                      ),
                    if (vm.savedAnalyses.isNotEmpty) ...[
                      ...vm.savedAnalyses.asMap().entries.map((entry) {
                        final index = entry.key;
                        final analysis = entry.value;
                        final isLastItem = index == vm.savedAnalyses.length - 1;
                        return Column(
                          children: [
                            Dismissible(
                              key: Key('analysis_$index'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (_) async {
                                await vm.removeAnalysis(index);
                              },
                              child: FoodAnalysisCard(
                                analysis: analysis,
                                onDelete: () => vm.removeAnalysis(index),
                              ),
                            ),
                            if (isLastItem && vm.isLoading)
                              const FoodAnalysisCard(
                                analysis: FoodAnalysis(
                                  name: 'Loading...',
                                  protein: 0,
                                  carbs: 0,
                                  fat: 0,
                                  calories: 0,
                                  healthScore: 0,
                                ),
                                isLoading: true,
                              ),
                          ],
                        );
                      }).toList(),
                    ] else if (!vm.isLoading) ...[
                      const SizedBox(height: 32),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No food added yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the + button to add your first meal',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[500],
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
    );
  }
}
