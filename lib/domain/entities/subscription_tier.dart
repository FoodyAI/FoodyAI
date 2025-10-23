enum SubscriptionTier {
  free,
  trial,
  pro,
}

extension SubscriptionTierExtension on SubscriptionTier {
  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.trial:
        return 'Trial';
      case SubscriptionTier.pro:
        return 'Pro';
    }
  }

  String get description {
    switch (this) {
      case SubscriptionTier.free:
        return '5 free scans per month';
      case SubscriptionTier.trial:
        return '3-day trial, all features unlocked';
      case SubscriptionTier.pro:
        return 'Unlimited scans, all features';
    }
  }

  int? get maxScansPerMonth {
    switch (this) {
      case SubscriptionTier.free:
        return 5;
      case SubscriptionTier.trial:
        return null; // Unlimited during trial
      case SubscriptionTier.pro:
        return null; // Unlimited
    }
  }

  bool get hasAds {
    switch (this) {
      case SubscriptionTier.free:
        return true;
      case SubscriptionTier.trial:
        return false;
      case SubscriptionTier.pro:
        return false;
    }
  }

  bool get isUnlimited {
    return this == SubscriptionTier.trial || this == SubscriptionTier.pro;
  }
}

class UserSubscription {
  final SubscriptionTier tier;
  final int scansUsedThisMonth;
  final DateTime? trialStartDate;
  final DateTime? trialEndDate;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;

  UserSubscription({
    required this.tier,
    this.scansUsedThisMonth = 0,
    this.trialStartDate,
    this.trialEndDate,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
  });

  bool get isTrialActive {
    if (tier != SubscriptionTier.trial || trialEndDate == null) return false;
    return DateTime.now().isBefore(trialEndDate!);
  }

  int get daysRemainingInTrial {
    if (!isTrialActive || trialEndDate == null) return 0;
    return trialEndDate!.difference(DateTime.now()).inDays;
  }

  int? get scansRemaining {
    final maxScans = tier.maxScansPerMonth;
    if (maxScans == null) return null; // Unlimited
    return maxScans - scansUsedThisMonth;
  }

  bool get canScan {
    if (tier.isUnlimited) return true;
    final remaining = scansRemaining;
    return remaining != null && remaining > 0;
  }

  UserSubscription copyWith({
    SubscriptionTier? tier,
    int? scansUsedThisMonth,
    DateTime? trialStartDate,
    DateTime? trialEndDate,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
  }) {
    return UserSubscription(
      tier: tier ?? this.tier,
      scansUsedThisMonth: scansUsedThisMonth ?? this.scansUsedThisMonth,
      trialStartDate: trialStartDate ?? this.trialStartDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      subscriptionStartDate:
          subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
    );
  }
}
