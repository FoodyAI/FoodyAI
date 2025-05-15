import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/health_analysis_content.dart';
import '../widgets/custom_app_bar.dart';

class AnalyzeView extends StatelessWidget {
  const AnalyzeView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(
        title: 'Health Analysis',
        icon: FontAwesomeIcons.chartLine,
      ),
      body: HealthAnalysisContent(),
    );
  }
}
