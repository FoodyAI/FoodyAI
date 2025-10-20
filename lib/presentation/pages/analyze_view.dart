import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/health_info_card.dart';
import '../widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_profile_viewmodel.dart';

class AnalyzeView extends StatelessWidget {
  const AnalyzeView({super.key});

  @override
  Widget build(BuildContext context) {
    final profileVM = Provider.of<UserProfileViewModel>(context);
    final profile = profileVM.profile;
    final isMetric = profileVM.isMetric;
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Health Analysis',
        icon: FontAwesomeIcons.chartLine,
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HealthInfoCard(profile: profile, isMetric: isMetric),
                  // Add bottom padding to prevent content from being hidden behind bottom nav bar
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }
}
