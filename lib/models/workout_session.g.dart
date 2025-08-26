// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkoutSession _$WorkoutSessionFromJson(Map<String, dynamic> json) =>
    WorkoutSession(
      sessionId: json['sessionId'] as String,
      userId: json['userId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      exerciseSets: (json['exerciseSets'] as List<dynamic>)
          .map((e) => ExerciseSet.fromJson(e as Map<String, dynamic>))
          .toList(),
      bodyPartVolumeMap: (json['bodyPartVolumeMap'] as Map<String, dynamic>)
          .map((k, e) => MapEntry(k, (e as num).toDouble())),
      totalVolume: (json['totalVolume'] as num).toDouble(),
      duration: Duration(microseconds: (json['duration'] as num).toInt()),
      isCompleted: json['isCompleted'] as bool,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$WorkoutSessionToJson(WorkoutSession instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'userId': instance.userId,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'exerciseSets': instance.exerciseSets,
      'bodyPartVolumeMap': instance.bodyPartVolumeMap,
      'totalVolume': instance.totalVolume,
      'duration': instance.duration.inMicroseconds,
      'isCompleted': instance.isCompleted,
      'notes': instance.notes,
    };

ExerciseSet _$ExerciseSetFromJson(Map<String, dynamic> json) => ExerciseSet(
  exerciseId: json['exerciseId'] as String,
  exerciseName: json['exerciseName'] as String,
  bodyParts: (json['bodyParts'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  weight: (json['weight'] as num).toDouble(),
  reps: (json['reps'] as num).toInt(),
  setNumber: (json['setNumber'] as num).toInt(),
  timestamp: DateTime.parse(json['timestamp'] as String),
  restTime: json['restTime'] == null
      ? null
      : Duration(microseconds: (json['restTime'] as num).toInt()),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$ExerciseSetToJson(ExerciseSet instance) =>
    <String, dynamic>{
      'exerciseId': instance.exerciseId,
      'exerciseName': instance.exerciseName,
      'bodyParts': instance.bodyParts,
      'weight': instance.weight,
      'reps': instance.reps,
      'setNumber': instance.setNumber,
      'timestamp': instance.timestamp.toIso8601String(),
      'restTime': instance.restTime?.inMicroseconds,
      'notes': instance.notes,
    };
