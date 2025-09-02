import 'package:sqflite/sqflite.dart';
import '../models/workout.dart';
import 'database_helper.dart';

/// Repository pattern for workout template data operations
/// Provides clean abstraction layer over SQLite database operations for templates
class WorkoutTemplateRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Save a new workout template to the database
  Future<String> saveTemplate(WorkoutTemplate template) async {
    final db = await _dbHelper.database;
    
    await db.transaction((txn) async {
      // Insert main template record
      await txn.insert(
        DatabaseHelper.tableWorkoutTemplates, 
        template.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Delete existing template exercises (in case of update)
      await txn.delete(
        DatabaseHelper.tableTemplateExercises,
        where: 'template_id = ?',
        whereArgs: [template.templateId],
      );
      
      // Insert template exercises
      for (final exercise in template.exercises) {
        await txn.insert(
          DatabaseHelper.tableTemplateExercises,
          exercise.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    
    return template.templateId;
  }

  /// Load a specific template by ID with all exercises
  Future<WorkoutTemplate?> getTemplate(String templateId) async {
    final db = await _dbHelper.database;
    
    // Get template record
    final templateMaps = await db.query(
      DatabaseHelper.tableWorkoutTemplates,
      where: 'template_id = ?',
      whereArgs: [templateId],
    );
    
    if (templateMaps.isEmpty) {
      return null;
    }
    
    // Get template exercises
    final exerciseMaps = await db.query(
      DatabaseHelper.tableTemplateExercises,
      where: 'template_id = ?',
      whereArgs: [templateId],
      orderBy: 'order_index ASC',
    );
    
    final exercises = exerciseMaps.map((map) => TemplateExercise.fromMap(map)).toList();
    
    return WorkoutTemplate.fromMap(templateMaps.first, exercises: exercises);
  }

  /// Get all templates for a user with optional filtering
  Future<List<WorkoutTemplate>> getTemplates({
    required String userId,
    TemplateCategory? category,
    TemplateDifficulty? difficulty,
    bool? isFavorite,
    String? searchQuery,
    String? orderBy,
    bool ascending = true,
    int? limit,
    int? offset,
  }) async {
    final db = await _dbHelper.database;
    
    // Build WHERE clause
    final whereConditions = <String>['user_id = ?'];
    final whereArgs = <dynamic>[userId];
    
    if (category != null) {
      whereConditions.add('category = ?');
      whereArgs.add(category.name);
    }
    
    if (difficulty != null) {
      whereConditions.add('difficulty_level = ?');
      whereArgs.add(difficulty.index);
    }
    
    if (isFavorite != null) {
      whereConditions.add('is_favorite = ?');
      whereArgs.add(isFavorite ? 1 : 0);
    }
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereConditions.add('(name LIKE ? OR description LIKE ?)');
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }
    
    // Build ORDER BY clause
    final orderByClause = orderBy ?? 'updated_at DESC';
    final finalOrderBy = ascending ? orderByClause : '$orderByClause DESC';
    
    // Execute query
    final templateMaps = await db.query(
      DatabaseHelper.tableWorkoutTemplates,
      where: whereConditions.join(' AND '),
      whereArgs: whereArgs,
      orderBy: finalOrderBy,
      limit: limit,
      offset: offset,
    );
    
    // Load exercises for each template
    final templates = <WorkoutTemplate>[];
    for (final templateMap in templateMaps) {
      final templateId = templateMap['template_id'] as String;
      
      final exerciseMaps = await db.query(
        DatabaseHelper.tableTemplateExercises,
        where: 'template_id = ?',
        whereArgs: [templateId],
        orderBy: 'order_index ASC',
      );
      
      final exercises = exerciseMaps.map((map) => TemplateExercise.fromMap(map)).toList();
      templates.add(WorkoutTemplate.fromMap(templateMap, exercises: exercises));
    }
    
    return templates;
  }

  /// Update an existing template
  Future<void> updateTemplate(WorkoutTemplate template) async {
    final updatedTemplate = template.copyWith(
      updatedAt: DateTime.now(),
    );
    
    await saveTemplate(updatedTemplate);
  }

  /// Delete a template and all its exercises
  Future<void> deleteTemplate(String templateId) async {
    final db = await _dbHelper.database;
    
    await db.transaction((txn) async {
      // Delete template exercises first (foreign key constraint)
      await txn.delete(
        DatabaseHelper.tableTemplateExercises,
        where: 'template_id = ?',
        whereArgs: [templateId],
      );
      
      // Delete template
      await txn.delete(
        DatabaseHelper.tableWorkoutTemplates,
        where: 'template_id = ?',
        whereArgs: [templateId],
      );
    });
  }

  /// Toggle favorite status for a template
  Future<void> toggleFavorite(String templateId) async {
    final template = await getTemplate(templateId);
    if (template == null) return;
    
    final updatedTemplate = template.copyWith(
      isFavorite: !template.isFavorite,
      updatedAt: DateTime.now(),
    );
    
    await updateTemplate(updatedTemplate);
  }

  /// Update template usage statistics
  Future<void> recordTemplateUsage(String templateId) async {
    final template = await getTemplate(templateId);
    if (template == null) return;
    
    final updatedTemplate = template.copyWith(
      usageCount: template.usageCount + 1,
      lastUsedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await updateTemplate(updatedTemplate);
  }

  /// Get template statistics for a user
  Future<TemplateStats> getTemplateStats(String userId) async {
    final db = await _dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_templates,
        SUM(CASE WHEN is_favorite = 1 THEN 1 ELSE 0 END) as favorite_templates,
        SUM(usage_count) as total_usage,
        AVG(usage_count) as avg_usage,
        COUNT(CASE WHEN last_used_at IS NOT NULL THEN 1 END) as used_templates
      FROM ${DatabaseHelper.tableWorkoutTemplates}
      WHERE user_id = ?
    ''', [userId]);
    
    if (result.isEmpty) {
      return TemplateStats.empty();
    }
    
    final data = result.first;
    return TemplateStats(
      totalTemplates: data['total_templates'] as int? ?? 0,
      favoriteTemplates: data['favorite_templates'] as int? ?? 0,
      totalUsage: data['total_usage'] as int? ?? 0,
      averageUsage: (data['avg_usage'] as double? ?? 0).round(),
      usedTemplates: data['used_templates'] as int? ?? 0,
    );
  }

  /// Get most popular templates for a user
  Future<List<WorkoutTemplate>> getPopularTemplates({
    required String userId,
    int limit = 5,
  }) async {
    return getTemplates(
      userId: userId,
      orderBy: 'usage_count',
      ascending: false,
      limit: limit,
    );
  }

  /// Get recently used templates
  Future<List<WorkoutTemplate>> getRecentTemplates({
    required String userId,
    int limit = 5,
  }) async {
    final db = await _dbHelper.database;
    
    final templateMaps = await db.query(
      DatabaseHelper.tableWorkoutTemplates,
      where: 'user_id = ? AND last_used_at IS NOT NULL',
      whereArgs: [userId],
      orderBy: 'last_used_at DESC',
      limit: limit,
    );
    
    // Load exercises for each template
    final templates = <WorkoutTemplate>[];
    for (final templateMap in templateMaps) {
      final templateId = templateMap['template_id'] as String;
      
      final exerciseMaps = await db.query(
        DatabaseHelper.tableTemplateExercises,
        where: 'template_id = ?',
        whereArgs: [templateId],
        orderBy: 'order_index ASC',
      );
      
      final exercises = exerciseMaps.map((map) => TemplateExercise.fromMap(map)).toList();
      templates.add(WorkoutTemplate.fromMap(templateMap, exercises: exercises));
    }
    
    return templates;
  }

  /// Get templates by category
  Future<Map<TemplateCategory, List<WorkoutTemplate>>> getTemplatesByCategory({
    required String userId,
  }) async {
    final templates = await getTemplates(userId: userId);
    
    final categorizedTemplates = <TemplateCategory, List<WorkoutTemplate>>{};
    
    for (final template in templates) {
      if (!categorizedTemplates.containsKey(template.category)) {
        categorizedTemplates[template.category] = [];
      }
      categorizedTemplates[template.category]!.add(template);
    }
    
    return categorizedTemplates;
  }

  /// Create a template from an existing workout
  Future<String> createTemplateFromWorkout({
    required Workout workout,
    required String templateName,
    String? description,
    TemplateDifficulty difficulty = TemplateDifficulty.beginner,
    TemplateCategory category = TemplateCategory.custom,
  }) async {
    final now = DateTime.now();
    final templateId = _dbHelper.generateWorkoutTemplateId();
    
    // Convert workout exercises to template exercises
    final templateExercises = <TemplateExercise>[];
    for (int i = 0; i < workout.exercises.length; i++) {
      final workoutExercise = workout.exercises[i];
      
      // Calculate suggested values from completed sets
      final completedSets = workoutExercise.sets.where((set) => set.isCompleted).toList();
      int suggestedSets = completedSets.isNotEmpty ? completedSets.length : 3;
      int suggestedRepsMin = completedSets.isNotEmpty ? completedSets.map((s) => s.reps).reduce((a, b) => a < b ? a : b) : 8;
      int suggestedRepsMax = completedSets.isNotEmpty ? completedSets.map((s) => s.reps).reduce((a, b) => a > b ? a : b) : 12;
      double? suggestedWeight = completedSets.isNotEmpty ? completedSets.map((s) => s.weight).reduce((a, b) => a + b) / completedSets.length : null;
      
      final templateExercise = TemplateExercise(
        templateExerciseId: _dbHelper.generateTemplateExerciseId(templateId, workoutExercise.exerciseId),
        templateId: templateId,
        exerciseId: workoutExercise.exerciseId,
        exerciseName: workoutExercise.exerciseName,
        bodyParts: workoutExercise.bodyParts,
        orderIndex: workoutExercise.orderIndex,
        suggestedSets: suggestedSets,
        suggestedRepsMin: suggestedRepsMin,
        suggestedRepsMax: suggestedRepsMax,
        suggestedWeight: suggestedWeight,
        notes: workoutExercise.notes,
      );
      
      templateExercises.add(templateExercise);
    }
    
    final template = WorkoutTemplate(
      templateId: templateId,
      userId: workout.userId,
      name: templateName,
      description: description,
      targetBodyParts: workout.targetBodyParts,
      estimatedDurationMinutes: workout.plannedDurationMinutes,
      difficulty: difficulty,
      category: category,
      createdAt: now,
      updatedAt: now,
      exercises: templateExercises,
    );
    
    await saveTemplate(template);
    return templateId;
  }

  /// Close the database connection
  Future<void> close() async {
    await _dbHelper.close();
  }
}

/// Statistics for workout templates
class TemplateStats {
  final int totalTemplates;
  final int favoriteTemplates;
  final int totalUsage;
  final int averageUsage;
  final int usedTemplates;

  const TemplateStats({
    required this.totalTemplates,
    required this.favoriteTemplates,
    required this.totalUsage,
    required this.averageUsage,
    required this.usedTemplates,
  });

  factory TemplateStats.empty() {
    return const TemplateStats(
      totalTemplates: 0,
      favoriteTemplates: 0,
      totalUsage: 0,
      averageUsage: 0,
      usedTemplates: 0,
    );
  }

  double get usageRate => totalTemplates > 0 ? usedTemplates / totalTemplates : 0.0;
  
  String get formattedUsageRate => '${(usageRate * 100).toStringAsFixed(0)}%';
}