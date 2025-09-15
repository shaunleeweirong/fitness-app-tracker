/// SQLite-based workout models for local data persistence
/// Designed for offline-first workout tracking functionality
library;

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
  
  String get summary => '$formattedWeight × $reps reps';

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
    // Try to parse exercises from map if provided, otherwise use the passed exercises parameter
    List<TemplateExercise> finalExercises = exercises ?? [];
    
    if (exercises == null && map.containsKey('exercises')) {
      // Deserialize exercises from the map (for cached data)
      final exercisesData = map['exercises'];
      if (exercisesData is List) {
        finalExercises = exercisesData
            .map((e) => TemplateExercise.fromMap(e as Map<String, dynamic>))
            .toList();
      }
    }
    
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
      exercises: finalExercises,
    );
  }

  /// Convert to SQLite Map (for database storage)
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

  /// Convert to complete Map including exercises (for caching/serialization)
  Map<String, dynamic> toCompleteMap() {
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
      'exercises': exercises.map((e) => e.toMap()).toList(),
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
    return Workout(
      workoutId: 'workout_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      name: customName ?? name,
      targetBodyParts: List.from(targetBodyParts),
      plannedDurationMinutes: estimatedDurationMinutes ?? 45,
      createdAt: DateTime.now(),
      status: WorkoutStatus.planned,
      exercises: exercises.map((templateExercise) => templateExercise.toWorkoutExercise()).toList(),
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

/// Represents a user's customized workout that preserves template references
/// This implements Option 1: Create Personal Copy approach for template preservation
class UserWorkout {
  final String userWorkoutId;
  final String userId;
  final String name;
  final String? baseTemplateId;          // Reference to original template
  final List<String> targetBodyParts;
  final int plannedDurationMinutes;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final int usageCount;
  final WorkoutSource source;
  final List<UserExercise> exercises;    // Customized exercise list
  final WorkoutCustomizations? modifications; // Track changes from template
  final String? notes;

  const UserWorkout({
    required this.userWorkoutId,
    required this.userId,
    required this.name,
    this.baseTemplateId,
    required this.targetBodyParts,
    required this.plannedDurationMinutes,
    required this.createdAt,
    this.lastUsedAt,
    this.usageCount = 0,
    required this.source,
    this.exercises = const [],
    this.modifications,
    this.notes,
  });

  /// Create UserWorkout from WorkoutTemplate with customizations
  factory UserWorkout.fromTemplate(
    WorkoutTemplate template, {
    required String userId,
    String? customName,
    List<UserExercise>? customExercises,
    WorkoutCustomizations? modifications,
  }) {
    print('🆕 [USER_WORKOUT] Creating user workout from template...');
    print('🆕 [USER_WORKOUT] Base template: ${template.name} (${template.templateId})');
    print('🆕 [USER_WORKOUT] User ID: $userId');
    
    final generatedName = customName ?? _generateCustomName(template.name);
    print('🆕 [USER_WORKOUT] Generated name: $generatedName');
    
    final exercises = customExercises ?? template.exercises.map((templateExercise) => 
      UserExercise.fromTemplateExercise(templateExercise)).toList();
    
    print('🆕 [USER_WORKOUT] Final exercise count: ${exercises.length}');
    
    return UserWorkout(
      userWorkoutId: 'user_workout_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      name: generatedName,
      baseTemplateId: template.templateId,
      targetBodyParts: List.from(template.targetBodyParts),
      plannedDurationMinutes: template.estimatedDurationMinutes ?? 45,
      createdAt: DateTime.now(),
      source: modifications != null ? WorkoutSource.userModified : WorkoutSource.fromTemplate,
      exercises: exercises,
      modifications: modifications,
    );
  }

  /// Create completely custom UserWorkout (not from template)
  factory UserWorkout.custom({
    required String userId,
    required String name,
    required List<String> targetBodyParts,
    required int plannedDurationMinutes,
    List<UserExercise> exercises = const [],
    String? notes,
  }) {
    print('🆕 [USER_WORKOUT] Creating custom user workout...');
    print('🆕 [USER_WORKOUT] Name: $name');
    print('🆕 [USER_WORKOUT] Target body parts: $targetBodyParts');
    
    return UserWorkout(
      userWorkoutId: 'user_workout_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      name: name,
      targetBodyParts: targetBodyParts,
      plannedDurationMinutes: plannedDurationMinutes,
      createdAt: DateTime.now(),
      source: WorkoutSource.userCustom,
      exercises: exercises,
      notes: notes,
    );
  }

  /// Convert UserWorkout to standard Workout for execution
  Workout toWorkout() {
    print('🔄 [USER_WORKOUT] Converting user workout to executable workout...');
    print('🔄 [USER_WORKOUT] User workout: $name');
    print('🔄 [USER_WORKOUT] Exercise count: ${exercises.length}');
    
    return Workout(
      workoutId: 'workout_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      name: name,
      targetBodyParts: List.from(targetBodyParts),
      plannedDurationMinutes: plannedDurationMinutes,
      createdAt: DateTime.now(),
      status: WorkoutStatus.planned,
      exercises: exercises.map((userExercise) => userExercise.toWorkoutExercise()).toList(),
      notes: notes,
    );
  }

  /// Generate custom name for modified templates
  static String _generateCustomName(String templateName) {
    return 'My $templateName';
  }

  /// Check if this workout has modifications from original template
  bool get hasModifications => modifications != null && modifications!.hasChanges;

  /// Get summary of modifications
  String get modificationSummary {
    if (!hasModifications) return 'No changes from template';
    
    final mod = modifications!;
    final changes = <String>[];
    
    if (mod.removedExerciseIds.isNotEmpty) {
      changes.add('${mod.removedExerciseIds.length} removed');
    }
    if (mod.addedExercises.isNotEmpty) {
      changes.add('${mod.addedExercises.length} added');
    }
    if (mod.modifiedExercises.isNotEmpty) {
      changes.add('${mod.modifiedExercises.length} modified');
    }
    
    return changes.join(', ');
  }

  /// Create copy with updated fields
  UserWorkout copyWith({
    String? name,
    List<String>? targetBodyParts,
    int? plannedDurationMinutes,
    List<UserExercise>? exercises,
    WorkoutCustomizations? modifications,
    String? notes,
  }) {
    return UserWorkout(
      userWorkoutId: userWorkoutId,
      userId: userId,
      name: name ?? this.name,
      baseTemplateId: baseTemplateId,
      targetBodyParts: targetBodyParts ?? this.targetBodyParts,
      plannedDurationMinutes: plannedDurationMinutes ?? this.plannedDurationMinutes,
      createdAt: createdAt,
      lastUsedAt: lastUsedAt,
      usageCount: usageCount,
      source: source,
      exercises: exercises ?? this.exercises,
      modifications: modifications ?? this.modifications,
      notes: notes ?? this.notes,
    );
  }
}

/// Represents the source/origin of a workout
enum WorkoutSource {
  systemTemplate,    // Direct from system template (unmodified)
  fromTemplate,      // Created from template but no modifications
  userModified,      // Modified from template
  userCustom,        // Built from scratch by user
}

/// Tracks customizations made to a template
class WorkoutCustomizations {
  final List<String> removedExerciseIds;
  final List<UserExercise> addedExercises;
  final Map<String, ExerciseModification> modifiedExercises;
  final DateTime modifiedAt;

  const WorkoutCustomizations({
    this.removedExerciseIds = const [],
    this.addedExercises = const [],
    this.modifiedExercises = const {},
    required this.modifiedAt,
  });

  /// Check if there are any modifications
  bool get hasChanges => 
    removedExerciseIds.isNotEmpty || 
    addedExercises.isNotEmpty || 
    modifiedExercises.isNotEmpty;

  /// Get total number of changes
  int get changeCount => 
    removedExerciseIds.length + 
    addedExercises.length + 
    modifiedExercises.length;
}

/// Represents modifications to a specific exercise
class ExerciseModification {
  final String exerciseId;
  final int? newSets;
  final int? newRepsMin;
  final int? newRepsMax;
  final double? newWeight;
  final int? newRestTime;
  final int? newOrderIndex;
  final DateTime modifiedAt;

  const ExerciseModification({
    required this.exerciseId,
    this.newSets,
    this.newRepsMin,
    this.newRepsMax,
    this.newWeight,
    this.newRestTime,
    this.newOrderIndex,
    required this.modifiedAt,
  });
}

/// User's customizable version of an exercise
class UserExercise {
  final String userExerciseId;
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
  final bool isFromTemplate;    // Track if this came from a template
  final String? sourceTemplateExerciseId; // Reference to original template exercise

  const UserExercise({
    required this.userExerciseId,
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
    this.isFromTemplate = false,
    this.sourceTemplateExerciseId,
  });

  /// Create UserExercise from TemplateExercise
  factory UserExercise.fromTemplateExercise(TemplateExercise templateExercise) {
    print('🔄 [USER_EXERCISE] Converting template exercise: ${templateExercise.exerciseName}');
    
    return UserExercise(
      userExerciseId: 'user_ex_${DateTime.now().millisecondsSinceEpoch}_${templateExercise.orderIndex}',
      exerciseId: templateExercise.exerciseId,
      exerciseName: templateExercise.exerciseName,
      bodyParts: List.from(templateExercise.bodyParts),
      orderIndex: templateExercise.orderIndex,
      suggestedSets: templateExercise.suggestedSets,
      suggestedRepsMin: templateExercise.suggestedRepsMin,
      suggestedRepsMax: templateExercise.suggestedRepsMax,
      suggestedWeight: templateExercise.suggestedWeight,
      restTimeSeconds: templateExercise.restTimeSeconds,
      notes: templateExercise.notes,
      isFromTemplate: true,
      sourceTemplateExerciseId: templateExercise.templateExerciseId,
    );
  }

  /// Create custom UserExercise (not from template)
  factory UserExercise.custom({
    required String exerciseId,
    required String exerciseName,
    required List<String> bodyParts,
    required int orderIndex,
    int suggestedSets = 3,
    int suggestedRepsMin = 8,
    int suggestedRepsMax = 12,
    double? suggestedWeight,
    int restTimeSeconds = 90,
    String? notes,
  }) {
    print('➕ [USER_EXERCISE] Creating custom exercise: $exerciseName');
    
    return UserExercise(
      userExerciseId: 'user_ex_${DateTime.now().millisecondsSinceEpoch}_$orderIndex',
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      bodyParts: bodyParts,
      orderIndex: orderIndex,
      suggestedSets: suggestedSets,
      suggestedRepsMin: suggestedRepsMin,
      suggestedRepsMax: suggestedRepsMax,
      suggestedWeight: suggestedWeight,
      restTimeSeconds: restTimeSeconds,
      notes: notes,
      isFromTemplate: false,
    );
  }

  /// Convert to WorkoutExercise for actual workout execution
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

  /// Get rep range as formatted string
  String get repsRange {
    if (suggestedRepsMin == suggestedRepsMax) {
      return '$suggestedRepsMin reps';
    }
    return '$suggestedRepsMin-$suggestedRepsMax reps';
  }

  /// Get weight as formatted string
  String get weightDisplay {
    if (suggestedWeight == null) return '';
    return suggestedWeight! % 1 == 0
        ? '${suggestedWeight!.toInt()}kg'
        : '${suggestedWeight}kg';
  }

  /// Create copy with updated fields
  UserExercise copyWith({
    int? orderIndex,
    int? suggestedSets,
    int? suggestedRepsMin,
    int? suggestedRepsMax,
    double? suggestedWeight,
    int? restTimeSeconds,
    String? notes,
  }) {
    return UserExercise(
      userExerciseId: userExerciseId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      bodyParts: bodyParts,
      orderIndex: orderIndex ?? this.orderIndex,
      suggestedSets: suggestedSets ?? this.suggestedSets,
      suggestedRepsMin: suggestedRepsMin ?? this.suggestedRepsMin,
      suggestedRepsMax: suggestedRepsMax ?? this.suggestedRepsMax,
      suggestedWeight: suggestedWeight ?? this.suggestedWeight,
      restTimeSeconds: restTimeSeconds ?? this.restTimeSeconds,
      notes: notes ?? this.notes,
      isFromTemplate: isFromTemplate,
      sourceTemplateExerciseId: sourceTemplateExerciseId,
    );
  }
}