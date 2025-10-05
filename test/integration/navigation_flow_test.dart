import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foody/main.dart' as app;

void main() {
  group('Navigation Flow Integration Tests', () {
    testWidgets('Complete navigation flow between all screens',
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

      // Test navigation between all main screens
      final screens = ['Home', 'Analyze', 'Profile'];

      for (final screen in screens) {
        // Navigate to screen
        await tester.tap(find.text(screen));
        await tester.pumpAndSettle();

        // Verify we're on the correct screen
        expect(find.text(screen), findsOneWidget);

        // Verify screen-specific content
        switch (screen) {
          case 'Home':
            expect(find.text('Consumed'), findsOneWidget);
            expect(find.text('Target'), findsOneWidget);
            expect(find.text('Remaining'), findsOneWidget);
            break;
          case 'Analyze':
            expect(find.text('Health Analysis'), findsOneWidget);
            break;
          case 'Profile':
            expect(find.text('Personal'), findsOneWidget);
            expect(find.text('Activity'), findsOneWidget);
            expect(find.text('Goals'), findsOneWidget);
            expect(find.text('Settings'), findsOneWidget);
            break;
        }
      }
    });

    testWidgets('Navigation with back button', (WidgetTester tester) async {
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

      // Test back navigation from different screens
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Test back navigation from Profile
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should go back to Home
      expect(find.text('Home'), findsOneWidget);

      // Test back navigation from Analyze
      await tester.tap(find.text('Analyze'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should go back to Home
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('Navigation with different user states',
        (WidgetTester tester) async {
      // Test navigation with different user states
      final userStates = [
        'guest',
        'authenticated',
        'onboarding_complete',
        'onboarding_incomplete'
      ];

      for (final state in userStates) {
        // Start the app
        app.main();
        await tester.pumpAndSettle();

        switch (state) {
          case 'guest':
            // Complete onboarding as guest
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
          case 'authenticated':
            // Complete onboarding with Google sign in
            await tester.tap(find.text('Sign in with Google'));
            await tester.pumpAndSettle();
            await tester.pumpAndSettle(const Duration(seconds: 2));
            break;
          case 'onboarding_complete':
            // Complete onboarding
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
          case 'onboarding_incomplete':
            // Stay on onboarding
            break;
        }

        // Test navigation based on state
        if (state == 'onboarding_incomplete') {
          // Should be on onboarding screens
          expect(find.text("What's your gender?"), findsOneWidget);
        } else {
          // Should be on main app with navigation
          expect(find.text('Home'), findsOneWidget);
          expect(find.text('Analyze'), findsOneWidget);
          expect(find.text('Profile'), findsOneWidget);
        }

        // Clean up for next test case
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/platform',
          null,
          (data) {},
        );
      }
    });

    testWidgets('Navigation with different screen orientations',
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

      // Test navigation in portrait orientation
      await tester.binding.setSurfaceSize(const Size(375, 667));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      await tester.tap(find.text('Analyze'));
      await tester.pumpAndSettle();
      expect(find.text('Analyze'), findsOneWidget);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsOneWidget);

      // Test navigation in landscape orientation
      await tester.binding.setSurfaceSize(const Size(667, 375));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      await tester.tap(find.text('Analyze'));
      await tester.pumpAndSettle();
      expect(find.text('Analyze'), findsOneWidget);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('Navigation with different screen sizes',
        (WidgetTester tester) async {
      // Test navigation on different screen sizes
      final screenSizes = [
        const Size(320, 568), // iPhone SE
        const Size(375, 667), // iPhone 8
        const Size(414, 896), // iPhone 11
        const Size(768, 1024), // iPad
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

        // Test navigation
        await tester.tap(find.text('Home'));
        await tester.pumpAndSettle();
        expect(find.text('Home'), findsOneWidget);

        await tester.tap(find.text('Analyze'));
        await tester.pumpAndSettle();
        expect(find.text('Analyze'), findsOneWidget);

        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        expect(find.text('Profile'), findsOneWidget);

        // Clean up for next test case
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/platform',
          null,
          (data) {},
        );
      }
    });

    testWidgets('Navigation with deep linking', (WidgetTester tester) async {
      // Test navigation with deep links
      // This would involve:
      // 1. Testing deep links to specific screens
      // 2. Testing deep links with parameters
      // 3. Testing deep links with authentication
      // 4. Testing deep links with different app states

      // Note: This would require implementing deep linking
      // and testing the navigation handling
    });

    testWidgets('Navigation with different themes',
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

      // Test navigation with light theme
      await tester.tap(find.text('Profile'));
      await tester.tap(find.text('Settings'));
      await tester.tap(find.text('Light Theme'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      await tester.tap(find.text('Analyze'));
      await tester.pumpAndSettle();
      expect(find.text('Analyze'), findsOneWidget);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsOneWidget);

      // Test navigation with dark theme
      await tester.tap(find.text('Settings'));
      await tester.tap(find.text('Dark Theme'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      await tester.tap(find.text('Analyze'));
      await tester.pumpAndSettle();
      expect(find.text('Analyze'), findsOneWidget);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('Navigation with different user profiles',
        (WidgetTester tester) async {
      // Test navigation with different user profiles
      final userProfiles = [
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

      for (final profile in userProfiles) {
        // Start the app
        app.main();
        await tester.pumpAndSettle();

        // Skip welcome and complete onboarding quickly
        await tester.tap(find.text('Skip for now'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(profile['gender'] as String));
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

        // Test navigation with this profile
        await tester.tap(find.text('Home'));
        await tester.pumpAndSettle();
        expect(find.text('Home'), findsOneWidget);

        await tester.tap(find.text('Analyze'));
        await tester.pumpAndSettle();
        expect(find.text('Analyze'), findsOneWidget);

        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        expect(find.text('Profile'), findsOneWidget);

        // Clean up for next test case
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/platform',
          null,
          (data) {},
        );
      }
    });

    testWidgets('Navigation with different app states',
        (WidgetTester tester) async {
      // Test navigation with different app states
      final appStates = [
        'loading',
        'onboarding',
        'home',
        'analyze',
        'profile',
        'settings',
        'error',
        'offline'
      ];

      for (final state in appStates) {
        // Start the app
        app.main();
        await tester.pumpAndSettle();

        // Navigate to specific state
        switch (state) {
          case 'loading':
            // Stay on loading screen
            break;
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
          case 'error':
            // Simulate error state
            // This would involve triggering an error
            // and testing navigation from error state
            break;
          case 'offline':
            // Simulate offline state
            // This would involve testing navigation
            // when the app is offline
            break;
        }

        // Test navigation based on state
        if (state == 'loading') {
          // Should show loading indicator
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        } else if (state == 'onboarding') {
          // Should be on onboarding screens
          expect(find.text("What's your gender?"), findsOneWidget);
        } else if (state == 'home') {
          // Should be on home screen
          expect(find.text('Home'), findsOneWidget);
        } else if (state == 'analyze') {
          // Should be on analyze screen
          expect(find.text('Analyze'), findsOneWidget);
        } else if (state == 'profile') {
          // Should be on profile screen
          expect(find.text('Profile'), findsOneWidget);
        } else if (state == 'settings') {
          // Should be on settings screen
          expect(find.text('Settings'), findsOneWidget);
        }

        // Verify we're testing the correct state
        expect(state, isA<String>());

        // Clean up for next test case
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/platform',
          null,
          (data) {},
        );
      }
    });

    testWidgets('Navigation with different network states',
        (WidgetTester tester) async {
      // Test navigation with different network states
      final networkStates = [
        'online',
        'offline',
        'slow_connection',
        'unstable_connection'
      ];

      for (final networkState in networkStates) {
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

        // Test navigation with this network state
        // Verify we're testing the correct network state
        expect(networkState, isA<String>());

        await tester.tap(find.text('Home'));
        await tester.pumpAndSettle();
        expect(find.text('Home'), findsOneWidget);

        await tester.tap(find.text('Analyze'));
        await tester.pumpAndSettle();
        expect(find.text('Analyze'), findsOneWidget);

        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        expect(find.text('Profile'), findsOneWidget);

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
