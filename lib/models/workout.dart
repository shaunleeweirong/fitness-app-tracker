/// SQLite-based workout models for local data persistence
/// Designed for offline-first workout tracking functionality

import 'package:flutter/foundation.dart';

class Workout {
  final String workoutId;
  final String userId;
  final String name;
  final List<String> targetBodyParts;
  final int plannedDurationMinutes;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final WorkoutStatus status;
  final List<WorkoutExercise> exercises;
  final String? notes;

  const Workout({
    required this.workoutId,
    required this.userId,
    required this.name,
    required this.targetBodyParts,
    required this.plannedDurationMinutes,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.status = WorkoutStatus.planned,
    this.exercises = const [],
    this.notes,
  });

  // Factory constructor from SQLite Map
  factory Workout.fromMap(Map<String, dynamic> map, {List<WorkoutExercise>? exercises}) {
    return Workout(
      workoutId: map['workout_id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      targetBodyParts: _parseStringList(map['target_body_parts'] as String?),
      plannedDurationMinutes: map['planned_duration_minutes'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      startedAt: map['started_at'] != null ? DateTime.parse(map['started_at'] as String) : null,
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
      status: WorkoutStatus.values[map['status'] as int],
      exercises: exercises ?? [],
      notes: map['notes'] as String?,
    );
  }

  // Convert to SQLite Map
  Map<String, dynamic> toMap() {
    return {
      'workout_id': workoutId,
      'user_id': userId,
      'name': name,
      'target_body_parts': _stringListToString(targetBodyParts),
      'planned_duration_minutes': plannedDurationMinutes,
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'status': status.index,
      'notes': notes,
    };
  }

  // Helper methods
  Duration get actualDuration {
    if (startedAt != null && completedAt != null) {
      return completedAt!.difference(startedAt!);
    }
    return Duration.zero;
  }
  
  bool get isCompleted => status == WorkoutStatus.completed;
  bool get isInProgress => status == WorkoutStatus.inProgress;
  bool get isPlanned => status == WorkoutStatus.planned;
  
  double get totalVolume {
    return exercises.fold(0.0, (sum, exercise) => sum + exercise.totalVolume);
  }
  
  int get totalSets {
    return exercises.fold(0, (sum, exercise) => sum + exercise.sets.length);
  }
  
  String get formattedDuration {
    if (actualDuration == Duration.zero) {
      return '${plannedDurationMinutes}min planned';
    }
    final minutes = actualDuration.inMinutes;
    return '${minutes}min actual';
  }

  // Create a copy with updated fields
  Workout copyWith({
    String? workoutId,
    String? userId,
    String? name,
    List<String>? targetBodyParts,
    int? plannedDurationMinutes,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    WorkoutStatus? status,
    List<WorkoutExercise>? exercises,
    String? notes,
  }) {
    return Workout(
      workoutId: workoutId ?? this.workoutId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      targetBodyParts: targetBodyParts ?? this.targetBodyParts,
      plannedDurationMinutes: plannedDurationMinutes ?? this.plannedDurationMinutes,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
    );
  }

  static List<String> _parseStringList(String? value) {
    if (value == null || value.isEmpty) return [];
    return value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  static String _stringListToString(List<String> list) {
    return list.join(',');
  }
}

class WorkoutExercise {
  final String exerciseId;
  final String exerciseName;
  final List<String> bodyParts;
  final List<WorkoutSet> sets;
  final String? notes;
  final int orderIndex;
  final String workoutId; // Foreign key

  const WorkoutExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.bodyParts,
    required this.sets,
    this.notes,
    required this.orderIndex,
    required this.workoutId,
  });

  // Factory constructor from SQLite Map
  factory WorkoutExercise.fromMap(Map<String, dynamic> map, {List<WorkoutSet>? sets}) {
    return WorkoutExercise(
      exerciseId: map['exercise_id'] as String,
      exerciseName: map['exercise_name'] as String,
      bodyParts: Workout._parseStringList(map['body_parts'] as String?),
      sets: sets ?? [],
      notes: map['notes'] as String?,
      orderIndex: map['order_index'] as int,
      workoutId: map['workout_id'] as String,
    );
  }

  // Convert to SQLite Map
  Map<String, dynamic> toMap() {
    return {
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'body_parts': Workout._stringListToString(bodyParts),
      'notes': notes,
      'order_index': orderIndex,
      'workout_id': workoutId,
    };
  }

  // Helper methods
  double get totalVolume {
    return sets.fold(0.0, (sum, set) => sum + set.volume);
  }
  
  int get completedSets {
    return sets.where((set) => set.isCompleted).length;
  }
  
  bool get isCompleted {
    return sets.isNotEmpty && sets.every((set) => set.isCompleted);
  }

  // Create a copy with updated fields
  WorkoutExercise copyWith({
    String? exerciseId,
    String? exerciseName,
    List<String>? bodyParts,
    List<WorkoutSet>? sets,
    String? notes,
    int? orderIndex,
    String? workoutId,
  }) {
    return WorkoutExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      bodyParts: bodyParts ?? this.bodyParts,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
      orderIndex: orderIndex ?? this.orderIndex,
      workoutId: workoutId ?? this.workoutId,
    );
  }
}

