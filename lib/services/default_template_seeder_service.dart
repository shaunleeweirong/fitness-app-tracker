import '../models/workout.dart';
import '../models/exercise.dart';
import '../services/workout_template_repository.dart';
import '../services/common_exercise_service.dart';
import '../services/database_helper.dart';

/// Service for seeding default workout templates into the database
/// Creates 7 professional workout templates on first app launch
class DefaultTemplateSeederService {
  final WorkoutTemplateRepository _templateRepository = WorkoutTemplateRepository();
  final CommonExerciseService _exerciseService = CommonExerciseService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  static const String systemUserId = 'system_templates';

  /// Check if default templates have already been seeded
  Future<bool> areDefaultTemplatesSeeded() async {
    try {
      final templates = await _templateRepository.getTemplates(userId: systemUserId);
      return templates.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Seed all default templates if they don't exist
  Future<void> seedDefaultTemplatesIfNeeded() async {
    if (await areDefaultTemplatesSeeded()) {
      return; // Already seeded
    }

    await seedDefaultTemplates();
  }

  /// Create and save all 7 default workout templates
  Future<void> seedDefaultTemplates() async {
    final now = DateTime.now();
    
    // Load exercises from database
    final allExercises = await _exerciseService.getAllExercises();
    
    // Create all 7 templates
    final templates = [
      await _createChestTemplate(allExercises, now),
      await _createUpperLegsTemplate(allExercises, now),
      await _createBackTemplate(allExercises, now),
      await _createShouldersTemplate(allExercises, now),
      await _createArmsTemplate(allExercises, now),
      await _createPushTemplate(allExercises, now),
      await _createPullTemplate(allExercises, now),
    ];

    // Save all templates
    for (final template in templates) {
      await _templateRepository.saveTemplate(template);
    }
  }

  /// Create Chest Focus template
  Future<WorkoutTemplate> _createChestTemplate(List<Exercise> allExercises, DateTime now) async {
    final exercises = _selectExercisesByBodyPart(allExercises, ['chest'], 6);
    final templateExercises = _createTemplateExercises('chest_template', exercises);

    return WorkoutTemplate(
      templateId: 'chest_template',
      userId: systemUserId,
      name: 'Chest Focus',
      description: 'Complete chest development with compound and isolation movements',
      targetBodyParts: ['chest', 'shoulders', 'upper arms'],
      estimatedDurationMinutes: 45,
      difficulty: TemplateDifficulty.intermediate,
      category: TemplateCategory.push,
      createdAt: now,
      updatedAt: now,
      exercises: templateExercises,
    );
  }

  /// Create Upper Legs template
  Future<WorkoutTemplate> _createUpperLegsTemplate(List<Exercise> allExercises, DateTime now) async {
    final exercises = _selectExercisesByBodyPart(allExercises, ['upper legs'], 7);
    final templateExercises = _createTemplateExercises('upper_legs_template', exercises);

    return WorkoutTemplate(
      templateId: 'upper_legs_template',
      userId: systemUserId,
      name: 'Upper Legs Power',
      description: 'Build strong quads, glutes, and hamstrings with proven exercises',
      targetBodyParts: ['upper legs'],
      estimatedDurationMinutes: 45,
      difficulty: TemplateDifficulty.intermediate,
      category: TemplateCategory.legs,
      createdAt: now,
      updatedAt: now,
      exercises: templateExercises,
    );
  }

  /// Create Back Focus template
  Future<WorkoutTemplate> _createBackTemplate(List<Exercise> allExercises, DateTime now) async {
    final exercises = _selectExercisesByBodyPart(allExercises, ['back'], 6);
    final templateExercises = _createTemplateExercises('back_template', exercises);

    return WorkoutTemplate(
      templateId: 'back_template',
      userId: systemUserId,
      name: 'Back Builder',
      description: 'Comprehensive back training for width, thickness, and strength',
      targetBodyParts: ['back', 'upper arms'],
      estimatedDurationMinutes: 45,
      difficulty: TemplateDifficulty.intermediate,
      category: TemplateCategory.pull,
      createdAt: now,
      updatedAt: now,
      exercises: templateExercises,
    );
  }

  /// Create Shoulders template
  Future<WorkoutTemplate> _createShouldersTemplate(List<Exercise> allExercises, DateTime now) async {
    final exercises = _selectExercisesByBodyPart(allExercises, ['shoulders'], 6);
    final templateExercises = _createTemplateExercises('shoulders_template', exercises);

    return WorkoutTemplate(
      templateId: 'shoulders_template',
      userId: systemUserId,
      name: 'Shoulder Sculptor',
      description: 'Build powerful, well-rounded shoulders with targeted training',
      targetBodyParts: ['shoulders', 'upper arms'],
      estimatedDurationMinutes: 45,
      difficulty: TemplateDifficulty.intermediate,
      category: TemplateCategory.upperBody,
      createdAt: now,
      updatedAt: now,
      exercises: templateExercises,
    );
  }

  /// Create Arms template
  Future<WorkoutTemplate> _createArmsTemplate(List<Exercise> allExercises, DateTime now) async {
    final upperArmExercises = _selectExercisesByBodyPart(allExercises, ['upper arms'], 5);
    final lowerArmExercises = _selectExercisesByBodyPart(allExercises, ['lower arms'], 2);
    final allArmExercises = [...upperArmExercises, ...lowerArmExercises];
    final templateExercises = _createTemplateExercises('arms_template', allArmExercises);

    return WorkoutTemplate(
      templateId: 'arms_template',
      userId: systemUserId,
      name: 'Arm Destroyer',
      description: 'Complete arm development focusing on biceps, triceps, and forearms',
      targetBodyParts: ['upper arms', 'lower arms'],
      estimatedDurationMinutes: 45,
      difficulty: TemplateDifficulty.intermediate,
      category: TemplateCategory.upperBody,
      createdAt: now,
      updatedAt: now,
      exercises: templateExercises,
    );
  }

  /// Create Push Day template
  Future<WorkoutTemplate> _createPushTemplate(List<Exercise> allExercises, DateTime now) async {
    final chestExercises = _selectExercisesByBodyPart(allExercises, ['chest'], 3);
    final shoulderExercises = _selectExercisesByBodyPart(allExercises, ['shoulders'], 3);
    final tricepExercises = _selectExercisesByBodyPart(allExercises, ['upper arms'], 2)
        .where((ex) => ex.name.toLowerCase().contains('tricep') || 
                      ex.name.toLowerCase().contains('extension') ||
                      ex.name.toLowerCase().contains('dips')).toList();
    
    final allPushExercises = [...chestExercises, ...shoulderExercises, ...tricepExercises];
    final templateExercises = _createTemplateExercises('push_template', allPushExercises);

    return WorkoutTemplate(
      templateId: 'push_template',
      userId: systemUserId,
      name: 'Push Day',
      description: 'Complete pushing muscle workout: chest, shoulders, and triceps',
      targetBodyParts: ['chest', 'shoulders', 'upper arms'],
      estimatedDurationMinutes: 45,
      difficulty: TemplateDifficulty.intermediate,
      category: TemplateCategory.push,
      createdAt: now,
      updatedAt: now,
      exercises: templateExercises,
    );
  }

  /// Create Pull Day template
  Future<WorkoutTemplate> _createPullTemplate(List<Exercise> allExercises, DateTime now) async {
    final backExercises = _selectExercisesByBodyPart(allExercises, ['back'], 4);
    final bicepExercises = _selectExercisesByBodyPart(allExercises, ['upper arms'], 2)
        .where((ex) => ex.name.toLowerCase().contains('curl') || 
                      ex.name.toLowerCase().contains('bicep')).toList();
    final forearmExercises = _selectExercisesByBodyPart(allExercises, ['lower arms'], 1);
    
    final allPullExercises = [...backExercises, ...bicepExercises, ...forearmExercises];
    final templateExercises = _createTemplateExercises('pull_template', allPullExercises);

    return WorkoutTemplate(
      templateId: 'pull_template',
      userId: systemUserId,
      name: 'Pull Day',
      description: 'Complete pulling muscle workout: back, biceps, and forearms',
      targetBodyParts: ['back', 'upper arms', 'lower arms'],
      estimatedDurationMinutes: 45,
      difficulty: TemplateDifficulty.intermediate,
      category: TemplateCategory.pull,
      createdAt: now,
      updatedAt: now,
      exercises: templateExercises,
    );
  }

  /// Select exercises for specific body parts, prioritizing popular/compound movements
  List<Exercise> _selectExercisesByBodyPart(List<Exercise> allExercises, List<String> bodyParts, int count) {
    final filtered = allExercises.where((exercise) {
      return bodyParts.any((bodyPart) => exercise.bodyParts.contains(bodyPart));
    }).toList();

    // Sort by popularity using equipment-focused popularity logic
    filtered.sort((a, b) {
      final aPopular = _isExercisePopular(a) ? 1 : 0;
      final bPopular = _isExercisePopular(b) ? 1 : 0;
      return bPopular.compareTo(aPopular);
    });

    // Return requested count, or all if less available
    return filtered.take(count).toList();
  }

  /// Create TemplateExercise objects from exercise data
  List<TemplateExercise> _createTemplateExercises(String templateId, List<Exercise> exercises) {
    final templateExercises = <TemplateExercise>[];
    
    for (int i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];
      final exerciseId = exercise.exerciseId;
      
      templateExercises.add(TemplateExercise(
        templateExerciseId: '${templateId}_$exerciseId',
        templateId: templateId,
        exerciseId: exerciseId,
        exerciseName: exercise.name,
        bodyParts: List<String>.from(exercise.bodyParts),
        orderIndex: i,
        suggestedSets: _getSuggestedSets(exercise.name),
        suggestedRepsMin: _getSuggestedRepsMin(exercise.name),
        suggestedRepsMax: _getSuggestedRepsMax(exercise.name),
        restTimeSeconds: 90,
        notes: 'Focus on controlled movement and proper form',
      ));
    }
    
    return templateExercises;
  }

  /// Get suggested sets based on exercise type
  int _getSuggestedSets(String exerciseName) {
    final name = exerciseName.toLowerCase();
    
    // Compound movements get more sets
    if (name.contains('squat') || name.contains('deadlift') || 
        name.contains('bench press') || name.contains('row')) {
      return 4;
    }
    
    // Isolation movements get standard sets
    return 3;
  }

  /// Get suggested minimum reps based on exercise type
  int _getSuggestedRepsMin(String exerciseName) {
    final name = exerciseName.toLowerCase();
    
    // Heavy compound movements
    if (name.contains('squat') || name.contains('deadlift') || name.contains('bench press')) {
      return 6;
    }
    
    // Isolation and accessory work
    if (name.contains('curl') || name.contains('extension') || name.contains('raise')) {
      return 10;
    }
    
    // Standard range
    return 8;
  }

  /// Get suggested maximum reps based on exercise type
  int _getSuggestedRepsMax(String exerciseName) {
    final name = exerciseName.toLowerCase();
    
    // Heavy compound movements
    if (name.contains('squat') || name.contains('deadlift') || name.contains('bench press')) {
      return 8;
    }
    
    // Isolation and accessory work
    if (name.contains('curl') || name.contains('extension') || name.contains('raise')) {
      return 15;
    }
    
    // Standard range
    return 12;
  }

  /// Determine if an exercise is popular using equipment-focused logic
  bool _isExercisePopular(Exercise exercise) {
    final name = exercise.name.toLowerCase();
    final equipment = exercise.equipments.join(' ').toLowerCase();
    
    // Equipment-based patterns (Highest Priority)
    final equipmentPriorities = [
      'barbell', 'dumbbell', 'machine', 'cable'
    ];
    
    if (equipmentPriorities.any((eq) => equipment.contains(eq))) {
      // Core movement patterns for equipment exercises
      final corePatterns = [
        'squat', 'deadlift', 'bench press', 'row', 
        'press', 'curl', 'extension', 'fly', 'raise', 'pulldown'
      ];
      
      if (corePatterns.any((pattern) => name.contains(pattern))) {
        return true;
      }
    }
    
    // Essential bodyweight movements (selective)
    if (equipment.contains('body weight')) {
      final essentialBodyweight = [
        'push-up', 'pull-up', 'chin-up', 'dip'
      ];
      
      return essentialBodyweight.any((pattern) => name.contains(pattern)) &&
             !name.contains('wide') && !name.contains('diamond') && 
             !name.contains('incline') && !name.contains('decline') &&
             !name.contains('pike') && !name.contains('archer');
    }
    
    return false;
  }

  /// Close database connections
  Future<void> close() async {
    await _templateRepository.close();
  }
}