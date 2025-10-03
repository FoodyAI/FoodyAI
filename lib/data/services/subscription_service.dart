import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/ai_provider.dart';

enum SubscriptionTier {
  free,
  premium,
}

class SubscriptionService {
  static const String _subscriptionTierKey = 'subscription_tier';
  static const String _freeAnalysesUsedKey = 'free_analyses_used';
  static const String _lastResetDateKey = 'last_reset_date';
  static const int _freeAnalysesLimit = 5;

  static Future<SubscriptionTier> getSubscriptionTier() async {
    final prefs = await SharedPreferences.getInstance();
    final tierIndex = prefs.getInt(_subscriptionTierKey) ?? SubscriptionTier.free.index;
    return SubscriptionTier.values[tierIndex];
  }

  static Future<void> setSubscriptionTier(SubscriptionTier tier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_subscriptionTierKey, tier.index);
  }

  static Future<int> getFreeAnalysesUsed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_freeAnalysesUsedKey) ?? 0;
  }

  static Future<void> incrementFreeAnalysesUsed() async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getFreeAnalysesUsed();
    await prefs.setInt(_freeAnalysesUsedKey, current + 1);
  }

  static Future<bool> canPerformAnalysis() async {
    final tier = await getSubscriptionTier();
    if (tier == SubscriptionTier.premium) {
      return true; // Premium users have unlimited access
    }

    // Check if we need to reset the monthly counter
    await _resetMonthlyCounterIfNeeded();
    
    final used = await getFreeAnalysesUsed();
    return used < _freeAnalysesLimit;
  }

  static Future<int> getRemainingFreeAnalyses() async {
    final tier = await getSubscriptionTier();
    if (tier == SubscriptionTier.premium) {
      return -1; // Unlimited
    }

    await _resetMonthlyCounterIfNeeded();
    final used = await getFreeAnalysesUsed();
    return (_freeAnalysesLimit - used).clamp(0, _freeAnalysesLimit);
  }

  static Future<void> _resetMonthlyCounterIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetDate = prefs.getString(_lastResetDateKey);
    final now = DateTime.now();
    
    if (lastResetDate == null) {
      // First time, set the reset date
      await prefs.setString(_lastResetDateKey, now.toIso8601String());
      await prefs.setInt(_freeAnalysesUsedKey, 0);
      return;
    }

    final lastReset = DateTime.parse(lastResetDate);
    final daysSinceReset = now.difference(lastReset).inDays;
    
    // Reset if it's been more than 30 days
    if (daysSinceReset >= 30) {
      await prefs.setString(_lastResetDateKey, now.toIso8601String());
      await prefs.setInt(_freeAnalysesUsedKey, 0);
    }
  }

  static Future<bool> isPremiumProvider(AIProvider provider) async {
    return provider != AIProvider.huggingface;
  }

  static Future<bool> canUseProvider(AIProvider provider) async {
    final tier = await getSubscriptionTier();
    if (tier == SubscriptionTier.premium) {
      return true;
    }
    
    // Free users can only use Hugging Face
    return provider == AIProvider.huggingface;
  }

  static Future<Map<String, dynamic>> getSubscriptionInfo() async {
    final tier = await getSubscriptionTier();
    final remaining = await getRemainingFreeAnalyses();
    final used = await getFreeAnalysesUsed();
    
    return {
      'tier': tier,
      'remainingAnalyses': remaining,
      'usedAnalyses': used,
      'totalFreeAnalyses': _freeAnalysesLimit,
      'isPremium': tier == SubscriptionTier.premium,
    };
  }
}