class WorkoutSet {
  final double weight;
  final int reps;
  final int setNumber;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? notes;
  final int? restTimeSeconds;
  final String workoutExerciseId; // Foreign key (composite: workoutId + exerciseId)

  const WorkoutSet({
    required this.weight,
    required this.reps,
    required this.setNumber,
    this.isCompleted = false,
    this.completedAt,
    this.notes,
    this.restTimeSeconds,
    required this.workoutExerciseId,
  });

  // Factory constructor from SQLite Map
  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      weight: (map['weight'] as num).toDouble(),
      reps: map['reps'] as int,
      setNumber: map['set_number'] as int,
      isCompleted: map['is_completed'] == 1,
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
      notes: map['notes'] as String?,
      restTimeSeconds: map['rest_time_seconds'] as int?,
      workoutExerciseId: map['workout_exercise_id'] as String,
    );
  }

  // Convert to SQLite Map
  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'reps': reps,
      'set_number': setNumber,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
      'notes': notes,
      'rest_time_seconds': restTimeSeconds,
      'workout_exercise_id': workoutExerciseId,
    };
  }

  // Helper methods
  double get volume => weight * reps;
  
  String get formattedWeight => weight % 1 == 0 ? '${weight.toInt()}kg' : '${weight}kg';
  
  String get summary => '${formattedWeight} × ${reps} reps';

  // Create a copy with updated fields
  WorkoutSet copyWith({
    double? weight,
    int? reps,
    int? setNumber,
    bool? isCompleted,
    DateTime? completedAt,
    String? notes,
    int? restTimeSeconds,
    String? workoutExerciseId,
  }) {
    return WorkoutSet(
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      setNumber: setNumber ?? this.setNumber,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      restTimeSeconds: restTimeSeconds ?? this.restTimeSeconds,
      workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
    );
  }
}

class User {
  final String userId;
  final String name;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final Map<String, int> bodyPartXP;
  final UserPreferences preferences;

  const User({
    required this.userId,
    required this.name,
    required this.createdAt,
    required this.lastActiveAt,
    this.bodyPartXP = const {},
    required this.preferences,
  });

