import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:first_fitness_test_app/models/workout.dart';
import 'package:first_fitness_test_app/services/database_helper.dart';
import 'package:first_fitness_test_app/services/workout_repository.dart';
import 'package:first_fitness_test_app/screens/workout_history_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Stage 4: WorkoutHistoryScreen Integration Tests', () {
    late DatabaseHelper dbHelper;
    late WorkoutRepository repository;
    late String mockUserId;

    setUp(() async {
      dbHelper = DatabaseHelper();
      repository = WorkoutRepository();
      await dbHelper.deleteDatabase();
      mockUserId = await dbHelper.createMockUser();
    });

    tearDown(() async {
      await repository.close();
    });

    test('Stage 4.1: Should display workout history correctly', () async {
      // Create test workouts with different statuses
      final workouts = [
        Workout(
          workoutId: 'history_test_001',
          userId: mockUserId,
          name: 'Chest Workout',
          targetBodyParts: ['chest', 'shoulders'],
          plannedDurationMinutes: 45,
          createdAt: DateTime.now(),
          status: WorkoutStatus.completed,
          startedAt: DateTime.now().subtract(const Duration(minutes: 50)),
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
                  workoutExerciseId: 'history_test_001_bench_press',
                  isCompleted: true,
                ),
              ],
              orderIndex: 1,
              workoutId: 'history_test_001',
            ),
          ],
        ),
        Workout(
          workoutId: 'history_test_002',
          userId: mockUserId,
          name: 'Back Workout',
          targetBodyParts: ['back'],
          plannedDurationMinutes: 50,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          status: WorkoutStatus.planned,
        ),
        Workout(
          workoutId: 'history_test_003',
          userId: mockUserId,
          name: 'Leg Workout',
          targetBodyParts: ['upper legs'],
          plannedDurationMinutes: 60,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          status: WorkoutStatus.inProgress,
          startedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];

      // Save all workouts
      for (final workout in workouts) {
        await repository.saveWorkout(workout);
      }

      // Verify workouts were saved
      final retrievedWorkouts = await repository.getWorkouts(userId: mockUserId);
      expect(retrievedWorkouts.length, 3);
      expect(retrievedWorkouts[0].name, 'Chest Workout'); // Should be ordered by creation date DESC (most recent first)
      expect(retrievedWorkouts[1].name, 'Back Workout');
      expect(retrievedWorkouts[2].name, 'Leg Workout');
    });

    test('Stage 4.2: Should calculate and display statistics correctly', () async {
      // Create workouts with specific statistics
      final completedWorkout1 = Workout(
        workoutId: 'stats_test_001',
        userId: mockUserId,
        name: 'Stats Test 1',
        targetBodyParts: ['chest'],
        plannedDurationMinutes: 45,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        status: WorkoutStatus.completed,
        startedAt: DateTime.now().subtract(const Duration(days: 3)),
        completedAt: DateTime.now().subtract(const Duration(days: 3)).add(const Duration(minutes: 50)),
        exercises: [
          WorkoutExercise(
            exerciseId: 'bench_press',
            exerciseName: 'Bench Press',
            bodyParts: ['chest'],
            sets: [
              WorkoutSet(
                weight: 100.0,
                reps: 10,
                setNumber: 1,
                workoutExerciseId: 'stats_test_001_bench_press',
                isCompleted: true,
              ),
            ],
            orderIndex: 1,
            workoutId: 'stats_test_001',
          ),
        ],
      );

      final completedWorkout2 = Workout(
        workoutId: 'stats_test_002',
        userId: mockUserId,
        name: 'Stats Test 2',
        targetBodyParts: ['back'],
        plannedDurationMinutes: 40,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        status: WorkoutStatus.completed,
        startedAt: DateTime.now().subtract(const Duration(days: 2)),
        completedAt: DateTime.now().subtract(const Duration(days: 2)).add(const Duration(minutes: 45)),
        exercises: [
          WorkoutExercise(
            exerciseId: 'pull_ups',
            exerciseName: 'Pull Ups',
            bodyParts: ['back'],
            sets: [
              WorkoutSet(
                weight: 0.0,
                reps: 15,
                setNumber: 1,
                workoutExerciseId: 'stats_test_002_pull_ups',
                isCompleted: true,
              ),
            ],
            orderIndex: 1,
            workoutId: 'stats_test_002',
          ),
        ],
      );

      final plannedWorkout = Workout(
        workoutId: 'stats_test_003',
        userId: mockUserId,
        name: 'Stats Test 3',
        targetBodyParts: ['legs'],
        plannedDurationMinutes: 60,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: WorkoutStatus.planned,
      );

      // Save workouts
      await repository.saveWorkout(completedWorkout1);
      await repository.saveWorkout(completedWorkout2);
      await repository.saveWorkout(plannedWorkout);

      // Get and verify statistics
      final stats = await repository.getWorkoutStats(mockUserId);
      
      expect(stats.totalWorkouts, 3);
      expect(stats.completedWorkouts, 2);
      expect(stats.completionRate, closeTo(0.67, 0.01));
      expect(stats.totalVolume, 1000.0); // 100*10 + 0*15
      expect(stats.averageDurationMinutes, closeTo(47.5, 1.0)); // (50+45)/2
    });

    test('Stage 4.3: Should filter workouts by status correctly', () async {
      // Create workouts with different statuses
      final workouts = [
        Workout(
          workoutId: 'filter_test_001',
          userId: mockUserId,
          name: 'Completed Workout',
          targetBodyParts: ['chest'],
          plannedDurationMinutes: 30,
          createdAt: DateTime.now(),
          status: WorkoutStatus.completed,
        ),
        Workout(
          workoutId: 'filter_test_002',
          userId: mockUserId,
          name: 'Planned Workout',
          targetBodyParts: ['back'],
          plannedDurationMinutes: 45,
          createdAt: DateTime.now(),
          status: WorkoutStatus.planned,
        ),
        Workout(
          workoutId: 'filter_test_003',
          userId: mockUserId,
          name: 'In Progress Workout',
          targetBodyParts: ['legs'],
          plannedDurationMinutes: 60,
          createdAt: DateTime.now(),
          status: WorkoutStatus.inProgress,
        ),
      ];

      for (final workout in workouts) {
        await repository.saveWorkout(workout);
      }

      // Test filtering by completed status
      final completedWorkouts = await repository.getWorkouts(
        userId: mockUserId,
        status: WorkoutStatus.completed,
      );
      expect(completedWorkouts.length, 1);
      expect(completedWorkouts.first.name, 'Completed Workout');

      // Test filtering by planned status
      final plannedWorkouts = await repository.getWorkouts(
        userId: mockUserId,
        status: WorkoutStatus.planned,
      );
      expect(plannedWorkouts.length, 1);
      expect(plannedWorkouts.first.name, 'Planned Workout');

      // Test filtering by in-progress status
      final inProgressWorkouts = await repository.getWorkouts(
        userId: mockUserId,
        status: WorkoutStatus.inProgress,
      );
      expect(inProgressWorkouts.length, 1);
      expect(inProgressWorkouts.first.name, 'In Progress Workout');
    });

    test('Stage 4.4: Should handle pagination correctly', () async {
      const pageSize = 5;
      
      // Create more workouts than page size
      final workouts = List.generate(12, (index) => 
        Workout(
          workoutId: 'pagination_test_${index.toString().padLeft(3, '0')}',
          userId: mockUserId,
          name: 'Workout ${index + 1}',
          targetBodyParts: ['chest'],
          plannedDurationMinutes: 30,
          createdAt: DateTime.now().subtract(Duration(days: index)),
          status: WorkoutStatus.completed,
        ),
      );

      // Save all workouts
      for (final workout in workouts) {
        await repository.saveWorkout(workout);
      }

      // Test first page
      final firstPage = await repository.getWorkouts(
        userId: mockUserId,
        limit: pageSize,
        offset: 0,
      );
      expect(firstPage.length, pageSize);
      expect(firstPage.first.name, 'Workout 1'); // Most recent

      // Test second page
      final secondPage = await repository.getWorkouts(
        userId: mockUserId,
        limit: pageSize,
        offset: pageSize,
      );
      expect(secondPage.length, pageSize);
      expect(secondPage.first.name, 'Workout 6'); // Next set

      // Test third page (partial)
      final thirdPage = await repository.getWorkouts(
        userId: mockUserId,
        limit: pageSize,
        offset: pageSize * 2,
      );
      expect(thirdPage.length, 2); // Only 2 remaining
      expect(thirdPage.first.name, 'Workout 11');
    });

    test('Stage 4.5: Should handle date range filtering', () async {
      final now = DateTime.now();
      final workouts = [
        Workout(
          workoutId: 'date_test_001',
          userId: mockUserId,
          name: 'Recent Workout',
          targetBodyParts: ['chest'],
          plannedDurationMinutes: 30,
          createdAt: now,
          status: WorkoutStatus.completed,
        ),
        Workout(
          workoutId: 'date_test_002',
          userId: mockUserId,
          name: 'Week Old Workout',
          targetBodyParts: ['back'],
          plannedDurationMinutes: 45,
          createdAt: now.subtract(const Duration(days: 7)),
          status: WorkoutStatus.completed,
        ),
        Workout(
          workoutId: 'date_test_003',
          userId: mockUserId,
          name: 'Month Old Workout',
          targetBodyParts: ['legs'],
          plannedDurationMinutes: 60,
          createdAt: now.subtract(const Duration(days: 30)),
          status: WorkoutStatus.completed,
        ),
      ];

      for (final workout in workouts) {
        await repository.saveWorkout(workout);
      }

      // Test date range filtering (last week)
      final recentWorkouts = await repository.getWorkoutsByDateRange(
        userId: mockUserId,
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now.add(const Duration(days: 1)),
      );

      expect(recentWorkouts.length, 2); // Recent and Week Old
      expect(recentWorkouts.any((w) => w.name == 'Recent Workout'), true);
      expect(recentWorkouts.any((w) => w.name == 'Week Old Workout'), true);
      expect(recentWorkouts.any((w) => w.name == 'Month Old Workout'), false);
    });

    testWidgets('Stage 4.6: WorkoutHistoryScreen widget integration', (WidgetTester tester) async {
      // Create a test workout for the widget to display
      final workout = Workout(
        workoutId: 'widget_integration_001',
        userId: mockUserId,
        name: 'Widget Test Workout',
        targetBodyParts: ['chest'],
        plannedDurationMinutes: 30,
        createdAt: DateTime.now(),
        status: WorkoutStatus.completed,
      );

      await repository.saveWorkout(workout);

      // Test the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutHistoryScreen(),
        ),
      );

      // Should create without throwing exceptions
      expect(find.byType(WorkoutHistoryScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Should show app bar
      expect(find.text('Workout History'), findsOneWidget);
      
      // Should have proper styling
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF0A0A0A));
    });

    test('Stage 4.7: Should handle empty workout history gracefully', () async {
      // Test with no workouts
      final workouts = await repository.getWorkouts(userId: mockUserId);
      expect(workouts, isEmpty);

      // Test statistics with no workouts
      final stats = await repository.getWorkoutStats(mockUserId);
      expect(stats.totalWorkouts, 0);
      expect(stats.completedWorkouts, 0);
      expect(stats.totalVolume, 0.0);
      expect(stats.completionRate, 0.0);
    });

    test('Stage 4.8: Should handle large workout volume correctly', () async {
      // Create workout with high volume
      final highVolumeWorkout = Workout(
        workoutId: 'volume_test_001',
        userId: mockUserId,
        name: 'High Volume Workout',
        targetBodyParts: ['chest', 'back'],
        plannedDurationMinutes: 120,
        createdAt: DateTime.now(),
        status: WorkoutStatus.completed,
        exercises: [
          WorkoutExercise(
            exerciseId: 'deadlift',
            exerciseName: 'Deadlift',
            bodyParts: ['back'],
            sets: [
              WorkoutSet(
                weight: 200.0,
                reps: 5,
                setNumber: 1,
                workoutExerciseId: 'volume_test_001_deadlift',
                isCompleted: true,
              ),
              WorkoutSet(
                weight: 200.0,
                reps: 5,
                setNumber: 2,
                workoutExerciseId: 'volume_test_001_deadlift',
                isCompleted: true,
              ),
            ],
            orderIndex: 1,
            workoutId: 'volume_test_001',
          ),
        ],
      );

      await repository.saveWorkout(highVolumeWorkout);

      // Verify high volume calculation
      final retrievedWorkout = await repository.getWorkout('volume_test_001');
      expect(retrievedWorkout!.totalVolume, 2000.0); // 200*5 + 200*5

      // Verify stats formatting
      final stats = await repository.getWorkoutStats(mockUserId);
      expect(stats.formattedTotalVolume, '2.0k kg');
    });
  });
}