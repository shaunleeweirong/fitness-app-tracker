/// Personal Record model for tracking exercise PRs
/// Tracks the best performance for each exercise per user

enum PersonalRecordType {
  weight,      // Heaviest single rep
  volume,      // Best single set volume (weight × reps)
  reps,        // Most reps at a given weight
}

class PersonalRecord {
  final String recordId;
  final String userId;
  final String exerciseId;
  final String exerciseName;
  final PersonalRecordType type;
  final double value;           // Weight in kg, volume in kg, or rep count
  final double? secondaryValue; // For reps PR: the weight used
  final DateTime achievedAt;
  final String? workoutId;      // Reference to the workout where PR was achieved
  final String? notes;

  const PersonalRecord({
    required this.recordId,
    required this.userId,
    required this.exerciseId,
    required this.exerciseName,
    required this.type,
    required this.value,
    this.secondaryValue,
    required this.achievedAt,
    this.workoutId,
    this.notes,
  });

  // Factory constructor from SQLite Map
  factory PersonalRecord.fromMap(Map<String, dynamic> map) {
    return PersonalRecord(
      recordId: map['record_id'] as String,
      userId: map['user_id'] as String,
      exerciseId: map['exercise_id'] as String,
      exerciseName: map['exercise_name'] as String,
      type: PersonalRecordType.values[map['type'] as int],
      value: (map['value'] as num).toDouble(),
      secondaryValue: map['secondary_value'] != null ? (map['secondary_value'] as num).toDouble() : null,
      achievedAt: DateTime.parse(map['achieved_at'] as String),
      workoutId: map['workout_id'] as String?,
      notes: map['notes'] as String?,
    );
  }

  // Convert to SQLite Map
  Map<String, dynamic> toMap() {
    return {
      'record_id': recordId,
      'user_id': userId,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'type': type.index,
      'value': value,
      'secondary_value': secondaryValue,
      'achieved_at': achievedAt.toIso8601String(),
      'workout_id': workoutId,
      'notes': notes,
    };
  }

  // Helper methods
  String get formattedValue {
    switch (type) {
      case PersonalRecordType.weight:
        return '${value % 1 == 0 ? value.toInt() : value}kg';
      case PersonalRecordType.volume:
        return '${value.toStringAsFixed(0)}kg volume';
      case PersonalRecordType.reps:
        final weightStr = secondaryValue != null 
            ? '${secondaryValue! % 1 == 0 ? secondaryValue!.toInt() : secondaryValue}kg'
            : 'bodyweight';
        return '${value.toInt()} reps @ $weightStr';
    }
  }

  String get displayTitle {
    switch (type) {
      case PersonalRecordType.weight:
        return 'Heaviest Weight';
      case PersonalRecordType.volume:
        return 'Best Volume';
      case PersonalRecordType.reps:
        return 'Most Reps';
    }
  }

  String get shortDescription {
    return '$displayTitle: $formattedValue';
  }

  // Create a copy with updated fields
  PersonalRecord copyWith({
    String? recordId,
    String? userId,
    String? exerciseId,
    String? exerciseName,
    PersonalRecordType? type,
    double? value,
    double? secondaryValue,
    DateTime? achievedAt,
    String? workoutId,
    String? notes,
  }) {
    return PersonalRecord(
      recordId: recordId ?? this.recordId,
      userId: userId ?? this.userId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      type: type ?? this.type,
      value: value ?? this.value,
      secondaryValue: secondaryValue ?? this.secondaryValue,
      achievedAt: achievedAt ?? this.achievedAt,
      workoutId: workoutId ?? this.workoutId,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalRecord &&
          runtimeType == other.runtimeType &&
          recordId == other.recordId;

  @override
  int get hashCode => recordId.hashCode;

  @override
  String toString() {
    return 'PersonalRecord{$exerciseName: $shortDescription}';
  }
}

/// Helper class for creating PersonalRecord from WorkoutSet
extension PersonalRecordFromSet on PersonalRecord {
  static PersonalRecord fromWorkoutSet({
    required String userId,
    required String exerciseId,
    required String exerciseName,
    required double weight,
    required int reps,
    required PersonalRecordType type,
    required DateTime achievedAt,
    String? workoutId,
  }) {
    late double value;
    double? secondaryValue;
    
    switch (type) {
      case PersonalRecordType.weight:
        value = weight;
        break;
      case PersonalRecordType.volume:
        value = weight * reps;
        break;
      case PersonalRecordType.reps:
        value = reps.toDouble();
        secondaryValue = weight;
        break;
    }

    return PersonalRecord(
      recordId: '${userId}_${exerciseId}_${type.name}_${achievedAt.millisecondsSinceEpoch}',
      userId: userId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      type: type,
      value: value,
      secondaryValue: secondaryValue,
      achievedAt: achievedAt,
      workoutId: workoutId,
    );
  }
}