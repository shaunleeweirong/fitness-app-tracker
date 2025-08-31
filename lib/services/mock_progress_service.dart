import '../models/user_progress.dart';
import '../models/workout_session.dart';

class MockProgressService {
  static UserProgress getMockProgress() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Create mock workout sessions for the past 14 days with focus on weekly patterns
    final sessions = <WorkoutSession>[];
    final dailyProgress = <DailyProgress>[];
    
    for (int i = 0; i < 14; i++) {
      final date = today.subtract(Duration(days: i));
      
      // Create realistic weekly patterns with varied volume levels
      // This week (days 0-6): Monday, Wednesday, Friday, Saturday workouts
      // Last week (days 7-13): More workouts for comparison
      final isThisWeek = i <= 6;
      
      // Define workout types and intensities
      String workoutType = 'rest';
      double intensityMultiplier = 0.0;
      
      if (isThisWeek) {
        // This week pattern: M(heavy legs), W(medium upper), F(heavy upper), S(light)
        switch (i) {
          case 0: // Monday - Heavy leg day
            workoutType = 'heavy_legs';
            intensityMultiplier = 2.5;
            break;
          case 2: // Wednesday - Medium upper body
            workoutType = 'medium_upper';
            intensityMultiplier = 1.2;
            break;
          case 4: // Friday - Heavy upper body
            workoutType = 'heavy_upper';
            intensityMultiplier = 2.0;
            break;
          case 5: // Saturday - Light accessories
            workoutType = 'light_accessories';
            intensityMultiplier = 0.6;
            break;
          default:
            continue; // Rest days
        }
      } else {
        // Last week - more frequent workouts for comparison
        if ([7, 9, 10, 12, 13].contains(i)) {
          workoutType = 'standard';
          intensityMultiplier = 1.5;
        } else {
          continue; // Rest days
        }
      }
      
      if (workoutType == 'rest') continue;
      
      // Create mock exercise sets based on workout type
      final exerciseSets = <ExerciseSet>[];
      
      if (workoutType == 'heavy_legs') {
        // Heavy leg day - high volume squats and deadlifts
        exerciseSets.addAll([
          ExerciseSet(
            exerciseId: 'squat',
            exerciseName: 'Barbell Squat',
            bodyParts: ['legs', 'upper legs'],
            weight: 100.0 * intensityMultiplier, // Heavy weight
            reps: 5,
            setNumber: 1,
            timestamp: date.add(const Duration(hours: 10)),
          ),
          ExerciseSet(
            exerciseId: 'squat',
            exerciseName: 'Barbell Squat',
            bodyParts: ['legs', 'upper legs'],
            weight: 100.0 * intensityMultiplier,
            reps: 5,
            setNumber: 2,
            timestamp: date.add(const Duration(hours: 10, minutes: 5)),
          ),
          ExerciseSet(
            exerciseId: 'squat',
            exerciseName: 'Barbell Squat',
            bodyParts: ['legs', 'upper legs'],
            weight: 100.0 * intensityMultiplier,
            reps: 5,
            setNumber: 3,
            timestamp: date.add(const Duration(hours: 10, minutes: 10)),
          ),
          ExerciseSet(
            exerciseId: 'deadlift',
            exerciseName: 'Barbell Deadlift',
            bodyParts: ['legs', 'back', 'upper legs'],
            weight: 120.0 * intensityMultiplier, // Heavy deadlift
            reps: 3,
            setNumber: 1,
            timestamp: date.add(const Duration(hours: 10, minutes: 15)),
          ),
          ExerciseSet(
            exerciseId: 'deadlift',
            exerciseName: 'Barbell Deadlift',
            bodyParts: ['legs', 'back', 'upper legs'],
            weight: 120.0 * intensityMultiplier,
            reps: 3,
            setNumber: 2,
            timestamp: date.add(const Duration(hours: 10, minutes: 20)),
          ),
        ]);
      } else if (workoutType == 'heavy_upper') {
        // Heavy upper body - bench press and rows
        exerciseSets.addAll([
          ExerciseSet(
            exerciseId: 'bench_press',
            exerciseName: 'Barbell Bench Press',
            bodyParts: ['chest'],
            weight: 80.0 * intensityMultiplier, // Heavy bench
            reps: 5,
            setNumber: 1,
            timestamp: date.add(const Duration(hours: 10)),
          ),
          ExerciseSet(
            exerciseId: 'bench_press',
            exerciseName: 'Barbell Bench Press',
            bodyParts: ['chest'],
            weight: 80.0 * intensityMultiplier,
            reps: 5,
            setNumber: 2,
            timestamp: date.add(const Duration(hours: 10, minutes: 5)),
          ),
          ExerciseSet(
            exerciseId: 'bench_press',
            exerciseName: 'Barbell Bench Press',
            bodyParts: ['chest'],
            weight: 80.0 * intensityMultiplier,
            reps: 5,
            setNumber: 3,
            timestamp: date.add(const Duration(hours: 10, minutes: 10)),
          ),
          ExerciseSet(
            exerciseId: 'barbell_row',
            exerciseName: 'Barbell Row',
            bodyParts: ['back'],
            weight: 70.0 * intensityMultiplier,
            reps: 6,
            setNumber: 1,
            timestamp: date.add(const Duration(hours: 10, minutes: 15)),
          ),
          ExerciseSet(
            exerciseId: 'barbell_row',
            exerciseName: 'Barbell Row',
            bodyParts: ['back'],
            weight: 70.0 * intensityMultiplier,
            reps: 6,
            setNumber: 2,
            timestamp: date.add(const Duration(hours: 10, minutes: 20)),
          ),
        ]);
      } else if (workoutType == 'medium_upper') {
        // Medium upper body workout
        exerciseSets.addAll([
          ExerciseSet(
            exerciseId: 'dumbbell_press',
            exerciseName: 'Dumbbell Press',
            bodyParts: ['chest'],
            weight: 25.0 * intensityMultiplier, // Medium weight dumbbells
            reps: 10,
            setNumber: 1,
            timestamp: date.add(const Duration(hours: 10)),
          ),
          ExerciseSet(
            exerciseId: 'dumbbell_press',
            exerciseName: 'Dumbbell Press',
            bodyParts: ['chest'],
            weight: 25.0 * intensityMultiplier,
            reps: 10,
            setNumber: 2,
            timestamp: date.add(const Duration(hours: 10, minutes: 5)),
          ),
          ExerciseSet(
            exerciseId: 'lat_pulldown',
            exerciseName: 'Lat Pulldown',
            bodyParts: ['back'],
            weight: 50.0 * intensityMultiplier,
            reps: 12,
            setNumber: 1,
            timestamp: date.add(const Duration(hours: 10, minutes: 10)),
          ),
        ]);
      } else if (workoutType == 'light_accessories') {
        // Light accessory workout
        exerciseSets.addAll([
          ExerciseSet(
            exerciseId: 'bicep_curl',
            exerciseName: 'Dumbbell Bicep Curl',
            bodyParts: ['arms'],
            weight: 12.0 * intensityMultiplier, // Light weight
            reps: 15,
            setNumber: 1,
            timestamp: date.add(const Duration(hours: 10)),
          ),
          ExerciseSet(
            exerciseId: 'tricep_extension',
            exerciseName: 'Tricep Extension',
            bodyParts: ['arms'],
            weight: 10.0 * intensityMultiplier,
            reps: 15,
            setNumber: 1,
            timestamp: date.add(const Duration(hours: 10, minutes: 5)),
          ),
        ]);
      } else {
        // Standard workout for previous week
        exerciseSets.addAll([
          ExerciseSet(
            exerciseId: 'bench_press',
            exerciseName: 'Barbell Bench Press',
            bodyParts: ['chest'],
            weight: 70.0 * intensityMultiplier,
            reps: 8,
            setNumber: 1,
            timestamp: date.add(const Duration(hours: 10)),
          ),
          ExerciseSet(
            exerciseId: 'squat',
            exerciseName: 'Barbell Squat',
            bodyParts: ['legs', 'upper legs'],
            weight: 90.0 * intensityMultiplier,
            reps: 8,
            setNumber: 1,
            timestamp: date.add(const Duration(hours: 10, minutes: 10)),
          ),
        ]);
      }
      
      // Create completed session
      final session = WorkoutSession(
        sessionId: 'session_$i',
        userId: 'mock_user',
        startTime: date.add(const Duration(hours: 10)),
        endTime: date.add(const Duration(hours: 10, minutes: 45)),
        exerciseSets: exerciseSets,
        bodyPartVolumeMap: _calculateBodyPartVolume(exerciseSets),
        totalVolume: _calculateTotalVolume(exerciseSets),
        duration: const Duration(minutes: 45),
        isCompleted: true,
      );
      
      sessions.add(session);
      
      // Create daily progress
      final dayProgress = DailyProgress(
        date: date,
        workoutCount: 1,
        totalVolume: session.totalVolume,
        bodyPartsWorked: session.bodyPartsWorked,
        exerciseCount: 2,
      );
      
      dailyProgress.add(dayProgress);
    }
    
