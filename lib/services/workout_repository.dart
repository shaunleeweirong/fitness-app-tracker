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
    debugPrint('💾 [SAVE_WORKOUT] Starting to save workout: ${workout.name}');
    debugPrint('📊 [SAVE_WORKOUT] Workout has ${workout.exercises.length} exercises');
    debugPrint('🔍 [SAVE_WORKOUT] Workout ID: ${workout.workoutId}');
    debugPrint('🔍 [SAVE_WORKOUT] Workout status: ${workout.status}');
    debugPrint('🔍 [SAVE_WORKOUT] Target body parts: ${workout.targetBodyParts}');
    
    // Log each exercise being saved
    for (var i = 0; i < workout.exercises.length; i++) {
      final exercise = workout.exercises[i];
      debugPrint('📝 [SAVE_WORKOUT] Exercise $i: ${exercise.exerciseName}');
      debugPrint('📝 [SAVE_WORKOUT]   Exercise ID: ${exercise.exerciseId}');
      debugPrint('📝 [SAVE_WORKOUT]   Body parts: ${exercise.bodyParts}');
      debugPrint('📝 [SAVE_WORKOUT]   Sets: ${exercise.sets.length}');
    }
    
    final db = await _dbHelper.database;
    
    await db.transaction((txn) async {
      // Insert main workout record
      await txn.insert(
        DatabaseHelper.tableWorkouts, 
        workout.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('✅ [SAVE_WORKOUT] Main workout record saved');
      
      // Insert workout exercises
      debugPrint('💾 [SAVE_WORKOUT] Saving ${workout.exercises.length} workout exercises...');
      for (var i = 0; i < workout.exercises.length; i++) {
        final exercise = workout.exercises[i];
        final exerciseId = _dbHelper.generateWorkoutExerciseId(
          workout.workoutId, 
          exercise.exerciseId
        );
        
        debugPrint('💾 [SAVE_WORKOUT] Saving exercise $i: ${exercise.exerciseName}');
        debugPrint('💾 [SAVE_WORKOUT]   Generated workout_exercise_id: $exerciseId');
        debugPrint('💾 [SAVE_WORKOUT]   Original exercise_id: ${exercise.exerciseId}');
        debugPrint('💾 [SAVE_WORKOUT]   Body parts: ${exercise.bodyParts}');
        
        final exerciseMap = exercise.toMap();
        exerciseMap['workout_exercise_id'] = exerciseId;
        exerciseMap['workout_id'] = workout.workoutId; // FIX: Set the workout_id properly
        
        debugPrint('💾 [SAVE_WORKOUT]   Exercise map keys: ${exerciseMap.keys.toList()}');
        debugPrint('💾 [SAVE_WORKOUT]   Exercise map workout_id value: ${exerciseMap['workout_id']}');
        debugPrint('💾 [SAVE_WORKOUT]   Full exercise map: $exerciseMap');
        
        await txn.insert(
          DatabaseHelper.tableWorkoutExercises,
          exerciseMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        
        debugPrint('✅ [SAVE_WORKOUT] Exercise $i saved successfully');
        
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
    
    debugPrint('🎉 [SAVE_WORKOUT] Transaction completed successfully');
    debugPrint('✅ [SAVE_WORKOUT] Workout saved with ${workout.exercises.length} exercises');
    return workout.workoutId;
  }

  /// Load a specific workout by ID with all exercises and sets
  Future<Workout?> getWorkout(String workoutId) async {
    debugPrint('📥 [LOAD_WORKOUT] Starting to load workout: $workoutId');
    
    final db = await _dbHelper.database;
    
    // Get main workout record
    final workoutMaps = await db.query(
      DatabaseHelper.tableWorkouts,
      where: 'workout_id = ?',
      whereArgs: [workoutId],
    );
    
    if (workoutMaps.isEmpty) {
      debugPrint('❌ [LOAD_WORKOUT] Workout not found: $workoutId');
      return null;
    }
    
    debugPrint('✅ [LOAD_WORKOUT] Main workout record found');
    final workoutMap = workoutMaps.first;
    debugPrint('🔍 [LOAD_WORKOUT] Workout name: ${workoutMap['name']}');
    debugPrint('🔍 [LOAD_WORKOUT] Workout status: ${workoutMap['status']}');
    
    // Get workout exercises
    debugPrint('🔍 [LOAD_WORKOUT] Querying workout exercises...');
    debugPrint('🔍 [LOAD_WORKOUT] Table: ${DatabaseHelper.tableWorkoutExercises}');
    debugPrint('🔍 [LOAD_WORKOUT] WHERE clause: workout_id = ?');
    debugPrint('🔍 [LOAD_WORKOUT] Parameter: $workoutId');
    
    final exerciseMaps = await db.query(
      DatabaseHelper.tableWorkoutExercises,
      where: 'workout_id = ?',
      whereArgs: [workoutId],
      orderBy: 'order_index ASC',
    );
    
    debugPrint('🔍 [LOAD_WORKOUT] Raw query result: ${exerciseMaps.length} rows');
    if (exerciseMaps.isNotEmpty) {
      debugPrint('🔍 [LOAD_WORKOUT] First row keys: ${exerciseMaps.first.keys.toList()}');
      debugPrint('🔍 [LOAD_WORKOUT] First row data: ${exerciseMaps.first}');
    }
    
    debugPrint('📋 [LOAD_WORKOUT] Found ${exerciseMaps.length} workout exercises in database');
    
    if (exerciseMaps.isEmpty) {
      debugPrint('⚠️ [LOAD_WORKOUT] WARNING: No exercises found for workout $workoutId');
    }
    
    final List<WorkoutExercise> exercises = [];
    
    for (var i = 0; i < exerciseMaps.length; i++) {
      final exerciseMap = exerciseMaps[i];
      final exerciseId = exerciseMap['workout_exercise_id'] as String;
      final exerciseName = exerciseMap['exercise_name'] as String;
      final originalExerciseId = exerciseMap['exercise_id'] as String;
      
      debugPrint('📋 [LOAD_WORKOUT] Loading exercise $i: $exerciseName');
      debugPrint('📋 [LOAD_WORKOUT]   workout_exercise_id: $exerciseId');
      debugPrint('📋 [LOAD_WORKOUT]   original exercise_id: $originalExerciseId');
      debugPrint('📋 [LOAD_WORKOUT]   exercise map keys: ${exerciseMap.keys.toList()}');
      
      // Get sets for this exercise
      final setMaps = await db.query(
        DatabaseHelper.tableWorkoutSets,
        where: 'workout_exercise_id = ?',
        whereArgs: [exerciseId],
        orderBy: 'set_number ASC',
      );
      
      debugPrint('📋 [LOAD_WORKOUT]   Found ${setMaps.length} sets for exercise $i');
      
      final sets = setMaps.map((setMap) => WorkoutSet.fromMap(setMap)).toList();
      final exercise = WorkoutExercise.fromMap(exerciseMap, sets: sets);
      exercises.add(exercise);
      
      debugPrint('✅ [LOAD_WORKOUT] Exercise $i loaded successfully');
    }
    
    debugPrint('🎯 [LOAD_WORKOUT] Creating final workout object...');
    final workout = Workout.fromMap(workoutMaps.first, exercises: exercises);
    debugPrint('🎯 [LOAD_WORKOUT] Final workout created with ${workout.exercises.length} exercises');
    debugPrint('🎉 [LOAD_WORKOUT] Workout loaded successfully with ${workout.exercises.length} exercises');
    
    // Log final workout exercises for verification
    for (var i = 0; i < workout.exercises.length; i++) {
      final exercise = workout.exercises[i];
      debugPrint('🎯 [LOAD_WORKOUT] Final exercise $i: ${exercise.exerciseName}');
    }
    
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
    debugPrint('🔄 UPDATING WORKOUT: ${workout.name} (ID: ${workout.workoutId})');
    debugPrint('   Total exercises to save: ${workout.exercises.length}');
    
    // Log all exercises being updated
    for (int i = 0; i < workout.exercises.length; i++) {
      final ex = workout.exercises[i];
      debugPrint('   Exercise ${i + 1}: ${ex.exerciseName} (ID: ${ex.exerciseId}) - ${ex.sets.length} sets');
    }
    
    // Check for duplicate exercise IDs in the workout
    final exerciseIds = workout.exercises.map((e) => e.exerciseId).toList();
    final uniqueIds = exerciseIds.toSet();
    if (exerciseIds.length != uniqueIds.length) {
      debugPrint('🚨 CRITICAL ERROR: Found duplicate exercise IDs in workout!');
      final duplicateIds = <String>[];
      for (final id in exerciseIds) {
        if (exerciseIds.where((x) => x == id).length > 1 && !duplicateIds.contains(id)) {
          duplicateIds.add(id);
        }
      }
      for (final dupId in duplicateIds) {
        final count = exerciseIds.where((x) => x == dupId).length;
        debugPrint('   Duplicate ID "$dupId" appears $count times');
      }
    }
    
    final db = await _dbHelper.database;
    
    try {
      await db.transaction((txn) async {
        debugPrint('📝 Starting database transaction...');
        
        // Update main workout record
        debugPrint('📝 Updating main workout record...');
        await txn.update(
          DatabaseHelper.tableWorkouts,
          workout.toMap(),
          where: 'workout_id = ?',
          whereArgs: [workout.workoutId],
        );
        debugPrint('✅ Main workout record updated');
        
        // Delete existing exercises and sets for this workout
        debugPrint('🗑️  Deleting existing exercises and sets...');
        await _deleteWorkoutExercisesAndSets(txn, workout.workoutId);
        debugPrint('✅ Existing exercises and sets deleted');
        
        // Insert updated exercises and sets
        debugPrint('💾 Inserting ${workout.exercises.length} updated exercises...');
        for (int i = 0; i < workout.exercises.length; i++) {
          final exercise = workout.exercises[i];
          final exerciseId = _dbHelper.generateWorkoutExerciseId(
            workout.workoutId, 
            exercise.exerciseId
          );
          
          debugPrint('   Inserting exercise ${i + 1}: ${exercise.exerciseName}');
          debugPrint('     Generated workout_exercise_id: $exerciseId');
          debugPrint('     Exercise ID: ${exercise.exerciseId}');
          debugPrint('     Workout ID: ${exercise.workoutId}');
          
          try {
            await txn.insert(
              DatabaseHelper.tableWorkoutExercises,
              exercise.toMap()..['workout_exercise_id'] = exerciseId,
            );
            debugPrint('     ✅ Exercise inserted successfully');
            
            debugPrint('     💾 Inserting ${exercise.sets.length} sets...');
            for (int j = 0; j < exercise.sets.length; j++) {
              final set = exercise.sets[j];
              debugPrint('       Set ${j + 1}: ${set.weight}kg x ${set.reps} (ID: ${set.workoutExerciseId})');
              
              await txn.insert(
                DatabaseHelper.tableWorkoutSets,
                set.toMap(),
              );
              debugPrint('       ✅ Set ${j + 1} inserted');
            }
            debugPrint('     ✅ All sets inserted for ${exercise.exerciseName}');
            
          } catch (e) {
            debugPrint('     ❌ FAILED to insert exercise ${exercise.exerciseName}: $e');
            debugPrint('     📊 Exercise data: ${exercise.toMap()}');
            rethrow;
          }
        }
        
        debugPrint('✅ All exercises and sets inserted successfully');
        debugPrint('✅ Database transaction completed');
      });
      
      debugPrint('🎉 WORKOUT UPDATE COMPLETED: ${workout.name}');
      
    } catch (e) {
      debugPrint('❌ WORKOUT UPDATE FAILED: $e');
      debugPrint('📊 Failed workout data: ${workout.toMap()}');
      rethrow;
    }
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

  /// Get workout summaries with optimized single-query approach
  /// Replaces the heavy getWorkouts method for list displays
  Future<List<WorkoutSummary>> getWorkoutSummaries({
    required String userId,
    WorkoutStatus? status,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    debugPrint('📊 [REPO] Loading workout summaries for user: $userId');
    debugPrint('📊 [REPO] Filters - Status: $status, Search: $searchQuery, Limit: $limit');
    
    final db = await _dbHelper.database;
    
    // Build WHERE clause
    final whereConditions = <String>['w.user_id = ?'];
    final whereArgs = <dynamic>[userId];
    
    if (status != null) {
      whereConditions.add('w.status = ?');
      whereArgs.add(status.index);
    }
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereConditions.add('(w.name LIKE ? OR w.notes LIKE ?)');
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }
    
    // Optimized query with aggregated exercise and set statistics
    final query = '''
      SELECT 
        w.*,
        COALESCE(exercise_stats.exercise_count, 0) as exercise_count,
        COALESCE(set_stats.total_sets, 0) as total_sets,
        COALESCE(set_stats.completed_sets, 0) as completed_sets,
        COALESCE(set_stats.total_volume, 0.0) as total_volume
      FROM ${DatabaseHelper.tableWorkouts} w
      LEFT JOIN (
        SELECT 
          workout_id,
          COUNT(*) as exercise_count
        FROM ${DatabaseHelper.tableWorkoutExercises}
        GROUP BY workout_id
      ) exercise_stats ON w.workout_id = exercise_stats.workout_id
      LEFT JOIN (
        SELECT 
          we.workout_id,
          COUNT(ws.set_number) as total_sets,
          SUM(CASE WHEN ws.is_completed = 1 THEN 1 ELSE 0 END) as completed_sets,
          SUM(CASE WHEN ws.is_completed = 1 THEN ws.weight * ws.reps ELSE 0 END) as total_volume
        FROM ${DatabaseHelper.tableWorkoutExercises} we
        LEFT JOIN ${DatabaseHelper.tableWorkoutSets} ws ON we.workout_exercise_id = ws.workout_exercise_id
        GROUP BY we.workout_id
      ) set_stats ON w.workout_id = set_stats.workout_id
      WHERE ${whereConditions.join(' AND ')}
      ORDER BY w.created_at DESC
      ${limit != null ? 'LIMIT $limit' : ''}
      ${offset != null ? 'OFFSET $offset' : ''}
    ''';
    
    debugPrint('🔍 [REPO] Executing optimized summary query...');
    final results = await db.rawQuery(query, whereArgs);
    
    debugPrint('✅ [REPO] Query returned ${results.length} workout summaries');
    
    final summaries = results.map((row) => WorkoutSummary.fromDatabaseRow(row)).toList();
    
    if (summaries.isNotEmpty) {
      debugPrint('📊 [REPO] First summary: ${summaries.first.name} (${summaries.first.exerciseCount} exercises)');
    }
    
    return summaries;
  }

  /// Get recent workout summaries with default 30-day time filtering
  /// Optimized for performance to prevent large dataset issues
  Future<List<WorkoutSummary>> getRecentWorkoutSummaries({
    required String userId,
    WorkoutStatus? status,
    String? searchQuery,
    int? limit,
    int daysBack = 30,
  }) async {
    debugPrint('📅 [REPO] Loading recent summaries: $daysBack days back');
    
    final db = await _dbHelper.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysBack));
    
    // Build WHERE clause with time filtering
    final whereConditions = <String>['w.user_id = ?', 'w.created_at >= ?'];
    final whereArgs = <dynamic>[userId, cutoffDate.toIso8601String()];
    
    if (status != null) {
      whereConditions.add('w.status = ?');
      whereArgs.add(status.index);
    }
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereConditions.add('(w.name LIKE ? OR w.notes LIKE ?)');
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }
    
    final query = '''
      SELECT 
        w.*,
        COALESCE(exercise_stats.exercise_count, 0) as exercise_count,
        COALESCE(set_stats.total_sets, 0) as total_sets,
        COALESCE(set_stats.completed_sets, 0) as completed_sets,
        COALESCE(set_stats.total_volume, 0.0) as total_volume
      FROM ${DatabaseHelper.tableWorkouts} w
      LEFT JOIN (
        SELECT 
          workout_id,
          COUNT(*) as exercise_count
        FROM ${DatabaseHelper.tableWorkoutExercises}
        GROUP BY workout_id
      ) exercise_stats ON w.workout_id = exercise_stats.workout_id
      LEFT JOIN (
        SELECT 
          we.workout_id,
          COUNT(ws.set_number) as total_sets,
          SUM(CASE WHEN ws.is_completed = 1 THEN 1 ELSE 0 END) as completed_sets,
          SUM(CASE WHEN ws.is_completed = 1 THEN ws.weight * ws.reps ELSE 0 END) as total_volume
        FROM ${DatabaseHelper.tableWorkoutExercises} we
        LEFT JOIN ${DatabaseHelper.tableWorkoutSets} ws ON we.workout_exercise_id = ws.workout_exercise_id
        GROUP BY we.workout_id
      ) set_stats ON w.workout_id = set_stats.workout_id
      WHERE ${whereConditions.join(' AND ')}
      ORDER BY w.created_at DESC
      ${limit != null ? 'LIMIT $limit' : ''}
    ''';
    
    final results = await db.rawQuery(query, whereArgs);
    debugPrint('✅ [REPO] Recent query returned ${results.length} summaries');
    
    return results.map((row) => WorkoutSummary.fromDatabaseRow(row)).toList();
  }

  /// Get paginated workout summaries for infinite scroll
  /// Uses page-based approach instead of offset for better performance
  Future<List<WorkoutSummary>> getPaginatedWorkoutSummaries({
    required String userId,
    WorkoutStatus? status,
    String? searchQuery,
    int page = 1,
    int pageSize = 20,
  }) async {
    debugPrint('📄 [REPO] Loading page $page (size: $pageSize)');
    
    final offset = (page - 1) * pageSize;
    
    return await getWorkoutSummaries(
      userId: userId,
      status: status,
      searchQuery: searchQuery,
      limit: pageSize,
      offset: offset,
    );
  }

  /// Enhanced getWorkoutStats with optional time filtering
  Future<WorkoutStats> getWorkoutStatsEnhanced(String userId, {int? daysBack}) async {
    debugPrint('📈 [REPO] Loading enhanced workout stats (${daysBack != null ? '$daysBack days' : 'all time'})');
    
    final db = await _dbHelper.database;
    
    // Build WHERE clause with optional time filtering
    final whereConditions = <String>['w.user_id = ?'];
    final whereArgs = <dynamic>[userId];
    
    if (daysBack != null) {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysBack));
      whereConditions.add('w.created_at >= ?');
      whereArgs.add(cutoffDate.toIso8601String());
    }
    
    final statsQuery = '''
      SELECT 
        COUNT(*) as total_workouts,
        SUM(CASE WHEN w.status = ${WorkoutStatus.completed.index} THEN 1 ELSE 0 END) as completed_workouts,
        SUM(CASE WHEN w.status = ${WorkoutStatus.inProgress.index} THEN 1 ELSE 0 END) as in_progress_workouts,
        COALESCE(SUM(volume_stats.total_volume), 0.0) as total_volume,
        COALESCE(SUM(set_stats.total_sets), 0) as total_sets,
        COALESCE(AVG(
          CASE 
            WHEN w.status = ${WorkoutStatus.completed.index} AND w.started_at IS NOT NULL AND w.completed_at IS NOT NULL
            THEN (julianday(w.completed_at) - julianday(w.started_at)) * 24 * 60
            ELSE w.planned_duration_minutes
          END
        ), 0.0) as avg_duration_minutes
      FROM ${DatabaseHelper.tableWorkouts} w
      LEFT JOIN (
        SELECT 
          we.workout_id,
          SUM(CASE WHEN ws.is_completed = 1 THEN ws.weight * ws.reps ELSE 0 END) as total_volume
        FROM ${DatabaseHelper.tableWorkoutExercises} we
        LEFT JOIN ${DatabaseHelper.tableWorkoutSets} ws ON we.workout_exercise_id = ws.workout_exercise_id
        GROUP BY we.workout_id
      ) volume_stats ON w.workout_id = volume_stats.workout_id
      LEFT JOIN (
        SELECT 
          we.workout_id,
          COUNT(ws.set_number) as total_sets
        FROM ${DatabaseHelper.tableWorkoutExercises} we
        LEFT JOIN ${DatabaseHelper.tableWorkoutSets} ws ON we.workout_exercise_id = ws.workout_exercise_id
        GROUP BY we.workout_id
      ) set_stats ON w.workout_id = set_stats.workout_id
      WHERE ${whereConditions.join(' AND ')}
    ''';
    
    final result = await db.rawQuery(statsQuery, whereArgs);
    
    if (result.isEmpty) {
      return const WorkoutStats(
        totalWorkouts: 0,
        completedWorkouts: 0,
        totalVolume: 0.0,
        averageDurationMinutes: 0.0,
      );
    }
    
    final data = result.first;
    debugPrint('✅ [REPO] Stats loaded: ${data['total_workouts']} total workouts');
    
    return WorkoutStats(
      totalWorkouts: data['total_workouts'] as int? ?? 0,
      completedWorkouts: data['completed_workouts'] as int? ?? 0,
      totalVolume: (data['total_volume'] as num?)?.toDouble() ?? 0.0,
      averageDurationMinutes: (data['avg_duration_minutes'] as num?)?.toDouble() ?? 0.0,
    );
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