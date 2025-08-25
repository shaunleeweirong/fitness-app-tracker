// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Exercise _$ExerciseFromJson(Map<String, dynamic> json) => Exercise(
  exerciseId: json['exerciseId'] as String,
  name: json['name'] as String,
  imageUrl: json['gifUrl'] as String,
  equipments: (json['equipments'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  bodyParts: (json['bodyParts'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  targetMuscles: (json['targetMuscles'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  secondaryMuscles: (json['secondaryMuscles'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  instructions: (json['instructions'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  exerciseType: json['exerciseType'] as String?,
  videoUrl: json['videoUrl'] as String?,
  keywords: (json['keywords'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  overview: json['overview'] as String?,
  exerciseTips: (json['exerciseTips'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  variations: (json['variations'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  relatedExerciseIds: (json['relatedExerciseIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$ExerciseToJson(Exercise instance) => <String, dynamic>{
  'exerciseId': instance.exerciseId,
  'name': instance.name,
  'gifUrl': instance.imageUrl,
  'equipments': instance.equipments,
  'bodyParts': instance.bodyParts,
  'targetMuscles': instance.targetMuscles,
  'secondaryMuscles': instance.secondaryMuscles,
  'instructions': instance.instructions,
  'exerciseType': instance.exerciseType,
  'videoUrl': instance.videoUrl,
  'keywords': instance.keywords,
  'overview': instance.overview,
  'exerciseTips': instance.exerciseTips,
  'variations': instance.variations,
  'relatedExerciseIds': instance.relatedExerciseIds,
};

ExerciseListResponse _$ExerciseListResponseFromJson(
  Map<String, dynamic> json,
) => ExerciseListResponse(
  exercises: (json['exercises'] as List<dynamic>)
      .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
);

Map<String, dynamic> _$ExerciseListResponseToJson(
  ExerciseListResponse instance,
) => <String, dynamic>{
  'exercises': instance.exercises,
  'total': instance.total,
  'page': instance.page,
  'limit': instance.limit,
};
