import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import '../models/workout.dart';
import 'database_helper.dart';

/// Repository pattern for workout data operations
/// Provides clean abstraction layer over SQLite database operations
class WorkoutRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Save a new workout to the database
  Future<String> saveWorkout(Workout workout) async {
    debugPrint('💾 Saving workout: ${workout.name}');
    debugPrint('📊 Workout has ${workout.exercises.length} exercises');
    
    final db = await _dbHelper.database;
    
    await db.transaction((txn) async {
      // Insert main workout record
      await txn.insert(
        DatabaseHelper.tableWorkouts, 
        workout.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('✅ Workout record saved');
      
      // Insert workout exercises
      debugPrint('💾 Saving ${workout.exercises.length} workout exercises...');
      for (final exercise in workout.exercises) {
        final exerciseId = _dbHelper.generateWorkoutExerciseId(
          workout.workoutId, 
          exercise.exerciseId
        );
        
        debugPrint('  Saving exercise: ${exercise.exerciseName} (ID: ${exercise.exerciseId})');
        
        await txn.insert(
          DatabaseHelper.tableWorkoutExercises,
          exercise.toMap()..['workout_exercise_id'] = exerciseId,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        
        // Insert workout sets
        for (final set in exercise.sets) {
          await txn.insert(
            DatabaseHelper.tableWorkoutSets,
            set.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
    
    debugPrint('🎉 Workout saved successfully: ${workout.workoutId}');
    return workout.workoutId;
  }

  /// Load a specific workout by ID with all exercises and sets
  Future<Workout?> getWorkout(String workoutId) async {
    debugPrint('📥 Loading workout: $workoutId');
    
    final db = await _dbHelper.database;
    
    // Get main workout record
    final workoutMaps = await db.query(
      DatabaseHelper.tableWorkouts,
      where: 'workout_id = ?',
      whereArgs: [workoutId],
    );
    
    if (workoutMaps.isEmpty) {
      debugPrint('❌ Workout not found: $workoutId');
      return null;
    }
    
    debugPrint('✅ Workout record found');
    
    // Get workout exercises
    final exerciseMaps = await db.query(
      DatabaseHelper.tableWorkoutExercises,
      where: 'workout_id = ?',
      whereArgs: [workoutId],
      orderBy: 'order_index ASC',
    );
    
    debugPrint('📋 Found ${exerciseMaps.length} workout exercises');
    
    final List<WorkoutExercise> exercises = [];
    
    for (final exerciseMap in exerciseMaps) {
      final exerciseId = exerciseMap['workout_exercise_id'] as String;
      final exerciseName = exerciseMap['exercise_name'] as String;
      
      debugPrint('  Loading exercise: $exerciseName (ID: ${exerciseMap['exercise_id']})');
      
      // Get sets for this exercise
      final setMaps = await db.query(
        DatabaseHelper.tableWorkoutSets,
        where: 'workout_exercise_id = ?',
        whereArgs: [exerciseId],
        orderBy: 'set_number ASC',
      );
      
      final sets = setMaps.map((setMap) => WorkoutSet.fromMap(setMap)).toList();
      final exercise = WorkoutExercise.fromMap(exerciseMap, sets: sets);
      exercises.add(exercise);
    }
    
    final workout = Workout.fromMap(workoutMaps.first, exercises: exercises);
    debugPrint('🎉 Workout loaded successfully with ${workout.exercises.length} exercises');
    
    return workout;
  }

  /// Get all workouts for a user, optionally filtered by status
  Future<List<Workout>> getWorkouts({
    required String userId,
    WorkoutStatus? status,
    int? limit,
    int? offset,
  }) async {
    final db = await _dbHelper.database;
    
    String whereClause = 'user_id = ?';
    List<dynamic> whereArgs = [userId];
    
    if (status != null) {
      whereClause += ' AND status = ?';
      whereArgs.add(status.index);
    }
    
    final workoutMaps = await db.query(
      DatabaseHelper.tableWorkouts,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
    
    final List<Workout> workouts = [];
    
    // Load each workout with its exercises (lightweight version)
    for (final workoutMap in workoutMaps) {
      final workoutId = workoutMap['workout_id'] as String;
      final workout = await getWorkout(workoutId);
      if (workout != null) {
        workouts.add(workout);
      }
    }
    
    return workouts;
  }

  /// Get workouts for a specific date range
  Future<List<Workout>> getWorkoutsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _dbHelper.database;
    
    final workoutMaps = await db.query(
      DatabaseHelper.tableWorkouts,
      where: 'user_id = ? AND created_at >= ? AND created_at <= ?',
      whereArgs: [
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'created_at DESC',
    );
    
    final List<Workout> workouts = [];
    
    for (final workoutMap in workoutMaps) {
      final workoutId = workoutMap['workout_id'] as String;
      final workout = await getWorkout(workoutId);
      if (workout != null) {
        workouts.add(workout);
      }
    }
    
    return workouts;
  }

  /// Update an existing workout
  Future<void> updateWorkout(Workout workout) async {
    final db = await _dbHelper.database;
    
    await db.transaction((txn) async {
      // Update main workout record
      await txn.update(
        DatabaseHelper.tableWorkouts,
        workout.toMap(),
        where: 'workout_id = ?',
        whereArgs: [workout.workoutId],
      );
      
      // Delete existing exercises and sets for this workout
      await _deleteWorkoutExercisesAndSets(txn, workout.workoutId);
      
      // Insert updated exercises and sets
      for (final exercise in workout.exercises) {
        final exerciseId = _dbHelper.generateWorkoutExerciseId(
          workout.workoutId, 
          exercise.exerciseId
        );
        
        await txn.insert(
          DatabaseHelper.tableWorkoutExercises,
          exercise.toMap()..['workout_exercise_id'] = exerciseId,
        );
        
        for (final set in exercise.sets) {
          await txn.insert(
            DatabaseHelper.tableWorkoutSets,
            set.toMap(),
          );
        }
      }
    });
  }

  /// Delete a workout and all associated data
  Future<void> deleteWorkout(String workoutId) async {
    final db = await _dbHelper.database;
    
    await db.transaction((txn) async {
      // Delete sets first (foreign key cascade should handle this, but being explicit)
      await _deleteWorkoutExercisesAndSets(txn, workoutId);
      
      // Delete main workout record
      await txn.delete(
        DatabaseHelper.tableWorkouts,
        where: 'workout_id = ?',
        whereArgs: [workoutId],
      );
    });
  }

  /// Helper method to delete exercises and sets for a workout
  Future<void> _deleteWorkoutExercisesAndSets(Transaction txn, String workoutId) async {
    // Get all exercise IDs for this workout
    final exerciseMaps = await txn.query(
      DatabaseHelper.tableWorkoutExercises,
      columns: ['workout_exercise_id'],
      where: 'workout_id = ?',
      whereArgs: [workoutId],
    );
    
    // Delete sets for each exercise
    for (final exerciseMap in exerciseMaps) {
      final exerciseId = exerciseMap['workout_exercise_id'] as String;
      await txn.delete(
        DatabaseHelper.tableWorkoutSets,
        where: 'workout_exercise_id = ?',
        whereArgs: [exerciseId],
      );
    }
    
    // Delete exercises
    await txn.delete(
      DatabaseHelper.tableWorkoutExercises,
      where: 'workout_id = ?',
      whereArgs: [workoutId],
    );
  }

  /// Start a workout (update status and set start time)
  Future<void> startWorkout(String workoutId) async {
    final db = await _dbHelper.database;
    
    await db.update(
      DatabaseHelper.tableWorkouts,
      {
        'status': WorkoutStatus.inProgress.index,
        'started_at': DateTime.now().toIso8601String(),
      },
      where: 'workout_id = ?',
      whereArgs: [workoutId],
    );
  }

  /// Complete a workout (update status and set completion time)
  Future<void> completeWorkout(String workoutId) async {
    final db = await _dbHelper.database;
    
    await db.update(
      DatabaseHelper.tableWorkouts,
      {
        'status': WorkoutStatus.completed.index,
        'completed_at': DateTime.now().toIso8601String(),
      },
      where: 'workout_id = ?',
      whereArgs: [workoutId],
    );
  }

  /// Cancel a workout
  Future<void> cancelWorkout(String workoutId) async {
    final db = await _dbHelper.database;
    
    await db.update(
      DatabaseHelper.tableWorkouts,
      {
        'status': WorkoutStatus.cancelled.index,
      },
      where: 'workout_id = ?',
      whereArgs: [workoutId],
    );
  }

  /// Get workout statistics for a user
  Future<WorkoutStats> getWorkoutStats(String userId) async {
    final db = await _dbHelper.database;
    
    // Get basic counts
    final totalWorkouts = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM ${DatabaseHelper.tableWorkouts} WHERE user_id = ?',
      [userId],
    )) ?? 0;
    
    final completedWorkouts = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM ${DatabaseHelper.tableWorkouts} WHERE user_id = ? AND status = ?',
      [userId, WorkoutStatus.completed.index],
    )) ?? 0;
    
    // Get total volume (only from completed workouts)
    final totalVolumeResult = await db.rawQuery('''
      SELECT SUM(ws.weight * ws.reps) as total_volume
      FROM ${DatabaseHelper.tableWorkoutSets} ws
      INNER JOIN ${DatabaseHelper.tableWorkoutExercises} we ON ws.workout_exercise_id = we.workout_exercise_id
      INNER JOIN ${DatabaseHelper.tableWorkouts} w ON we.workout_id = w.workout_id
      WHERE w.user_id = ? AND w.status = ? AND ws.is_completed = 1
    ''', [userId, WorkoutStatus.completed.index]);
    
    final totalVolume = (totalVolumeResult.first['total_volume'] as double?) ?? 0.0;
    
    // Get average workout duration
    final avgDurationResult = await db.rawQuery('''
      SELECT AVG(
        CASE 
          WHEN started_at IS NOT NULL AND completed_at IS NOT NULL
          THEN (julianday(completed_at) - julianday(started_at)) * 24 * 60
          ELSE planned_duration_minutes
        END
      ) as avg_duration
      FROM ${DatabaseHelper.tableWorkouts}
      WHERE user_id = ? AND status = ?
    ''', [userId, WorkoutStatus.completed.index]);
    
    final avgDuration = (avgDurationResult.first['avg_duration'] as double?) ?? 0.0;
    
    return WorkoutStats(
      totalWorkouts: totalWorkouts,
      completedWorkouts: completedWorkouts,
      totalVolume: totalVolume,
      averageDurationMinutes: avgDuration,
    );
  }

  /// Get volume by body part for progress tracking
  Future<Map<String, double>> getVolumeByBodyPart(String userId) async {
    final db = await _dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT we.body_parts, SUM(ws.weight * ws.reps) as volume
      FROM ${DatabaseHelper.tableWorkoutSets} ws
      INNER JOIN ${DatabaseHelper.tableWorkoutExercises} we ON ws.workout_exercise_id = we.workout_exercise_id
      INNER JOIN ${DatabaseHelper.tableWorkouts} w ON we.workout_id = w.workout_id
      WHERE w.user_id = ? AND w.status = ? AND ws.is_completed = 1
      GROUP BY we.body_parts
    ''', [userId, WorkoutStatus.completed.index]);
    
    final Map<String, double> volumeByBodyPart = {};
    
    for (final row in result) {
      final bodyPartsString = row['body_parts'] as String?;
      final volume = (row['volume'] as double?) ?? 0.0;
      
      if (bodyPartsString != null) {
        // Parse comma-separated body parts
        final bodyParts = bodyPartsString.split(',').map((s) => s.trim()).toList();
        
        // Distribute volume across body parts (if exercise targets multiple)
        final volumePerBodyPart = volume / bodyParts.length;
        
        for (final bodyPart in bodyParts) {
          volumeByBodyPart[bodyPart] = (volumeByBodyPart[bodyPart] ?? 0.0) + volumePerBodyPart;
        }
      }
    }
    
    return volumeByBodyPart;
  }

  /// Close database connection
  Future<void> close() async {
    await _dbHelper.close();
  }
}

/// Workout statistics data class
class WorkoutStats {
  final int totalWorkouts;
  final int completedWorkouts;
  final double totalVolume;
  final double averageDurationMinutes;

  const WorkoutStats({
    required this.totalWorkouts,
    required this.completedWorkouts,
    required this.totalVolume,
    required this.averageDurationMinutes,
  });

  double get completionRate {
    if (totalWorkouts == 0) return 0.0;
    return completedWorkouts / totalWorkouts;
  }

  String get formattedTotalVolume {
    if (totalVolume >= 1000) {
      return '${(totalVolume / 1000).toStringAsFixed(1)}k kg';
    }
    return '${totalVolume.toStringAsFixed(0)} kg';
  }

  String get formattedAvgDuration {
    return '${averageDurationMinutes.toStringAsFixed(0)}min';
  }
}