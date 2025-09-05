import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/progress_dashboard_data.dart';
import '../models/user_progress.dart';
import '../models/workout_session.dart';
import '../services/database_helper.dart';
import 'workout_template_repository.dart';

/// Service responsible for calculating and providing all progress-related data
/// Consolidates data from multiple sources into a unified dashboard view
class ProgressService {
  final DatabaseHelper _databaseHelper;
  final WorkoutTemplateRepository _templateRepository;
  
  static const String _defaultUserId = 'default_user'; // For single-user app

  ProgressService({
    DatabaseHelper? databaseHelper,
    WorkoutTemplateRepository? templateRepository,
  }) : _databaseHelper = databaseHelper ?? DatabaseHelper(),
       _templateRepository = templateRepository ?? WorkoutTemplateRepository();

  /// Get comprehensive progress data for the dashboard
  Future<ProgressDataResult> getProgressData([String? userId]) async {
    try {
      final effectiveUserId = userId ?? _defaultUserId;
      
      debugPrint('Loading progress data for user: $effectiveUserId');
      
      // Get user progress (this contains most of our calculated data)
      final userProgress = await _getUserProgress(effectiveUserId);
      
      // Get completed workout sessions for additional calculations
      final completedSessions = await _getCompletedWorkoutSessions(effectiveUserId);
      
      debugPrint('Found ${completedSessions.length} completed workout sessions');
      
      // Calculate additional metrics not in UserProgress
      final additionalMetrics = _calculateAdditionalMetrics(completedSessions);
      
      // Generate training insights
      final insights = _generateTrainingInsights(userProgress.bodyPartProgress);
      
      final data = ProgressDashboardData(
        // Lifetime totals from UserProgress
        totalWorkouts: userProgress.currentStats.totalWorkouts,
        totalVolumeLifted: userProgress.currentStats.totalVolumeLifted,
        totalTimeExercised: userProgress.currentStats.totalTimeExercised,
        currentStreak: userProgress.streakData.currentStreak,
        longestStreak: userProgress.streakData.longestStreak,
        totalAchievements: userProgress.achievements.length,
        
        // Comparison data from UserProgress methods
        weeklyComparison: userProgress.getWeeklyComparison(),
        monthlyComparison: userProgress.getMonthlyComparison(),
        
        // Body part progress
        bodyPartProgress: userProgress.bodyPartProgress,
        
        // Achievement data
        recentAchievements: userProgress.achievements.take(5).toList(),
        allAchievements: userProgress.achievements,
        
        // Training insights
        closeToLevelUp: insights.closeToLevelUp,
        needsAttention: insights.needsAttention,
        
        // Additional metrics
        lastWorkoutDate: userProgress.currentStats.lastWorkoutDate,
        averageWorkoutDuration: additionalMetrics.averageWorkoutDuration,
        totalSets: userProgress.currentStats.totalSets,
      );
      
      debugPrint('Successfully loaded progress data');
      return ProgressDataResult.success(data);
      
    } on DatabaseException catch (e) {
      final errorMsg = 'Database error loading progress: ${e.toString()}';
      debugPrint(errorMsg);
      return ProgressDataResult.error(errorMsg);
    } catch (e) {
      final errorMsg = 'Unexpected error loading progress: ${e.toString()}';
      debugPrint(errorMsg);
      return ProgressDataResult.error(errorMsg);
    }
  }

  /// Get comprehensive progress data synchronously (returns empty data on error)
  Future<ProgressDashboardData> getProgressDataSync([String? userId]) async {
    final result = await getProgressData(userId);
    return result.data ?? ProgressDashboardData.empty();
  }

  /// Get or create user progress from database
  Future<UserProgress> _getUserProgress(String userId) async {
    try {
      // Try to get existing progress from database
      // For now, we'll create a mock progress since we don't have user persistence yet
      // TODO: Implement actual database storage for UserProgress
      
      final completedSessions = await _getCompletedWorkoutSessions(userId);
      
      if (completedSessions.isEmpty) {
        return UserProgress.initial(userId);
      }
      
      // Build UserProgress from workout sessions
      return _buildUserProgressFromSessions(userId, completedSessions);
    } catch (e) {
      debugPrint('Error getting user progress: $e');
      return UserProgress.initial(userId);
    }
  }

