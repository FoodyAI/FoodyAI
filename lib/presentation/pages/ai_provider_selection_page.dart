import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../domain/entities/ai_provider.dart';
import '../../core/constants/app_colors.dart';

class AIProviderSelectionPage extends StatefulWidget {
  const AIProviderSelectionPage({Key? key}) : super(key: key);

  @override
  State<AIProviderSelectionPage> createState() => _AIProviderSelectionPageState();
}

class _AIProviderSelectionPageState extends State<AIProviderSelectionPage> {
  AIProvider? _selectedProvider;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDarkMode ? AppColors.white : AppColors.black,
          ),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        title: Text(
          'Choose Your AI Provider',
          style: TextStyle(
            color: isDarkMode ? AppColors.white : AppColors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeader(isDarkMode),
            const SizedBox(height: 32),
            
            // Subscription Benefits
            _buildSubscriptionBenefits(isDarkMode),
            const SizedBox(height: 32),
            
            // AI Provider Cards
            _buildAIProviderCards(isDarkMode),
            const SizedBox(height: 32),
            
            // Continue Button
            _buildContinueButton(isDarkMode, screenSize),
            const SizedBox(height: 16),
            
            // Terms and Privacy
            _buildTermsAndPrivacy(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Unlock Accurate Food Analysis',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.white : AppColors.black,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Choose the AI provider that best fits your needs. Premium providers offer higher accuracy and better nutrition insights.',
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode ? AppColors.darkTextSecondary : AppColors.grey600,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionBenefits(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primaryLight.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.crown,
                  color: AppColors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Premium Benefits',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBenefitItem('🎯', 'Higher accuracy nutrition analysis'),
          _buildBenefitItem('📊', 'Detailed macro and micronutrient breakdown'),
          _buildBenefitItem('🍎', 'Better food recognition and portion estimation'),
          _buildBenefitItem('📈', 'Nutritional trends and insights'),
          _buildBenefitItem('♾️', 'Unlimited food analyses per month'),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.grey600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIProviderCards(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available AI Providers',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.white : AppColors.black,
          ),
        ),
        const SizedBox(height: 16),
        ...AIProvider.values.map((provider) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildAIProviderCard(provider, isDarkMode),
          );
        }),
      ],
    );
  }

  Widget _buildAIProviderCard(AIProvider provider, bool isDarkMode) {
    final isSelected = _selectedProvider == provider;
    final isPremium = provider != AIProvider.huggingface;

    return InkWell(
      onTap: () => setState(() => _selectedProvider = provider),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.withOpacity(AppColors.primary, 0.1)
              : (isDarkMode ? AppColors.darkCardBackground : AppColors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? AppColors.primary 
                : (isDarkMode ? AppColors.darkDivider : AppColors.grey300),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.withOpacity(
                      _getAIProviderColor(provider),
                      0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FaIcon(
                    _getAIProviderIcon(provider),
                    color: _getAIProviderColor(provider),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDarkMode ? AppColors.white : AppColors.black),
                              ),
                            ),
                          ),
                          if (isPremium) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'PREMIUM',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'FREE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isPremium
                                  ? AppColors.withOpacity(AppColors.orange, 0.1)
                                  : AppColors.withOpacity(AppColors.success, 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              provider.pricing,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isPremium ? AppColors.orange : AppColors.success,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isPremium)
                            Text(
                              '• ${_getAccuracyPercentage(provider)}% accuracy',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? AppColors.darkTextSecondary : AppColors.grey600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.check,
                      color: AppColors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              provider.description,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? AppColors.darkTextSecondary : AppColors.grey600,
                height: 1.4,
              ),
            ),
            if (isPremium) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.withOpacity(AppColors.primary, 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.lightbulb,
                      color: AppColors.primary,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Upgrade to Premium to unlock this AI provider',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton(bool isDarkMode, Size screenSize) {
    final isPremium = _selectedProvider != null && _selectedProvider != AIProvider.huggingface;
    
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          ElevatedButton(
            onPressed: _selectedProvider != null ? () => _handleContinue() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : Text(
                    isPremium ? 'Upgrade to Premium' : 'Continue with Free',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          if (isPremium) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.withOpacity(AppColors.success, 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.gift,
                        color: AppColors.success,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Special Offer: First Month Free!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Then \$4.99/month or \$39.99/year (save 33%)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTermsAndPrivacy(bool isDarkMode) {
    return Center(
      child: Text(
        'By continuing, you agree to our Terms of Service and Privacy Policy',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: isDarkMode ? AppColors.darkTextSecondary : AppColors.grey500,
        ),
      ),
    );
  }

  void _handleContinue() async {
    if (_selectedProvider == null) return;
    
    setState(() => _isLoading = true);
    
    // Simulate processing time
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;
    
    // If premium provider selected, show subscription flow
    if (_selectedProvider != AIProvider.huggingface) {
      // TODO: Implement subscription flow
      Navigator.of(context).pop(_selectedProvider);
    } else {
      Navigator.of(context).pop(_selectedProvider);
    }
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

  String _getAccuracyPercentage(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return '95';
      case AIProvider.gemini:
        return '92';
      case AIProvider.claude:
        return '94';
      case AIProvider.huggingface:
        return '78';
    }
  }
}
