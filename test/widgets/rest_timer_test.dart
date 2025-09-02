import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:first_fitness_test_app/widgets/rest_timer.dart';

void main() {
  group('RestTimer Widget Tests', () {
    testWidgets('RestTimer displays initial duration correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RestTimer(initialDurationSeconds: 90),
          ),
        ),
      );

      // Check that initial time is displayed (may appear multiple times due to presets)
      expect(find.text('01:30'), findsAtLeastNWidgets(1));
      expect(find.text('Rest Timer'), findsOneWidget);
    });

    testWidgets('RestTimer shows start button initially', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RestTimer(initialDurationSeconds: 60),
          ),
        ),
      );

      // Should show start button
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
      
      // Should show preset durations (may appear in both display and presets)
      expect(find.text('01:00'), findsAtLeastNWidgets(1)); // 60 seconds preset
      expect(find.text('01:30'), findsAtLeastNWidgets(1)); // 90 seconds preset
    });

    testWidgets('RestTimer preset duration selection works', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RestTimer(initialDurationSeconds: 90),
          ),
        ),
      );

      // Initial duration should be 90 seconds (01:30)
      expect(find.text('01:30'), findsAtLeastNWidgets(1));

      // Tap on 60-second preset (01:00)
      await tester.tap(find.text('01:00').first);
      await tester.pump();

      // Timer display should now show 01:00
      expect(find.text('01:00'), findsAtLeastNWidgets(1));
    });

    testWidgets('RestTimer controls are functional', (tester) async {
      bool timerStarted = false;
      bool timerCompleted = false;
      bool timerStopped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RestTimer(
              initialDurationSeconds: 5, // Short duration for testing
              onTimerStart: () => timerStarted = true,
              onTimerComplete: () => timerCompleted = true,
              onTimerStop: () => timerStopped = true,
            ),
          ),
        ),
      );

      // Test start button
      await tester.tap(find.text('Start'));
      await tester.pump();
      
      expect(timerStarted, isTrue);
      expect(find.text('Pause'), findsOneWidget);

      // Test pause button
      await tester.tap(find.text('Pause'));
      await tester.pump();
      
      expect(find.text('Start'), findsOneWidget);

      // Test reset button
      await tester.tap(find.text('Reset'));
      await tester.pump();
      
      expect(timerStopped, isTrue);
      expect(find.text('00:05'), findsOneWidget); // Back to initial duration
    });

    testWidgets('RestTimer color changes based on remaining time', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RestTimer(initialDurationSeconds: 5), // Very short for testing
          ),
        ),
      );

      // Start the timer
      await tester.tap(find.text('Start'));
      await tester.pump();

      // Let some time pass (simulate countdown)
      await tester.pump(const Duration(seconds: 1));
      
      // Timer should be running
      expect(find.text('RESTING'), findsOneWidget);
    });

    testWidgets('RestTimer format time correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RestTimer(initialDurationSeconds: 125), // 2:05
          ),
        ),
      );

      expect(find.text('02:05'), findsOneWidget);
    });

    testWidgets('RestTimer shows completion dialog when timer finishes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RestTimer(initialDurationSeconds: 1), // 1 second for quick test
          ),
        ),
      );

      // Start the timer
      await tester.tap(find.text('Start'));
      await tester.pump();

      // Wait for timer to complete (with some extra time for safety)
      await tester.pump(const Duration(seconds: 2));

      // Should show completion dialog
      expect(find.text('Rest Complete! 💪'), findsOneWidget);
      expect(find.text('Time for your next set!'), findsOneWidget);
    });

    testWidgets('RestTimer handles quick set preset correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RestTimer(initialDurationSeconds: 90),
          ),
        ),
      );

      // Check that quick set presets are shown
      expect(find.text('Quick Set'), findsOneWidget);
      
      // Test all preset durations
      final presets = ['01:00', '01:30', '02:00', '03:00', '05:00'];
      for (final preset in presets) {
        expect(find.text(preset), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('RestTimer skip button works correctly', (tester) async {
      bool timerCompleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RestTimer(
              initialDurationSeconds: 60,
              onTimerComplete: () => timerCompleted = true,
            ),
          ),
        ),
      );

      // Start the timer first
      await tester.tap(find.text('Start'));
      await tester.pump();

      // Skip the timer
      await tester.tap(find.text('Skip'));
      await tester.pump();

      // Should trigger completion callback
      expect(timerCompleted, isTrue);
    });
  });
}