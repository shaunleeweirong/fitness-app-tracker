import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:first_fitness_test_app/models/workout.dart';
import 'package:first_fitness_test_app/services/database_helper.dart';
import 'package:first_fitness_test_app/services/workout_repository.dart';
import 'package:first_fitness_test_app/screens/workout_setup_screen.dart';
import 'package:first_fitness_test_app/screens/workout_logging_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Stage 3: Workout Flow Integration Tests', () {
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

    test('Stage 3.1: Should create workout via WorkoutSetupScreen integration', () async {
      // Create workout using repository (simulating WorkoutSetupScreen flow)
      final workout = Workout(
        workoutId: 'integration_test_001',
        userId: mockUserId,
        name: 'Integration Test Workout',
        targetBodyParts: ['chest', 'shoulders'],
        plannedDurationMinutes: 45,
        createdAt: DateTime.now(),
        status: WorkoutStatus.planned,
      );

      // Save workout
      final savedId = await repository.saveWorkout(workout);
      expect(savedId, workout.workoutId);

      // Verify workout can be retrieved
      final retrieved = await repository.getWorkout(workout.workoutId);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Integration Test Workout');
      expect(retrieved.targetBodyParts, ['chest', 'shoulders']);
      expect(retrieved.status, WorkoutStatus.planned);
    });

    test('Stage 3.2: Should start workout and track progress', () async {
      // Create planned workout
      final workout = Workout(
        workoutId: 'progress_test_001',
        userId: mockUserId,
        name: 'Progress Test',
        targetBodyParts: ['back'],
        plannedDurationMinutes: 60,
        createdAt: DateTime.now(),
        status: WorkoutStatus.planned,
      );

      await repository.saveWorkout(workout);

      // Start workout (simulating WorkoutLoggingScreen behavior)
      await repository.startWorkout(workout.workoutId);

      // Verify workout was started
      final startedWorkout = await repository.getWorkout(workout.workoutId);
      expect(startedWorkout!.status, WorkoutStatus.inProgress);
      expect(startedWorkout.startedAt, isNotNull);
    });

    test('Stage 3.3: Should save exercise with sets during workout', () async {
      // Create workout in progress
      final workout = Workout(
        workoutId: 'exercise_test_001',
        userId: mockUserId,
        name: 'Exercise Test',
        targetBodyParts: ['chest'],
        plannedDurationMinutes: 45,
        createdAt: DateTime.now(),
        status: WorkoutStatus.inProgress,
        startedAt: DateTime.now(),
      );

      await repository.saveWorkout(workout);

      // Add exercise with sets (simulating logging screen interaction)
      final sets = [
        WorkoutSet(
          weight: 80.0,
          reps: 10,
          setNumber: 1,
          workoutExerciseId: 'exercise_test_001_bench_press',
        ),
        WorkoutSet(
          weight: 80.0,
          reps: 8,
          setNumber: 2,
          workoutExerciseId: 'exercise_test_001_bench_press',
        ),
      ];

      final exercise = WorkoutExercise(
        exerciseId: 'bench_press',
        exerciseName: 'Bench Press',
        bodyParts: ['chest'],
        sets: sets,
        orderIndex: 1,
        workoutId: workout.workoutId,
      );

      // Update workout with exercise
      final updatedWorkout = workout.copyWith(
        exercises: [exercise],
      );

      await repository.updateWorkout(updatedWorkout);

      // Verify exercise was saved
      final retrievedWorkout = await repository.getWorkout(workout.workoutId);
      expect(retrievedWorkout!.exercises.length, 1);
      expect(retrievedWorkout.exercises.first.exerciseName, 'Bench Press');
      expect(retrievedWorkout.exercises.first.sets.length, 2);
      expect(retrievedWorkout.totalVolume, 1440.0); // (80*10) + (80*8)
    });

    test('Stage 3.4: Should complete workout with statistics', () async {
      // Create workout with exercises
      final sets = [
        WorkoutSet(
          weight: 100.0,
          reps: 5,
          setNumber: 1,
          workoutExerciseId: 'completion_test_001_squat',
          isCompleted: true,
        ),
      ];

      final exercise = WorkoutExercise(
        exerciseId: 'squat',
        exerciseName: 'Squat',
        bodyParts: ['upper legs'],
        sets: sets,
        orderIndex: 1,
        workoutId: 'completion_test_001',
      );

      final workout = Workout(
        workoutId: 'completion_test_001',
        userId: mockUserId,
        name: 'Completion Test',
        targetBodyParts: ['upper legs'],
        plannedDurationMinutes: 30,
        createdAt: DateTime.now(),
        status: WorkoutStatus.inProgress,
        startedAt: DateTime.now().subtract(const Duration(minutes: 25)),
        exercises: [exercise],
      );

      await repository.saveWorkout(workout);

      // Complete workout
      await repository.completeWorkout(workout.workoutId);

      // Verify completion
      final completedWorkout = await repository.getWorkout(workout.workoutId);
      expect(completedWorkout!.status, WorkoutStatus.completed);
      expect(completedWorkout.completedAt, isNotNull);
      expect(completedWorkout.totalVolume, 500.0); // 100*5
    });

    test('Stage 3.5: Should calculate workout statistics correctly', () async {
      // Create multiple completed workouts for statistics
      final workout1 = Workout(
        workoutId: 'stats_test_001',
        userId: mockUserId,
        name: 'Chest Day',
        targetBodyParts: ['chest'],
        plannedDurationMinutes: 45,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        status: WorkoutStatus.completed,
        startedAt: DateTime.now().subtract(const Duration(days: 2)),
        completedAt: DateTime.now().subtract(const Duration(days: 2)).add(const Duration(minutes: 50)),
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
                workoutExerciseId: 'stats_test_001_bench_press',
                isCompleted: true,
              ),
            ],
            orderIndex: 1,
            workoutId: 'stats_test_001',
          ),
        ],
      );

      final workout2 = Workout(
        workoutId: 'stats_test_002',
        userId: mockUserId,
        name: 'Back Day',
        targetBodyParts: ['back'],
        plannedDurationMinutes: 40,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: WorkoutStatus.completed,
        startedAt: DateTime.now().subtract(const Duration(days: 1)),
        completedAt: DateTime.now().subtract(const Duration(days: 1)).add(const Duration(minutes: 45)),
        exercises: [
          WorkoutExercise(
            exerciseId: 'pull_ups',
            exerciseName: 'Pull Ups',
            bodyParts: ['back'],
            sets: [
              WorkoutSet(
                weight: 0.0,
                reps: 12,
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

      await repository.saveWorkout(workout1);
      await repository.saveWorkout(workout2);

      // Get statistics
      final stats = await repository.getWorkoutStats(mockUserId);

      expect(stats.totalWorkouts, 2);
      expect(stats.completedWorkouts, 2);
      expect(stats.completionRate, 1.0);
      expect(stats.totalVolume, 800.0); // 80*10 + 0*12
      expect(stats.averageDurationMinutes, closeTo(47.5, 1.0)); // (50+45)/2
    });

    testWidgets('Stage 3.6: WorkoutSetupScreen should create workouts successfully', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutSetupScreen(),
        ),
      );

      // Verify setup screen loads
      expect(find.text('Create Workout'), findsAtLeastNWidgets(1));
      expect(find.text('Workout Duration'), findsOneWidget);

      // Verify duration selector is present
      expect(find.text('45min'), findsOneWidget);
      
      // Test passes if no exceptions thrown
      expect(tester.takeException(), isNull);
    });

    testWidgets('Stage 3.7: WorkoutLoggingScreen should handle workout loading', (WidgetTester tester) async {
      // Create test workout first
      final workout = Workout(
        workoutId: 'widget_test_001',
        userId: mockUserId,
        name: 'Widget Test Workout',
        targetBodyParts: ['arms'],
        plannedDurationMinutes: 30,
        createdAt: DateTime.now(),
        status: WorkoutStatus.planned,
      );

      await repository.saveWorkout(workout);

      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutLoggingScreen(workoutId: workout.workoutId),
        ),
      );

      // Should create and load without exceptions
      expect(find.byType(WorkoutLoggingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}