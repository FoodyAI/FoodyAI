import 'package:flutter/material.dart';
import '../widgets/health_analysis_content.dart';

class AnalyzeView extends StatelessWidget {
  const AnalyzeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Analysis'),
      ),
      body: const HealthAnalysisContent(),
    );
  }
}
