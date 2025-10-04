import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foody/presentation/widgets/google_signin_button.dart';

void main() {
  group('GoogleSignInButton Widget Tests', () {
    testWidgets('should display Google sign in text',
        (WidgetTester tester) async {
      // Arrange - Create the widget
      const button = GoogleSignInButton(
        onPressed: null,
      );

      // Act - Pump the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: button,
          ),
        ),
      );

      // Assert - Check if the button text is displayed
      expect(find.text("Sign in with Google"), findsOneWidget);
    });

    testWidgets('should have Google logo', (WidgetTester tester) async {
      // Arrange
      const button = GoogleSignInButton(
        onPressed: null,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: button,
          ),
        ),
      );

      // Assert - Check if Google logo exists
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should be tappable when onPressed is provided',
        (WidgetTester tester) async {
      // Arrange
      bool wasPressed = false;
      final button = GoogleSignInButton(
        onPressed: () {
          wasPressed = true;
        },
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: button,
          ),
        ),
      );

      // Tap the button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert - Check if the callback was called
      expect(wasPressed, isTrue);
    });

    testWidgets('should not be tappable when onPressed is null',
        (WidgetTester tester) async {
      // Arrange
      const button = GoogleSignInButton(
        onPressed: null,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: button,
          ),
        ),
      );

      // Assert - Check if the button is disabled
      final elevatedButton =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(elevatedButton.onPressed, isNull);
    });

    testWidgets('should have correct styling in light theme',
        (WidgetTester tester) async {
      // Arrange
      const button = GoogleSignInButton(
        onPressed: null,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: button,
          ),
        ),
      );

      // Assert - Check if the button has correct styling
      final elevatedButton =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(elevatedButton.style?.elevation, equals(0));
      expect(
          elevatedButton.style?.backgroundColor, isA<MaterialStateProperty>());
    });

    testWidgets('should have correct styling in dark theme',
        (WidgetTester tester) async {
      // Arrange
      const button = GoogleSignInButton(
        onPressed: null,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: button,
          ),
        ),
      );

      // Assert - Check if the button has correct styling
      final elevatedButton =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(elevatedButton.style?.elevation, equals(0));
      expect(
          elevatedButton.style?.backgroundColor, isA<MaterialStateProperty>());
    });

    testWidgets('should have correct text styling',
        (WidgetTester tester) async {
      // Arrange
      const button = GoogleSignInButton(
        onPressed: null,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: button,
          ),
        ),
      );

      // Assert - Check if the text has correct styling
      final textWidget = tester.widget<Text>(find.text("Sign in with Google"));
      expect(textWidget.style?.fontWeight, equals(FontWeight.w500));
    });
  });
}
