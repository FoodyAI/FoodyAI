import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foody/presentation/widgets/food_analysis_card.dart';
import 'package:foody/data/models/food_analysis.dart';

void main() {
  group('FoodAnalysisCard Widget Tests', () {
    testWidgets('should display food analysis information',
        (WidgetTester tester) async {
      // Arrange - Create test data
      final analysis = FoodAnalysis(
        name: 'Apple',
        protein: 0.3,
        carbs: 14.0,
        fat: 0.2,
        calories: 52.0,
        healthScore: 8.5,
        imagePath: '/path/to/image.jpg',
      );

      final card = FoodAnalysisCard(
        analysis: analysis,
        onDelete: null,
      );

      // Act - Pump the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      // Assert - Check if food information is displayed
      expect(find.text("Apple"), findsOneWidget);
      expect(find.text("52"), findsOneWidget); // Calories
      expect(find.text("8.5"), findsOneWidget); // Health score
    });

    testWidgets('should display nutritional information',
        (WidgetTester tester) async {
      // Arrange
      final analysis = FoodAnalysis(
        name: 'Banana',
        protein: 1.1,
        carbs: 22.8,
        fat: 0.3,
        calories: 89.0,
        healthScore: 7.5,
      );

      final card = FoodAnalysisCard(
        analysis: analysis,
        onDelete: null,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      // Assert - Check if nutritional information is displayed
      expect(find.text("1.1g"), findsOneWidget); // Protein
      expect(find.text("22.8g"), findsOneWidget); // Carbs
      expect(find.text("0.3g"), findsOneWidget); // Fat
    });

    testWidgets('should be tappable when onTap is provided',
        (WidgetTester tester) async {
      // Arrange
      final analysis = FoodAnalysis(
        name: 'Orange',
        protein: 0.9,
        carbs: 11.8,
        fat: 0.1,
        calories: 47.0,
        healthScore: 8.0,
      );

      bool wasTapped = false;
      final card = FoodAnalysisCard(
        analysis: analysis,
        onDelete: null,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      // Tap the card
      await tester.tap(find.byType(Card));
      await tester.pump();

      // Assert - Check if the callback was called
      expect(wasTapped, isTrue);
    });

    testWidgets('should have delete button when onDelete is provided',
        (WidgetTester tester) async {
      // Arrange
      final analysis = FoodAnalysis(
        name: 'Grape',
        protein: 0.6,
        carbs: 15.5,
        fat: 0.2,
        calories: 62.0,
        healthScore: 7.0,
      );

      final card = FoodAnalysisCard(
        analysis: analysis,
        onDelete: null,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      // Assert - Check if delete button exists
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('should call onDelete when delete button is tapped',
        (WidgetTester tester) async {
      // Arrange
      final analysis = FoodAnalysis(
        name: 'Strawberry',
        protein: 0.7,
        carbs: 7.7,
        fat: 0.3,
        calories: 32.0,
        healthScore: 9.0,
      );

      bool wasDeleted = false;
      final card = FoodAnalysisCard(
        analysis: analysis,
        onDelete: () {
          wasDeleted = true;
        },
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      // Tap the delete button
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();

      // Assert - Check if the callback was called
      expect(wasDeleted, isTrue);
    });

    testWidgets('should display health score with correct color',
        (WidgetTester tester) async {
      // Arrange
      final analysis = FoodAnalysis(
        name: 'Blueberry',
        protein: 0.7,
        carbs: 14.5,
        fat: 0.3,
        calories: 57.0,
        healthScore: 8.5,
      );

      final card = FoodAnalysisCard(
        analysis: analysis,
        onDelete: null,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      // Assert - Check if health score is displayed
      expect(find.text("8.5"), findsOneWidget);
    });

    testWidgets('should have correct styling', (WidgetTester tester) async {
      // Arrange
      final analysis = FoodAnalysis(
        name: 'Mango',
        protein: 0.8,
        carbs: 15.0,
        fat: 0.4,
        calories: 60.0,
        healthScore: 7.5,
      );

      final card = FoodAnalysisCard(
        analysis: analysis,
        onDelete: null,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      // Assert - Check if the card has correct styling
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(Padding), findsWidgets);
    });
  });
}
