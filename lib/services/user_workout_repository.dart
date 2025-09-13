import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import '../models/workout.dart';
import 'database_helper.dart';

/// Repository for user's personal workout storage with template preservation
/// Implements Option 1: Create Personal Copy approach for template customization
class UserWorkoutRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Save a user's customized workout to the database
  Future<String> saveUserWorkout(UserWorkout userWorkout) async {
    print('💾 [USER_WORKOUT_REPO] Saving user workout: ${userWorkout.name}');
    print('💾 [USER_WORKOUT_REPO] Workout ID: ${userWorkout.userWorkoutId}');
    print('💾 [USER_WORKOUT_REPO] Base template: ${userWorkout.baseTemplateId}');
    print('💾 [USER_WORKOUT_REPO] Exercise count: ${userWorkout.exercises.length}');
    print('💾 [USER_WORKOUT_REPO] Source: ${userWorkout.source}');
    
    final db = await _dbHelper.database;
    
    try {
      await db.transaction((txn) async {
        // Insert main user workout record
        print('💾 [USER_WORKOUT_REPO] Inserting main workout record...');
        await txn.insert(
          'user_workouts', 
          _userWorkoutToMap(userWorkout),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('✅ [USER_WORKOUT_REPO] Main workout record saved');
        
        // Insert user exercises
        print('💾 [USER_WORKOUT_REPO] Saving ${userWorkout.exercises.length} user exercises...');
        for (final exercise in userWorkout.exercises) {
          print('💾 [USER_WORKOUT_REPO]   Saving exercise: ${exercise.exerciseName}');
          
          await txn.insert(
            'user_workout_exercises',
            _userExerciseToMap(exercise, userWorkout.userWorkoutId),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        print('✅ [USER_WORKOUT_REPO] All exercises saved');
        
        // Save modifications if present
        if (userWorkout.modifications != null) {
          print('💾 [USER_WORKOUT_REPO] Saving workout modifications...');
          await _saveWorkoutCustomizations(txn, userWorkout);
          print('✅ [USER_WORKOUT_REPO] Modifications saved');
        }
      });
      
      print('✅ [USER_WORKOUT_REPO] User workout saved successfully: ${userWorkout.userWorkoutId}');
      return userWorkout.userWorkoutId;
      
    } catch (e) {
      print('❌ [USER_WORKOUT_REPO] ERROR saving user workout: $e');
      rethrow;
    }
  }

  /// Get user workout by ID
  Future<UserWorkout?> getUserWorkout(String userWorkoutId) async {
    print('🔍 [USER_WORKOUT_REPO] Loading user workout: $userWorkoutId');
    
    final db = await _dbHelper.database;
    
    try {
      // Get main workout record
      final workoutMaps = await db.query(
        'user_workouts',
        where: 'user_workout_id = ?',
        whereArgs: [userWorkoutId],
      );
      
      if (workoutMaps.isEmpty) {
        print('⚠️ [USER_WORKOUT_REPO] User workout not found: $userWorkoutId');
        return null;
      }
      
      final workoutMap = workoutMaps.first;
      print('✅ [USER_WORKOUT_REPO] Found user workout: ${workoutMap['name']}');
      
      // Get user exercises
      print('🔍 [USER_WORKOUT_REPO] Loading user exercises...');
      final exerciseMaps = await db.query(
        'user_workout_exercises',
        where: 'user_workout_id = ?',
        whereArgs: [userWorkoutId],
        orderBy: 'order_index ASC',
      );
      
      print('✅ [USER_WORKOUT_REPO] Found ${exerciseMaps.length} exercises');
      
      // Get modifications if present
      final modifications = await _loadWorkoutCustomizations(db, userWorkoutId);
      
      return _mapToUserWorkout(workoutMap, exerciseMaps, modifications);
      
    } catch (e) {
      print('❌ [USER_WORKOUT_REPO] ERROR loading user workout: $e');
      return null;
    }
  }

  /// Get all user workouts for a specific user
  Future<List<UserWorkout>> getUserWorkouts(String userId) async {
    print('🔍 [USER_WORKOUT_REPO] Loading all user workouts for user: $userId');
    
    final db = await _dbHelper.database;
    
    try {
      final workoutMaps = await db.query(
        'user_workouts',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
      
      print('✅ [USER_WORKOUT_REPO] Found ${workoutMaps.length} user workouts');
      
      final userWorkouts = <UserWorkout>[];
      
      for (final workoutMap in workoutMaps) {
        final userWorkoutId = workoutMap['user_workout_id'] as String;
        
        // Load exercises for this workout
        final exerciseMaps = await db.query(
          'user_workout_exercises',
          where: 'user_workout_id = ?',
          whereArgs: [userWorkoutId],
          orderBy: 'order_index ASC',
        );
        
        // Load modifications
        final modifications = await _loadWorkoutCustomizations(db, userWorkoutId);
        
        final userWorkout = _mapToUserWorkout(workoutMap, exerciseMaps, modifications);
        userWorkouts.add(userWorkout);
        
        print('✅ [USER_WORKOUT_REPO] Loaded: ${userWorkout.name} (${userWorkout.exercises.length} exercises)');
      }
      
      return userWorkouts;
      
    } catch (e) {
      print('❌ [USER_WORKOUT_REPO] ERROR loading user workouts: $e');
      return [];
    }
  }

  /// Get user workouts based on template
  Future<List<UserWorkout>> getUserWorkoutsByTemplate(String userId, String templateId) async {
    print('🔍 [USER_WORKOUT_REPO] Loading user workouts based on template: $templateId');
    
    final db = await _dbHelper.database;
    
    try {
      final workoutMaps = await db.query(
        'user_workouts',
        where: 'user_id = ? AND base_template_id = ?',
        whereArgs: [userId, templateId],
        orderBy: 'created_at DESC',
      );
      
      print('✅ [USER_WORKOUT_REPO] Found ${workoutMaps.length} workouts based on template');
      
      final userWorkouts = <UserWorkout>[];
      
      for (final workoutMap in workoutMaps) {
        final userWorkoutId = workoutMap['user_workout_id'] as String;
        
        final exerciseMaps = await db.query(
          'user_workout_exercises',
          where: 'user_workout_id = ?',
          whereArgs: [userWorkoutId],
          orderBy: 'order_index ASC',
        );
        
        final modifications = await _loadWorkoutCustomizations(db, userWorkoutId);
        final userWorkout = _mapToUserWorkout(workoutMap, exerciseMaps, modifications);
        userWorkouts.add(userWorkout);
      }
      
      return userWorkouts;
      
    } catch (e) {
      print('❌ [USER_WORKOUT_REPO] ERROR loading template-based workouts: $e');
      return [];
    }
  }

  /// Update user workout usage statistics
  Future<void> recordWorkoutUsage(String userWorkoutId) async {
    print('📊 [USER_WORKOUT_REPO] Recording usage for workout: $userWorkoutId');
    
    final db = await _dbHelper.database;
    
    try {
      await db.update(
        'user_workouts',
        {
          'last_used_at': DateTime.now().toIso8601String(),
          'usage_count': 'usage_count + 1',
        },
        where: 'user_workout_id = ?',
        whereArgs: [userWorkoutId],
      );
      
      print('✅ [USER_WORKOUT_REPO] Usage recorded successfully');
      
    } catch (e) {
      print('❌ [USER_WORKOUT_REPO] ERROR recording usage: $e');
    }
  }

  /// Delete user workout
  Future<void> deleteUserWorkout(String userWorkoutId) async {
    print('🗑️ [USER_WORKOUT_REPO] Deleting user workout: $userWorkoutId');
    
    final db = await _dbHelper.database;
    
    try {
      await db.transaction((txn) async {
        // Delete workout modifications
        await txn.delete(
          'user_workout_modifications',
          where: 'user_workout_id = ?',
          whereArgs: [userWorkoutId],
        );
        
        // Delete user exercises
        await txn.delete(
          'user_workout_exercises',
          where: 'user_workout_id = ?',
          whereArgs: [userWorkoutId],
        );
        
        // Delete main workout record
        await txn.delete(
          'user_workouts',
          where: 'user_workout_id = ?',
          whereArgs: [userWorkoutId],
        );
      });
      
      print('✅ [USER_WORKOUT_REPO] User workout deleted successfully');
      
    } catch (e) {
      print('❌ [USER_WORKOUT_REPO] ERROR deleting user workout: $e');
      rethrow;
    }
  }

  /// Convert UserWorkout to Map for database storage
  Map<String, dynamic> _userWorkoutToMap(UserWorkout userWorkout) {
    return {
      'user_workout_id': userWorkout.userWorkoutId,
      'user_id': userWorkout.userId,
      'name': userWorkout.name,
      'base_template_id': userWorkout.baseTemplateId,
      'target_body_parts': userWorkout.targetBodyParts.join(','),
      'planned_duration_minutes': userWorkout.plannedDurationMinutes,
      'created_at': userWorkout.createdAt.toIso8601String(),
      'last_used_at': userWorkout.lastUsedAt?.toIso8601String(),
      'usage_count': userWorkout.usageCount,
      'source': userWorkout.source.index,
      'notes': userWorkout.notes,
    };
  }

  /// Convert UserExercise to Map for database storage
  Map<String, dynamic> _userExerciseToMap(UserExercise exercise, String userWorkoutId) {
    return {
      'user_exercise_id': exercise.userExerciseId,
      'user_workout_id': userWorkoutId,
      'exercise_id': exercise.exerciseId,
      'exercise_name': exercise.exerciseName,
      'body_parts': exercise.bodyParts.join(','),
      'order_index': exercise.orderIndex,
      'suggested_sets': exercise.suggestedSets,
      'suggested_reps_min': exercise.suggestedRepsMin,
      'suggested_reps_max': exercise.suggestedRepsMax,
      'suggested_weight': exercise.suggestedWeight,
      'rest_time_seconds': exercise.restTimeSeconds,
      'notes': exercise.notes,
      'is_from_template': exercise.isFromTemplate ? 1 : 0,
      'source_template_exercise_id': exercise.sourceTemplateExerciseId,
    };
  }

  /// Convert database maps to UserWorkout object
  UserWorkout _mapToUserWorkout(
    Map<String, dynamic> workoutMap,
    List<Map<String, dynamic>> exerciseMaps,
    WorkoutCustomizations? modifications,
  ) {
    final exercises = exerciseMaps.map((exerciseMap) => _mapToUserExercise(exerciseMap)).toList();
    
    return UserWorkout(
      userWorkoutId: workoutMap['user_workout_id'] as String,
      userId: workoutMap['user_id'] as String,
      name: workoutMap['name'] as String,
      baseTemplateId: workoutMap['base_template_id'] as String?,
      targetBodyParts: (workoutMap['target_body_parts'] as String?)?.split(',') ?? [],
      plannedDurationMinutes: workoutMap['planned_duration_minutes'] as int,
      createdAt: DateTime.parse(workoutMap['created_at'] as String),
      lastUsedAt: workoutMap['last_used_at'] != null 
          ? DateTime.parse(workoutMap['last_used_at'] as String) 
          : null,
      usageCount: workoutMap['usage_count'] as int? ?? 0,
      source: WorkoutSource.values[workoutMap['source'] as int],
      exercises: exercises,
      modifications: modifications,
      notes: workoutMap['notes'] as String?,
    );
  }

  /// Convert database map to UserExercise object
  UserExercise _mapToUserExercise(Map<String, dynamic> exerciseMap) {
    return UserExercise(
      userExerciseId: exerciseMap['user_exercise_id'] as String,
      exerciseId: exerciseMap['exercise_id'] as String,
      exerciseName: exerciseMap['exercise_name'] as String,
      bodyParts: (exerciseMap['body_parts'] as String?)?.split(',') ?? [],
      orderIndex: exerciseMap['order_index'] as int,
      suggestedSets: exerciseMap['suggested_sets'] as int? ?? 3,
      suggestedRepsMin: exerciseMap['suggested_reps_min'] as int? ?? 8,
      suggestedRepsMax: exerciseMap['suggested_reps_max'] as int? ?? 12,
      suggestedWeight: exerciseMap['suggested_weight'] as double?,
      restTimeSeconds: exerciseMap['rest_time_seconds'] as int? ?? 90,
      notes: exerciseMap['notes'] as String?,
      isFromTemplate: (exerciseMap['is_from_template'] as int? ?? 0) == 1,
      sourceTemplateExerciseId: exerciseMap['source_template_exercise_id'] as String?,
    );
  }

  /// Save workout customizations to database
  Future<void> _saveWorkoutCustomizations(Transaction txn, UserWorkout userWorkout) async {
    final modifications = userWorkout.modifications!;
    
    // Save removed exercises
    for (final removedId in modifications.removedExerciseIds) {
      await txn.insert(
        'user_workout_modifications',
        {
          'user_workout_id': userWorkout.userWorkoutId,
          'modification_type': 'removed',
          'exercise_id': removedId,
          'modified_at': modifications.modifiedAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    // Save added exercises
    for (final addedExercise in modifications.addedExercises) {
      await txn.insert(
        'user_workout_modifications',
        {
          'user_workout_id': userWorkout.userWorkoutId,
          'modification_type': 'added',
          'exercise_id': addedExercise.exerciseId,
          'modified_at': modifications.modifiedAt.toIso8601String(),
          'modification_data': _exerciseModificationToJson(addedExercise),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    // Save modified exercises
    for (final entry in modifications.modifiedExercises.entries) {
      await txn.insert(
        'user_workout_modifications',
        {
          'user_workout_id': userWorkout.userWorkoutId,
          'modification_type': 'modified',
          'exercise_id': entry.key,
          'modified_at': entry.value.modifiedAt.toIso8601String(),
          'modification_data': _exerciseModificationToJson(entry.value),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Load workout customizations from database
  Future<WorkoutCustomizations?> _loadWorkoutCustomizations(Database db, String userWorkoutId) async {
    final modificationMaps = await db.query(
      'user_workout_modifications',
      where: 'user_workout_id = ?',
      whereArgs: [userWorkoutId],
    );
    
    if (modificationMaps.isEmpty) return null;
    
    final removedIds = <String>[];
    final addedExercises = <UserExercise>[];
    final modifiedExercises = <String, ExerciseModification>{};
    DateTime? latestModification;
    
    for (final map in modificationMaps) {
      final modifiedAt = DateTime.parse(map['modified_at'] as String);
      latestModification ??= modifiedAt;
      if (modifiedAt.isAfter(latestModification)) {
        latestModification = modifiedAt;
      }
      
      final type = map['modification_type'] as String;
      final exerciseId = map['exercise_id'] as String;
      
      switch (type) {
        case 'removed':
          removedIds.add(exerciseId);
          break;
        case 'added':
          // Note: Would need to reconstruct UserExercise from modification_data JSON
          // This is a simplified version
          break;
        case 'modified':
          // Note: Would need to reconstruct ExerciseModification from modification_data JSON
          // This is a simplified version
          break;
      }
    }
    
    return WorkoutCustomizations(
      removedExerciseIds: removedIds,
      addedExercises: addedExercises,
      modifiedExercises: modifiedExercises,
      modifiedAt: latestModification ?? DateTime.now(),
    );
  }

  /// Convert exercise modification to JSON string (placeholder)
  String _exerciseModificationToJson(dynamic modification) {
    // This would serialize the modification to JSON
    // Simplified for now
    return '{}';
  }
}