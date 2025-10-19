import 'ai_provider.dart';

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

enum WeightGoal {
  lose,
  maintain,
  gain;

  String get displayName {
    switch (this) {
      case WeightGoal.lose:
        return 'Lose Weight';
      case WeightGoal.maintain:
        return 'Maintain Weight';
      case WeightGoal.gain:
        return 'Gain Weight';
    }
  }

  double get calorieAdjustment {
    switch (this) {
      case WeightGoal.lose:
        return -500.0; // 500 calorie deficit
      case WeightGoal.maintain:
        return 0.0;
      case WeightGoal.gain:
        return 500.0; // 500 calorie surplus
    }
  }
}

class UserProfile {
  final String gender;
  final int age;
  final double weightKg;
  final double heightCm;
  final ActivityLevel activityLevel;
  final WeightGoal weightGoal;
  final AIProvider aiProvider;
  final String? fcmToken;
  final bool notificationsEnabled;
  final bool isPremium;

  UserProfile({
    required this.gender,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.activityLevel,
    this.weightGoal = WeightGoal.maintain,
    AIProvider? aiProvider, // Ignore any AI provider passed, always use Gemini
    this.fcmToken,
    this.notificationsEnabled = true,
    this.isPremium = false,
  }) : aiProvider = AIProvider.gemini; // ALWAYS use Gemini - ignores parameter

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  double get dailyCalories {
    double bmr = gender == 'male'
        ? 10 * weightKg + 6.25 * heightCm - 5 * age + 5
        : 10 * weightKg + 6.25 * heightCm - 5 * age - 161;

    double tdee;
    switch (activityLevel) {
      case ActivityLevel.sedentary:
        tdee = bmr * 1.2;
        break;
      case ActivityLevel.lightlyActive:
        tdee = bmr * 1.375;
        break;
      case ActivityLevel.moderatelyActive:
        tdee = bmr * 1.55;
        break;
      case ActivityLevel.veryActive:
        tdee = bmr * 1.725;
        break;
      case ActivityLevel.extraActive:
        tdee = bmr * 1.9;
        break;
    }

    return tdee + weightGoal.calorieAdjustment;
  }
}
