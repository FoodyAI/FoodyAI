import 'package:flutter/material.dart';
import '../widgets/health_analysis_content.dart';
import '../widgets/custom_app_bar.dart';

class AnalyzeView extends StatelessWidget {
  const AnalyzeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: const CustomAppBar(
        title: 'Health Analysis',
        icon: Icons.analytics,
      ),
      body: const HealthAnalysisContent(),
    );
  }
}
