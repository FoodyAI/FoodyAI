import 'package:flutter_test/flutter_test.dart';
import 'package:foody/domain/entities/user_profile.dart';

void main() {
  group('UserProfile BMI Calculation', () {
    test('should calculate BMI correctly for normal weight male', () {
      // Arrange - Set up your test data
      final profile = UserProfile(
        gender: 'male',
        age: 30,
        weightKg: 70.0,
        heightCm: 175.0,
        activityLevel: ActivityLevel.moderatelyActive,
      );

      // Act - Execute the function you're testing
      final bmi = profile.bmi;

      // Assert - Check if the result is what you expected
      expect(bmi, closeTo(22.86, 0.01)); // BMI = 70 / (1.75 * 1.75)
    });

    test('should calculate BMI correctly for overweight person', () {
      // Arrange
      final profile = UserProfile(
        gender: 'female',
        age: 25,
        weightKg: 80.0,
        heightCm: 160.0, // 1.6 meters
        activityLevel: ActivityLevel.sedentary,
      );

      // Act
      final bmi = profile.bmi;

      // Assert
      expect(bmi, closeTo(31.25, 0.01)); // BMI = 80 / (1.6 * 1.6)
    });

    test('should calculate BMI correctly for underweight person', () {
      // Arrange
      final profile = UserProfile(
        gender: 'male',
        age: 20,
        weightKg: 50.0,
        heightCm: 180.0, // 1.8 meters
        activityLevel: ActivityLevel.lightlyActive,
      );

      // Act
      final bmi = profile.bmi;

      // Assert
      expect(bmi, closeTo(15.43, 0.01)); // BMI = 50 / (1.8 * 1.8)
    });

    test('should handle edge case - very tall person', () {
      // Arrange
      final profile = UserProfile(
        gender: 'male',
        age: 35,
        weightKg: 100.0,
        heightCm: 200.0, // 2 meters tall
        activityLevel: ActivityLevel.veryActive,
      );

      // Act
      final bmi = profile.bmi;

      // Assert
      expect(bmi, closeTo(25.0, 0.01)); // BMI = 100 / (2.0 * 2.0)
    });

    test('should handle edge case - very short person', () {
      // Arrange
      final profile = UserProfile(
        gender: 'female',
        age: 28,
        weightKg: 45.0,
        heightCm: 150.0, // 1.5 meters
        activityLevel: ActivityLevel.moderatelyActive,
      );

      // Act
      final bmi = profile.bmi;

      // Assert
      expect(bmi, closeTo(20.0, 0.01)); // BMI = 45 / (1.5 * 1.5)
    });
  });
}
