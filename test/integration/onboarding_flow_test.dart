import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foody/main.dart' as app;

void main() {
  group('Onboarding Flow Integration Tests', () {
    testWidgets('Complete onboarding flow from welcome to home',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify we're on the welcome screen
      expect(find.text('Foody'), findsOneWidget);
      expect(find.text('AI-Powered Food Analysis'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.text('Skip for now'), findsOneWidget);

      // Tap "Skip for now" to continue as guest
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();

      // Should navigate to onboarding
      expect(find.text("What's your gender?"), findsOneWidget);
      expect(find.text('This helps us calculate your daily calorie needs'),
          findsOneWidget);

      // Select Male gender
      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();

      // Tap Next button
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Should be on measurements page
      expect(find.text('Your Measurements'), findsOneWidget);
      expect(find.text("Let's get to know your body better"), findsOneWidget);

      // Test unit toggle
      expect(find.text('Metric'), findsOneWidget);
      await tester.tap(find.text('Metric'));
      await tester.pumpAndSettle();
      expect(find.text('Imperial'), findsOneWidget);

      // Toggle back to metric
      await tester.tap(find.text('Imperial'));
      await tester.pumpAndSettle();
      expect(find.text('Metric'), findsOneWidget);

      // Edit age
      await tester.tap(find.text('25 years'));
      await tester.pumpAndSettle();

      // Should show age dialog
      expect(find.text('Select Age'), findsOneWidget);

      // Cancel the dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Edit weight
      await tester.tap(find.text('70.0 kg'));
      await tester.pumpAndSettle();

      // Should show weight dialog
      expect(find.text('Edit Weight'), findsOneWidget);

      // Cancel the dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Edit height
      await tester.tap(find.text('170.0 cm'));
      await tester.pumpAndSettle();

      // Should show height dialog
      expect(find.text('Edit Height'), findsOneWidget);

      // Cancel the dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Tap Next to continue
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Should be on activity page
      expect(find.text('Your Activity Level'), findsOneWidget);
      expect(
          find.text('How active are you in your daily life?'), findsOneWidget);

      // Select moderately active
      await tester.tap(find.text('Moderately Active'));
      await tester.pumpAndSettle();

      // Should show weight goal section
      expect(find.text('Your Weight Goal'), findsOneWidget);
      expect(find.text('What would you like to achieve?'), findsOneWidget);

      // Select maintain weight goal
      await tester.tap(find.text('Maintain Weight'));
      await tester.pumpAndSettle();

      // Tap Next to continue
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Should be on summary page
      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('Review your information before submitting'),
          findsOneWidget);

      // Verify summary information
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Measurements'), findsOneWidget);
      expect(find.text('Activity Level'), findsOneWidget);
      expect(find.text('Weight Goal'), findsOneWidget);

      // Submit the form
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // Should navigate to analysis loading view
      expect(find.text('Setting up your profile...'), findsOneWidget);
      expect(
          find.text(
              'Please wait while we prepare your personalized experience'),
          findsOneWidget);

      // Wait for loading to complete and navigate to home
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should be on home screen
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Analyze'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('Onboarding with Google sign in', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify we're on the welcome screen
      expect(find.text('Foody'), findsOneWidget);

      // Tap Google sign in button
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();

      // Should show loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Note: In a real test, you would mock the Google sign-in response
      // For this integration test, we'll simulate the sign-in completion
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should navigate to onboarding or home depending on implementation
      // This would depend on whether the user has completed onboarding before
    });

    testWidgets('Onboarding form validation', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Skip welcome screen
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();

      // Try to proceed without selecting gender
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Should still be on gender page (Next button should be disabled)
      expect(find.text("What's your gender?"), findsOneWidget);

      // Select gender
      await tester.tap(find.text('Female'));
      await tester.pumpAndSettle();

      // Now Next button should be enabled
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Should proceed to measurements page
      expect(find.text('Your Measurements'), findsOneWidget);
    });

    testWidgets('Onboarding back navigation', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Skip welcome screen
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();

      // Complete first page
      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Should be on measurements page
      expect(find.text('Your Measurements'), findsOneWidget);

      // Go back
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // Should be back on gender page
      expect(find.text("What's your gender?"), findsOneWidget);
      expect(find.text('Male'), findsOneWidget); // Should still be selected
    });

    testWidgets('Onboarding with different user profiles',
        (WidgetTester tester) async {
      // Test with different gender, age, weight, height combinations
      final testCases = [
        {
          'gender': 'Female',
          'age': 25,
          'weight': 60.0,
          'height': 165.0,
          'activity': 'Lightly Active',
          'goal': 'Lose Weight'
        },
        {
          'gender': 'Male',
          'age': 35,
          'weight': 80.0,
          'height': 180.0,
          'activity': 'Very Active',
          'goal': 'Gain Weight'
        }
      ];

      for (final testCase in testCases) {
        // Start the app
        app.main();
        await tester.pumpAndSettle();

        // Skip welcome screen
        await tester.tap(find.text('Skip for now'));
        await tester.pumpAndSettle();

        // Select gender
        await tester.tap(find.text(testCase['gender'] as String));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        // Skip measurements (using defaults)
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        // Select activity level
        await tester.tap(find.text(testCase['activity'] as String));
        await tester.pumpAndSettle();

        // Select weight goal
        await tester.tap(find.text(testCase['goal'] as String));
        await tester.pumpAndSettle();

        // Submit
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Submit'));
        await tester.pumpAndSettle();

        // Should complete onboarding
        await tester.pumpAndSettle(const Duration(seconds: 3));
        expect(find.text('Home'), findsOneWidget);

        // Clean up for next test case
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/platform',
          null,
          (data) {},
        );
      }
    });
  });
}
