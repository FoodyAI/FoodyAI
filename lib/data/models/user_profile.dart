/// ActivityLevel enum with multiplier
enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  extraActive,
}

extension ActivityLevelX on ActivityLevel {
  String get displayName {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.lightlyActive:
        return 'Lightly active';
      case ActivityLevel.moderatelyActive:
        return 'Moderately active';
      case ActivityLevel.veryActive:
        return 'Very active';
      case ActivityLevel.extraActive:
        return 'Extra active';
    }
  }

  double get multiplier {
    switch (this) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.lightlyActive:
        return 1.375;
      case ActivityLevel.moderatelyActive:
        return 1.55;
      case ActivityLevel.veryActive:
        return 1.725;
      case ActivityLevel.extraActive:
        return 1.9;
    }
  }
}

/// UserProfile now includes gender & age, and uses Mifflin–St Jeor
class UserProfile {
  final String gender;            // "Male" or "Female"
  final int age;                  // in years
  final double weightKg;
  final double heightCm;
  final ActivityLevel activityLevel;

  UserProfile({
    required this.gender,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.activityLevel,
  });

  double get heightM => heightCm / 100;
  double get bmi => weightKg / (heightM * heightM);

  /// Ideal weight for BMI = 22
  double get recommendedWeightKg => 22 * heightM * heightM;

  /// Basal Metabolic Rate via Mifflin–St Jeor
  double get bmr {
    var base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    base += gender.toLowerCase() == 'male' ? 5 : -161;
    return base;
  }

  /// Total Daily Energy Expenditure (TDEE)
  double get dailyCalories => bmr * activityLevel.multiplier;
}
