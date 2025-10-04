import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foody/presentation/widgets/connection_banner.dart';

void main() {
  group('ConnectionBanner Widget Tests', () {
    testWidgets('should display offline message when disconnected',
        (WidgetTester tester) async {
      // Arrange - Create the widget
      const banner = ConnectionBanner(
        isConnected: false,
      );

      // Act - Pump the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: banner,
          ),
        ),
      );

      // Assert - Check if the offline message is displayed
      expect(find.text("You're offline"), findsOneWidget);
      expect(find.text("You're back online"), findsNothing);
    });

    testWidgets('should display online message when connected',
        (WidgetTester tester) async {
      // Arrange - Create the widget
      const banner = ConnectionBanner(
        isConnected: true,
      );

      // Act - Pump the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: banner,
          ),
        ),
      );

      // Assert - Check if the online message is displayed
      expect(find.text("You're back online"), findsOneWidget);
      expect(find.text("You're offline"), findsNothing);
    });

    testWidgets('should have correct styling for offline state',
        (WidgetTester tester) async {
      // Arrange
      const banner = ConnectionBanner(
        isConnected: false,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: banner,
          ),
        ),
      );

      // Assert - Check if the banner has the correct styling
      final container = tester.widget<Container>(find.byType(Container));
      expect(container.decoration, isA<BoxDecoration>());

      final boxDecoration = container.decoration as BoxDecoration;
      expect(boxDecoration.color, equals(Colors.red));
    });

    testWidgets('should have correct styling for online state',
        (WidgetTester tester) async {
      // Arrange
      const banner = ConnectionBanner(
        isConnected: true,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: banner,
          ),
        ),
      );

      // Assert - Check if the banner has the correct styling
      final container = tester.widget<Container>(find.byType(Container));
      expect(container.decoration, isA<BoxDecoration>());

      final boxDecoration = container.decoration as BoxDecoration;
      expect(boxDecoration.color, equals(Colors.green));
    });

    testWidgets('should be centered', (WidgetTester tester) async {
      // Arrange
      const banner = ConnectionBanner(
        isConnected: false,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: banner,
          ),
        ),
      );

      // Assert - Check if the text is centered
      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('should have correct text styling',
        (WidgetTester tester) async {
      // Arrange
      const banner = ConnectionBanner(
        isConnected: false,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: banner,
          ),
        ),
      );

      // Assert - Check if the text has correct styling
      final textWidget = tester.widget<Text>(find.text("You're offline"));
      expect(textWidget.style?.color, equals(Colors.white));
      expect(textWidget.style?.fontSize, equals(14.0));
      expect(textWidget.style?.fontWeight, equals(FontWeight.w500));
    });
  });
}
