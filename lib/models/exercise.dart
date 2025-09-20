import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';

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
  
  /// Check if exercise matches a template category
  bool matchesTemplateCategory(String templateCategory) {
    try {
      final categoryLower = templateCategory.toLowerCase();
      
      switch (categoryLower) {
        case 'strength':
          return _isStrengthExercise();
        case 'cardio':
          return _isCardioExercise();
        case 'fullbody':
          return _isFullBodyExercise();
        case 'upperbody':
          return _isUpperBodyExercise();
        case 'lowerbody':
          return _isLowerBodyExercise();
        case 'push':
          return _isPushExercise();
        case 'pull':
          return _isPullExercise();
        case 'legs':
          return _isLegExercise();
        case 'custom':
          return true; // Custom category includes all exercises
        default:
          debugPrint('⚠️ Unknown template category: $templateCategory, defaulting to true');
          return true;
      }
    } catch (e) {
      debugPrint('❌ Error filtering exercise ${name} by category $templateCategory: $e');
      return true; // Include exercise if filtering fails
    }
  }
  
  bool _isStrengthExercise() {
    // Check exercise type first
    if (safeExerciseType.toLowerCase() == 'strength') return true;
    
    // Check for strength-based equipment
    final strengthEquipment = ['barbell', 'dumbbell', 'kettlebell', 'weight', 'machine', 'cable'];
    if (equipments.any((eq) => strengthEquipment.any((str) => eq.toLowerCase().contains(str)))) {
      return true;
    }
    
    // Check for strength movement patterns
    final strengthPatterns = ['squat', 'deadlift', 'bench', 'press', 'row', 'curl', 'extension'];
    return strengthPatterns.any((pattern) => name.toLowerCase().contains(pattern));
  }
  
  bool _isCardioExercise() {
    if (safeExerciseType.toLowerCase() == 'cardio') return true;
    
    final cardioKeywords = ['running', 'cycling', 'rowing', 'jumping', 'burpee', 'mountain climber', 'high knees'];
    return cardioKeywords.any((keyword) => name.toLowerCase().contains(keyword)) ||
           equipments.any((eq) => ['treadmill', 'bike', 'rower', 'elliptical'].contains(eq.toLowerCase()));
  }
  
  bool _isFullBodyExercise() {
    // Compound movements that work multiple body parts
    final fullBodyPatterns = ['deadlift', 'clean', 'snatch', 'thruster', 'burpee', 'turkish'];
    if (fullBodyPatterns.any((pattern) => name.toLowerCase().contains(pattern))) return true;
    
    // Check if exercise targets multiple major body parts
    final majorBodyParts = ['chest', 'back', 'legs', 'shoulders', 'arms'];
    final targetedParts = bodyParts.where((part) => 
      majorBodyParts.any((major) => part.toLowerCase().contains(major))
    ).length;
    
    return targetedParts >= 2;
  }
  
  bool _isUpperBodyExercise() {
    final upperBodyParts = ['chest', 'back', 'shoulders', 'arms', 'biceps', 'triceps', 'lats'];
    return bodyParts.any((part) => 
      upperBodyParts.any((upper) => part.toLowerCase().contains(upper))
    );
  }
  
  bool _isLowerBodyExercise() {
    final lowerBodyParts = ['legs', 'quads', 'hamstrings', 'glutes', 'calves', 'thighs'];
    return bodyParts.any((part) => 
      lowerBodyParts.any((lower) => part.toLowerCase().contains(lower))
    );
  }
  
  bool _isPushExercise() {
    // Push movements primarily target chest, shoulders, triceps
    final pushBodyParts = ['chest', 'shoulders', 'triceps'];
    final pushPatterns = ['press', 'push', 'fly', 'dip'];
    
    return bodyParts.any((part) => 
      pushBodyParts.any((push) => part.toLowerCase().contains(push))
    ) || pushPatterns.any((pattern) => name.toLowerCase().contains(pattern));
  }
  
  bool _isPullExercise() {
    // Pull movements primarily target back, biceps
    final pullBodyParts = ['back', 'biceps', 'lats'];
    final pullPatterns = ['pull', 'row', 'curl', 'chin', 'lat'];
    
    return bodyParts.any((part) => 
      pullBodyParts.any((pull) => part.toLowerCase().contains(pull))
    ) || pullPatterns.any((pattern) => name.toLowerCase().contains(pattern));
  }
  
  bool _isLegExercise() {
    final legBodyParts = ['legs', 'quads', 'hamstrings', 'glutes', 'calves'];
    final legPatterns = ['squat', 'lunge', 'leg', 'calf'];
    
    return bodyParts.any((part) => 
      legBodyParts.any((leg) => part.toLowerCase().contains(leg))
    ) || legPatterns.any((pattern) => name.toLowerCase().contains(pattern));
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