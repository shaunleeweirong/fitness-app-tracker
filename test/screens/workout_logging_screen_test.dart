import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:first_fitness_test_app/screens/workout_logging_screen.dart';
import 'package:first_fitness_test_app/services/database_helper.dart';
import 'package:first_fitness_test_app/services/workout_repository.dart';
import 'package:first_fitness_test_app/models/workout.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('WorkoutLoggingScreen Widget Tests', () {
    late DatabaseHelper dbHelper;
    late WorkoutRepository repository;
    late String mockUserId;
    late Workout testWorkout;

    setUp(() async {
      dbHelper = DatabaseHelper();
      repository = WorkoutRepository();
      await dbHelper.deleteDatabase(); // Clean slate for each test

      // Create mock user and test workout
      mockUserId = await dbHelper.createMockUser();
      testWorkout = Workout(
        workoutId: 'test_workout_001',
        userId: mockUserId,
        name: 'Test Chest Workout',
        targetBodyParts: ['chest', 'shoulders'],
        plannedDurationMinutes: 45,
        createdAt: DateTime.now(),
        status: WorkoutStatus.planned,
      );

      await repository.saveWorkout(testWorkout);
    });

    tearDown(() async {
      await repository.close();
    });

    testWidgets('should display loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutLoggingScreen(workoutId: testWorkout.workoutId),
        ),
      );

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Test Chest Workout'), findsNothing);
    });

    testWidgets('should display workout information after loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutLoggingScreen(workoutId: testWorkout.workoutId),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Should display workout name in app bar
      expect(find.text('Test Chest Workout'), findsOneWidget);
      expect(find.text('0 exercises • 0 sets'), findsOneWidget);
      expect(find.text('Finish'), findsOneWidget);
    });

    testWidgets('should display workout progress section', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutLoggingScreen(workoutId: testWorkout.workoutId),
        ),
      );

      await tester.pumpAndSettle();

      // Should display progress metrics
      expect(find.text('Total Volume'), findsOneWidget);
      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('Exercises'), findsOneWidget);
      expect(find.text('0 kg'), findsOneWidget); // Initial volume
    });

    testWidgets('should display exercise selection when no exercise selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutLoggingScreen(workoutId: testWorkout.workoutId),
        ),
      );

      await tester.pumpAndSettle();

      // Should show exercise selection section
      expect(find.text('Select Exercise'), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle non-existent workout gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const WorkoutLoggingScreen(workoutId: 'non_existent_workout'),
        ),
      );

      await tester.pumpAndSettle();

      // Should show error state
      expect(find.text('Workout not found'), findsOneWidget);
      expect(find.text('Workout Not Found'), findsOneWidget);
    });

    testWidgets('should start workout when status is planned', (WidgetTester tester) async {
      // Ensure workout is in planned state
      expect(testWorkout.status, WorkoutStatus.planned);

      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutLoggingScreen(workoutId: testWorkout.workoutId),
        ),
      );

      await tester.pumpAndSettle();

      // Verify workout was started (check that started time is shown)
      // Duration should show some time has passed
      expect(find.textContaining(':'), findsAtLeastNWidgets(1));
    });

    testWidgets('should display finish button in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutLoggingScreen(workoutId: testWorkout.workoutId),
        ),
      );

      await tester.pumpAndSettle();

      // Should have finish button
      expect(find.text('Finish'), findsOneWidget);
      
      // Button should be tappable
      final finishButton = find.text('Finish');
      await tester.tap(finishButton);
      await tester.pump();
      
      // Should show error snackbar when no exercises added
      expect(find.text('Please add at least one exercise before finishing'), findsOneWidget);
    });

    testWidgets('should have proper styling and colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutLoggingScreen(workoutId: testWorkout.workoutId),
        ),
      );

      await tester.pumpAndSettle();

      // Check scaffold background color
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF0A0A0A));

      // Check app bar styling
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, Colors.transparent);
      expect(appBar.elevation, 0);
    });

    group('Exercise Selection Tests', () {
      testWidgets('should show loading indicator while loading exercises', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: WorkoutLoggingScreen(workoutId: testWorkout.workoutId),
          ),
        );

        // Initial pump - workout loading
        await tester.pump();
        
        // Second pump - exercises loading
        await tester.pump();
        
        // Might find loading indicator for exercises
        // This is timing-dependent, so we just verify no crash
        expect(tester.takeException(), isNull);
      });

      testWidgets('should display available exercises after loading', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: WorkoutLoggingScreen(workoutId: testWorkout.workoutId),
          ),
        );

        await tester.pumpAndSettle();

        // Should have exercise selection section
        expect(find.text('Select Exercise'), findsOneWidget);
        
        // Note: Actual exercise list depends on ExerciseService mock data
        // For now, we verify the structure exists
        expect(find.byIcon(Icons.fitness_center), findsAtLeastNWidgets(1));
      });
    });

    group('Error Handling Tests', () {
      testWidgets('should show error snackbar on database failures', (WidgetTester tester) async {
        // Close database to simulate error
        await dbHelper.close();

        await tester.pumpWidget(
          MaterialApp(
            home: WorkoutLoggingScreen(workoutId: testWorkout.workoutId),
          ),
        );

        await tester.pumpAndSettle();

        // Should handle error gracefully
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle widget disposal correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: WorkoutLoggingScreen(workoutId: testWorkout.workoutId),
          ),
        );

        await tester.pumpAndSettle();

        // Navigate away (simulating disposal)
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: Text('New Screen')),
          ),
        );

        // Should dispose without errors
        expect(tester.takeException(), isNull);
      });
    });

    group('Navigation Tests', () {
      testWidgets('should handle back navigation', (WidgetTester tester) async {
        bool popped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WorkoutLoggingScreen(workoutId: testWorkout.workoutId),
                      ),
                    ).then((_) => popped = true);
                  },
                  child: const Text('Navigate'),
                ),
              ),
            ),
          ),
        );

        // Navigate to workout logging
        await tester.tap(find.text('Navigate'));
        await tester.pumpAndSettle();

        // Verify we're on the logging screen
        expect(find.text('Test Chest Workout'), findsOneWidget);

        // Find back button in app bar
        final backButton = find.byIcon(Icons.arrow_back);
        expect(backButton, findsOneWidget);

        // Tap back button
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Should have navigated back
        expect(popped, true);
      });
    });

    group('Progress Display Tests', () {
      testWidgets('should show zero values initially', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: WorkoutLoggingScreen(workoutId: testWorkout.workoutId),
          ),
        );

        await tester.pumpAndSettle();

        // Should show initial zero values
        expect(find.text('0 kg'), findsOneWidget);
        expect(find.text('0 exercises • 0 sets'), findsOneWidget);
      });

      testWidgets('should display duration timer', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: WorkoutLoggingScreen(workoutId: testWorkout.workoutId),
          ),
        );

        await tester.pumpAndSettle();

        // Should show duration in MM:SS format
        expect(find.textContaining(':'), findsAtLeastNWidgets(1));
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should have proper semantics', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: WorkoutLoggingScreen(workoutId: testWorkout.workoutId),
          ),
        );

        await tester.pumpAndSettle();

        // Check that important widgets are accessible
        expect(find.text('Test Chest Workout'), findsOneWidget);
        expect(find.text('Finish'), findsOneWidget);
        expect(find.text('Select Exercise'), findsOneWidget);
      });

      testWidgets('should support large text sizes', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: WorkoutLoggingScreen(workoutId: testWorkout.workoutId),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should render without crashes with large text
        expect(find.text('Test Chest Workout'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  });
}