  // Factory constructor from SQLite Map
  factory User.fromMap(Map<String, dynamic> map, {UserPreferences? preferences}) {
    return User(
      userId: map['user_id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastActiveAt: DateTime.parse(map['last_active_at'] as String),
      bodyPartXP: _parseXPMap(map['body_part_xp'] as String?),
      preferences: preferences ?? UserPreferences.defaultPreferences(),
    );
  }

  // Convert to SQLite Map
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'last_active_at': lastActiveAt.toIso8601String(),
      'body_part_xp': _xpMapToString(bodyPartXP),
    };
  }

  static Map<String, int> _parseXPMap(String? value) {
    if (value == null || value.isEmpty) return {};
    final Map<String, int> result = {};
    for (final pair in value.split(',')) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        result[parts[0].trim()] = int.tryParse(parts[1].trim()) ?? 0;
      }
    }
    return result;
  }

  static String _xpMapToString(Map<String, int> map) {
    return map.entries.map((e) => '${e.key}:${e.value}').join(',');
  }
}

class UserPreferences {
  final String defaultWeightUnit;
  final int defaultRestTime;
  final List<String> favoriteBodyParts;
  final bool soundEnabled;
  final bool vibrationEnabled;

  const UserPreferences({
    this.defaultWeightUnit = 'kg',
    this.defaultRestTime = 90,
    this.favoriteBodyParts = const [],
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  factory UserPreferences.defaultPreferences() {
    return const UserPreferences();
  }

  // Factory constructor from SQLite Map
  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      defaultWeightUnit: map['default_weight_unit'] as String? ?? 'kg',
      defaultRestTime: map['default_rest_time'] as int? ?? 90,
      favoriteBodyParts: Workout._parseStringList(map['favorite_body_parts'] as String?),
      soundEnabled: (map['sound_enabled'] as int? ?? 1) == 1,
      vibrationEnabled: (map['vibration_enabled'] as int? ?? 1) == 1,
    );
  }

  // Convert to SQLite Map
  Map<String, dynamic> toMap(String userId) {
    return {
      'user_id': userId,
      'default_weight_unit': defaultWeightUnit,
      'default_rest_time': defaultRestTime,
      'favorite_body_parts': Workout._stringListToString(favoriteBodyParts),
      'sound_enabled': soundEnabled ? 1 : 0,
      'vibration_enabled': vibrationEnabled ? 1 : 0,
    };
  }
}

enum WorkoutStatus {
  planned,
  inProgress,
  completed,
  cancelled,
}

/// Difficulty levels for workout templates
enum TemplateDifficulty {
  beginner,
  intermediate,
  advanced,
}

/// Categories for organizing workout templates
enum TemplateCategory {
  custom,
  strength,
  cardio,
  fullBody,
  upperBody,
  lowerBody,
  push,
  pull,
  legs,
}

/// Workout template model for saving and reusing workout plans
class WorkoutTemplate {
  final String templateId;
  final String userId;
  final String name;
  final String? description;
  final List<String> targetBodyParts;
  final int? estimatedDurationMinutes;
  final TemplateDifficulty difficulty;
  final TemplateCategory category;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUsedAt;
  final int usageCount;
  final List<TemplateExercise> exercises;

  const WorkoutTemplate({
    required this.templateId,
    required this.userId,
    required this.name,
    this.description,
    required this.targetBodyParts,
    this.estimatedDurationMinutes,
    this.difficulty = TemplateDifficulty.beginner,
    this.category = TemplateCategory.custom,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastUsedAt,
    this.usageCount = 0,
    this.exercises = const [],
  });

