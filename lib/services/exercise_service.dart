import 'package:flutter/foundation.dart';
import '../models/exercise.dart';
import 'exercise_api_client.dart';
import 'exercise_database.dart';
import 'common_exercise_service.dart';

class ExerciseService {
  final ExerciseApiClient _apiClient;
  final ExerciseDatabase _database;
  final CommonExerciseService _commonService;
  
  ExerciseService({
    ExerciseApiClient? apiClient,
    ExerciseDatabase? database,
    CommonExerciseService? commonService,
  }) : _apiClient = apiClient ?? ExerciseApiClient(),
        _database = database ?? ExerciseDatabase(),
        _commonService = commonService ?? CommonExerciseService();

  /// Get exercises with hybrid approach: Common database + API + cache
  Future<List<Exercise>> getExercises({
    String? bodyPart,
    String? equipment,
    String? searchQuery,
    int limit = 50,
    bool forceRefresh = false,
    bool useCommonDatabase = true,
  }) async {
    debugPrint('🔍 ExerciseService.getExercises called - bodyPart: $bodyPart, limit: $limit, useCommon: $useCommonDatabase'); // Debug
    
    // Strategy 1: Use common exercise database for fast, curated results
    if (useCommonDatabase && !forceRefresh) {
      try {
        List<Exercise> commonExercises;
        
        if (searchQuery != null && searchQuery.isNotEmpty) {
          commonExercises = await _commonService.searchExercises(searchQuery);
        } else if (bodyPart != null) {
          commonExercises = await _commonService.getExercisesByBodyPart(bodyPart);
        } else if (equipment != null) {
          commonExercises = await _commonService.getExercisesByEquipment(equipment);
        } else {
          commonExercises = await _commonService.getAllExercises();
        }
        
        if (commonExercises.isNotEmpty) {
          debugPrint('✅ Found ${commonExercises.length} exercises from common database'); // Debug
          return commonExercises.take(limit).toList();
        }
      } catch (e) {
        debugPrint('⚠️ Common database unavailable, falling back to API: $e'); // Debug
      }
    }
    
    // Strategy 2: Use API with caching (original logic)
    try {
      // Try cache first unless force refresh is requested
      if (!forceRefresh) {
        final cachedExercises = await _database.getCachedExercises(
          bodyPartFilter: bodyPart ?? 'all',
          limit: limit,
          searchQuery: searchQuery,
        );
        
        if (cachedExercises.isNotEmpty) {
          debugPrint('✅ Found ${cachedExercises.length} cached exercises'); // Debug
          final filteredExercises = _filterExercises(cachedExercises, searchQuery: searchQuery);
          _sortByPopularity(filteredExercises);
          return filteredExercises;
        }
      }

      debugPrint('🌐 Attempting API call...'); // Debug
      
      // Fetch from API using new endpoints
      List<Exercise> exercises;
      
      try {
        if (bodyPart != null) {
          debugPrint('🔍 Calling getExercisesByBodyPart for: $bodyPart');
          exercises = await _apiClient.getExercisesByBodyPart(bodyPart, limit: limit);
        } else if (equipment != null) {
          debugPrint('🔍 Calling getExercisesByEquipment for: $equipment');
          exercises = await _apiClient.getExercisesByEquipment(equipment, limit: limit);
        } else {
          debugPrint('🔍 Calling getAllExercises with search: $searchQuery');
          exercises = await _apiClient.getAllExercises(
            search: searchQuery, 
            limit: limit,
          );
        }
        
        debugPrint('✅ API Success! Got ${exercises.length} exercises'); // Debug
      } catch (apiError) {
        debugPrint('❌ API call failed: $apiError');
        rethrow; // Re-throw to be caught by outer catch block
      }
      
      // Cache the results
      await _database.cacheExercises(exercises, bodyPartFilter: bodyPart ?? 'all');
      
      // Apply search filter and limit
      final filteredExercises = _filterExercises(exercises, searchQuery: searchQuery);
      _sortByPopularity(filteredExercises);
      
      return filteredExercises.take(limit).toList();
      
    } catch (e) {
      debugPrint('❌ API failed, trying final fallbacks: $e'); // Debug
      
      // Strategy 3: Try cached data as fallback
      final cachedExercises = await _database.getCachedExercises(
        bodyPartFilter: bodyPart ?? 'all',
        searchQuery: searchQuery,
      );
      
      if (cachedExercises.isNotEmpty) {
        debugPrint('✅ Using ${cachedExercises.length} cached exercises as fallback'); // Debug
        _sortByPopularity(cachedExercises);
        return cachedExercises.take(limit).toList();
      }
      
      // Strategy 4: Try common database as final fallback
      try {
        List<Exercise> commonExercises;
        
        if (searchQuery != null && searchQuery.isNotEmpty) {
          commonExercises = await _commonService.searchExercises(searchQuery);
        } else if (bodyPart != null) {
          commonExercises = await _commonService.getExercisesByBodyPart(bodyPart);
        } else {
          commonExercises = await _commonService.getAllExercises();
        }
        
        if (commonExercises.isNotEmpty) {
          debugPrint('✅ Using ${commonExercises.length} exercises from common database as final fallback'); // Debug
          return commonExercises.take(limit).toList();
        }
      } catch (commonError) {
        debugPrint('⚠️ Common database also failed: $commonError'); // Debug
      }
      
      debugPrint('📝 Using mock data as ultimate fallback'); // Debug
      // Ultimate fallback: return comprehensive mock data
      return _getMockExercises(bodyPart: bodyPart, limit: limit);
    }
  }

