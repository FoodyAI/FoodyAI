import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/subscription_service.dart';

class UsageLimitWidget extends StatefulWidget {
  const UsageLimitWidget({Key? key}) : super(key: key);

  @override
  State<UsageLimitWidget> createState() => _UsageLimitWidgetState();
}

class _UsageLimitWidgetState extends State<UsageLimitWidget> {
  Map<String, dynamic>? _subscriptionInfo;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionInfo();
  }

  Future<void> _loadSubscriptionInfo() async {
    final info = await SubscriptionService.getSubscriptionInfo();
    if (mounted) {
      setState(() {
        _subscriptionInfo = info;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_subscriptionInfo == null) {
      return const SizedBox.shrink();
    }

    final isPremium = _subscriptionInfo!['isPremium'] as bool;
    final remaining = _subscriptionInfo!['remainingAnalyses'] as int;
    final used = _subscriptionInfo!['usedAnalyses'] as int;
    final total = _subscriptionInfo!['totalFreeAnalyses'] as int;

    if (isPremium) {
      return const SizedBox.shrink(); // Don't show for premium users
    }

    final isLowOnAnalyses = remaining <= 2;
    final isOutOfAnalyses = remaining == 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOutOfAnalyses 
            ? AppColors.error.withOpacity(0.1)
            : isLowOnAnalyses 
                ? AppColors.orange.withOpacity(0.1)
                : AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOutOfAnalyses 
              ? AppColors.error.withOpacity(0.3)
              : isLowOnAnalyses 
                  ? AppColors.orange.withOpacity(0.3)
                  : AppColors.success.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                isOutOfAnalyses 
                    ? FontAwesomeIcons.exclamationTriangle
                    : isLowOnAnalyses 
                        ? FontAwesomeIcons.clock
                        : FontAwesomeIcons.chartLine,
                color: isOutOfAnalyses 
                    ? AppColors.error
                    : isLowOnAnalyses 
                        ? AppColors.orange
                        : AppColors.success,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                isOutOfAnalyses 
                    ? 'Analyses Limit Reached'
                    : isLowOnAnalyses 
                        ? 'Low on Free Analyses'
                        : 'Free Analyses Remaining',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isOutOfAnalyses 
                      ? AppColors.error
                      : isLowOnAnalyses 
                          ? AppColors.orange
                          : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isOutOfAnalyses 
                ? 'You\'ve used all $total free analyses this month. Upgrade to Premium for unlimited access!'
                : isLowOnAnalyses 
                    ? 'You have $remaining analyses left this month. Consider upgrading to Premium for unlimited access.'
                    : 'You have $remaining of $total free analyses remaining this month.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: used / total,
                  backgroundColor: AppColors.grey300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOutOfAnalyses 
                        ? AppColors.error
                        : isLowOnAnalyses 
                            ? AppColors.orange
                            : AppColors.success,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$used/$total',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey600,
                ),
              ),
            ],
          ),
          if (isOutOfAnalyses || isLowOnAnalyses) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showUpgradeDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Upgrade to Premium',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Premium'),
        content: const Text(
          'Get unlimited food analyses with premium AI providers for higher accuracy and better insights.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement subscription flow
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }
}