  /// Factory constructor from SQLite Map
  factory WorkoutTemplate.fromMap(Map<String, dynamic> map, {List<TemplateExercise>? exercises}) {
    return WorkoutTemplate(
      templateId: map['template_id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      targetBodyParts: Workout._parseStringList(map['target_body_parts'] as String?),
      estimatedDurationMinutes: map['estimated_duration_minutes'] as int?,
      difficulty: TemplateDifficulty.values[map['difficulty_level'] as int? ?? 0],
      category: _parseTemplateCategory(map['category'] as String?),
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      lastUsedAt: map['last_used_at'] != null ? DateTime.parse(map['last_used_at'] as String) : null,
      usageCount: map['usage_count'] as int? ?? 0,
      exercises: exercises ?? [],
    );
  }

  /// Convert to SQLite Map
  Map<String, dynamic> toMap() {
    return {
      'template_id': templateId,
      'user_id': userId,
      'name': name,
      'description': description,
      'target_body_parts': Workout._stringListToString(targetBodyParts),
      'estimated_duration_minutes': estimatedDurationMinutes,
      'difficulty_level': difficulty.index,
      'category': category.name,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_used_at': lastUsedAt?.toIso8601String(),
      'usage_count': usageCount,
    };
  }

  /// Create a copy with updated fields
  WorkoutTemplate copyWith({
    String? templateId,
    String? userId,
    String? name,
    String? description,
    List<String>? targetBodyParts,
    int? estimatedDurationMinutes,
    TemplateDifficulty? difficulty,
    TemplateCategory? category,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUsedAt,
    int? usageCount,
    List<TemplateExercise>? exercises,
  }) {
    return WorkoutTemplate(
      templateId: templateId ?? this.templateId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      targetBodyParts: targetBodyParts ?? this.targetBodyParts,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      usageCount: usageCount ?? this.usageCount,
      exercises: exercises ?? this.exercises,
    );
  }

  /// Get difficulty display name
  String get difficultyName {
    switch (difficulty) {
      case TemplateDifficulty.beginner:
        return 'Beginner';
      case TemplateDifficulty.intermediate:
        return 'Intermediate';
      case TemplateDifficulty.advanced:
        return 'Advanced';
    }
  }

  /// Get category display name
  String get categoryName {
    switch (category) {
      case TemplateCategory.custom:
        return 'Custom';
      case TemplateCategory.strength:
        return 'Strength';
      case TemplateCategory.cardio:
        return 'Cardio';
      case TemplateCategory.fullBody:
        return 'Full Body';
      case TemplateCategory.upperBody:
        return 'Upper Body';
      case TemplateCategory.lowerBody:
        return 'Lower Body';
      case TemplateCategory.push:
        return 'Push';
      case TemplateCategory.pull:
        return 'Pull';
      case TemplateCategory.legs:
        return 'Legs';
    }
  }

  /// Convert template to a workout
  Workout toWorkout({required String userId, String? customName}) {
    debugPrint('🔄 Converting template "$name" to workout...');
    debugPrint('📊 Template has ${exercises.length} exercises');
    
    // Generate workoutId first
    final workoutId = 'workout_${DateTime.now().millisecondsSinceEpoch}';
    
    final workoutExercises = exercises.map((templateExercise) {
      debugPrint('  Converting: ${templateExercise.exerciseName} (ID: ${templateExercise.exerciseId})');
      return templateExercise.toWorkoutExercise().copyWith(workoutId: workoutId);
    }).toList();
    
    debugPrint('💪 Created workout "$workoutId" with ${workoutExercises.length} exercises');
    
    return Workout(
      workoutId: workoutId,
      userId: userId,
      name: customName ?? name,
      targetBodyParts: List.from(targetBodyParts),
      plannedDurationMinutes: estimatedDurationMinutes ?? 45,
      createdAt: DateTime.now(),
      status: WorkoutStatus.planned,
      exercises: workoutExercises,
    );
  }

  /// Parse category from string
  static TemplateCategory _parseTemplateCategory(String? value) {
    if (value == null) return TemplateCategory.custom;
    try {
      return TemplateCategory.values.firstWhere(
        (category) => category.name.toLowerCase() == value.toLowerCase(),
        orElse: () => TemplateCategory.custom,
      );
    } catch (e) {
      return TemplateCategory.custom;
    }
  }
}

/// Template exercise with suggested sets, reps, and weights
class TemplateExercise {
  final String templateExerciseId;
  final String templateId;
  final String exerciseId;
  final String exerciseName;
  final List<String> bodyParts;
  final int orderIndex;
  final int suggestedSets;
  final int suggestedRepsMin;
  final int suggestedRepsMax;
  final double? suggestedWeight;
  final int restTimeSeconds;
  final String? notes;

