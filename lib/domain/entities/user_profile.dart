enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  extraActive;

  String get displayName {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active';
      case ActivityLevel.veryActive:
        return 'Very Active';
      case ActivityLevel.extraActive:
        return 'Extra Active';
    }
  }
}

class UserProfile {
  final String gender;
  final int age;
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

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  double get dailyCalories {
    double bmr = gender == 'male'
        ? 10 * weightKg + 6.25 * heightCm - 5 * age + 5
        : 10 * weightKg + 6.25 * heightCm - 5 * age - 161;

    switch (activityLevel) {
      case ActivityLevel.sedentary:
        return bmr * 1.2;
      case ActivityLevel.lightlyActive:
        return bmr * 1.375;
      case ActivityLevel.moderatelyActive:
        return bmr * 1.55;
      case ActivityLevel.veryActive:
        return bmr * 1.725;
      case ActivityLevel.extraActive:
        return bmr * 1.9;
    }
  }
}
