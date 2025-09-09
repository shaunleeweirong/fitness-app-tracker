/// Service for managing personal records (PRs)
/// Handles CRUD operations and automatic PR detection

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/personal_record.dart';
import '../models/workout.dart';
import 'database_helper.dart';

class PersonalRecordService {
  final DatabaseHelper _databaseHelper;
  
  static const String _defaultUserId = 'default_user';

  PersonalRecordService({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  /// Get all personal records for a user
  Future<List<PersonalRecord>> getPersonalRecords([String? userId]) async {
    final effectiveUserId = userId ?? _defaultUserId;
    final db = await _databaseHelper.database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tablePersonalRecords,
        where: 'user_id = ?',
        whereArgs: [effectiveUserId],
        orderBy: 'achieved_at DESC',
      );

      return maps.map((map) => PersonalRecord.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting personal records: $e');
      return [];
    }
  }

  /// Get personal records for a specific exercise
  Future<List<PersonalRecord>> getPersonalRecordsForExercise(
    String exerciseId, [
    String? userId,
  ]) async {
    final effectiveUserId = userId ?? _defaultUserId;
    final db = await _databaseHelper.database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tablePersonalRecords,
        where: 'user_id = ? AND exercise_id = ?',
        whereArgs: [effectiveUserId, exerciseId],
        orderBy: 'type ASC, achieved_at DESC',
      );

      return maps.map((map) => PersonalRecord.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting personal records for exercise $exerciseId: $e');
      return [];
    }
  }