  /// Get a specific exercise by ID with caching
  Future<Exercise?> getExerciseById(String exerciseId) async {
    try {
      // Try cache first
      final cachedExercise = await _database.getCachedExerciseById(exerciseId);
      if (cachedExercise != null) {
        return cachedExercise;
      }

      // Fetch from API
      final exercise = await _apiClient.getExerciseById(exerciseId);
      
      // Cache the result
      await _database.cacheExercises([exercise]);
      
      return exercise;
      
    } catch (e) {
      // Return null if exercise not found
      return null;
    }
  }

  /// Get body parts with hybrid approach
  Future<List<String>> getBodyParts({bool forceRefresh = false}) async {
    try {
      // Try common database first for instant results
      if (!forceRefresh) {
        final commonBodyParts = await _commonService.getBodyParts();
        if (commonBodyParts.isNotEmpty) {
          debugPrint('✅ Found ${commonBodyParts.length} body parts from common database'); // Debug
          return commonBodyParts;
        }
      }
      
      // Try cached metadata
      if (!forceRefresh) {
        final cachedBodyParts = await _database.getCachedMetadata('bodyParts');
        if (cachedBodyParts != null) {
          return cachedBodyParts;
        }
      }

      // Fetch from API
      final bodyParts = await _apiClient.getBodyParts();
      await _database.cacheMetadata('bodyParts', bodyParts);
      
      return bodyParts;
      
    } catch (e) {
      // Final fallback: try common database again
      try {
        final commonBodyParts = await _commonService.getBodyParts();
        if (commonBodyParts.isNotEmpty) {
          return commonBodyParts;
        }
      } catch (commonError) {
        debugPrint('⚠️ Common database also failed for body parts: $commonError'); // Debug
      }
      
      // Ultimate fallback: return default body parts
      return _getDefaultBodyParts();
    }
  }