    // Create progress stats
    final totalVolume = sessions.fold(0.0, (sum, session) => sum + session.totalVolume);
    final totalDuration = sessions.fold(Duration.zero, (sum, session) => sum + session.duration);
    final totalSets = sessions.fold(0, (sum, session) => sum + session.totalSets);
    
    final progressStats = ProgressStats(
      totalWorkouts: sessions.length,
      totalTimeExercised: totalDuration,
      totalVolumeLifted: totalVolume,
      totalSets: totalSets,
      lastWorkoutDate: sessions.isNotEmpty ? sessions.first.endTime : null,
    );
    
    // Create body part progress
    final bodyPartProgress = <String, BodyPartProgress>{};
    final bodyParts = ['chest', 'legs', 'upper legs', 'back', 'shoulders'];
    
    for (final bodyPart in bodyParts) {
      double totalBodyPartVolume = 0;
      
      for (final session in sessions) {
        if (session.bodyPartVolumeMap.containsKey(bodyPart)) {
          totalBodyPartVolume += session.bodyPartVolumeMap[bodyPart]!;
        }
      }
      
      if (totalBodyPartVolume > 0) {
        bodyPartProgress[bodyPart] = BodyPartProgress.initial(bodyPart)
            .addVolume(totalBodyPartVolume);
      }
    }
    
