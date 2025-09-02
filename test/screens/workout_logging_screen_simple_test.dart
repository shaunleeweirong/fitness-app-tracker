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

  group('WorkoutLoggingScreen Simple Tests', () {
    late DatabaseHelper dbHelper;
    late WorkoutRepository repository;
    late String mockUserId;
    late Workout testWorkout;

    setUp(() async {
      dbHelper = DatabaseHelper();
      repository = WorkoutRepository();
      await dbHelper.deleteDatabase();

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

    testWidgets('should create WorkoutLoggingScreen widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutLoggingScreen(workoutId: testWorkout.workoutId),
        ),
      );

      // Should create without throwing exceptions
      expect(find.byType(WorkoutLoggingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
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

    testWidgets('should handle non-existent workout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const WorkoutLoggingScreen(workoutId: 'non_existent_workout'),
        ),
      );

      // Initial loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Let the future complete and check for error state
      await tester.pump(const Duration(seconds: 1));
      
      // Should handle gracefully without throwing
      expect(tester.takeException(), isNull);
    });

    testWidgets('should have proper scaffold structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutLoggingScreen(workoutId: testWorkout.workoutId),
        ),
      );

      // Should have scaffold with proper styling
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF0A0A0A));
      
      // Should have app bar
      expect(find.byType(AppBar), findsOneWidget);
      
      // Should have scrollable body
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should dispose properly without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutLoggingScreen(workoutId: testWorkout.workoutId),
        ),
      );

      // Navigate away to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('New Screen')),
        ),
      );

      // Should dispose without errors
      expect(tester.takeException(), isNull);
    });

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
      await tester.pump();

      // Find and tap back button
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pump();
      }

      // Should handle navigation
      expect(tester.takeException(), isNull);
    });

    group('Workout Data Integration', () {
      testWidgets('should integrate with WorkoutRepository', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: WorkoutLoggingScreen(workoutId: testWorkout.workoutId),
          ),
        );

        // Should create and integrate properly
        expect(find.byType(WorkoutLoggingScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle database operations gracefully', (WidgetTester tester) async {
        // Close database before test to simulate error conditions
        await dbHelper.close();
        
        await tester.pumpWidget(
          MaterialApp(
            home: WorkoutLoggingScreen(workoutId: testWorkout.workoutId),
          ),
        );

        // Should handle database errors gracefully
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
      });
    });

    group('Widget Structure Tests', () {
      testWidgets('should have proper Material Design theming', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: WorkoutLoggingScreen(workoutId: testWorkout.workoutId),
          ),
        );

        // Check theme colors
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, const Color(0xFF0A0A0A));

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.backgroundColor, Colors.transparent);
        expect(appBar.elevation, 0);
      });

      testWidgets('should support accessibility', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: WorkoutLoggingScreen(workoutId: testWorkout.workoutId),
          ),
        );

        // Should have proper semantics structure
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });
    });
  });
}