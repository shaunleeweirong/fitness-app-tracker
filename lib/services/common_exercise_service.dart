import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/exercise.dart';

/// Service for managing the curated common exercise database
/// Provides 483+ premium gym exercises with popularity-based selection for immediate use
class CommonExerciseService {
  static const String _assetPath = 'assets/data/common_exercises_database.json';
  
  Map<String, dynamic>? _database;
  Map<String, List<Exercise>>? _exercisesByBodyPart;
  List<Exercise>? _allExercises;
  
  // Singleton pattern
  static final CommonExerciseService _instance = CommonExerciseService._internal();
  factory CommonExerciseService() => _instance;
  CommonExerciseService._internal();

  /// Initialize the service by loading the common exercise database
  Future<void> initialize() async {
    if (_database != null) return; // Already initialized
    
    try {
      print('🔄 Loading common exercise database...');
      final String jsonString = await rootBundle.loadString(_assetPath);
      _database = jsonDecode(jsonString);
      
      _parseExerciseData();
      
      final totalExercises = _allExercises?.length ?? 0;
      final bodyPartCount = _exercisesByBodyPart?.length ?? 0;
      
      print('✅ Common exercise database loaded successfully');
      print('   📊 Total exercises: $totalExercises');
      print('   🎯 Body parts covered: $bodyPartCount');
      
    } catch (e) {
      print('❌ Failed to load common exercise database: $e');
      _initializeEmptyDatabase();
    }
  }

  /// Parse the loaded JSON data into Exercise objects
  void _parseExerciseData() {
    _exercisesByBodyPart = <String, List<Exercise>>{};
    _allExercises = <Exercise>[];
    
    final bodyParts = _database!['body_parts'] as Map<String, dynamic>;
    
    for (final entry in bodyParts.entries) {
      final bodyPart = entry.key;
      final bodyPartData = entry.value as Map<String, dynamic>;
      final exerciseList = bodyPartData['exercises'] as List<dynamic>;
      
      final exercises = exerciseList.map((exerciseJson) {
        return Exercise(
          exerciseId: exerciseJson['exerciseId'] as String,
          name: exerciseJson['name'] as String,
          imageUrl: exerciseJson['gifUrl'] as String? ?? '',
          equipments: (exerciseJson['equipments'] as List<dynamic>?)?.cast<String>() ?? [],
          bodyParts: (exerciseJson['bodyParts'] as List<dynamic>?)?.cast<String>() ?? [],
          exerciseType: exerciseJson['exerciseType'] as String?,
          targetMuscles: (exerciseJson['targetMuscles'] as List<dynamic>?)?.cast<String>() ?? [],
          secondaryMuscles: (exerciseJson['secondaryMuscles'] as List<dynamic>?)?.cast<String>() ?? [],
          videoUrl: exerciseJson['videoUrl'] as String?,
          keywords: (exerciseJson['keywords'] as List<dynamic>?)?.cast<String>(),
          overview: exerciseJson['overview'] as String?,
          instructions: (exerciseJson['instructions'] as List<dynamic>?)?.cast<String>() ?? [],
          exerciseTips: (exerciseJson['exerciseTips'] as List<dynamic>?)?.cast<String>(),
          variations: (exerciseJson['variations'] as List<dynamic>?)?.cast<String>(),
          relatedExerciseIds: (exerciseJson['relatedExerciseIds'] as List<dynamic>?)?.cast<String>(),
        );
      }).toList();
      
      _exercisesByBodyPart![bodyPart] = exercises;
      _allExercises!.addAll(exercises);
    }
  }

  /// Initialize empty database as fallback
  void _initializeEmptyDatabase() {
    _database = {
      'metadata': {
        'total_exercises': 0,
        'total_body_parts': 0,
      },
      'body_parts': <String, dynamic>{},
    };
    _exercisesByBodyPart = <String, List<Exercise>>{};
    _allExercises = <Exercise>[];
  }

  /// Get all common exercises
  Future<List<Exercise>> getAllExercises() async {
    await initialize();
    final exercises = List<Exercise>.from(_allExercises ?? []);
    _sortByPopularity(exercises);
    return exercises;
  }