  /// Get completed workout sessions from database
  Future<List<WorkoutSession>> _getCompletedWorkoutSessions(String userId) async {
    try {
      final db = await _databaseHelper.database;
      
      // Query completed workouts based on actual database schema
      final List<Map<String, dynamic>> workoutMaps = await db.query(
        'workouts',
        where: 'user_id = ? AND status = ?',
        whereArgs: [userId, 2], // Status 2 = completed (based on WorkoutStatus.completed)
        orderBy: 'completed_at DESC',
      );
      
      // Convert to WorkoutSession objects with exercise sets
      List<WorkoutSession> sessions = [];
      
      for (final workoutMap in workoutMaps) {
        final workoutId = workoutMap['workout_id'] as String;
        
        // Get exercise sets for this workout
        final exerciseSets = await _getExerciseSetsForWorkout(db, workoutId);
        
        // Calculate body part volume map
        final bodyPartVolumeMap = <String, double>{};
        double totalVolume = 0.0;
        
        for (final exerciseSet in exerciseSets) {
          final volume = exerciseSet.calculateVolume();
          totalVolume += volume;
          
          for (final bodyPart in exerciseSet.bodyParts) {
            bodyPartVolumeMap[bodyPart] = (bodyPartVolumeMap[bodyPart] ?? 0.0) + volume;
          }
        }
        
        // Calculate duration
        final startTime = DateTime.parse(workoutMap['started_at'] ?? workoutMap['created_at']);
        final completedTime = DateTime.parse(workoutMap['completed_at'] ?? DateTime.now().toIso8601String());
        final duration = completedTime.difference(startTime);
        
        final session = WorkoutSession(
          sessionId: workoutId,
          userId: workoutMap['user_id'],
          startTime: startTime,
          endTime: completedTime,
          exerciseSets: exerciseSets,
          bodyPartVolumeMap: bodyPartVolumeMap,
          totalVolume: totalVolume,
          duration: duration,
          isCompleted: true,
          notes: workoutMap['notes'],
        );
        
        sessions.add(session);
      }
      
      return sessions;
    } catch (e) {
      debugPrint('Error getting completed workout sessions: $e');
      return [];
    }
  }

