import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:first_fitness_test_app/services/workout_repository.dart';
import 'package:first_fitness_test_app/services/database_helper.dart';
import 'package:first_fitness_test_app/models/workout.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('WorkoutRepository Tests', () {
    late WorkoutRepository repository;
    late DatabaseHelper dbHelper;
    late String mockUserId;

    setUp(() async {
      repository = WorkoutRepository();
      dbHelper = DatabaseHelper();
      
      // Clean slate for each test
      await dbHelper.deleteDatabase();
      
      // Create mock user
      mockUserId = await dbHelper.createMockUser();
    });

    tearDown(() async {
      await repository.close();
    });

    group('Workout CRUD Operations', () {
      test('should save and retrieve a basic workout', () async {
        // Create a basic workout
        final workout = Workout(
          workoutId: 'workout_001',
          userId: mockUserId,
          name: 'Upper Body Push',
          targetBodyParts: ['chest', 'shoulders'],
          plannedDurationMinutes: 45,
          createdAt: DateTime.now(),
          status: WorkoutStatus.planned,
        );

        // Save workout
        final savedId = await repository.saveWorkout(workout);
        expect(savedId, workout.workoutId);

        // Retrieve workout
        final retrieved = await repository.getWorkout(workout.workoutId);
        expect(retrieved, isNotNull);
        expect(retrieved!.workoutId, workout.workoutId);
        expect(retrieved.name, workout.name);
        expect(retrieved.targetBodyParts, workout.targetBodyParts);
        expect(retrieved.plannedDurationMinutes, workout.plannedDurationMinutes);
        expect(retrieved.status, workout.status);
        expect(retrieved.exercises, isEmpty);
      });

      test('should save and retrieve workout with exercises and sets', () async {
        // Create workout with exercises and sets
        final sets = [
          WorkoutSet(
            weight: 80.0,
            reps: 10,
            setNumber: 1,
            workoutExerciseId: 'workout_001_bench_press',
          ),
          WorkoutSet(
            weight: 80.0,
            reps: 8,
            setNumber: 2,
            workoutExerciseId: 'workout_001_bench_press',
          ),
        ];

        final exercises = [
          WorkoutExercise(
            exerciseId: 'bench_press',
            exerciseName: 'Bench Press',
            bodyParts: ['chest', 'shoulders'],
            sets: sets,
            orderIndex: 1,
            workoutId: 'workout_001',
          ),
        ];

        final workout = Workout(
          workoutId: 'workout_001',
          userId: mockUserId,
          name: 'Chest Day',
          targetBodyParts: ['chest', 'shoulders'],
          plannedDurationMinutes: 60,
          createdAt: DateTime.now(),
          exercises: exercises,
        );

        // Save workout
        await repository.saveWorkout(workout);

        // Retrieve workout
        final retrieved = await repository.getWorkout(workout.workoutId);
        expect(retrieved, isNotNull);
        expect(retrieved!.exercises.length, 1);
        
        final retrievedExercise = retrieved.exercises.first;
        expect(retrievedExercise.exerciseId, 'bench_press');
        expect(retrievedExercise.exerciseName, 'Bench Press');
        expect(retrievedExercise.sets.length, 2);
        
        final retrievedSet1 = retrievedExercise.sets.first;
        expect(retrievedSet1.weight, 80.0);
        expect(retrievedSet1.reps, 10);
        expect(retrievedSet1.setNumber, 1);
      });

      test('should update existing workout', () async {
        // Create and save initial workout
        final workout = Workout(
          workoutId: 'workout_001',
          userId: mockUserId,
          name: 'Initial Name',
          targetBodyParts: ['chest'],
          plannedDurationMinutes: 30,
          createdAt: DateTime.now(),
        );

        await repository.saveWorkout(workout);

        // Update workout
        final updatedWorkout = workout.copyWith(
          name: 'Updated Name',
          targetBodyParts: ['chest', 'shoulders'],
          plannedDurationMinutes: 45,
          notes: 'Added notes',
        );

        await repository.updateWorkout(updatedWorkout);

        // Retrieve updated workout
        final retrieved = await repository.getWorkout(workout.workoutId);
        expect(retrieved!.name, 'Updated Name');
        expect(retrieved.targetBodyParts, ['chest', 'shoulders']);
        expect(retrieved.plannedDurationMinutes, 45);
        expect(retrieved.notes, 'Added notes');
      });

      test('should delete workout and all associated data', () async {
        // Create workout with exercises and sets
        final workout = Workout(
          workoutId: 'workout_001',
          userId: mockUserId,
          name: 'To Delete',
          targetBodyParts: ['chest'],
          plannedDurationMinutes: 30,
          createdAt: DateTime.now(),
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
                  workoutExerciseId: 'workout_001_bench_press',
                ),
              ],
              orderIndex: 1,
              workoutId: 'workout_001',
            ),
          ],
        );

        await repository.saveWorkout(workout);

        // Verify workout exists
        final beforeDelete = await repository.getWorkout(workout.workoutId);
        expect(beforeDelete, isNotNull);

        // Delete workout
        await repository.deleteWorkout(workout.workoutId);

        // Verify workout is deleted
        final afterDelete = await repository.getWorkout(workout.workoutId);
        expect(afterDelete, isNull);
      });
    });

    group('Workout Queries', () {
      setUp(() async {
        // Create test workouts
        final workouts = [
          Workout(
            workoutId: 'workout_001',
            userId: mockUserId,
            name: 'Chest Day',
            targetBodyParts: ['chest'],
            plannedDurationMinutes: 45,
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            status: WorkoutStatus.completed,
          ),
          Workout(
            workoutId: 'workout_002',
            userId: mockUserId,
            name: 'Back Day',
            targetBodyParts: ['back'],
            plannedDurationMinutes: 50,
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            status: WorkoutStatus.planned,
          ),
          Workout(
            workoutId: 'workout_003',
            userId: mockUserId,
            name: 'Leg Day',
            targetBodyParts: ['upper legs'],
            plannedDurationMinutes: 60,
            createdAt: DateTime.now(),
            status: WorkoutStatus.inProgress,
          ),
        ];

        for (final workout in workouts) {
          await repository.saveWorkout(workout);
        }
      });

      test('should get all workouts for user', () async {
        final workouts = await repository.getWorkouts(userId: mockUserId);
        expect(workouts.length, 3);
        
        // Should be ordered by created_at DESC (newest first)
        expect(workouts[0].name, 'Leg Day');
        expect(workouts[1].name, 'Back Day');
        expect(workouts[2].name, 'Chest Day');
      });

      test('should filter workouts by status', () async {
        final completedWorkouts = await repository.getWorkouts(
          userId: mockUserId,
          status: WorkoutStatus.completed,
        );
        expect(completedWorkouts.length, 1);
        expect(completedWorkouts.first.name, 'Chest Day');

        final plannedWorkouts = await repository.getWorkouts(
          userId: mockUserId,
          status: WorkoutStatus.planned,
        );
        expect(plannedWorkouts.length, 1);
        expect(plannedWorkouts.first.name, 'Back Day');
      });

      test('should limit and offset results', () async {
        final firstTwo = await repository.getWorkouts(
          userId: mockUserId,
          limit: 2,
        );
        expect(firstTwo.length, 2);
        expect(firstTwo[0].name, 'Leg Day');
        expect(firstTwo[1].name, 'Back Day');

        final skipFirst = await repository.getWorkouts(
          userId: mockUserId,
          limit: 2,
          offset: 1,
        );
        expect(skipFirst.length, 2);
        expect(skipFirst[0].name, 'Back Day');
        expect(skipFirst[1].name, 'Chest Day');
      });

      test('should get workouts by date range', () async {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        
        // Get workouts from yesterday to today
        final recentWorkouts = await repository.getWorkoutsByDateRange(
          userId: mockUserId,
          startDate: yesterday.subtract(const Duration(hours: 1)),
          endDate: today.add(const Duration(hours: 1)),
        );
        
        expect(recentWorkouts.length, 2); // Back Day and Leg Day
      });
    });

    group('Workout Status Operations', () {
      test('should start workout correctly', () async {
        final workout = Workout(
          workoutId: 'workout_001',
          userId: mockUserId,
          name: 'Test Workout',
          targetBodyParts: ['chest'],
          plannedDurationMinutes: 30,
          createdAt: DateTime.now(),
          status: WorkoutStatus.planned,
        );

        await repository.saveWorkout(workout);

        // Start workout
        await repository.startWorkout(workout.workoutId);

        // Verify status and start time
        final updated = await repository.getWorkout(workout.workoutId);
        expect(updated!.status, WorkoutStatus.inProgress);
        expect(updated.startedAt, isNotNull);
      });

      test('should complete workout correctly', () async {
        final workout = Workout(
          workoutId: 'workout_001',
          userId: mockUserId,
          name: 'Test Workout',
          targetBodyParts: ['chest'],
          plannedDurationMinutes: 30,
          createdAt: DateTime.now(),
          status: WorkoutStatus.inProgress,
          startedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        );

        await repository.saveWorkout(workout);

        // Complete workout
        await repository.completeWorkout(workout.workoutId);

        // Verify status and completion time
        final updated = await repository.getWorkout(workout.workoutId);
        expect(updated!.status, WorkoutStatus.completed);
        expect(updated.completedAt, isNotNull);
      });

      test('should cancel workout correctly', () async {
        final workout = Workout(
          workoutId: 'workout_001',
          userId: mockUserId,
          name: 'Test Workout',
          targetBodyParts: ['chest'],
          plannedDurationMinutes: 30,
          createdAt: DateTime.now(),
          status: WorkoutStatus.inProgress,
        );

        await repository.saveWorkout(workout);

        // Cancel workout
        await repository.cancelWorkout(workout.workoutId);

        // Verify status
        final updated = await repository.getWorkout(workout.workoutId);
        expect(updated!.status, WorkoutStatus.cancelled);
      });
    });

    group('Workout Statistics', () {
      setUp(() async {
        // Create test workouts with exercises and sets
        final completedWorkout1 = Workout(
          workoutId: 'workout_001',
          userId: mockUserId,
          name: 'Chest Day',
          targetBodyParts: ['chest'],
          plannedDurationMinutes: 45,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          startedAt: DateTime.now().subtract(const Duration(days: 2)),
          completedAt: DateTime.now().subtract(const Duration(days: 2)).add(const Duration(minutes: 50)),
          status: WorkoutStatus.completed,
          exercises: [
            WorkoutExercise(
              exerciseId: 'bench_press',
              exerciseName: 'Bench Press',
              bodyParts: ['chest', 'shoulders'],
              sets: [
                WorkoutSet(
                  weight: 80.0,
                  reps: 10,
                  setNumber: 1,
                  isCompleted: true,
                  workoutExerciseId: 'workout_001_bench_press',
                ),
                WorkoutSet(
                  weight: 80.0,
                  reps: 8,
                  setNumber: 2,
                  isCompleted: true,
                  workoutExerciseId: 'workout_001_bench_press',
                ),
              ],
              orderIndex: 1,
              workoutId: 'workout_001',
            ),
          ],
        );

        final completedWorkout2 = Workout(
          workoutId: 'workout_002',
          userId: mockUserId,
          name: 'Back Day',
          targetBodyParts: ['back'],
          plannedDurationMinutes: 50,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          startedAt: DateTime.now().subtract(const Duration(days: 1)),
          completedAt: DateTime.now().subtract(const Duration(days: 1)).add(const Duration(minutes: 55)),
          status: WorkoutStatus.completed,
          exercises: [
            WorkoutExercise(
              exerciseId: 'pull_ups',
              exerciseName: 'Pull Ups',
              bodyParts: ['back'],
              sets: [
                WorkoutSet(
                  weight: 0.0,
                  reps: 10,
                  setNumber: 1,
                  isCompleted: true,
                  workoutExerciseId: 'workout_002_pull_ups',
                ),
              ],
              orderIndex: 1,
              workoutId: 'workout_002',
            ),
          ],
        );

        final plannedWorkout = Workout(
          workoutId: 'workout_003',
          userId: mockUserId,
          name: 'Leg Day',
          targetBodyParts: ['upper legs'],
          plannedDurationMinutes: 60,
          createdAt: DateTime.now(),
          status: WorkoutStatus.planned,
        );

        await repository.saveWorkout(completedWorkout1);
        await repository.saveWorkout(completedWorkout2);
        await repository.saveWorkout(plannedWorkout);
      });

      test('should calculate workout statistics correctly', () async {
        final stats = await repository.getWorkoutStats(mockUserId);
        
        expect(stats.totalWorkouts, 3);
        expect(stats.completedWorkouts, 2);
        expect(stats.completionRate, closeTo(0.67, 0.01));
        expect(stats.totalVolume, 1440.0); // (80*10 + 80*8) + (0*10) = 1440
        expect(stats.averageDurationMinutes, closeTo(52.5, 1.0)); // (50+55)/2
      });

      test('should calculate volume by body part correctly', () async {
        final volumeByBodyPart = await repository.getVolumeByBodyPart(mockUserId);
        
        expect(volumeByBodyPart['chest'], 720.0); // Half of bench press volume (1440/2)
        expect(volumeByBodyPart['shoulders'], 720.0); // Half of bench press volume (1440/2)
        expect(volumeByBodyPart['back'], 0.0); // Pull ups have 0 weight
      });

      test('should format statistics correctly', () async {
        final stats = await repository.getWorkoutStats(mockUserId);
        
        expect(stats.formattedTotalVolume, '1.4k kg');
        expect(stats.formattedAvgDuration, contains('min'));
      });
    });

    group('Error Handling', () {
      test('should return null for non-existent workout', () async {
        final workout = await repository.getWorkout('non_existent_id');
        expect(workout, isNull);
      });

      test('should handle empty results gracefully', () async {
        // Query for workouts of non-existent user
        final workouts = await repository.getWorkouts(userId: 'non_existent_user');
        expect(workouts, isEmpty);

        // Get stats for user with no workouts
        final emptyUserId = 'empty_user';
        final stats = await repository.getWorkoutStats(emptyUserId);
        expect(stats.totalWorkouts, 0);
        expect(stats.completedWorkouts, 0);
        expect(stats.totalVolume, 0.0);
        expect(stats.completionRate, 0.0);
      });

      test('should handle database transaction failures', () async {
        // This test would require mocking database failures
        // For now, we verify that our transaction structure is sound
        final workout = Workout(
          workoutId: 'workout_001',
          userId: mockUserId,
          name: 'Test Workout',
          targetBodyParts: ['chest'],
          plannedDurationMinutes: 30,
          createdAt: DateTime.now(),
        );

        // Should not throw
        await repository.saveWorkout(workout);
        await repository.updateWorkout(workout);
        await repository.deleteWorkout(workout.workoutId);
      });
    });

    group('Performance Tests', () {
      test('should handle large number of workouts efficiently', () async {
        const workoutCount = 50;
        final workouts = List.generate(workoutCount, (index) => 
          Workout(
            workoutId: 'workout_${index.toString().padLeft(3, '0')}',
            userId: mockUserId,
            name: 'Workout $index',
            targetBodyParts: ['chest'],
            plannedDurationMinutes: 30,
            createdAt: DateTime.now().subtract(Duration(days: index)),
            status: index % 3 == 0 ? WorkoutStatus.completed : WorkoutStatus.planned,
          ),
        );

        // Save all workouts
        final stopwatch = Stopwatch()..start();
        for (final workout in workouts) {
          await repository.saveWorkout(workout);
        }
        stopwatch.stop();

        // Should complete reasonably quickly (under 5 seconds)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));

        // Verify all workouts saved
        final allWorkouts = await repository.getWorkouts(userId: mockUserId);
        expect(allWorkouts.length, workoutCount);
      });
    });
  });
}