  const TemplateExercise({
    required this.templateExerciseId,
    required this.templateId,
    required this.exerciseId,
    required this.exerciseName,
    required this.bodyParts,
    required this.orderIndex,
    this.suggestedSets = 3,
    this.suggestedRepsMin = 8,
    this.suggestedRepsMax = 12,
    this.suggestedWeight,
    this.restTimeSeconds = 90,
    this.notes,
  });

  /// Factory constructor from SQLite Map
  factory TemplateExercise.fromMap(Map<String, dynamic> map) {
    return TemplateExercise(
      templateExerciseId: map['template_exercise_id'] as String,
      templateId: map['template_id'] as String,
      exerciseId: map['exercise_id'] as String,
      exerciseName: map['exercise_name'] as String,
      bodyParts: Workout._parseStringList(map['body_parts'] as String?),
      orderIndex: map['order_index'] as int,
      suggestedSets: map['suggested_sets'] as int? ?? 3,
      suggestedRepsMin: map['suggested_reps_min'] as int? ?? 8,
      suggestedRepsMax: map['suggested_reps_max'] as int? ?? 12,
      suggestedWeight: map['suggested_weight'] as double?,
      restTimeSeconds: map['rest_time_seconds'] as int? ?? 90,
      notes: map['notes'] as String?,
    );
  }

  /// Convert to SQLite Map
  Map<String, dynamic> toMap() {
    return {
      'template_exercise_id': templateExerciseId,
      'template_id': templateId,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'body_parts': Workout._stringListToString(bodyParts),
      'order_index': orderIndex,
      'suggested_sets': suggestedSets,
      'suggested_reps_min': suggestedRepsMin,
      'suggested_reps_max': suggestedRepsMax,
      'suggested_weight': suggestedWeight,
      'rest_time_seconds': restTimeSeconds,
      'notes': notes,
    };
  }

  /// Create a copy with updated fields
  TemplateExercise copyWith({
    String? templateExerciseId,
    String? templateId,
    String? exerciseId,
    String? exerciseName,
    List<String>? bodyParts,
    int? orderIndex,
    int? suggestedSets,
    int? suggestedRepsMin,
    int? suggestedRepsMax,
    double? suggestedWeight,
    int? restTimeSeconds,
    String? notes,
  }) {
    return TemplateExercise(
      templateExerciseId: templateExerciseId ?? this.templateExerciseId,
      templateId: templateId ?? this.templateId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      bodyParts: bodyParts ?? this.bodyParts,
      orderIndex: orderIndex ?? this.orderIndex,
      suggestedSets: suggestedSets ?? this.suggestedSets,
      suggestedRepsMin: suggestedRepsMin ?? this.suggestedRepsMin,
      suggestedRepsMax: suggestedRepsMax ?? this.suggestedRepsMax,
      suggestedWeight: suggestedWeight ?? this.suggestedWeight,
      restTimeSeconds: restTimeSeconds ?? this.restTimeSeconds,
      notes: notes ?? this.notes,
    );
  }

  /// Get suggested reps range as string
  String get suggestedRepsRange {
    if (suggestedRepsMin == suggestedRepsMax) {
      return '$suggestedRepsMin reps';
    } else {
      return '$suggestedRepsMin-$suggestedRepsMax reps';
    }
  }

  /// Get formatted suggested weight
  String? get formattedSuggestedWeight {
    if (suggestedWeight == null) return null;
    return suggestedWeight! % 1 == 0 
        ? '${suggestedWeight!.toInt()}kg'
        : '${suggestedWeight}kg';
  }

  /// Convert template exercise to workout exercise
  WorkoutExercise toWorkoutExercise() {
    return WorkoutExercise(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      bodyParts: List.from(bodyParts),
      sets: [], // Sets will be added during workout
      notes: notes,
      orderIndex: orderIndex,
      workoutId: '', // Will be set when added to workout
    );
  }
}