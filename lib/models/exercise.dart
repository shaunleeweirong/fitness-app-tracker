import 'package:json_annotation/json_annotation.dart';

part 'exercise.g.dart';

@JsonSerializable()
class Exercise {
  final String exerciseId;
  final String name;
  @JsonKey(name: 'gifUrl')
  final String imageUrl;  // Map gifUrl to imageUrl for compatibility
  final List<String> equipments;
  final List<String> bodyParts;
  final List<String> targetMuscles;
  final List<String> secondaryMuscles;
  final List<String> instructions;
  
  // Optional fields that may not be in API response
  final String? exerciseType;
  final String? videoUrl;
  final List<String>? keywords;
  final String? overview;
  final List<String>? exerciseTips;
  final List<String>? variations;
  final List<String>? relatedExerciseIds;

  const Exercise({
    required this.exerciseId,
    required this.name,
    required this.imageUrl,
    required this.equipments,
    required this.bodyParts,
    required this.targetMuscles,
    required this.secondaryMuscles,
    required this.instructions,
    this.exerciseType,
    this.videoUrl,
    this.keywords,
    this.overview,
    this.exerciseTips,
    this.variations,
    this.relatedExerciseIds,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) => _$ExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseToJson(this);

  // Helper methods for UI
  String get primaryBodyPart => bodyParts.isNotEmpty ? bodyParts.first : '';
  String get primaryEquipment => equipments.isNotEmpty ? equipments.first : '';
  String get primaryTargetMuscle => targetMuscles.isNotEmpty ? targetMuscles.first : '';
  
  // Handle optional fields safely
  String get gifUrl => imageUrl; // For GIF support
  List<String> get safeKeywords => keywords ?? [];
  List<String> get safeExerciseTips => exerciseTips ?? [];
  List<String> get safeVariations => variations ?? [];
  List<String> get safeRelatedIds => relatedExerciseIds ?? [];
  String get safeOverview => overview ?? 'No description available';
  String get safeExerciseType => exerciseType ?? 'strength';
  
  bool matchesBodyPart(String bodyPart) {
    return bodyParts.any((part) => part.toLowerCase().contains(bodyPart.toLowerCase()));
  }
  
  bool matchesSearch(String query) {
    final searchLower = query.toLowerCase();
    return name.toLowerCase().contains(searchLower) ||
           bodyParts.any((part) => part.toLowerCase().contains(searchLower)) ||
           equipments.any((equipment) => equipment.toLowerCase().contains(searchLower)) ||
           targetMuscles.any((muscle) => muscle.toLowerCase().contains(searchLower)) ||
           safeKeywords.any((keyword) => keyword.toLowerCase().contains(searchLower));
  }
}

@JsonSerializable()
class ExerciseListResponse {
  final List<Exercise> exercises;
  final int total;
  final int page;
  final int limit;

  const ExerciseListResponse({
    required this.exercises,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory ExerciseListResponse.fromJson(Map<String, dynamic> json) => _$ExerciseListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseListResponseToJson(this);
}