  /// Get equipment types with caching
  Future<List<String>> getEquipmentTypes({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh) {
        final cachedEquipment = await _database.getCachedMetadata('equipmentTypes');
        if (cachedEquipment != null) {
          return cachedEquipment;
        }
      }

      final equipmentTypes = await _apiClient.getEquipmentTypes();
      await _database.cacheMetadata('equipmentTypes', equipmentTypes);
      
      return equipmentTypes;
      
    } catch (e) {
      // Return default equipment types if API fails
      return _getDefaultEquipmentTypes();
    }
  }

  /// Search exercises with fuzzy matching
  Future<List<Exercise>> searchExercises(String query, {
    double threshold = 0.3,
    int limit = 20,
  }) async {
    if (query.isEmpty) return [];
    
    try {
      // First try cached search
      final cachedExercises = await _database.getCachedExercises(
        searchQuery: query,
        limit: limit,
      );
      
      if (cachedExercises.isNotEmpty) {
        debugPrint('✅ Using cached search results for "$query"');
        return cachedExercises;
      }

      debugPrint('🔍 Searching API for "$query"...'); // Debug
      
      // Use new fuzzy search API
      final exercises = await _apiClient.searchExercises(
        query,
        threshold: threshold,
        limit: limit,
      );
      
      // Cache the search results
      await _database.cacheExercises(exercises, bodyPartFilter: 'search_$query');
      
      return exercises;
      
    } catch (e) {
      debugPrint('❌ Search API failed, trying local fallback: $e'); // Debug
      
      // Fallback: search through mock data
      final allExercises = _getMockExercises(limit: 200);
      return allExercises.where((exercise) => exercise.matchesSearch(query)).take(limit).toList();
    }
  }

  /// Get cache statistics
  Future<Map<String, int>> getCacheStats() async {
    return await _database.getCacheStats();
  }

  /// Clear cache
  Future<void> clearCache() async {
    await _database.clearAllCache();
  }

  /// Preload popular exercises for better performance
  Future<void> preloadPopularExercises() async {
    try {
      final popularBodyParts = ['chest', 'back', 'shoulders', 'legs'];
      
      for (final bodyPart in popularBodyParts) {
        await getExercises(bodyPart: bodyPart, limit: 20);
        // Small delay to avoid overwhelming the API
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      // Ignore errors during preloading
    }
  }

  /// Filter exercises based on search query
  List<Exercise> _filterExercises(List<Exercise> exercises, {String? searchQuery}) {
    if (searchQuery == null || searchQuery.isEmpty) {
      return exercises;
    }
    
    return exercises.where((exercise) => exercise.matchesSearch(searchQuery)).toList();
  }

  /// Mock exercises for development/offline use - comprehensive dataset
  List<Exercise> _getMockExercises({String? bodyPart, int limit = 10}) {
    final allMockExercises = [
      // CHEST EXERCISES
      const Exercise(
        exerciseId: 'mock_chest_1',
        name: 'Barbell Bench Press',
        imageUrl: 'Barbell-Bench-Press_Chest.png',
        equipments: ['Barbell'],
        bodyParts: ['Chest'],
        exerciseType: 'weight_reps',
        targetMuscles: ['Pectoralis Major Clavicular Head'],
        secondaryMuscles: ['Deltoid Anterior', 'Triceps Brachii'],
        videoUrl: 'Barbell-Bench-Press_Chest_.mp4',
        keywords: ['chest', 'barbell', 'strength', 'upper body', 'compound'],
        overview: 'The Bench Press is a classic strength training exercise that primarily targets the chest, shoulders, and triceps.',
        instructions: [
          'Grip the barbell with hands slightly wider than shoulder-width apart',
          'Slowly lower the barbell down to your chest keeping elbows at 90-degree angle',
          'Once the barbell touches your chest, push it back up to starting position',
          'Keep your back flat on the bench throughout the movement'
        ],
        exerciseTips: [
          'Avoid arching your back excessively',
          'Control the movement - don\'t lift too quickly', 
          'Never lift without a spotter',
          'Keep your feet firmly planted on the ground'
        ],
        variations: ['Incline Bench Press', 'Decline Bench Press', 'Dumbbell Bench Press', 'Close-Grip Bench Press'],
        relatedExerciseIds: ['mock_chest_2', 'mock_chest_3'],
      ),
      const Exercise(
        exerciseId: 'mock_chest_2',
        name: 'Dumbbell Flyes',
        imageUrl: 'Dumbbell-Flyes_Chest.png',
        equipments: ['Dumbbell'],
        bodyParts: ['Chest'],
        exerciseType: 'weight_reps',
        targetMuscles: ['Pectoralis Major Sternal Head'],
        secondaryMuscles: ['Deltoid Anterior'],
        videoUrl: 'Dumbbell-Flyes_Chest_.mp4',
        keywords: ['chest', 'dumbbell', 'isolation', 'flyes'],
        overview: 'Dumbbell flyes isolate the chest muscles and provide great stretch and contraction.',
        instructions: [
          'Lie on bench holding dumbbells above chest',
          'Lower dumbbells in wide arc until chest is stretched',
          'Bring dumbbells back together above chest',
          'Keep slight bend in elbows throughout movement'
        ],
        exerciseTips: ['Focus on the stretch', 'Don\'t go too heavy', 'Control the negative'],
        variations: ['Incline Dumbbell Flyes', 'Cable Flyes', 'Pec Deck Flyes'],
        relatedExerciseIds: ['mock_chest_1', 'mock_chest_3'],
      ),
      const Exercise(
        exerciseId: 'mock_chest_3',
        name: 'Push-ups',
        imageUrl: 'Push-ups_Chest.png',
        equipments: ['Body Weight'],
        bodyParts: ['Chest'],
        exerciseType: 'weight_reps',
        targetMuscles: ['Pectoralis Major'],
        secondaryMuscles: ['Deltoid Anterior', 'Triceps Brachii', 'Core'],
        videoUrl: 'Push-ups_Chest_.mp4',
        keywords: ['chest', 'bodyweight', 'calisthenics', 'functional'],
        overview: 'Push-ups are a fundamental bodyweight exercise that builds upper body strength.',
        instructions: [
          'Start in plank position with hands under shoulders',
          'Lower body until chest nearly touches ground',
          'Push back up to starting position',
          'Keep body in straight line throughout'
        ],
        exerciseTips: ['Keep core tight', 'Don\'t let hips sag', 'Full range of motion'],
        variations: ['Diamond Push-ups', 'Wide Push-ups', 'Incline Push-ups', 'Decline Push-ups'],
        relatedExerciseIds: ['mock_chest_1', 'mock_chest_2'],
      ),
      
      // BACK EXERCISES
      const Exercise(
        exerciseId: 'mock_back_1',
        name: 'Pull-ups',
        imageUrl: 'Pull-ups_Back.png',
        equipments: ['Body Weight'],
        bodyParts: ['Back'],
        exerciseType: 'weight_reps',
        targetMuscles: ['Latissimus Dorsi'],
        secondaryMuscles: ['Rhomboids', 'Middle Trapezius', 'Biceps Brachii'],
        videoUrl: 'Pull-ups_Back_.mp4',
        keywords: ['back', 'bodyweight', 'vertical pull', 'compound'],
        overview: 'Pull-ups are one of the best exercises for building back width and overall upper body strength.',
        instructions: [
          'Hang from pull-up bar with hands wider than shoulders',
          'Pull your body up until chin clears the bar',
          'Lower yourself back down with control',
          'Keep core engaged throughout movement'
        ],
        exerciseTips: ['Don\'t swing or use momentum', 'Full range of motion', 'Squeeze shoulder blades'],
        variations: ['Chin-ups', 'Wide Grip Pull-ups', 'Neutral Grip Pull-ups', 'Assisted Pull-ups'],
        relatedExerciseIds: ['mock_back_2', 'mock_back_3'],
      ),
      const Exercise(
        exerciseId: 'mock_back_2',
        name: 'Barbell Rows',
        imageUrl: 'Barbell-Rows_Back.png',
        equipments: ['Barbell'],
        bodyParts: ['Back'],
        exerciseType: 'weight_reps',
        targetMuscles: ['Latissimus Dorsi', 'Middle Trapezius', 'Rhomboids'],
        secondaryMuscles: ['Posterior Deltoid', 'Biceps Brachii'],
        videoUrl: 'Barbell-Rows_Back_.mp4',
        keywords: ['back', 'barbell', 'horizontal pull', 'compound'],
        overview: 'Barbell rows build thickness in the back muscles and improve posture.',
        instructions: [
          'Bend over holding barbell with overhand grip',
          'Keep back straight and core engaged',
          'Pull barbell to lower chest/upper abdomen',
          'Lower with control back to starting position'
        ],
        exerciseTips: ['Keep back straight', 'Pull to lower chest', 'Squeeze shoulder blades'],
        variations: ['T-Bar Rows', 'Dumbbell Rows', 'Cable Rows', 'Inverted Rows'],
        relatedExerciseIds: ['mock_back_1', 'mock_back_3'],
      ),
      
      // SHOULDERS EXERCISES  
      const Exercise(
        exerciseId: 'mock_shoulders_1',
        name: 'Overhead Press',
        imageUrl: 'Overhead-Press_Shoulders.png',
        equipments: ['Barbell'],
        bodyParts: ['Shoulders'],
        exerciseType: 'weight_reps',
        targetMuscles: ['Deltoid Anterior', 'Deltoid Medial'],
        secondaryMuscles: ['Triceps Brachii', 'Upper Trapezius', 'Core'],
        videoUrl: 'Overhead-Press_Shoulders_.mp4',
        keywords: ['shoulders', 'barbell', 'press', 'compound'],
        overview: 'The overhead press is excellent for building shoulder strength and stability.',
        instructions: [
          'Hold barbell at shoulder height',
          'Press weight straight overhead',
          'Lower with control back to shoulders',
          'Keep core tight throughout movement'
        ],
        exerciseTips: ['Keep core engaged', 'Press straight up', 'Don\'t arch back excessively'],
        variations: ['Dumbbell Shoulder Press', 'Behind Neck Press', 'Push Press', 'Seated Press'],
        relatedExerciseIds: ['mock_shoulders_2'],
      ),
      const Exercise(
        exerciseId: 'mock_shoulders_2',
        name: 'Lateral Raises',
        imageUrl: 'Lateral-Raises_Shoulders.png',
        equipments: ['Dumbbell'],
        bodyParts: ['Shoulders'],
        exerciseType: 'weight_reps',
        targetMuscles: ['Deltoid Medial'],
        secondaryMuscles: ['Deltoid Anterior', 'Deltoid Posterior'],
        videoUrl: 'Lateral-Raises_Shoulders_.mp4',
        keywords: ['shoulders', 'dumbbell', 'isolation', 'lateral'],
        overview: 'Lateral raises isolate the middle deltoids for broader shoulders.',
        instructions: [
          'Hold dumbbells at sides with slight elbow bend',
          'Raise weights out to sides until parallel to ground',
          'Lower with control back to starting position',
          'Keep core stable throughout'
        ],
        exerciseTips: ['Don\'t swing the weights', 'Lead with your pinkies', 'Control the negative'],
        variations: ['Cable Lateral Raises', 'Machine Lateral Raises', 'Bent-over Lateral Raises'],
        relatedExerciseIds: ['mock_shoulders_1'],
      ),
      
      // ARMS EXERCISES
      const Exercise(
        exerciseId: 'mock_arms_1', 
        name: 'Bicep Curls',
        imageUrl: 'Bicep-Curls_Arms.png',
        equipments: ['Dumbbell'],
        bodyParts: ['Arms'],
        exerciseType: 'weight_reps',
        targetMuscles: ['Biceps Brachii'],
        secondaryMuscles: ['Brachialis', 'Brachioradialis'],
        videoUrl: 'Bicep-Curls_Arms_.mp4',
        keywords: ['arms', 'biceps', 'dumbbell', 'isolation'],
        overview: 'Bicep curls are the classic exercise for building bigger, stronger biceps.',
        instructions: [
          'Hold dumbbells at sides with palms facing forward',
          'Curl weights up by flexing biceps',
          'Squeeze at the top of the movement',
          'Lower with control back to starting position'
        ],
        exerciseTips: ['Don\'t swing the weight', 'Keep elbows stationary', 'Full range of motion'],
        variations: ['Hammer Curls', 'Preacher Curls', 'Cable Curls', 'Barbell Curls'],
        relatedExerciseIds: ['mock_arms_2'],
      ),
      const Exercise(
        exerciseId: 'mock_arms_2',
        name: 'Tricep Dips',
        imageUrl: 'Tricep-Dips_Arms.png',
        equipments: ['Body Weight'],
        bodyParts: ['Arms'],
        exerciseType: 'weight_reps',
        targetMuscles: ['Triceps Brachii'],
        secondaryMuscles: ['Deltoid Anterior', 'Pectoralis Major'],
        videoUrl: 'Tricep-Dips_Arms_.mp4',
        keywords: ['arms', 'triceps', 'bodyweight', 'compound'],
        overview: 'Tricep dips effectively target the triceps and can be done anywhere.',
        instructions: [
          'Sit on edge of bench with hands beside hips',
          'Lower body by bending elbows',
          'Push back up to starting position',
          'Keep torso upright throughout movement'
        ],
        exerciseTips: ['Don\'t go too low', 'Keep elbows close to body', 'Control the movement'],
        variations: ['Assisted Dips', 'Weighted Dips', 'Ring Dips', 'Chair Dips'],
        relatedExerciseIds: ['mock_arms_1'],
      ),
      
      // LEGS EXERCISES
      const Exercise(
        exerciseId: 'mock_legs_1',
        name: 'Barbell Squat',
        imageUrl: 'Barbell-Squat_Legs.png',
        equipments: ['Barbell'],
        bodyParts: ['Legs'],
        exerciseType: 'weight_reps',
        targetMuscles: ['Quadriceps'],
        secondaryMuscles: ['Glutes', 'Hamstrings', 'Core'],
        videoUrl: 'Barbell-Squat_Legs_.mp4',
        keywords: ['legs', 'barbell', 'compound', 'strength'],
        overview: 'The squat is the king of leg exercises, building overall lower body strength.',
        instructions: [
          'Position barbell on upper back/traps',
          'Stand with feet shoulder-width apart',
          'Lower by pushing hips back and bending knees',
          'Drive through heels to return to standing'
        ],
        exerciseTips: ['Keep chest up', 'Knees track over toes', 'Full depth when possible'],
        variations: ['Front Squat', 'Goblet Squat', 'Box Squat', 'Bulgarian Split Squat'],
        relatedExerciseIds: ['mock_legs_2', 'mock_legs_3'],
      ),
      const Exercise(
        exerciseId: 'mock_legs_2',
        name: 'Deadlifts',
        imageUrl: 'Deadlifts_Legs.png',
        equipments: ['Barbell'],
        bodyParts: ['Legs'],
        exerciseType: 'weight_reps',
        targetMuscles: ['Hamstrings', 'Glutes'],
        secondaryMuscles: ['Lower Back', 'Traps', 'Core'],
        videoUrl: 'Deadlifts_Legs_.mp4',
        keywords: ['legs', 'barbell', 'posterior chain', 'compound'],
        overview: 'Deadlifts work the entire posterior chain and build total-body strength.',
        instructions: [
          'Stand with feet hip-width apart, bar over mid-foot',
          'Grip bar with hands just outside legs',
          'Keep back straight, chest up',
          'Drive through heels to lift bar to hip level'
        ],
        exerciseTips: ['Keep bar close to body', 'Engage lats', 'Don\'t round back'],
        variations: ['Romanian Deadlifts', 'Sumo Deadlifts', 'Trap Bar Deadlifts'],
        relatedExerciseIds: ['mock_legs_1', 'mock_legs_3'],
      ),
      const Exercise(
        exerciseId: 'mock_legs_3',
        name: 'Lunges',
        imageUrl: 'Lunges_Legs.png',
        equipments: ['Body Weight'],
        bodyParts: ['Legs'],
        exerciseType: 'weight_reps',
        targetMuscles: ['Quadriceps', 'Glutes'],
        secondaryMuscles: ['Hamstrings', 'Calves', 'Core'],
        videoUrl: 'Lunges_Legs_.mp4',
        keywords: ['legs', 'bodyweight', 'unilateral', 'functional'],
        overview: 'Lunges are excellent for building single-leg strength and improving balance.',
        instructions: [
          'Step forward into lunge position',
          'Lower back knee toward ground',
          'Push off front foot to return to starting position',
          'Keep torso upright throughout movement'
        ],
        exerciseTips: ['Don\'t let knee collapse inward', 'Step far enough forward', 'Control the descent'],
        variations: ['Reverse Lunges', 'Walking Lunges', 'Lateral Lunges', 'Curtsy Lunges'],
        relatedExerciseIds: ['mock_legs_1', 'mock_legs_2'],
      ),
    ];

    if (bodyPart != null) {
      return allMockExercises.where((ex) => ex.matchesBodyPart(bodyPart)).take(limit).toList();
    }
    
    return allMockExercises.take(limit).toList();
  }

  List<String> _getDefaultBodyParts() {
    return [
      'chest', 'back', 'shoulders', 'arms', 'legs', 'glutes', 'abs', 'calves'
    ];
  }

  List<String> _getDefaultEquipmentTypes() {
    return [
      'barbell', 'dumbbell', 'bodyweight', 'cable', 'machine', 'kettlebell'
    ];
  }

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

  /// Dispose resources
  void dispose() {
    _apiClient.dispose();
  }
}