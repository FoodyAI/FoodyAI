import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_profile_viewmodel.dart';
import '../widgets/health_info_card.dart';

class AnalyzeView extends StatelessWidget {
  const AnalyzeView({super.key});

  @override
  Widget build(BuildContext context) {
    final profileVM = Provider.of<UserProfileViewModel>(context);
    final profile = profileVM.profile!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Analysis'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HealthInfoCard(
                profile: profile,
                isMetric: profileVM.isMetric,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