  /// Get exercises for a specific body part
  Future<List<Exercise>> getExercisesByBodyPart(String bodyPart) async {
    await initialize();
    final exercises = List<Exercise>.from(_exercisesByBodyPart?[bodyPart.toLowerCase()] ?? []);
    _sortByPopularity(exercises);
    return exercises;
  }

  /// Get available body parts
  Future<List<String>> getBodyParts() async {
    await initialize();
    return _exercisesByBodyPart?.keys.toList() ?? [];
  }

  /// Search exercises by name or keywords
  Future<List<Exercise>> searchExercises(String query) async {
    await initialize();
    
    if (query.isEmpty) return getAllExercises();
    
    final queryLower = query.toLowerCase();
    final allExercises = await getAllExercises();
    
    final searchResults = allExercises.where((exercise) {
      // Search in exercise name
      if (exercise.name.toLowerCase().contains(queryLower)) return true;
      
      // Search in target muscles
      if (exercise.targetMuscles.any((muscle) => 
          muscle.toLowerCase().contains(queryLower))) return true;
      
      // Search in equipment
      if (exercise.equipments.any((equipment) => 
          equipment.toLowerCase().contains(queryLower))) return true;
      
      // Search in keywords if available
      if (exercise.keywords?.any((keyword) => 
          keyword.toLowerCase().contains(queryLower)) == true) return true;
      
      return false;
    }).toList();
    
    _sortByPopularity(searchResults);
    return searchResults;
  }

  /// Get exercises by equipment type
  Future<List<Exercise>> getExercisesByEquipment(String equipment) async {
    await initialize();
    final allExercises = await getAllExercises();
    
    final equipmentResults = allExercises.where((exercise) =>
      exercise.equipments.any((eq) => 
        eq.toLowerCase().contains(equipment.toLowerCase()))
    ).toList();
    
    _sortByPopularity(equipmentResults);
    return equipmentResults;
  }

  /// Get a specific exercise by ID
  Future<Exercise?> getExerciseById(String exerciseId) async {
    await initialize();
    final allExercises = await getAllExercises();
    
    try {
      return allExercises.firstWhere((exercise) => exercise.exerciseId == exerciseId);
    } catch (e) {
      return null;
    }
  }

  /// Get database metadata
  Future<Map<String, dynamic>> getMetadata() async {
    await initialize();
    return Map.from(_database?['metadata'] ?? {});
  }

  /// Get statistics about the common exercise database
  Future<Map<String, int>> getStats() async {
    await initialize();
    
    final stats = <String, int>{};
    
    // Total exercises
    stats['total_exercises'] = _allExercises?.length ?? 0;
    
    // Exercises per body part
    for (final entry in (_exercisesByBodyPart ?? {}).entries) {
      stats['${entry.key}_exercises'] = entry.value.length;
    }
    
    // Equipment distribution
    final equipmentCount = <String, int>{};
    for (final exercise in _allExercises ?? []) {
      for (final equipment in exercise.equipments) {
        equipmentCount[equipment] = (equipmentCount[equipment] ?? 0) + 1;
      }
    }
    
    // Add top equipment types to stats
    final sortedEquipment = equipmentCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (int i = 0; i < sortedEquipment.length && i < 5; i++) {
      final equipment = sortedEquipment[i];
      stats['equipment_${equipment.key.replaceAll(' ', '_')}_count'] = equipment.value;
    }
    
    return stats;
  }

  /// Get random exercises for discovery/recommendations
  Future<List<Exercise>> getRandomExercises(int count) async {
    await initialize();
    final allExercises = await getAllExercises();
    
    if (allExercises.length <= count) return allExercises;
    
    allExercises.shuffle();
    final randomResults = allExercises.take(count).toList();
    _sortByPopularity(randomResults);
    return randomResults;
  }

  /// Check if the database is loaded and available
  bool get isInitialized => _database != null;
  
  /// Get the number of exercises available
  int get exerciseCount => _allExercises?.length ?? 0;
  
  /// Get the number of body parts covered
  int get bodyPartCount => _exercisesByBodyPart?.length ?? 0;

  /// Sort exercises with popular exercises first
  void _sortByPopularity(List<Exercise> exercises) {
    exercises.sort((a, b) {
      final aIsPopular = _isPopularExercise(a);
      final bIsPopular = _isPopularExercise(b);
      
      // Popular exercises come first
      if (aIsPopular && !bIsPopular) return -1;
      if (!aIsPopular && bIsPopular) return 1;
      
      // Both same popularity level - maintain existing order
      return 0;
    });
  }

