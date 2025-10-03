import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../domain/entities/ai_provider.dart';
import '../../core/constants/app_colors.dart';

class AIProviderSelectionDialog extends StatefulWidget {
  const AIProviderSelectionDialog({Key? key}) : super(key: key);

  @override
  State<AIProviderSelectionDialog> createState() => _AIProviderSelectionDialogState();
}

class _AIProviderSelectionDialogState extends State<AIProviderSelectionDialog> {
  AIProvider _selectedProvider = AIProvider.openai;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.withOpacity(AppColors.primary, 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.brain,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Choose Your AI Provider',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? AppColors.white : AppColors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select the AI model for analyzing your food images',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? AppColors.darkTextSecondary : AppColors.grey600,
              ),
            ),
            const SizedBox(height: 24),
            ...AIProvider.values.map((provider) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAIProviderCard(provider, isDarkMode),
              );
            }),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_selectedProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIProviderCard(AIProvider provider, bool isDarkMode) {
    final isSelected = _selectedProvider == provider;

    return InkWell(
      onTap: () => setState(() => _selectedProvider = provider),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.withOpacity(AppColors.primary, 0.1)
              : (isDarkMode ? AppColors.darkCardBackground : AppColors.grey100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.withOpacity(
                  _getAIProviderColor(provider),
                  0.1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FaIcon(
                _getAIProviderIcon(provider),
                color: _getAIProviderColor(provider),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          provider.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppColors.primary
                                : (isDarkMode ? AppColors.white : AppColors.black),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (provider.isRecommended) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'RECOMMENDED',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: provider.isFree
                              ? AppColors.withOpacity(AppColors.success, 0.1)
                              : AppColors.withOpacity(AppColors.orange, 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          provider.pricing,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: provider.isFree
                                ? AppColors.success
                                : AppColors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              const FaIcon(
                FontAwesomeIcons.circleCheck,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getAIProviderIcon(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return FontAwesomeIcons.brain;
      case AIProvider.gemini:
        return FontAwesomeIcons.gem;
      case AIProvider.claude:
        return FontAwesomeIcons.robot;
      case AIProvider.huggingface:
        return FontAwesomeIcons.code;
    }
  }

  Color _getAIProviderColor(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return AppColors.primary;
      case AIProvider.gemini:
        return AppColors.blue;
      case AIProvider.claude:
        return AppColors.profile;
      case AIProvider.huggingface:
        return AppColors.orange;
    }
  }
}
