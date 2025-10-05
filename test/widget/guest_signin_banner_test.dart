import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foody/presentation/widgets/guest_signin_banner.dart';

void main() {
  group('GuestSignInBanner Widget Tests', () {
    testWidgets('should display sign in message', (WidgetTester tester) async {
      // Arrange - Create the widget
      const banner = GuestSignInBanner();

      // Act - Pump the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: banner,
          ),
        ),
      );

      // Assert - Check if the sign in message is displayed
      expect(find.text("Sign in to sync & backup your data"), findsOneWidget);
    });

    testWidgets('should have dismiss button', (WidgetTester tester) async {
      // Arrange
      const banner = GuestSignInBanner();

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: banner,
          ),
        ),
      );

      // Assert - Check if dismiss button exists
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should dismiss when close button is tapped',
        (WidgetTester tester) async {
      // Arrange
      const banner = GuestSignInBanner();

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: banner,
          ),
        ),
      );

      // Verify banner is visible
      expect(find.text("Sign in to sync & backup your data"), findsOneWidget);

      // Tap the dismiss button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump(); // Trigger animation
      await tester
          .pump(const Duration(milliseconds: 500)); // Wait for animation

      // Assert - Banner should be dismissed
      expect(find.text("Sign in to sync & backup your data"), findsNothing);
    });

    testWidgets('should have correct styling', (WidgetTester tester) async {
      // Arrange
      const banner = GuestSignInBanner();

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: banner,
          ),
        ),
      );

      // Assert - Check if the banner has correct styling
      final container = tester.widget<Container>(find.byType(Container));
      expect(container.decoration, isA<BoxDecoration>());

      final boxDecoration = container.decoration as BoxDecoration;
      expect(boxDecoration.borderRadius, isA<BorderRadius>());
    });

    testWidgets('should have Google sign in button',
        (WidgetTester tester) async {
      // Arrange
      const banner = GuestSignInBanner();

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: banner,
          ),
        ),
      );

      // Assert - Check if Google sign in button exists
      expect(find.text("Sign in with Google"), findsOneWidget);
    });

    testWidgets('should have correct text styling',
        (WidgetTester tester) async {
      // Arrange
      const banner = GuestSignInBanner();

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: banner,
          ),
        ),
      );

      // Assert - Check if the text has correct styling
      final textWidget =
          tester.widget<Text>(find.text("Sign in to sync & backup your data"));
      expect(textWidget.style?.fontSize, equals(14.0));
      expect(textWidget.style?.fontWeight, equals(FontWeight.w500));
    });
  });
}
