import 'package:flutter_test/flutter_test.dart';
import 'package:foody/data/models/food_analysis.dart';

void main() {
  group('FoodAnalysis Tests', () {
    test('should create FoodAnalysis with correct values', () {
      // Arrange
      final analysis = FoodAnalysis(
        name: 'Apple',
        protein: 0.3,
        carbs: 14.0,
        fat: 0.2,
        calories: 52.0,
        healthScore: 8.5,
        imagePath: '/path/to/image.jpg',
      );

      // Act & Assert
      expect(analysis.name, equals('Apple'));
      expect(analysis.protein, equals(0.3));
      expect(analysis.carbs, equals(14.0));
      expect(analysis.fat, equals(0.2));
      expect(analysis.calories, equals(52.0));
      expect(analysis.healthScore, equals(8.5));
      expect(analysis.imagePath, equals('/path/to/image.jpg'));
    });

    test('should create FoodAnalysis with current date by default', () {
      // Arrange
      final beforeCreation =
          DateTime.now().subtract(const Duration(seconds: 1));

      // Act
      final analysis = FoodAnalysis(
        name: 'Banana',
        protein: 1.1,
        carbs: 22.8,
        fat: 0.3,
        calories: 89.0,
        healthScore: 7.5,
      );

      final afterCreation = DateTime.now().add(const Duration(seconds: 1));

      // Assert
      expect(analysis.date.isAfter(beforeCreation), isTrue);
      expect(analysis.date.isBefore(afterCreation), isTrue);
    });

    test('should create FoodAnalysis with custom date', () {
      // Arrange
      final customDate = DateTime(2024, 1, 15, 10, 30);

      // Act
      final analysis = FoodAnalysis(
        name: 'Orange',
        protein: 0.9,
        carbs: 11.8,
        fat: 0.1,
        calories: 47.0,
        healthScore: 8.0,
        date: customDate,
      );

      // Assert
      expect(analysis.date, equals(customDate));
    });

    test('should create FoodAnalysis using withCurrentDate factory', () {
      // Arrange
      final beforeCreation =
          DateTime.now().subtract(const Duration(seconds: 1));

      // Act
      final analysis = FoodAnalysis.withCurrentDate(
        name: 'Grape',
        protein: 0.6,
        carbs: 15.5,
        fat: 0.2,
        calories: 62.0,
        healthScore: 7.0,
      );

      final afterCreation = DateTime.now().add(const Duration(seconds: 1));

      // Assert
      expect(analysis.name, equals('Grape'));
      expect(analysis.date.isAfter(beforeCreation), isTrue);
      expect(analysis.date.isBefore(afterCreation), isTrue);
    });

    test('should convert to JSON correctly', () {
      // Arrange
      final customDate = DateTime(2024, 1, 15, 10, 30);
      final analysis = FoodAnalysis(
        name: 'Strawberry',
        protein: 0.7,
        carbs: 7.7,
        fat: 0.3,
        calories: 32.0,
        healthScore: 9.0,
        imagePath: '/path/to/strawberry.jpg',
        orderNumber: 1,
        date: customDate,
        dateOrderNumber: 2,
      );

      // Act
      final json = analysis.toJson();

      // Assert
      expect(json['name'], equals('Strawberry'));
      expect(json['protein'], equals(0.7));
      expect(json['carbs'], equals(7.7));
      expect(json['fat'], equals(0.3));
      expect(json['calories'], equals(32.0));
      expect(json['healthScore'], equals(9.0));
      expect(json['imagePath'], equals('/path/to/strawberry.jpg'));
      expect(json['orderNumber'], equals(1));
      expect(json['date'], equals(customDate.millisecondsSinceEpoch));
      expect(json['dateOrderNumber'], equals(2));
    });

    test('should create from JSON correctly', () {
      // Arrange
      final customDate = DateTime(2024, 1, 15, 10, 30);
      final json = {
        'name': 'Blueberry',
        'protein': 0.7,
        'carbs': 14.5,
        'fat': 0.3,
        'calories': 57.0,
        'healthScore': 8.5,
        'imagePath': '/path/to/blueberry.jpg',
        'orderNumber': 3,
        'date': customDate.millisecondsSinceEpoch,
        'dateOrderNumber': 4,
      };

      // Act
      final analysis = FoodAnalysis.fromJson(json);

      // Assert
      expect(analysis.name, equals('Blueberry'));
      expect(analysis.protein, equals(0.7));
      expect(analysis.carbs, equals(14.5));
      expect(analysis.fat, equals(0.3));
      expect(analysis.calories, equals(57.0));
      expect(analysis.healthScore, equals(8.5));
      expect(analysis.imagePath, equals('/path/to/blueberry.jpg'));
      expect(analysis.orderNumber, equals(3));
      expect(analysis.date, equals(customDate));
      expect(analysis.dateOrderNumber, equals(4));
    });
  });
}
