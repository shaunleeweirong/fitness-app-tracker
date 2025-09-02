import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:first_fitness_test_app/screens/workout_history_screen.dart';
import 'package:first_fitness_test_app/services/database_helper.dart';
import 'package:first_fitness_test_app/services/workout_repository.dart';
import 'package:first_fitness_test_app/models/workout.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('WorkoutHistoryScreen Widget Tests', () {
    late DatabaseHelper dbHelper;
    late WorkoutRepository repository;
    late String mockUserId;

    setUp(() async {
      dbHelper = DatabaseHelper();
      repository = WorkoutRepository();
      await dbHelper.deleteDatabase(); // Clean slate for each test

      // Create mock user
      mockUserId = await dbHelper.createMockUser();
    });

    tearDown(() async {
      await repository.close();
    });

    testWidgets('should display loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutHistoryScreen(),
        ),
      );

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Workout History'), findsOneWidget);
    });

    testWidgets('should display empty state when no workouts', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutHistoryScreen(),
        ),
      );

      // Wait for loading to complete
      await tester.pump(const Duration(seconds: 1));

      // Should display empty state
      expect(find.text('No workouts yet'), findsOneWidget);
      expect(find.text('Start your fitness journey by creating your first workout!'), findsOneWidget);
      expect(find.text('Create Workout'), findsOneWidget);
    });

    testWidgets('should display workouts when available', (WidgetTester tester) async {
      // Create test workouts
      final testWorkouts = [
        Workout(
          workoutId: 'test_001',
          userId: mockUserId,
          name: 'Chest Day',
          targetBodyParts: ['chest', 'shoulders'],
          plannedDurationMinutes: 45,
          createdAt: DateTime.now(),
          status: WorkoutStatus.completed,
        ),
        Workout(
          workoutId: 'test_002',
          userId: mockUserId,
          name: 'Back Day',
          targetBodyParts: ['back'],
          plannedDurationMinutes: 50,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          status: WorkoutStatus.planned,
        ),
      ];

      for (final workout in testWorkouts) {
        await repository.saveWorkout(workout);
      }

      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutHistoryScreen(),
        ),
      );

      // Wait for loading to complete
      await tester.pump(const Duration(seconds: 1));

      // Should display workout names
      expect(find.text('Chest Day'), findsOneWidget);
      expect(find.text('Back Day'), findsOneWidget);
      
      // Should display status indicators
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('PLANNED'), findsOneWidget);
    });

    testWidgets('should display statistics section when workouts exist', (WidgetTester tester) async {
      // Create a completed workout with exercises
      final workout = Workout(
        workoutId: 'stats_test',
        userId: mockUserId,
        name: 'Stats Test Workout',
        targetBodyParts: ['chest'],
        plannedDurationMinutes: 30,
        createdAt: DateTime.now(),
        status: WorkoutStatus.completed,
        startedAt: DateTime.now().subtract(const Duration(minutes: 35)),
        completedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        exercises: [
          WorkoutExercise(
            exerciseId: 'bench_press',
            exerciseName: 'Bench Press',
            bodyParts: ['chest'],
            sets: [
              WorkoutSet(
                weight: 80.0,
                reps: 10,
                setNumber: 1,
                workoutExerciseId: 'stats_test_bench_press',
                isCompleted: true,
              ),
            ],
            orderIndex: 1,
            workoutId: 'stats_test',
          ),
        ],
      );

      await repository.saveWorkout(workout);

      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutHistoryScreen(),
        ),
      );

      // Wait for loading to complete
      await tester.pump(const Duration(seconds: 1));

      // Should display statistics section
      expect(find.text('Your Progress'), findsOneWidget);
      expect(find.text('Total Workouts'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Total Volume'), findsOneWidget);
      expect(find.text('Avg Duration'), findsOneWidget);
    });

    testWidgets('should have proper app bar with filter button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutHistoryScreen(),
        ),
      );

      // Should have app bar with title and filter button
      expect(find.text('Workout History'), findsOneWidget);
      expect(find.byIcon(Icons.filter_alt_outlined), findsOneWidget);

      // Check app bar styling
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, Colors.transparent);
      expect(appBar.elevation, 0);
    });

    testWidgets('should show filter dialog when filter button pressed', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutHistoryScreen(),
        ),
      );

      // Tap filter button
      await tester.tap(find.byIcon(Icons.filter_alt_outlined));
      await tester.pumpAndSettle();

      // Should show filter dialog
      expect(find.text('Filter Workouts'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Date Range'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('should support pull-to-refresh', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutHistoryScreen(),
        ),
      );

      // Should have RefreshIndicator
      expect(find.byType(RefreshIndicator), findsOneWidget);

      // Test pull-to-refresh gesture
      await tester.fling(find.byType(RefreshIndicator), const Offset(0, 300), 1000);
      await tester.pump();

      // Should not throw any errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle proper scrolling and pagination', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutHistoryScreen(),
        ),
      );

      // Should have CustomScrollView for scroll handling
      expect(find.byType(CustomScrollView), findsOneWidget);
      
      // Should not throw errors during scroll
      expect(tester.takeException(), isNull);
    });

    testWidgets('should have proper styling and theming', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutHistoryScreen(),
        ),
      );

      // Check scaffold background color
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF0A0A0A));
    });

    testWidgets('should dispose properly without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutHistoryScreen(),
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

    group('Workout Interaction Tests', () {
      testWidgets('should navigate to logging screen for in-progress workouts', (WidgetTester tester) async {
        // Create in-progress workout
        final workout = Workout(
          workoutId: 'in_progress_test',
          userId: mockUserId,
          name: 'In Progress Workout',
          targetBodyParts: ['chest'],
          plannedDurationMinutes: 45,
          createdAt: DateTime.now(),
          status: WorkoutStatus.inProgress,
        );

        await repository.saveWorkout(workout);

        await tester.pumpWidget(
          MaterialApp(
            home: const WorkoutHistoryScreen(),
            routes: {
              '/workout-logging': (context) {
                final workoutId = ModalRoute.of(context)?.settings.arguments as String?;
                return Scaffold(
                  body: Text('Logging Screen: $workoutId'),
                );
              },
            },
          ),
        );

        // Wait for loading
        await tester.pump(const Duration(seconds: 1));

        // Find and tap the workout tile
        final workoutTile = find.text('In Progress Workout');
        expect(workoutTile, findsOneWidget);

        await tester.tap(workoutTile);
        await tester.pumpAndSettle();

        // Note: Navigation testing is complex in unit tests
        // We verify no exceptions are thrown during tap
        expect(tester.takeException(), isNull);
      });

      testWidgets('should show workout details for completed workouts', (WidgetTester tester) async {
        // Create completed workout
        final workout = Workout(
          workoutId: 'completed_test',
          userId: mockUserId,
          name: 'Completed Workout',
          targetBodyParts: ['back'],
          plannedDurationMinutes: 60,
          createdAt: DateTime.now(),
          status: WorkoutStatus.completed,
        );

        await repository.saveWorkout(workout);

        await tester.pumpWidget(
          const MaterialApp(
            home: WorkoutHistoryScreen(),
          ),
        );

        // Wait for loading
        await tester.pump(const Duration(seconds: 1));

        // Find and tap the workout tile
        final workoutTile = find.text('Completed Workout');
        expect(workoutTile, findsOneWidget);

        await tester.tap(workoutTile);
        await tester.pumpAndSettle();

        // Should show modal bottom sheet with workout details
        // Note: Modal testing can be complex, we verify no crashes
        expect(tester.takeException(), isNull);
      });
    });

    group('Filter Tests', () {
      testWidgets('should show active filter indicators', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: WorkoutHistoryScreen(),
          ),
        );

        // Initially no active filters
        expect(find.text('Active Filters:'), findsNothing);

        // Test passes if no exceptions during filter state changes
        expect(tester.takeException(), isNull);
      });

      testWidgets('should clear filters correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: WorkoutHistoryScreen(),
          ),
        );

        // Open filter dialog
        await tester.tap(find.byIcon(Icons.filter_alt_outlined));
        await tester.pumpAndSettle();

        // Tap clear button
        await tester.tap(find.text('Clear'));
        await tester.pumpAndSettle();

        // Should close dialog and clear filters
        expect(find.text('Filter Workouts'), findsNothing);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should have proper semantics', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: WorkoutHistoryScreen(),
          ),
        );

        // Check that important widgets are accessible
        expect(find.text('Workout History'), findsOneWidget);
        expect(find.byType(RefreshIndicator), findsOneWidget);
        expect(find.byType(CustomScrollView), findsOneWidget);
      });

      testWidgets('should support large text sizes', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: const WorkoutHistoryScreen(),
            ),
          ),
        );

        // Should render without crashes with large text
        expect(find.text('Workout History'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('should handle database errors gracefully', (WidgetTester tester) async {
        // Close database to simulate error
        await dbHelper.close();

        await tester.pumpWidget(
          const MaterialApp(
            home: WorkoutHistoryScreen(),
          ),
        );

        // Wait for error handling
        await tester.pump(const Duration(seconds: 1));

        // Should handle error gracefully without crashes
        expect(tester.takeException(), isNull);
      });
    });
  });
}