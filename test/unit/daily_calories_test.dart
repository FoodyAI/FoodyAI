import 'package:flutter_test/flutter_test.dart';
import 'package:foody/domain/entities/user_profile.dart';

void main() {
  group('Daily Calories Calculation', () {
    test('should calculate correct calories for sedentary male', () {
      // Arrange
      final profile = UserProfile(
        gender: 'male',
        age: 30,
        weightKg: 70.0,
        heightCm: 175.0,
        activityLevel: ActivityLevel.sedentary,
        weightGoal: WeightGoal.maintain,
      );
      
      // Act
      final dailyCalories = profile.dailyCalories;
      
      // Assert
      // BMR = 10 * 70 + 6.25 * 175 - 5 * 30 + 5 = 700 + 1093.75 - 150 + 5 = 1648.75
      // TDEE = 1648.75 * 1.2 = 1978.5
      expect(dailyCalories, closeTo(1978.5, 1.0));
    });
    
    test('should calculate correct calories for very active female', () {
      // Arrange
      final profile = UserProfile(
        gender: 'female',
        age: 25,
        weightKg: 60.0,
        heightCm: 165.0,
        activityLevel: ActivityLevel.veryActive,
        weightGoal: WeightGoal.maintain,
      );
      
      // Act
      final dailyCalories = profile.dailyCalories;
      
      // Assert
      // BMR = 10 * 60 + 6.25 * 165 - 5 * 25 - 161 = 600 + 1031.25 - 125 - 161 = 1345.25
      // TDEE = 1345.25 * 1.725 = 2320.56
      expect(dailyCalories, closeTo(2320.56, 1.0));
    });
    
    test('should calculate correct calories for moderately active male', () {
      // Arrange
      final profile = UserProfile(
        gender: 'male',
        age: 35,
        weightKg: 80.0,
        heightCm: 180.0,
        activityLevel: ActivityLevel.moderatelyActive,
        weightGoal: WeightGoal.maintain,
      );
      
      // Act
      final dailyCalories = profile.dailyCalories;
      
      // Assert
      // BMR = 10 * 80 + 6.25 * 180 - 5 * 35 + 5 = 800 + 1125 - 175 + 5 = 1755
      // TDEE = 1755 * 1.55 = 2720.25
      expect(dailyCalories, closeTo(2720.25, 1.0));
    });
    
    test('should calculate correct calories for extra active female', () {
      // Arrange
      final profile = UserProfile(
        gender: 'female',
        age: 22,
        weightKg: 55.0,
        heightCm: 160.0,
        activityLevel: ActivityLevel.extraActive,
        weightGoal: WeightGoal.maintain,
      );
      
      // Act
      final dailyCalories = profile.dailyCalories;
      
      // Assert
      // BMR = 10 * 55 + 6.25 * 160 - 5 * 22 - 161 = 550 + 1000 - 110 - 161 = 1279
      // TDEE = 1279 * 1.9 = 2430.1
      expect(dailyCalories, closeTo(2430.1, 1.0));
    });
    
    test('should calculate correct calories for lightly active male', () {
      // Arrange
      final profile = UserProfile(
        gender: 'male',
        age: 40,
        weightKg: 90.0,
        heightCm: 185.0,
        activityLevel: ActivityLevel.lightlyActive,
        weightGoal: WeightGoal.maintain,
      );
      
      // Act
      final dailyCalories = profile.dailyCalories;
      
      // Assert
      // BMR = 10 * 90 + 6.25 * 185 - 5 * 40 + 5 = 900 + 1156.25 - 200 + 5 = 1861.25
      // TDEE = 1861.25 * 1.375 = 2559.22
      expect(dailyCalories, closeTo(2559.22, 1.0));
    });
  });
}
