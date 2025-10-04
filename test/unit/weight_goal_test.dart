import 'package:flutter_test/flutter_test.dart';
import 'package:foody/domain/entities/user_profile.dart';

void main() {
  group('WeightGoal Tests', () {
    test('should return correct calorie adjustment for maintain', () {
      // Arrange
      const weightGoal = WeightGoal.maintain;
      
      // Act
      final adjustment = weightGoal.calorieAdjustment;
      
      // Assert
      expect(adjustment, equals(0.0));
    });
    
    test('should return correct calorie adjustment for lose', () {
      // Arrange
      const weightGoal = WeightGoal.lose;
      
      // Act
      final adjustment = weightGoal.calorieAdjustment;
      
      // Assert
      expect(adjustment, equals(-500.0));
    });
    
    test('should return correct calorie adjustment for gain', () {
      // Arrange
      const weightGoal = WeightGoal.gain;
      
      // Act
      final adjustment = weightGoal.calorieAdjustment;
      
      // Assert
      expect(adjustment, equals(500.0));
    });
    
    test('should return correct display name for maintain', () {
      // Arrange
      const weightGoal = WeightGoal.maintain;
      
      // Act
      final displayName = weightGoal.displayName;
      
      // Assert
      expect(displayName, equals('Maintain Weight'));
    });
    
    test('should return correct display name for lose', () {
      // Arrange
      const weightGoal = WeightGoal.lose;
      
      // Act
      final displayName = weightGoal.displayName;
      
      // Assert
      expect(displayName, equals('Lose Weight'));
    });
    
    test('should return correct display name for gain', () {
      // Arrange
      const weightGoal = WeightGoal.gain;
      
      // Act
      final displayName = weightGoal.displayName;
      
      // Assert
      expect(displayName, equals('Gain Weight'));
    });
  });
}
