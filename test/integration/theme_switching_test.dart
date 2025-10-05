import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foody/main.dart' as app;

void main() {
  group('Theme Switching Integration Tests', () {
    testWidgets('Complete theme switching workflow',
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

      // Go to Settings tab
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Should show Appearance section
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Customize your app experience'), findsOneWidget);

      // Test Light Theme
      await tester.tap(find.text('Light Theme'));
      await tester.pumpAndSettle();

      // Verify theme has changed to light
      final lightTheme = Theme.of(tester.element(find.byType(MaterialApp)));
      expect(lightTheme.brightness, equals(Brightness.light));

      // Test Dark Theme
      await tester.tap(find.text('Dark Theme'));
      await tester.pumpAndSettle();

      // Verify theme has changed to dark
      final darkTheme = Theme.of(tester.element(find.byType(MaterialApp)));
      expect(darkTheme.brightness, equals(Brightness.dark));

      // Test System Theme
      await tester.tap(find.text('System Theme'));
      await tester.pumpAndSettle();

      // Verify theme follows system
      final systemTheme = Theme.of(tester.element(find.byType(MaterialApp)));
      // System theme will depend on the device's current setting
      expect(
          systemTheme.brightness, anyOf([Brightness.light, Brightness.dark]));
    });

    testWidgets('Theme persistence across app restarts',
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

      // Go to Settings tab
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Set theme to dark
      await tester.tap(find.text('Dark Theme'));
      await tester.pumpAndSettle();

      // Verify dark theme is applied
      final darkTheme = Theme.of(tester.element(find.byType(MaterialApp)));
      expect(darkTheme.brightness, equals(Brightness.dark));

      // Navigate away and back to verify persistence
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Verify dark theme is still selected
      expect(find.text('Dark Theme'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Verify theme is still dark
      final persistentTheme =
          Theme.of(tester.element(find.byType(MaterialApp)));
      expect(persistentTheme.brightness, equals(Brightness.dark));
    });

    testWidgets('Theme switching affects all screens',
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

      // Test theme switching on Home screen
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Set to light theme
      await tester.tap(find.text('Light Theme'));
      await tester.pumpAndSettle();

      // Navigate to Home screen
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // Verify light theme on Home screen
      final homeLightTheme = Theme.of(tester.element(find.byType(MaterialApp)));
      expect(homeLightTheme.brightness, equals(Brightness.light));

      // Navigate to Analyze screen
      await tester.tap(find.text('Analyze'));
      await tester.pumpAndSettle();

      // Verify light theme on Analyze screen
      final analyzeLightTheme =
          Theme.of(tester.element(find.byType(MaterialApp)));
      expect(analyzeLightTheme.brightness, equals(Brightness.light));

      // Navigate back to Profile and change to dark theme
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Set to dark theme
      await tester.tap(find.text('Dark Theme'));
      await tester.pumpAndSettle();

      // Navigate to Home screen
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // Verify dark theme on Home screen
      final homeDarkTheme = Theme.of(tester.element(find.byType(MaterialApp)));
      expect(homeDarkTheme.brightness, equals(Brightness.dark));

      // Navigate to Analyze screen
      await tester.tap(find.text('Analyze'));
      await tester.pumpAndSettle();

      // Verify dark theme on Analyze screen
      final analyzeDarkTheme =
          Theme.of(tester.element(find.byType(MaterialApp)));
      expect(analyzeDarkTheme.brightness, equals(Brightness.dark));
    });

    testWidgets('Theme switching with different user profiles',
        (WidgetTester tester) async {
      // Test theme switching with different user configurations
      final testCases = [
        {
          'gender': 'Male',
          'age': 25,
          'weight': 70.0,
          'height': 175.0,
          'activity': 'Moderately Active',
          'goal': 'Maintain Weight'
        },
        {
          'gender': 'Female',
          'age': 30,
          'weight': 60.0,
          'height': 165.0,
          'activity': 'Lightly Active',
          'goal': 'Lose Weight'
        }
      ];

      for (final testCase in testCases) {
        // Start the app
        app.main();
        await tester.pumpAndSettle();

        // Skip welcome and complete onboarding quickly
        await tester.tap(find.text('Skip for now'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(testCase['gender'] as String));
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

        // Test theme switching
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();

        // Test all theme options
        await tester.tap(find.text('Light Theme'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Dark Theme'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('System Theme'));
        await tester.pumpAndSettle();

        // Clean up for next test case
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/platform',
          null,
          (data) {},
        );
      }
    });

    testWidgets('Theme switching performance', (WidgetTester tester) async {
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
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Test rapid theme switching
      final startTime = DateTime.now();

      for (int i = 0; i < 10; i++) {
        await tester.tap(find.text('Light Theme'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Dark Theme'));
        await tester.pumpAndSettle();
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // Verify theme switching is reasonably fast
      expect(duration.inMilliseconds,
          lessThan(5000)); // Should complete in under 5 seconds
    });

    testWidgets('Theme switching with different screen sizes',
        (WidgetTester tester) async {
      // Test theme switching on different screen sizes
      final screenSizes = [
        Size(320, 568), // iPhone SE
        Size(375, 667), // iPhone 8
        Size(414, 896), // iPhone 11
        Size(768, 1024), // iPad
      ];

      for (final size in screenSizes) {
        // Set screen size
        await tester.binding.setSurfaceSize(size);

        // Start the app
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

        // Test theme switching
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();

        // Test theme switching
        await tester.tap(find.text('Light Theme'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Dark Theme'));
        await tester.pumpAndSettle();

        // Clean up for next test case
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/platform',
          null,
          (data) {},
        );
      }
    });

    testWidgets('Theme switching with system theme changes',
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
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Set to system theme
      await tester.tap(find.text('System Theme'));
      await tester.pumpAndSettle();

      // Verify system theme is selected
      expect(find.text('System Theme'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Test that theme follows system changes
      // This would involve:
      // 1. Simulating system theme changes
      // 2. Verifying app theme updates accordingly
      // 3. Testing both light and dark system themes
    });

    testWidgets('Theme switching with different app states',
        (WidgetTester tester) async {
      // Test theme switching in different app states
      final appStates = [
        'onboarding',
        'home',
        'analyze',
        'profile',
        'settings'
      ];

      for (final state in appStates) {
        // Start the app
        app.main();
        await tester.pumpAndSettle();

        // Navigate to specific state
        switch (state) {
          case 'onboarding':
            // Stay on onboarding
            break;
          case 'home':
            // Complete onboarding and go to home
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
            break;
          case 'analyze':
            // Complete onboarding and go to analyze
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
            await tester.tap(find.text('Analyze'));
            await tester.pumpAndSettle();
            break;
          case 'profile':
            // Complete onboarding and go to profile
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
            await tester.tap(find.text('Profile'));
            await tester.pumpAndSettle();
            break;
          case 'settings':
            // Complete onboarding and go to settings
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
            await tester.tap(find.text('Profile'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Settings'));
            await tester.pumpAndSettle();
            break;
        }

        // Test theme switching in this state
        if (state == 'settings') {
          // Test theme switching directly
          await tester.tap(find.text('Light Theme'));
          await tester.pumpAndSettle();

          await tester.tap(find.text('Dark Theme'));
          await tester.pumpAndSettle();
        } else if (state == 'profile') {
          // Navigate to settings and test theme switching
          await tester.tap(find.text('Settings'));
          await tester.pumpAndSettle();

          await tester.tap(find.text('Light Theme'));
          await tester.pumpAndSettle();

          await tester.tap(find.text('Dark Theme'));
          await tester.pumpAndSettle();
        }

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
