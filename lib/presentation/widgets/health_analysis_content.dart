import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_profile_viewmodel.dart';
import 'health_info_card.dart';

class HealthAnalysisContent extends StatelessWidget {
  final Widget? additionalContent;

  const HealthAnalysisContent({
    super.key,
    this.additionalContent,
  });

  @override
  Widget build(BuildContext context) {
    final profileVM = Provider.of<UserProfileViewModel>(context);
    final profile = profileVM.profile!;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HealthInfoCard(
              profile: profile,
              isMetric: profileVM.isMetric,
            ),
            if (additionalContent != null) ...[
              const SizedBox(height: 24),
              additionalContent!,
            ],
          ],
        ),
      ),
    );
  }
}
