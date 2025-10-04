import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foody/presentation/widgets/calorie_tracking_card.dart';

void main() {
  group('CalorieTrackingCard Widget Tests', () {
    testWidgets('should display calorie information',
        (WidgetTester tester) async {
      // Arrange - Create the widget with test data
      final card = CalorieTrackingCard(
        totalCaloriesConsumed: 1200,
        recommendedCalories: 2000,
        savedAnalyses: [],
        selectedDate: DateTime.now(),
        onDateSelected: (date) {},
      );

      // Act - Pump the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      // Assert - Check if calorie information is displayed
      expect(find.text("1,200"), findsOneWidget); // Consumed calories
      expect(find.text("2,000"), findsOneWidget); // Target calories
      expect(find.text("800"), findsOneWidget); // Remaining calories
    });

    testWidgets('should display progress bar', (WidgetTester tester) async {
      // Arrange
      final card = CalorieTrackingCard(
        totalCaloriesConsumed: 1200,
        recommendedCalories: 2000,
        savedAnalyses: [],
        selectedDate: DateTime.now(),
        onDateSelected: (date) {},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      // Assert - Check if progress bar exists
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should calculate correct progress percentage',
        (WidgetTester tester) async {
      // Arrange
      final card = CalorieTrackingCard(
        totalCaloriesConsumed: 1200,
        recommendedCalories: 2000,
        savedAnalyses: [],
        selectedDate: DateTime.now(),
        onDateSelected: (date) {},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      // Assert - Check if progress bar has correct value
      final progressBar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator));
      expect(progressBar.value, equals(0.6)); // 1200/2000 = 0.6
    });

    testWidgets('should display correct labels', (WidgetTester tester) async {
      // Arrange
      final card = CalorieTrackingCard(
        totalCaloriesConsumed: 1200,
        recommendedCalories: 2000,
        savedAnalyses: [],
        selectedDate: DateTime.now(),
        onDateSelected: (date) {},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      // Assert - Check if labels are displayed
      expect(find.text("Consumed"), findsOneWidget);
      expect(find.text("Target"), findsOneWidget);
      expect(find.text("Remaining"), findsOneWidget);
    });

    testWidgets('should handle zero calories', (WidgetTester tester) async {
      // Arrange
      final card = CalorieTrackingCard(
        totalCaloriesConsumed: 0,
        recommendedCalories: 2000,
        savedAnalyses: [],
        selectedDate: DateTime.now(),
        onDateSelected: (date) {},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      // Assert - Check if zero calories are displayed correctly
      expect(find.text("0"), findsOneWidget);
      expect(find.text("2,000"), findsOneWidget);
    });

    testWidgets('should handle over target calories',
        (WidgetTester tester) async {
      // Arrange
      final card = CalorieTrackingCard(
        totalCaloriesConsumed: 2500,
        recommendedCalories: 2000,
        savedAnalyses: [],
        selectedDate: DateTime.now(),
        onDateSelected: (date) {},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      // Assert - Check if over target is handled correctly
      expect(find.text("2,500"), findsOneWidget);
      expect(find.text("2,000"), findsOneWidget);
      expect(find.text("-500"), findsOneWidget);
    });

    testWidgets('should have correct styling', (WidgetTester tester) async {
      // Arrange
      final card = CalorieTrackingCard(
        totalCaloriesConsumed: 1200,
        recommendedCalories: 2000,
        savedAnalyses: [],
        selectedDate: DateTime.now(),
        onDateSelected: (date) {},
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