  /// Get exercise sets for a specific workout from database
  Future<List<ExerciseSet>> _getExerciseSetsForWorkout(Database db, String workoutId) async {
    try {
      // Query workout exercises for this workout
      final exerciseQuery = '''
        SELECT we.exercise_id, we.exercise_name, we.body_parts,
               ws.weight, ws.reps, ws.set_number, ws.completed_at, ws.notes as set_notes
        FROM workout_exercises we
        JOIN workout_sets ws ON we.workout_exercise_id = ws.workout_exercise_id
        WHERE we.workout_id = ? AND ws.is_completed = 1
        ORDER BY we.order_index, ws.set_number
      ''';
      
      final List<Map<String, dynamic>> setMaps = await db.rawQuery(exerciseQuery, [workoutId]);
      
      return setMaps.map((setMap) {
        // Parse body parts from JSON string
        List<String> bodyParts = [];
        if (setMap['body_parts'] != null) {
          final bodyPartsStr = setMap['body_parts'] as String;
          // Simple parsing - assuming comma-separated values for now
          bodyParts = bodyPartsStr.split(',').map((s) => s.trim()).toList();
        }
        
        return ExerciseSet(
          exerciseId: setMap['exercise_id'],
          exerciseName: setMap['exercise_name'],
          bodyParts: bodyParts,
          weight: setMap['weight']?.toDouble() ?? 0.0,
          reps: setMap['reps'] ?? 0,
          setNumber: setMap['set_number'] ?? 1,
          timestamp: DateTime.parse(setMap['completed_at'] ?? DateTime.now().toIso8601String()),
          notes: setMap['set_notes'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting exercise sets for workout $workoutId: $e');
      return [];
    }
  }

  /// Build UserProgress from workout sessions
  UserProgress _buildUserProgressFromSessions(String userId, List<WorkoutSession> sessions) {
    var progress = UserProgress.initial(userId);
    
    // Update progress with each completed session
    for (final session in sessions) {
      if (session.isCompleted) {
        progress = progress.updateWithSession(session);
      }
    }
    
    return progress;
  }

  /// Calculate additional metrics not stored in UserProgress
  _AdditionalMetrics _calculateAdditionalMetrics(List<WorkoutSession> sessions) {
    if (sessions.isEmpty) {
      return _AdditionalMetrics(averageWorkoutDuration: 0.0);
    }

    final completedSessions = sessions.where((s) => s.isCompleted).toList();
    
    if (completedSessions.isEmpty) {
      return _AdditionalMetrics(averageWorkoutDuration: 0.0);
    }

    // Calculate average workout duration
    final totalDuration = completedSessions.fold<Duration>(
      Duration.zero,
      (sum, session) => sum + session.duration,
    );
    
    final averageSeconds = totalDuration.inSeconds / completedSessions.length;
    
    return _AdditionalMetrics(averageWorkoutDuration: averageSeconds);
  }

  /// Generate training insights for the dashboard
  _TrainingInsights _generateTrainingInsights(Map<String, BodyPartProgress> bodyPartProgress) {
    final closeToLevelUp = <String>[];
    final needsAttention = <String>[];
    
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(Duration(days: 7));
    
    for (final entry in bodyPartProgress.entries) {
      final bodyPart = entry.key;
      final progress = entry.value;
      
      // Check if close to level up (>70% progress)
      if (progress.progressPercentage > 0.7) {
        closeToLevelUp.add(bodyPart);
      }
      
      // Check if needs attention (not worked in 7+ days)
      if (progress.lastWorked.isBefore(sevenDaysAgo)) {
        needsAttention.add(bodyPart);
      }
    }
    
    return _TrainingInsights(
      closeToLevelUp: closeToLevelUp,
      needsAttention: needsAttention,
    );
  }

  /// Calculate body part heat map intensities for visualization
  Future<Map<String, double>> getBodyPartHeatMap([String? userId]) async {
    final effectiveUserId = userId ?? _defaultUserId;
    final userProgress = await _getUserProgress(effectiveUserId);
    
    final heatMap = <String, double>{};
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(Duration(days: 7));
    
    // Calculate heat intensity based on recent activity
    for (final entry in userProgress.bodyPartProgress.entries) {
      final bodyPart = entry.key;
      final progress = entry.value;
      
      // Calculate days since last worked
      final daysSinceLastWorked = now.difference(progress.lastWorked).inDays;
      
      // Calculate intensity: 1.0 = worked today, 0.0 = not worked in 7+ days
      double intensity;
      if (daysSinceLastWorked <= 0) {
        intensity = 1.0; // Worked today
      } else if (daysSinceLastWorked >= 7) {
        intensity = 0.0; // Not worked in 7+ days
      } else {
        intensity = 1.0 - (daysSinceLastWorked / 7.0); // Linear fade over 7 days
      }
      
      heatMap[bodyPart] = intensity;
    }
    
    return heatMap;
  }

  /// Dispose of resources
  void dispose() {
    // Clean up any resources if needed
    _databaseHelper.close();
  }
}

/// Helper class for additional metrics
class _AdditionalMetrics {
  final double averageWorkoutDuration;
  
  _AdditionalMetrics({required this.averageWorkoutDuration});
}

/// Helper class for training insights
class _TrainingInsights {
  final List<String> closeToLevelUp;
  final List<String> needsAttention;
  
  _TrainingInsights({
    required this.closeToLevelUp,
    required this.needsAttention,
  });
}