  /// Determine if an exercise is popular (prioritizing equipment-based exercises)
  bool _isPopularExercise(Exercise exercise) {
    final name = exercise.name.toLowerCase();
    
    // Exclude advanced/niche variations that shouldn't be popular
    final excludePatterns = [
      'single leg', 'single arm', 'one leg', 'one arm',
      'alternating', 'bulgarian', 'pistol', 'archer',
      'deficit', 'pause', 'tempo', 'isometric', 'eccentric',
      'assisted', 'with support', 'rehabilitation', 'therapy',
      'smith machine', 'lever machine', 'cable machine',
      'plyometric', 'explosive', 'pulsing', 'static', 'dynamic',
      'curtsey', 'sumo', 'zercher', 'jefferson',
      'hindu', 'cossack', 'shrimp', 'sissy',
      'jump', 'jumping', 'hop', 'bounce',
      'reverse', 'inverted', 'twisted', 'twisting',
      'kneeling', 'lying', 'seated', 'bent over',
      'wide grip', 'narrow grip', 'close grip',
      'behind neck', 'behind head', 'between',
      'finger', 'wrist', 'thumb', 'forearm',
      'v.', 'v2', 'variation', 'advanced',
      'tennis ball', 'exercise ball', 'on the wall',
      'staircase', 'step up', 'step down', 'drop',
      'three', 'two', 'double', 'triple',
      'suspended', 'potty', 'modified', 'split',
      'side', 'lateral', 'front', 'rear',
      'alternate', 'rotating', 'rotation',
      'concentration', 'isolation', 'hammer',
      'cable', 'band', 'swiss ball', 'bosu',
      'wall', 'on bench', 'with bench',
      'male', 'female', 'beginner', 'intermediate',
      'waiter', 'cross', 'neutral grip', 'palm',
      'groin', 'inner', 'outer',
      'power point', 'hanging', 'flexion',
      'zottman', 'preacher', 'korean', 'clap',
      'wide hand', 'donkey', 'rocking', 'straight leg',
    ];
    
    // Early return if exercise contains excluded patterns
    for (final pattern in excludePatterns) {
      if (name.contains(pattern)) {
        return false;
      }
    }
    
    // Check if exercise uses equipment (prioritize over bodyweight)
    final hasEquipment = exercise.equipments.isNotEmpty && 
        !exercise.equipments.every((eq) => eq.toLowerCase().contains('body weight'));
    
    // Equipment-based core movements (highest priority)
    final equipmentBasedPatterns = [
      'barbell squat', 'barbell deadlift', 'barbell bench press', 'barbell row',
      'dumbbell press', 'dumbbell row', 'dumbbell fly', 'dumbbell curl',
      'lat pulldown', 'pulldown', 'leg press', 'machine press',
      'cable row', 'cable fly', 'tricep extension', 'leg extension',
      'leg curl', 'calf raise', 'shoulder press', 'chest press'
    ];
    
    // Check equipment-based patterns first
    for (final pattern in equipmentBasedPatterns) {
      if (name.contains(pattern)) {
        return true;
      }
    }
    
    // If exercise uses equipment, check core movement patterns
    if (hasEquipment) {
      final coreMovementPatterns = [
        'squat', 'deadlift', 'bench press', 'row', 'press',
        'curl', 'extension', 'fly', 'raise', 'pulldown'
      ];
      
      for (final pattern in coreMovementPatterns) {
        if (name.contains(pattern)) {
          return true;
        }
      }
    }
    
    // Only allow select bodyweight exercises that are truly essential
    final essentialBodyweightPatterns = [
      'push up', 'pushup', 'pull up', 'pullup', 'chin up', 'chin-up',
      'dip' // Only basic dips, not all variations
    ];
    
    for (final pattern in essentialBodyweightPatterns) {
      if (name.contains(pattern)) {
        // Extra check: avoid variations of bodyweight exercises
        if (!name.contains('wide') && !name.contains('diamond') && 
            !name.contains('incline') && !name.contains('decline') &&
            !name.contains('pike') && !name.contains('archer')) {
          return true;
        }
      }
    }
    
    return false;
  }
}