    // Create achievements
    final achievements = <Achievement>[
      Achievement.firstWorkout(),
      Achievement.tenWorkouts(),
      Achievement.weekStreak(),
    ];
    
    // Create streak data
    final streakData = StreakData(
      currentStreak: 5,
      longestStreak: 7,
      lastWorkoutDate: today.subtract(const Duration(days: 1)),
    );
    
    return UserProgress(
      userId: 'mock_user',
      lastUpdated: DateTime.now(),
      currentStats: progressStats,
      dailyProgress: dailyProgress.reversed.toList(), // Most recent first
      bodyPartProgress: bodyPartProgress,
      achievements: achievements,
      streakData: streakData,
      milestones: [],
    );
  }

  static Map<String, double> _calculateBodyPartVolume(List<ExerciseSet> exerciseSets) {
    final bodyPartVolume = <String, double>{};
    
    for (final exerciseSet in exerciseSets) {
      final volume = exerciseSet.weight * exerciseSet.reps;
      
      for (final bodyPart in exerciseSet.bodyParts) {
        bodyPartVolume[bodyPart] = (bodyPartVolume[bodyPart] ?? 0) + volume;
      }
    }
    
    return bodyPartVolume;
  }

  static double _calculateTotalVolume(List<ExerciseSet> exerciseSets) {
    return exerciseSets.fold(0.0, (sum, set) => sum + (set.weight * set.reps));
  }
}