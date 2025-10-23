import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Unit Conversion Tests', () {
    test('should convert pounds to kilograms correctly', () {
      // Arrange
      const weightLbs = 154.32; // 70 kg in pounds
      const expectedKg = 70.0;

      // Act
      const result = weightLbs * 0.453592;

      // Assert
      expect(result, closeTo(expectedKg, 0.01));
    });

    test('should convert kilograms to pounds correctly', () {
      // Arrange
      const weightKg = 70.0;
      const expectedLbs = 154.32;

      // Act
      const result = weightKg * 2.20462;

      // Assert
      expect(result, closeTo(expectedLbs, 0.01));
    });

    test('should convert inches to centimeters correctly', () {
      // Arrange
      const heightInches = 68.9; // 175 cm in inches
      const expectedCm = 175.0;

      // Act
      const result = heightInches * 2.54;

      // Assert
      expect(result, closeTo(expectedCm, 0.01));
    });

    test('should convert centimeters to inches correctly', () {
      // Arrange
      const heightCm = 175.0;
      const expectedInches = 68.9;

      // Act
      const result = heightCm / 2.54;

      // Assert
      expect(result, closeTo(expectedInches, 0.01));
    });

    test('should handle edge case - very heavy person', () {
      // Arrange
      const weightLbs = 300.0; // 136.08 kg
      const expectedKg = 136.08;

      // Act
      const result = weightLbs * 0.453592;

      // Assert
      expect(result, closeTo(expectedKg, 0.01));
    });

    test('should handle edge case - very light person', () {
      // Arrange
      const weightKg = 40.0; // 88.18 lbs
      const expectedLbs = 88.18;

      // Act
      const result = weightKg * 2.20462;

      // Assert
      expect(result, closeTo(expectedLbs, 0.01));
    });

    test('should handle edge case - very tall person', () {
      // Arrange
      const heightInches = 80.0; // 203.2 cm
      const expectedCm = 203.2;

      // Act
      const result = heightInches * 2.54;

      // Assert
      expect(result, closeTo(expectedCm, 0.01));
    });

    test('should handle edge case - very short person', () {
      // Arrange
      const heightCm = 140.0; // 55.12 inches
      const expectedInches = 55.12;

      // Act
      const result = heightCm / 2.54;

      // Assert
      expect(result, closeTo(expectedInches, 0.01));
    });
  });
}
