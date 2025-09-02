import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:first_fitness_test_app/models/workout.dart';
import 'package:first_fitness_test_app/services/database_helper.dart';
import 'package:first_fitness_test_app/services/workout_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Stage 5: Complete Workout Flow Integration Tests', () {
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

    test('Stage 5.1: Complete workout creation to completion flow', () async {
      // Step 1: Create a new workout (WorkoutSetupScreen equivalent)
      final plannedWorkout = Workout(
        workoutId: 'complete_flow_001',
        userId: mockUserId,
        name: 'Complete Flow Test Workout',
        targetBodyParts: ['chest', 'shoulders'],
        plannedDurationMinutes: 45,
        createdAt: DateTime.now(),
        status: WorkoutStatus.planned,
      );

      // Save the planned workout
      await repository.saveWorkout(plannedWorkout);

      // Verify workout was created
      final createdWorkout = await repository.getWorkout('complete_flow_001');
      expect(createdWorkout, isNotNull);
      expect(createdWorkout!.status, WorkoutStatus.planned);
      expect(createdWorkout.targetBodyParts, ['chest', 'shoulders']);

      // Step 2: Start the workout (WorkoutLoggingScreen initialization)
      await repository.startWorkout('complete_flow_001');
      
      // Small delay to ensure duration calculation
      await Future.delayed(const Duration(milliseconds: 10));

      // Verify workout was started
      final startedWorkout = await repository.getWorkout('complete_flow_001');
      expect(startedWorkout!.status, WorkoutStatus.inProgress);
      expect(startedWorkout.startedAt, isNotNull);

      // Step 3: Add exercises during workout
      final benchPressExercise = WorkoutExercise(
        exerciseId: 'bench_press',
        exerciseName: 'Bench Press',
        bodyParts: ['chest', 'shoulders'],
        sets: [
          WorkoutSet(
            weight: 80.0,
            reps: 10,
            setNumber: 1,
            workoutExerciseId: 'complete_flow_001_bench_press',
            isCompleted: true,
          ),
          WorkoutSet(
            weight: 80.0,
            reps: 8,
            setNumber: 2,
            workoutExerciseId: 'complete_flow_001_bench_press',
            isCompleted: true,
          ),
        ],
        orderIndex: 1,
        workoutId: 'complete_flow_001',
      );

      final shoulderPressExercise = WorkoutExercise(
        exerciseId: 'shoulder_press',
        exerciseName: 'Shoulder Press',
        bodyParts: ['shoulders'],
        sets: [
          WorkoutSet(
            weight: 60.0,
            reps: 12,
            setNumber: 1,
            workoutExerciseId: 'complete_flow_001_shoulder_press',
            isCompleted: true,
          ),
        ],
        orderIndex: 2,
        workoutId: 'complete_flow_001',
      );

      // Update workout with exercises
      final workoutWithExercises = startedWorkout.copyWith(
        exercises: [benchPressExercise, shoulderPressExercise],
      );

      await repository.updateWorkout(workoutWithExercises);

      // Verify exercises were added
      final workoutWithExercisesRetrieved = await repository.getWorkout('complete_flow_001');
      expect(workoutWithExercisesRetrieved!.exercises.length, 2);
      expect(workoutWithExercisesRetrieved.exercises.first.exerciseName, 'Bench Press');
      expect(workoutWithExercisesRetrieved.exercises.last.exerciseName, 'Shoulder Press');
      
      // Verify volume calculations
      final expectedVolume = (80.0 * 10) + (80.0 * 8) + (60.0 * 12); // 800 + 640 + 720 = 2160
      expect(workoutWithExercisesRetrieved.totalVolume, expectedVolume);

      // Step 4: Complete the workout
      await repository.completeWorkout('complete_flow_001');

      // Verify workout completion
      final completedWorkout = await repository.getWorkout('complete_flow_001');
      expect(completedWorkout!.status, WorkoutStatus.completed);
      expect(completedWorkout.completedAt, isNotNull);
      expect(completedWorkout.actualDuration.inMilliseconds, greaterThanOrEqualTo(0));

      // Step 5: Verify workout appears in history (WorkoutHistoryScreen equivalent)
      final allWorkouts = await repository.getWorkouts(userId: mockUserId);
      expect(allWorkouts.length, 1);
      expect(allWorkouts.first.workoutId, 'complete_flow_001');
      expect(allWorkouts.first.status, WorkoutStatus.completed);

      // Step 6: Verify statistics update
      final stats = await repository.getWorkoutStats(mockUserId);
      expect(stats.totalWorkouts, 1);
      expect(stats.completedWorkouts, 1);
      expect(stats.completionRate, 1.0);
      expect(stats.totalVolume, expectedVolume);
    });

    test('Stage 5.2: Multiple workout session flow', () async {
      final workoutSessions = [
        {
          'id': 'session_001',
          'name': 'Chest Day',
          'bodyParts': ['chest'],
          'duration': 45,
          'exercises': [
            {'name': 'Bench Press', 'weight': 80.0, 'reps': 10, 'sets': 3},
          ],
        },
        {
          'id': 'session_002',
          'name': 'Back Day',
          'bodyParts': ['back'],
          'duration': 50,
          'exercises': [
            {'name': 'Pull Ups', 'weight': 0.0, 'reps': 12, 'sets': 3},
            {'name': 'Barbell Row', 'weight': 70.0, 'reps': 8, 'sets': 3},
          ],
        },
        {
          'id': 'session_003',
          'name': 'Leg Day',
          'bodyParts': ['upper legs'],
          'duration': 60,
          'exercises': [
            {'name': 'Squat', 'weight': 100.0, 'reps': 5, 'sets': 5},
          ],
        },
      ];

      double totalExpectedVolume = 0;

      // Create and complete multiple workouts
      for (int i = 0; i < workoutSessions.length; i++) {
        final session = workoutSessions[i];
        
        // Create workout
        final workout = Workout(
          workoutId: session['id'] as String,
          userId: mockUserId,
          name: session['name'] as String,
          targetBodyParts: session['bodyParts'] as List<String>,
          plannedDurationMinutes: session['duration'] as int,
          createdAt: DateTime.now().subtract(Duration(days: workoutSessions.length - i - 1)),
          status: WorkoutStatus.planned,
        );

        await repository.saveWorkout(workout);
        await repository.startWorkout(workout.workoutId);

        // Add exercises
        final exercises = <WorkoutExercise>[];
        final sessionExercises = session['exercises'] as List<Map<String, dynamic>>;
        
        for (int j = 0; j < sessionExercises.length; j++) {
          final exerciseData = sessionExercises[j];
          final sets = <WorkoutSet>[];
          
          // Create sets for this exercise
          for (int setIndex = 0; setIndex < (exerciseData['sets'] as int); setIndex++) {
            final weight = exerciseData['weight'] as double;
            final reps = exerciseData['reps'] as int;
            
            sets.add(WorkoutSet(
              weight: weight,
              reps: reps,
              setNumber: setIndex + 1,
              workoutExerciseId: '${workout.workoutId}_${exerciseData['name']}'.toLowerCase().replaceAll(' ', '_'),
              isCompleted: true,
            ));
            
            totalExpectedVolume += weight * reps;
          }
          
          exercises.add(WorkoutExercise(
            exerciseId: exerciseData['name'].toLowerCase().replaceAll(' ', '_'),
            exerciseName: exerciseData['name'] as String,
            bodyParts: session['bodyParts'] as List<String>,
            sets: sets,
            orderIndex: j + 1,
            workoutId: workout.workoutId,
          ));
        }

        // Update workout with exercises and complete it
        final workoutWithExercises = workout.copyWith(
          exercises: exercises,
          status: WorkoutStatus.inProgress,
          startedAt: DateTime.now().subtract(Duration(days: workoutSessions.length - i - 1, minutes: session['duration'] as int)),
        );

        await repository.updateWorkout(workoutWithExercises);
        await repository.completeWorkout(workout.workoutId);
      }

      // Verify all workouts were created
      final allWorkouts = await repository.getWorkouts(userId: mockUserId);
      expect(allWorkouts.length, 3);

      // Verify ordering (most recent first)
      expect(allWorkouts[0].name, 'Leg Day');
      expect(allWorkouts[1].name, 'Back Day');
      expect(allWorkouts[2].name, 'Chest Day');

      // Verify comprehensive statistics
      final stats = await repository.getWorkoutStats(mockUserId);
      expect(stats.totalWorkouts, 3);
      expect(stats.completedWorkouts, 3);
      expect(stats.completionRate, 1.0);
      expect(stats.totalVolume, totalExpectedVolume);

      // Test filtering by body part
      final chestWorkouts = await repository.getWorkouts(
        userId: mockUserId,
        status: WorkoutStatus.completed,
      );
      expect(chestWorkouts.length, 3); // All completed

      // Test volume by body part
      final volumeByBodyPart = await repository.getVolumeByBodyPart(mockUserId);
      expect(volumeByBodyPart.isNotEmpty, true);
      expect(volumeByBodyPart['chest'], greaterThan(0));
      expect(volumeByBodyPart['back'], greaterThan(0));
      expect(volumeByBodyPart['upper legs'], greaterThan(0));
    });

    test('Stage 5.3: Workout cancellation and resumption flow', () async {
      // Create and start a workout
      final workout = Workout(
        workoutId: 'cancellation_test_001',
        userId: mockUserId,
        name: 'Cancellation Test Workout',
        targetBodyParts: ['chest'],
        plannedDurationMinutes: 30,
        createdAt: DateTime.now(),
        status: WorkoutStatus.planned,
      );

      await repository.saveWorkout(workout);
      await repository.startWorkout(workout.workoutId);

      // Verify workout is in progress
      final inProgressWorkout = await repository.getWorkout(workout.workoutId);
      expect(inProgressWorkout!.status, WorkoutStatus.inProgress);

      // Add some exercises
      final exercise = WorkoutExercise(
        exerciseId: 'bench_press',
        exerciseName: 'Bench Press',
        bodyParts: ['chest'],
        sets: [
          WorkoutSet(
            weight: 80.0,
            reps: 10,
            setNumber: 1,
            workoutExerciseId: 'cancellation_test_001_bench_press',
            isCompleted: true,
          ),
        ],
        orderIndex: 1,
        workoutId: workout.workoutId,
      );

      final workoutWithExercise = inProgressWorkout.copyWith(
        exercises: [exercise],
      );

      await repository.updateWorkout(workoutWithExercise);

      // Cancel the workout
      await repository.cancelWorkout(workout.workoutId);

      // Verify workout was cancelled
      final cancelledWorkout = await repository.getWorkout(workout.workoutId);
      expect(cancelledWorkout!.status, WorkoutStatus.cancelled);

      // Verify cancelled workout appears in history
      final allWorkouts = await repository.getWorkouts(userId: mockUserId);
      expect(allWorkouts.length, 1);
      expect(allWorkouts.first.status, WorkoutStatus.cancelled);

      // Verify statistics don't count cancelled workouts as completed
      final stats = await repository.getWorkoutStats(mockUserId);
      expect(stats.totalWorkouts, 1);
      expect(stats.completedWorkouts, 0);
      expect(stats.completionRate, 0.0);
    });

    test('Stage 5.4: Date range filtering and pagination flow', () async {
      final now = DateTime.now();
      
      // Create workouts across different dates
      final workouts = List.generate(15, (index) =>
        Workout(
          workoutId: 'date_test_${index.toString().padLeft(3, '0')}',
          userId: mockUserId,
          name: 'Workout ${index + 1}',
          targetBodyParts: ['chest'],
          plannedDurationMinutes: 30,
          createdAt: now.subtract(Duration(days: index)),
          status: index % 3 == 0 ? WorkoutStatus.completed : WorkoutStatus.planned,
        ),
      );

      // Save all workouts
      for (final workout in workouts) {
        await repository.saveWorkout(workout);
        if (workout.status == WorkoutStatus.completed) {
          await repository.startWorkout(workout.workoutId);
          await repository.completeWorkout(workout.workoutId);
        }
      }

      // Test pagination - first page
      final firstPage = await repository.getWorkouts(
        userId: mockUserId,
        limit: 5,
        offset: 0,
      );
      expect(firstPage.length, 5);
      expect(firstPage.first.name, 'Workout 1'); // Most recent

      // Test pagination - second page
      final secondPage = await repository.getWorkouts(
        userId: mockUserId,
        limit: 5,
        offset: 5,
      );
      expect(secondPage.length, 5);
      expect(secondPage.first.name, 'Workout 6');

      // Test date range filtering (last week)
      final lastWeekWorkouts = await repository.getWorkoutsByDateRange(
        userId: mockUserId,
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now.add(const Duration(days: 1)),
      );
      expect(lastWeekWorkouts.length, 8); // Day 0-7 = 8 workouts

      // Test status filtering
      final completedWorkouts = await repository.getWorkouts(
        userId: mockUserId,
        status: WorkoutStatus.completed,
      );
      expect(completedWorkouts.length, 5); // Every 3rd workout (0, 3, 6, 9, 12)
    });

    test('Stage 5.5: Performance test with large dataset', () async {
      const workoutCount = 100;
      const exerciseCount = 3;
      const setsPerExercise = 3;

      final stopwatch = Stopwatch()..start();

      // Create large dataset
      for (int i = 0; i < workoutCount; i++) {
        final workout = Workout(
          workoutId: 'perf_test_${i.toString().padLeft(3, '0')}',
          userId: mockUserId,
          name: 'Performance Test Workout $i',
          targetBodyParts: [['chest'], ['back'], ['upper legs']][i % 3],
          plannedDurationMinutes: 30 + (i % 60),
          createdAt: DateTime.now().subtract(Duration(days: i)),
          status: i % 2 == 0 ? WorkoutStatus.completed : WorkoutStatus.planned,
        );

        await repository.saveWorkout(workout);

        // Add exercises for completed workouts
        if (workout.status == WorkoutStatus.completed) {
          await repository.startWorkout(workout.workoutId);

          final exercises = <WorkoutExercise>[];
          for (int j = 0; j < exerciseCount; j++) {
            final sets = <WorkoutSet>[];
            for (int k = 0; k < setsPerExercise; k++) {
              sets.add(WorkoutSet(
                weight: 50.0 + (j * 10),
                reps: 8 + (k * 2),
                setNumber: k + 1,
                workoutExerciseId: '${workout.workoutId}_exercise_$j',
                isCompleted: true,
              ));
            }

            exercises.add(WorkoutExercise(
              exerciseId: 'exercise_$j',
              exerciseName: 'Exercise $j',
              bodyParts: [workout.targetBodyParts.first],
              sets: sets,
              orderIndex: j + 1,
              workoutId: workout.workoutId,
            ));
          }

          final workoutWithExercises = workout.copyWith(
            exercises: exercises,
            status: WorkoutStatus.inProgress,
            startedAt: DateTime.now().subtract(Duration(days: i, minutes: workout.plannedDurationMinutes)),
          );

          await repository.updateWorkout(workoutWithExercises);
          await repository.completeWorkout(workout.workoutId);
        }
      }

      stopwatch.stop();

      // Performance assertions
      expect(stopwatch.elapsedMilliseconds, lessThan(30000)); // Should complete within 30 seconds

      // Verify data integrity
      final allWorkouts = await repository.getWorkouts(userId: mockUserId);
      expect(allWorkouts.length, workoutCount);

      final stats = await repository.getWorkoutStats(mockUserId);
      expect(stats.totalWorkouts, workoutCount);
      expect(stats.completedWorkouts, 50); // Half are completed
      expect(stats.totalVolume, greaterThan(0));

      // Test pagination performance
      final paginationStopwatch = Stopwatch()..start();
      final paginatedResults = await repository.getWorkouts(
        userId: mockUserId,
        limit: 20,
        offset: 40,
      );
      paginationStopwatch.stop();

      expect(paginatedResults.length, 20);
      expect(paginationStopwatch.elapsedMilliseconds, lessThan(1000)); // Should be fast
    });

    test('Stage 5.6: Error handling and data consistency', () async {
      // Test invalid workout operations
      expect(
        () => repository.getWorkout('non_existent_workout'),
        returnsNormally,
      );

      final result = await repository.getWorkout('non_existent_workout');
      expect(result, isNull);

      // Test operations on non-existent workout
      expect(
        () => repository.startWorkout('non_existent_workout'),
        throwsA(isA<Exception>()),
      );

      expect(
        () => repository.completeWorkout('non_existent_workout'),
        throwsA(isA<Exception>()),
      );

      // Test data consistency with concurrent operations
      final workout = Workout(
        workoutId: 'consistency_test_001',
        userId: mockUserId,
        name: 'Consistency Test',
        targetBodyParts: ['chest'],
        plannedDurationMinutes: 30,
        createdAt: DateTime.now(),
        status: WorkoutStatus.planned,
      );

      await repository.saveWorkout(workout);

      // Multiple state changes should be handled correctly
      await repository.startWorkout(workout.workoutId);
      await repository.completeWorkout(workout.workoutId);

      // Verify final state
      final finalWorkout = await repository.getWorkout(workout.workoutId);
      expect(finalWorkout!.status, WorkoutStatus.completed);
      expect(finalWorkout.startedAt, isNotNull);
      expect(finalWorkout.completedAt, isNotNull);
    });
  });
}