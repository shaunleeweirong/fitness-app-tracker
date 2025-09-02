import 'package:flutter_test/flutter_test.dart';
import 'package:first_fitness_test_app/models/workout.dart';

void main() {
  group('Workout Model Tests', () {
    late Workout testWorkout;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 1, 10, 0, 0);
      testWorkout = Workout(
        workoutId: 'workout_1',
        userId: 'user_1',
        name: 'Upper Body Push',
        targetBodyParts: ['chest', 'shoulders', 'upper arms'],
        plannedDurationMinutes: 45,
        createdAt: testDate,
        status: WorkoutStatus.planned,
      );
    });

    test('should create workout with required fields', () {
      expect(testWorkout.workoutId, 'workout_1');
      expect(testWorkout.userId, 'user_1');
      expect(testWorkout.name, 'Upper Body Push');
      expect(testWorkout.targetBodyParts, ['chest', 'shoulders', 'upper arms']);
      expect(testWorkout.plannedDurationMinutes, 45);
      expect(testWorkout.createdAt, testDate);
      expect(testWorkout.status, WorkoutStatus.planned);
      expect(testWorkout.exercises, isEmpty);
    });

    test('should convert to and from SQLite Map correctly', () {
      // Convert to map
      final map = testWorkout.toMap();
      expect(map['workout_id'], 'workout_1');
      expect(map['user_id'], 'user_1');
      expect(map['name'], 'Upper Body Push');
      expect(map['target_body_parts'], 'chest,shoulders,upper arms');
      expect(map['planned_duration_minutes'], 45);
      expect(map['created_at'], testDate.toIso8601String());
      expect(map['status'], 0); // WorkoutStatus.planned.index

      // Convert back from map
      final workoutFromMap = Workout.fromMap(map);
      expect(workoutFromMap.workoutId, testWorkout.workoutId);
      expect(workoutFromMap.userId, testWorkout.userId);
      expect(workoutFromMap.name, testWorkout.name);
      expect(workoutFromMap.targetBodyParts, testWorkout.targetBodyParts);
      expect(workoutFromMap.plannedDurationMinutes, testWorkout.plannedDurationMinutes);
      expect(workoutFromMap.createdAt, testWorkout.createdAt);
      expect(workoutFromMap.status, testWorkout.status);
    });

    test('should handle nullable fields correctly', () {
      final workoutWithNulls = testWorkout.copyWith(
        startedAt: testDate.add(const Duration(hours: 1)),
        completedAt: testDate.add(const Duration(hours: 2)),
        notes: 'Great workout!',
      );

      final map = workoutWithNulls.toMap();
      expect(map['started_at'], isNotNull);
      expect(map['completed_at'], isNotNull);
      expect(map['notes'], 'Great workout!');

      final fromMap = Workout.fromMap(map);
      expect(fromMap.startedAt, workoutWithNulls.startedAt);
      expect(fromMap.completedAt, workoutWithNulls.completedAt);
      expect(fromMap.notes, workoutWithNulls.notes);
    });

    test('should calculate actual duration correctly', () {
      expect(testWorkout.actualDuration, Duration.zero);

      final startedWorkout = testWorkout.copyWith(
        startedAt: testDate,
        completedAt: testDate.add(const Duration(minutes: 50)),
      );

      expect(startedWorkout.actualDuration, const Duration(minutes: 50));
    });

    test('should identify workout status correctly', () {
      expect(testWorkout.isPlanned, true);
      expect(testWorkout.isInProgress, false);
      expect(testWorkout.isCompleted, false);

      final inProgressWorkout = testWorkout.copyWith(status: WorkoutStatus.inProgress);
      expect(inProgressWorkout.isInProgress, true);

      final completedWorkout = testWorkout.copyWith(status: WorkoutStatus.completed);
      expect(completedWorkout.isCompleted, true);
    });

    test('should handle empty and null body parts list', () {
      final emptyBodyParts = Workout.fromMap({
        'workout_id': 'test',
        'user_id': 'test',
        'name': 'Test',
        'target_body_parts': '',
        'planned_duration_minutes': 30,
        'created_at': testDate.toIso8601String(),
        'status': 0,
      });

      expect(emptyBodyParts.targetBodyParts, isEmpty);

      final nullBodyParts = Workout.fromMap({
        'workout_id': 'test',
        'user_id': 'test',
        'name': 'Test',
        'target_body_parts': null,
        'planned_duration_minutes': 30,
        'created_at': testDate.toIso8601String(),
        'status': 0,
      });

      expect(nullBodyParts.targetBodyParts, isEmpty);
    });
  });

  group('WorkoutExercise Model Tests', () {
    late WorkoutExercise testExercise;

    setUp(() {
      testExercise = WorkoutExercise(
        exerciseId: 'bench_press',
        exerciseName: 'Bench Press',
        bodyParts: ['chest', 'shoulders'],
        sets: [],
        orderIndex: 1,
        workoutId: 'workout_1',
      );
    });

    test('should create exercise with required fields', () {
      expect(testExercise.exerciseId, 'bench_press');
      expect(testExercise.exerciseName, 'Bench Press');
      expect(testExercise.bodyParts, ['chest', 'shoulders']);
      expect(testExercise.orderIndex, 1);
      expect(testExercise.workoutId, 'workout_1');
      expect(testExercise.sets, isEmpty);
    });

    test('should convert to and from SQLite Map correctly', () {
      final map = testExercise.toMap();
      expect(map['exercise_id'], 'bench_press');
      expect(map['exercise_name'], 'Bench Press');
      expect(map['body_parts'], 'chest,shoulders');
      expect(map['order_index'], 1);
      expect(map['workout_id'], 'workout_1');

      final fromMap = WorkoutExercise.fromMap(map);
      expect(fromMap.exerciseId, testExercise.exerciseId);
      expect(fromMap.exerciseName, testExercise.exerciseName);
      expect(fromMap.bodyParts, testExercise.bodyParts);
      expect(fromMap.orderIndex, testExercise.orderIndex);
      expect(fromMap.workoutId, testExercise.workoutId);
    });

    test('should calculate total volume from sets', () {
      final sets = [
        WorkoutSet(weight: 80, reps: 10, setNumber: 1, workoutExerciseId: 'workout_1_bench_press'),
        WorkoutSet(weight: 80, reps: 8, setNumber: 2, workoutExerciseId: 'workout_1_bench_press'),
        WorkoutSet(weight: 75, reps: 6, setNumber: 3, workoutExerciseId: 'workout_1_bench_press'),
      ];

      final exerciseWithSets = testExercise.copyWith(sets: sets);
      expect(exerciseWithSets.totalVolume, 1890.0); // 800 + 640 + 450
    });
  });

  group('WorkoutSet Model Tests', () {
    late WorkoutSet testSet;

    setUp(() {
      testSet = WorkoutSet(
        weight: 80.5,
        reps: 10,
        setNumber: 1,
        workoutExerciseId: 'workout_1_bench_press',
      );
    });

    test('should create set with required fields', () {
      expect(testSet.weight, 80.5);
      expect(testSet.reps, 10);
      expect(testSet.setNumber, 1);
      expect(testSet.workoutExerciseId, 'workout_1_bench_press');
      expect(testSet.isCompleted, false);
    });

    test('should convert to and from SQLite Map correctly', () {
      final map = testSet.toMap();
      expect(map['weight'], 80.5);
      expect(map['reps'], 10);
      expect(map['set_number'], 1);
      expect(map['is_completed'], 0);
      expect(map['workout_exercise_id'], 'workout_1_bench_press');

      final fromMap = WorkoutSet.fromMap(map);
      expect(fromMap.weight, testSet.weight);
      expect(fromMap.reps, testSet.reps);
      expect(fromMap.setNumber, testSet.setNumber);
      expect(fromMap.isCompleted, testSet.isCompleted);
      expect(fromMap.workoutExerciseId, testSet.workoutExerciseId);
    });

    test('should calculate volume correctly', () {
      expect(testSet.volume, 805.0); // 80.5 * 10
    });

    test('should format weight correctly', () {
      expect(testSet.formattedWeight, '80.5kg');

      final wholeNumberSet = testSet.copyWith(weight: 80.0);
      expect(wholeNumberSet.formattedWeight, '80kg');
    });

    test('should create summary string correctly', () {
      expect(testSet.summary, '80.5kg × 10 reps');
    });

    test('should handle completed status correctly', () {
      expect(testSet.isCompleted, false);

      final completedSet = testSet.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      expect(completedSet.isCompleted, true);
      expect(completedSet.completedAt, isNotNull);
    });
  });

  group('User Model Tests', () {
    late User testUser;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 1);
      testUser = User(
        userId: 'user_1',
        name: 'John Doe',
        createdAt: testDate,
        lastActiveAt: testDate,
        bodyPartXP: {'chest': 100, 'shoulders': 75},
        preferences: UserPreferences.defaultPreferences(),
      );
    });

    test('should create user with required fields', () {
      expect(testUser.userId, 'user_1');
      expect(testUser.name, 'John Doe');
      expect(testUser.createdAt, testDate);
      expect(testUser.lastActiveAt, testDate);
      expect(testUser.bodyPartXP, {'chest': 100, 'shoulders': 75});
    });

    test('should convert to and from SQLite Map correctly', () {
      final map = testUser.toMap();
      expect(map['user_id'], 'user_1');
      expect(map['name'], 'John Doe');
      expect(map['body_part_xp'], 'chest:100,shoulders:75');

      final fromMap = User.fromMap(map);
      expect(fromMap.userId, testUser.userId);
      expect(fromMap.name, testUser.name);
      expect(fromMap.bodyPartXP, testUser.bodyPartXP);
    });
  });

  group('UserPreferences Model Tests', () {
    test('should create default preferences correctly', () {
      final prefs = UserPreferences.defaultPreferences();
      expect(prefs.defaultWeightUnit, 'kg');
      expect(prefs.defaultRestTime, 90);
      expect(prefs.favoriteBodyParts, isEmpty);
      expect(prefs.soundEnabled, true);
      expect(prefs.vibrationEnabled, true);
    });

    test('should convert to and from SQLite Map correctly', () {
      final prefs = UserPreferences(
        defaultWeightUnit: 'lbs',
        defaultRestTime: 120,
        favoriteBodyParts: ['chest', 'back'],
        soundEnabled: false,
        vibrationEnabled: true,
      );

      final map = prefs.toMap('user_1');
      expect(map['default_weight_unit'], 'lbs');
      expect(map['default_rest_time'], 120);
      expect(map['favorite_body_parts'], 'chest,back');
      expect(map['sound_enabled'], 0);
      expect(map['vibration_enabled'], 1);

      final fromMap = UserPreferences.fromMap(map);
      expect(fromMap.defaultWeightUnit, prefs.defaultWeightUnit);
      expect(fromMap.defaultRestTime, prefs.defaultRestTime);
      expect(fromMap.favoriteBodyParts, prefs.favoriteBodyParts);
      expect(fromMap.soundEnabled, prefs.soundEnabled);
      expect(fromMap.vibrationEnabled, prefs.vibrationEnabled);
    });
  });
}