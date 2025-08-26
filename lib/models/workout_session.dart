import 'package:json_annotation/json_annotation.dart';

part 'workout_session.g.dart';

@JsonSerializable()
class WorkoutSession {
  final String sessionId;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final List<ExerciseSet> exerciseSets;
  final Map<String, double> bodyPartVolumeMap; // bodyPart -> total volume
  final double totalVolume;
  final Duration duration;
  final bool isCompleted;
  final String? notes;

  const WorkoutSession({
    required this.sessionId,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.exerciseSets,
    required this.bodyPartVolumeMap,
    required this.totalVolume,
    required this.duration,
    required this.isCompleted,
    this.notes,
  });

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => _$WorkoutSessionFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutSessionToJson(this);

  /// Create a new session for starting a workout
  factory WorkoutSession.start({
    required String sessionId,
    required String userId,
    String? notes,
  }) {
    return WorkoutSession(
      sessionId: sessionId,
      userId: userId,
      startTime: DateTime.now(),
      exerciseSets: [],
      bodyPartVolumeMap: {},
      totalVolume: 0.0,
      duration: Duration.zero,
      isCompleted: false,
      notes: notes,
    );
  }

  /// Complete the workout session with calculations
  WorkoutSession complete() {
    final now = DateTime.now();
    final sessionDuration = endTime != null ? endTime!.difference(startTime) : now.difference(startTime);
    
    // Calculate volume per body part
    final Map<String, double> volumeMap = {};
    double totalVol = 0.0;
    
    for (final exerciseSet in exerciseSets) {
      final volume = exerciseSet.calculateVolume();
      totalVol += volume;
      
      for (final bodyPart in exerciseSet.bodyParts) {
        volumeMap[bodyPart] = (volumeMap[bodyPart] ?? 0.0) + volume;
      }
    }
    
    return WorkoutSession(
      sessionId: sessionId,
      userId: userId,
      startTime: startTime,
      endTime: now,
      exerciseSets: exerciseSets,
      bodyPartVolumeMap: volumeMap,
      totalVolume: totalVol,
      duration: sessionDuration,
      isCompleted: true,
      notes: notes,
    );
  }

  /// Add an exercise set to the session
  WorkoutSession addExerciseSet(ExerciseSet exerciseSet) {
    return WorkoutSession(
      sessionId: sessionId,
      userId: userId,
      startTime: startTime,
      endTime: endTime,
      exerciseSets: [...exerciseSets, exerciseSet],
      bodyPartVolumeMap: bodyPartVolumeMap,
      totalVolume: totalVolume,
      duration: duration,
      isCompleted: isCompleted,
      notes: notes,
    );
  }

  /// Get unique body parts worked in this session
  Set<String> get bodyPartsWorked {
    return exerciseSets
        .expand((set) => set.bodyParts)
        .toSet();
  }

  /// Get total number of sets completed
  int get totalSets => exerciseSets.length;

  /// Get total number of exercises
  int get totalExercises => exerciseSets.map((set) => set.exerciseId).toSet().length;
}

@JsonSerializable()
class ExerciseSet {
  final String exerciseId;
  final String exerciseName;
  final List<String> bodyParts;
  final double weight;
  final int reps;
  final int setNumber;
  final DateTime timestamp;
  final Duration? restTime;
  final String? notes;

  const ExerciseSet({
    required this.exerciseId,
    required this.exerciseName,
    required this.bodyParts,
    required this.weight,
    required this.reps,
    required this.setNumber,
    required this.timestamp,
    this.restTime,
    this.notes,
  });

  factory ExerciseSet.fromJson(Map<String, dynamic> json) => _$ExerciseSetFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseSetToJson(this);

  /// Calculate volume for this set (weight × reps)
  double calculateVolume() => weight * reps;

  /// Get primary body part
  String get primaryBodyPart => bodyParts.isNotEmpty ? bodyParts.first : 'unknown';
}