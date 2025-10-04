import 'package:flutter_test/flutter_test.dart';
import 'package:foody/domain/entities/user_profile.dart';

void main() {
  group('ActivityLevel Tests', () {
    test('should return correct display name for sedentary', () {
      // Arrange
      const activityLevel = ActivityLevel.sedentary;

      // Act
      final displayName = activityLevel.displayName;

      // Assert
      expect(displayName, equals('Sedentary'));
    });

    test('should return correct display name for lightly active', () {
      // Arrange
      const activityLevel = ActivityLevel.lightlyActive;

      // Act
      final displayName = activityLevel.displayName;

      // Assert
      expect(displayName, equals('Lightly Active'));
    });

    test('should return correct display name for moderately active', () {
      // Arrange
      const activityLevel = ActivityLevel.moderatelyActive;

      // Act
      final displayName = activityLevel.displayName;

      // Assert
      expect(displayName, equals('Moderately Active'));
    });

    test('should return correct display name for very active', () {
      // Arrange
      const activityLevel = ActivityLevel.veryActive;

      // Act
      final displayName = activityLevel.displayName;

      // Assert
      expect(displayName, equals('Very Active'));
    });

    test('should return correct display name for extra active', () {
      // Arrange
      const activityLevel = ActivityLevel.extraActive;

      // Act
      final displayName = activityLevel.displayName;

      // Assert
      expect(displayName, equals('Extra Active'));
    });
  });
}
