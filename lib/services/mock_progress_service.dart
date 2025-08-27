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
      
      // Create more realistic weekly patterns: 3-4 workouts per week
      // This week (days 0-6): 3 workouts (days 1, 3, 5)  
      // Last week (days 7-13): 4 workouts (days 8, 10, 11, 13)
      final isThisWeek = i <= 6;
      final shouldWorkout = isThisWeek 
          ? [1, 3, 5].contains(i)  // This week: 3 workouts
          : [8, 10, 11, 13].contains(i);  // Last week: 4 workouts
      
      if (!shouldWorkout) continue;
      
      // Create mock exercise sets
      final exerciseSets = <ExerciseSet>[
        ExerciseSet(
          exerciseId: 'bench_press',
          exerciseName: 'Barbell Bench Press',
          bodyParts: ['chest'],
          weight: 61 + (i * 1.1), // Progressive overload in KG (135 lbs = ~61 kg)
          reps: 10,
          setNumber: 1,
          timestamp: date.add(const Duration(hours: 10)),
        ),
        ExerciseSet(
          exerciseId: 'bench_press',
          exerciseName: 'Barbell Bench Press',
          bodyParts: ['chest'],
          weight: 61 + (i * 1.1),
          reps: 8,
          setNumber: 2,
          timestamp: date.add(const Duration(hours: 10, minutes: 5)),
        ),
        ExerciseSet(
          exerciseId: 'squat',
          exerciseName: 'Barbell Squat',
          bodyParts: ['legs', 'upper legs'],
          weight: 84 + (i * 2.3), // Progressive overload in KG (185 lbs = ~84 kg)
          reps: 12,
          setNumber: 1,
          timestamp: date.add(const Duration(hours: 10, minutes: 10)),
        ),
        ExerciseSet(
          exerciseId: 'squat',
          exerciseName: 'Barbell Squat',
          bodyParts: ['legs', 'upper legs'],
          weight: 84 + (i * 2.3),
          reps: 10,
          setNumber: 2,
          timestamp: date.add(const Duration(hours: 10, minutes: 15)),
        ),
      ];
      
      // Create completed session
      final session = WorkoutSession(
        sessionId: 'session_$i',
        userId: 'mock_user',
        startTime: date.add(const Duration(hours: 10)),
        endTime: date.add(const Duration(hours: 10, minutes: 45)),
        exerciseSets: exerciseSets,
        bodyPartVolumeMap: {
          'chest': (61 + i * 1.1) * 18, // weight * total reps in KG
          'legs': (84 + i * 2.3) * 22,
          'upper legs': (84 + i * 2.3) * 22,
        },
        totalVolume: (61 + i * 1.1) * 18 + (84 + i * 2.3) * 44, // chest + legs in KG
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
      int workoutCount = 0;
      
      for (final session in sessions) {
        if (session.bodyPartVolumeMap.containsKey(bodyPart)) {
          totalBodyPartVolume += session.bodyPartVolumeMap[bodyPart]!;
          workoutCount++;
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
}