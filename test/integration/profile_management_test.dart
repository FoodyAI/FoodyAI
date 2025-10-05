import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foody/main.dart' as app;

void main() {
  group('Profile Management Integration Tests', () {
    testWidgets('Complete profile editing workflow',
        (WidgetTester tester) async {
      // Start the app and complete onboarding
      app.main();
      await tester.pumpAndSettle();

      // Skip welcome and complete onboarding quickly
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Should be on profile view
      expect(find.text('Profile'), findsOneWidget);

      // Test Personal tab
      expect(find.text('Personal'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Goals'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Test editing personal information
      await tester.tap(find.text('Personal'));
      await tester.pumpAndSettle();

      // Should show personal information cards
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('Height'), findsOneWidget);

      // Test editing gender
      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();

      // Should show gender selection dialog
      expect(find.text('Select Gender'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);

      // Select Female
      await tester.tap(find.text('Female'));
      await tester.pumpAndSettle();

      // Should close dialog and update display
      expect(find.text('Female'), findsOneWidget);

      // Test editing age
      await tester.tap(find.text('25 years'));
      await tester.pumpAndSettle();

      // Should show age selection dialog
      expect(find.text('Select Age'), findsOneWidget);

      // Cancel the dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Test editing weight
      await tester.tap(find.text('70.0 kg'));
      await tester.pumpAndSettle();

      // Should show weight editing dialog
      expect(find.text('Edit Weight'), findsOneWidget);

      // Cancel the dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Test editing height
      await tester.tap(find.text('170.0 cm'));
      await tester.pumpAndSettle();

      // Should show height editing dialog
      expect(find.text('Edit Height'), findsOneWidget);

      // Cancel the dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('Activity level management', (WidgetTester tester) async {
      // Start the app and complete onboarding
      app.main();
      await tester.pumpAndSettle();

      // Skip welcome and complete onboarding quickly
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Test Activity tab
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();

      // Should show activity level options
      expect(find.text('Activity Level'), findsOneWidget);
      expect(
          find.text('How active are you in your daily life?'), findsOneWidget);

      // Test all activity levels
      final activityLevels = [
        'Sedentary',
        'Lightly Active',
        'Moderately Active',
        'Very Active',
        'Extra Active'
      ];

      for (final level in activityLevels) {
        await tester.tap(find.text(level));
        await tester.pumpAndSettle();

        // Should show selection indicator
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      }
    });

    testWidgets('Weight goal management', (WidgetTester tester) async {
      // Start the app and complete onboarding
      app.main();
      await tester.pumpAndSettle();

      // Skip welcome and complete onboarding quickly
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Test Goals tab
      await tester.tap(find.text('Goals'));
      await tester.pumpAndSettle();

      // Should show weight goal options
      expect(find.text('Weight Goal'), findsOneWidget);
      expect(find.text('What would you like to achieve?'), findsOneWidget);

      // Test all weight goals
      final weightGoals = ['Lose Weight', 'Maintain Weight', 'Gain Weight'];

      for (final goal in weightGoals) {
        await tester.tap(find.text(goal));
        await tester.pumpAndSettle();

        // Should show selection indicator
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      }
    });

    testWidgets('Settings management', (WidgetTester tester) async {
      // Start the app and complete onboarding
      app.main();
      await tester.pumpAndSettle();

      // Skip welcome and complete onboarding quickly
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Test Settings tab
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Should show settings sections
      expect(find.text('AI Provider'), findsOneWidget);
      expect(find.text('Measurement Units'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);

      // Test AI Provider selection
      expect(
          find.text('Choose the AI model for food analysis'), findsOneWidget);

      // Test different AI providers
      final aiProviders = [
        'OpenAI GPT-4o mini',
        'Google Gemini 2.5 Flash',
        'Anthropic Claude 3.5 Sonnet',
        'Hugging Face'
      ];

      for (final provider in aiProviders) {
        if (find.text(provider).evaluate().isNotEmpty) {
          await tester.tap(find.text(provider));
          await tester.pumpAndSettle();

          // Should show selection indicator
          expect(find.byIcon(Icons.check_circle), findsOneWidget);
        }
      }

      // Test Measurement Units
      expect(find.text('Choose your preferred measurement system'),
          findsOneWidget);

      // Test metric/imperial toggle
      await tester.tap(find.text('Metric (kg, cm)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Imperial (lbs, ft)'));
      await tester.pumpAndSettle();

      // Test Appearance settings
      expect(find.text('Customize your app experience'), findsOneWidget);

      // Test theme options
      await tester.tap(find.text('Light Theme'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dark Theme'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('System Theme'));
      await tester.pumpAndSettle();
    });

    testWidgets('Guest mode vs authenticated mode',
        (WidgetTester tester) async {
      // Start the app and complete onboarding as guest
      app.main();
      await tester.pumpAndSettle();

      // Skip welcome and complete onboarding quickly
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Test Settings tab
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Should show guest account section
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Sync across devices'), findsOneWidget);
      expect(find.text('Backup your history'), findsOneWidget);
      expect(find.text('Advanced analytics'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);

      // Test Google sign in button
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();

      // Should show loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Note: In a real test, you would mock the Google sign-in response
      // For this integration test, we'll simulate the sign-in completion
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // After sign in, the guest account section should be hidden
      // and the user should have access to cloud sync features
    });

    testWidgets('Profile data persistence', (WidgetTester tester) async {
      // Start the app and complete onboarding
      app.main();
      await tester.pumpAndSettle();

      // Skip welcome and complete onboarding quickly
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Make some changes to profile
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Very Active'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Goals'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lose Weight'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark Theme'));
      await tester.pumpAndSettle();

      // Navigate away and back to verify persistence
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Verify changes are still there
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();
      expect(find.text('Very Active'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      await tester.tap(find.text('Goals'));
      await tester.pumpAndSettle();
      expect(find.text('Lose Weight'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Dark Theme'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('Profile validation and error handling',
        (WidgetTester tester) async {
      // Start the app and complete onboarding
      app.main();
      await tester.pumpAndSettle();

      // Skip welcome and complete onboarding quickly
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Test Personal tab
      await tester.tap(find.text('Personal'));
      await tester.pumpAndSettle();

      // Test editing with invalid values
      // This would involve:
      // 1. Entering invalid age (negative, too high)
      // 2. Entering invalid weight (negative, too high)
      // 3. Entering invalid height (negative, too high)
      // 4. Verifying error messages are shown
      // 5. Ensuring invalid values are not saved

      // Test network connectivity issues
      // This would involve:
      // 1. Simulating network disconnection
      // 2. Attempting to save profile changes
      // 3. Verifying appropriate error messages
      // 4. Ensuring data is not lost
    });

    testWidgets('Profile synchronization', (WidgetTester tester) async {
      // Test profile synchronization between devices
      // This would involve:
      // 1. Signing in on multiple devices
      // 2. Making changes on one device
      // 3. Verifying changes appear on other devices
      // 4. Testing conflict resolution
      // 5. Verifying offline changes are synced when online

      // Note: This would require mocking cloud services
      // and testing the synchronization logic
    });
  });
}