  /// Get the current PR for a specific exercise and type
  Future<PersonalRecord?> getCurrentPR(
    String exerciseId,
    PersonalRecordType type, [
    String? userId,
  ]) async {
    final effectiveUserId = userId ?? _defaultUserId;
    final db = await _databaseHelper.database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tablePersonalRecords,
        where: 'user_id = ? AND exercise_id = ? AND type = ?',
        whereArgs: [effectiveUserId, exerciseId, type.index],
        orderBy: 'value DESC, achieved_at DESC',
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return PersonalRecord.fromMap(maps.first);
    } catch (e) {
      debugPrint('Error getting current PR for $exerciseId ($type): $e');
      return null;
    }
  }

  /// Check if a workout set creates any new PRs and save them
  Future<List<PersonalRecord>> checkAndSaveNewPRs(
    WorkoutSet set,
    String exerciseId,
    String exerciseName, [
    String? userId,
    String? workoutId,
  ]) async {
    final effectiveUserId = userId ?? _defaultUserId;
    final newPRs = <PersonalRecord>[];

    try {
      // Check for weight PR (heaviest weight)
      final weightPR = await _checkWeightPR(
        set,
        exerciseId,
        exerciseName,
        effectiveUserId,
        workoutId,
      );
      if (weightPR != null) newPRs.add(weightPR);

      // Check for volume PR (best single set volume)
      final volumePR = await _checkVolumePR(
        set,
        exerciseId,
        exerciseName,
        effectiveUserId,
        workoutId,
      );
      if (volumePR != null) newPRs.add(volumePR);

      // Check for reps PR (most reps at a given weight)
      final repsPR = await _checkRepsPR(
        set,
        exerciseId,
        exerciseName,
        effectiveUserId,
        workoutId,
      );
      if (repsPR != null) newPRs.add(repsPR);

      // Save all new PRs to database
      for (final pr in newPRs) {
        await _savePR(pr);
      }

      if (newPRs.isNotEmpty) {
        debugPrint('🏆 NEW PRs ACHIEVED for $exerciseName:');
        for (final pr in newPRs) {
          debugPrint('   ${pr.displayTitle}: ${pr.formattedValue}');
        }
      }

      return newPRs;
    } catch (e) {
      debugPrint('Error checking/saving PRs for $exerciseName: $e');
      return [];
    }
  }

  /// Check for new weight PR
  Future<PersonalRecord?> _checkWeightPR(
    WorkoutSet set,
    String exerciseId,
    String exerciseName,
    String userId,
    String? workoutId,
  ) async {
    final currentPR = await getCurrentPR(exerciseId, PersonalRecordType.weight, userId);
    
    if (currentPR == null || set.weight > currentPR.value) {
      return PersonalRecordFromSet.fromWorkoutSet(
        userId: userId,
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        weight: set.weight,
        reps: set.reps,
        type: PersonalRecordType.weight,
        achievedAt: DateTime.now(),
        workoutId: workoutId,
      );
    }
    
    return null;
  }

  /// Check for new volume PR
  Future<PersonalRecord?> _checkVolumePR(
    WorkoutSet set,
    String exerciseId,
    String exerciseName,
    String userId,
    String? workoutId,
  ) async {
    final currentPR = await getCurrentPR(exerciseId, PersonalRecordType.volume, userId);
    final setVolume = set.volume;
    
    if (currentPR == null || setVolume > currentPR.value) {
      return PersonalRecordFromSet.fromWorkoutSet(
        userId: userId,
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        weight: set.weight,
        reps: set.reps,
        type: PersonalRecordType.volume,
        achievedAt: DateTime.now(),
        workoutId: workoutId,
      );
    }
    
    return null;
  }

  /// Check for new reps PR
  Future<PersonalRecord?> _checkRepsPR(
    WorkoutSet set,
    String exerciseId,
    String exerciseName,
    String userId,
    String? workoutId,
  ) async {
    // For reps PR, we check if this is more reps at the same or higher weight
    final db = await _databaseHelper.database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tablePersonalRecords,
        where: 'user_id = ? AND exercise_id = ? AND type = ? AND secondary_value <= ?',
        whereArgs: [userId, exerciseId, PersonalRecordType.reps.index, set.weight],
        orderBy: 'value DESC',
        limit: 1,
      );

      PersonalRecord? currentBest;
      if (maps.isNotEmpty) {
        currentBest = PersonalRecord.fromMap(maps.first);
      }

      // Check if this set has more reps than the current best at this weight or lower
      if (currentBest == null || set.reps > currentBest.value.toInt()) {
        return PersonalRecordFromSet.fromWorkoutSet(
          userId: userId,
          exerciseId: exerciseId,
          exerciseName: exerciseName,
          weight: set.weight,
          reps: set.reps,
          type: PersonalRecordType.reps,
          achievedAt: DateTime.now(),
          workoutId: workoutId,
        );
      }
    } catch (e) {
      debugPrint('Error checking reps PR: $e');
    }
    
    return null;
  }

  /// Save a personal record to the database
  Future<void> _savePR(PersonalRecord pr) async {
    final db = await _databaseHelper.database;
    
    try {
      await db.insert(
        DatabaseHelper.tablePersonalRecords,
        pr.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      debugPrint('✅ Saved PR: ${pr.exerciseName} - ${pr.shortDescription}');
    } catch (e) {
      debugPrint('❌ Error saving PR: $e');
      rethrow;
    }
  }

  /// Get recent PRs (last 30 days)
  Future<List<PersonalRecord>> getRecentPRs([String? userId]) async {
    final effectiveUserId = userId ?? _defaultUserId;
    final db = await _databaseHelper.database;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tablePersonalRecords,
        where: 'user_id = ? AND achieved_at >= ?',
        whereArgs: [effectiveUserId, thirtyDaysAgo.toIso8601String()],
        orderBy: 'achieved_at DESC',
        limit: 10,
      );

      return maps.map((map) => PersonalRecord.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting recent PRs: $e');
      return [];
    }
  }

  /// Get PR summary statistics
  Future<Map<String, dynamic>> getPRStats([String? userId]) async {
    final effectiveUserId = userId ?? _defaultUserId;
    final db = await _databaseHelper.database;
    
    try {
      // Get total PR count
      final totalPRs = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseHelper.tablePersonalRecords} WHERE user_id = ?',
        [effectiveUserId],
      )) ?? 0;

      // Get PRs this month
      final thisMonthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
      final monthlyPRs = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseHelper.tablePersonalRecords} WHERE user_id = ? AND achieved_at >= ?',
        [effectiveUserId, thisMonthStart.toIso8601String()],
      )) ?? 0;

      // Get unique exercises with PRs
      final uniqueExercises = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(DISTINCT exercise_id) FROM ${DatabaseHelper.tablePersonalRecords} WHERE user_id = ?',
        [effectiveUserId],
      )) ?? 0;

      return {
        'totalPRs': totalPRs,
        'monthlyPRs': monthlyPRs,
        'uniqueExercises': uniqueExercises,
      };
    } catch (e) {
      debugPrint('Error getting PR stats: $e');
      return {
        'totalPRs': 0,
        'monthlyPRs': 0,
        'uniqueExercises': 0,
      };
    }
  }

  /// Delete a personal record
  Future<void> deletePR(String recordId) async {
    final db = await _databaseHelper.database;
    
    try {
      await db.delete(
        DatabaseHelper.tablePersonalRecords,
        where: 'record_id = ?',
        whereArgs: [recordId],
      );
      
      debugPrint('Deleted PR with ID: $recordId');
    } catch (e) {
      debugPrint('Error deleting PR: $e');
      rethrow;
    }
  }

  /// Dispose of resources
  void dispose() {
    // Clean up any resources if needed
  }
}