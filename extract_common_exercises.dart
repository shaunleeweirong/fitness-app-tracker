import 'dart:convert';
import 'dart:io';
import 'lib/services/exercise_api_client.dart';
import 'lib/models/exercise.dart';

/// Script to extract 20 most common exercises per body part from ExerciseDB API
/// Generates common_exercises_database.json for immediate app integration
void main() async {
  print('🚀 Starting common exercise extraction...');
  
  final extractor = CommonExerciseExtractor();
  await extractor.extractAllExercises();
}

class CommonExerciseExtractor {
  final ExerciseApiClient _apiClient = ExerciseApiClient();
  
  // Body parts and their exercise limits for 500 total exercises
  final Map<String, int> bodyPartLimits = {
    'upper legs': 80,   // 16% - Largest muscle group, most variations
    'chest': 70,        // 14% - Major pushing muscle group
    'back': 70,         // 14% - Major pulling muscle group  
    'shoulders': 60,    // 12% - Complex joint, many angles
    'upper arms': 50,   // 10% - Biceps, triceps
    'waist': 50,        // 10% - Abs, core
    'cardio': 50,       // 10% - HIIT, functional movements
    'lower legs': 40,   // 8% - Calves, smaller muscle group
    'lower arms': 30,   // 6% - Forearms, grip work
  };
  
  // Equipment priority (higher priority = more common)
  final Map<String, int> equipmentPriority = {
    'body weight': 10,
    'dumbbell': 9,
    'barbell': 8,
    'cable': 7,
    'machine': 6,
    'kettlebell': 5,
    'resistance band': 4,
    'medicine ball': 3,
    'smith machine': 2,
    'leverage machine': 1,
  };
  
  // Gym popularity patterns (tier-based scoring)
  final Map<String, int> gymPopularityTiers = {
    // Tier 1: Absolute gym essentials (40 points)
    'squat': 40,
    'deadlift': 40,
    'bench press': 40,
    'bench': 40,
    'row': 40,
    'pull up': 40,
    'pullup': 40,
    'chin up': 40,
    'overhead press': 40,
    'military press': 40,
    'curl': 40,
    'extension': 40,
    
    // Tier 2: Common gym movements (25 points)
    'lunge': 25,
    'step up': 25,
    'leg press': 25,
    'fly': 25,
    'raise': 25,
    'dip': 25,
    'push up': 25,
    'pushup': 25,
    'plank': 25,
    'crunch': 25,
    'sit up': 25,
    'press': 25,
    
    // Tier 3: Recognized movements (10 points)  
    'shrug': 10,
    'upright row': 10,
    'good morning': 10,
    'hip thrust': 10,
    'calf raise': 10,
    'leg curl': 10,
    'leg extension': 10,
    'lat pulldown': 10,
  };
  
  // Anti-patterns that reduce scores (exercises to avoid)
  final List<String> antiPatterns = [
    'single leg', 'single arm', 'bulgarian', 'pistol', 'archer',
    'deficit', 'pause', 'tempo', 'cluster', 'rest pause',
    'isometric', 'eccentric', 'plyometric', 'explosive',
    'rehabilitation', 'therapy', 'corrective'
  ];

  Future<void> extractAllExercises() async {
    final Map<String, List<Exercise>> allExercises = {};
    
    print('📊 Extracting exercises for ${bodyPartLimits.length} body parts...\n');
    print('🎯 Target: ${bodyPartLimits.values.reduce((a, b) => a + b)} total exercises\n');
    
    // Extract exercises for each body part
    for (final bodyPart in bodyPartLimits.keys) {
      print('🔍 Processing: ${bodyPart.toUpperCase()}');
      
      try {
        final exercises = await _extractExercisesForBodyPart(bodyPart);
        allExercises[bodyPart] = exercises;
        
        print('✅ Extracted ${exercises.length} exercises for $bodyPart');
        print('   Top 3: ${exercises.take(3).map((e) => e.name).join(', ')}\n');
        
        // Small delay to avoid overwhelming API
        await Future.delayed(const Duration(milliseconds: 200));
        
      } catch (e) {
        print('❌ Failed to extract exercises for $bodyPart: $e\n');
        allExercises[bodyPart] = [];
      }
    }
    
    // Generate output file
    await _generateOutputFile(allExercises);
    
    // Print summary
    _printExtractionSummary(allExercises);
  }

  Future<List<Exercise>> _extractExercisesForBodyPart(String bodyPart) async {
    final targetCount = bodyPartLimits[bodyPart]!;
    
    // Get exercises with pagination (API limit is 100 per request)
    final allExercises = <Exercise>[];
    final maxNeeded = (targetCount * 3).clamp(100, 500); // Fetch 3x target for better selection
    int currentOffset = 0;
    
    print('   📥 Fetching up to $maxNeeded exercises for selection...');
    
    while (allExercises.length < maxNeeded) {
      final limit = (maxNeeded - allExercises.length).clamp(1, 100); // Max 100 per request
      
      try {
        final batch = await _apiClient.getExercisesByBodyPart(
          bodyPart, 
          limit: limit,
          offset: currentOffset,
        );
        
        if (batch.isEmpty) break; // No more exercises available
        
        allExercises.addAll(batch);
        currentOffset += batch.length;
        
        print('   📄 Fetched ${batch.length} exercises (total: ${allExercises.length})');
        
        // Small delay between API calls to be respectful
        if (allExercises.length < maxNeeded) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
        
      } catch (e) {
        print('   ⚠️  Error fetching batch at offset $currentOffset: $e');
        break;
      }
    }
    
    if (allExercises.isEmpty) {
      print('⚠️  No exercises found for $bodyPart');
      return [];
    }
    
    print('   ✅ Total fetched: ${allExercises.length} exercises');
    
    // Apply selection criteria and rank exercises
    final rankedExercises = _rankExercisesByCommonness(allExercises);
    
    // Return target number of most common exercises
    final selectedExercises = rankedExercises.take(targetCount).toList();
    
    print('   🎯 Selected ${selectedExercises.length} common exercises');
    
    return selectedExercises;
  }

  List<Exercise> _rankExercisesByCommonness(List<Exercise> exercises) {
    // Score each exercise based on NEW gym popularity-focused criteria
    final List<({Exercise exercise, double score})> scoredExercises = [];
    
    for (final exercise in exercises) {
      double score = 0.0;
      
      // 1. Gym Popularity Score (40 points) - PRIMARY FACTOR
      score += _getGymPopularityScore(exercise);
      
      // 2. Equipment Accessibility Score (30 points)
      score += _getEquipmentScore(exercise);
      
      // 3. Movement Effectiveness Score (20 points)
      score += _getEffectivenessScore(exercise);
      
      // 4. Safety/Accessibility Score (10 points)
      score += _getSimplicityScore(exercise);
      
      // Apply anti-pattern penalty
      score -= _getAntiPatternPenalty(exercise);
      
      scoredExercises.add((exercise: exercise, score: score));
    }
    
    // Sort by score (highest first)
    scoredExercises.sort((a, b) => b.score.compareTo(a.score));
    
    // Return just the exercises
    return scoredExercises.map((item) => item.exercise).toList();
  }

  // NEW: Primary gym popularity scoring (0-40 points)
  double _getGymPopularityScore(Exercise exercise) {
    final name = exercise.name.toLowerCase();
    
    // Check for gym essential patterns (highest priority)
    for (final pattern in gymPopularityTiers.keys) {
      if (name.contains(pattern)) {
        return gymPopularityTiers[pattern]!.toDouble();
      }
    }
    
    return 0.0; // No recognizable gym pattern
  }
  
  // NEW: Anti-pattern penalty (reduces score for overly complex exercises)
  double _getAntiPatternPenalty(Exercise exercise) {
    final name = exercise.name.toLowerCase();
    double penalty = 0.0;
    
    for (final antiPattern in antiPatterns) {
      if (name.contains(antiPattern)) {
        penalty += 10.0; // Heavy penalty for each anti-pattern
      }
    }
    
    return penalty;
  }

  double _getEquipmentScore(Exercise exercise) {
    if (exercise.equipments.isEmpty) return 15.0; // Bodyweight gets good score
    
    // Get highest priority equipment (scaled to 30 points max)
    int maxPriority = 0;
    for (final equipment in exercise.equipments) {
      final priority = equipmentPriority[equipment.toLowerCase()] ?? 0;
      if (priority > maxPriority) maxPriority = priority;
    }
    
    return (maxPriority * 3).toDouble(); // Scale to 30 point max
  }


  double _getSimplicityScore(Exercise exercise) {
    final name = exercise.name.toLowerCase();
    double score = 10.0; // Start with full 10 points
    
    // Penalty for complex movements
    if (name.contains('alternating')) score -= 2.0;
    if (name.contains('single')) score -= 1.0;
    if (name.contains('complex')) score -= 3.0;
    if (name.contains('advanced')) score -= 2.0;
    if (name.contains('deficit')) score -= 2.0;
    if (name.contains('pause')) score -= 1.0;
    
    // Bonus for simple, accessible movements
    if (name.contains('basic')) score += 2.0;
    if (name.contains('standard')) score += 1.0;
    
    // Penalty for overly long names (usually indicates complexity)
    final wordCount = name.split(' ').length;
    if (wordCount > 5) score -= 2.0;
    else if (wordCount > 3) score -= 1.0;
    
    return score.clamp(0.0, 10.0);
  }

  double _getEffectivenessScore(Exercise exercise) {
    double score = 10.0; // Base score (20 points max, scaled to 20)
    
    // Bonus for compound movements (multiple muscle groups)
    if (exercise.secondaryMuscles.length >= 2) score += 5.0;
    if (exercise.secondaryMuscles.length >= 4) score += 3.0;
    
    // Bonus for targeting major muscle groups
    final targets = exercise.targetMuscles.join(' ').toLowerCase();
    if (targets.contains('pectorals') || targets.contains('latissimus') || 
        targets.contains('quadriceps') || targets.contains('glutes')) score += 3.0;
    
    // Bonus for fundamental movement patterns
    final name = exercise.name.toLowerCase();
    if (name.contains('squat') || name.contains('deadlift') || 
        name.contains('press') || name.contains('row')) score += 2.0;
    
    return score.clamp(0.0, 20.0);
  }

  Future<void> _generateOutputFile(Map<String, List<Exercise>> allExercises) async {
    print('📝 Generating common_exercises_database.json...');
    
    // Calculate totals
    int totalExercises = 0;
    final Map<String, dynamic> output = {
      'metadata': {
        'generated_at': DateTime.now().toIso8601String(),
        'total_body_parts': bodyPartLimits.length,
        'target_total_exercises': bodyPartLimits.values.reduce((a, b) => a + b),
        'selection_criteria': [
          'Gym Popularity Filter (40 points) - squat, deadlift, bench press, etc.',
          'Equipment Accessibility (30 points) - dumbbells, barbells, machines preferred',
          'Movement Effectiveness (20 points) - compound movements, major muscles',
          'Safety/Accessibility (10 points) - beginner-friendly, teachable form',
          'Anti-pattern penalty - avoids overly complex or obscure exercises'
        ],
        'body_part_distribution': bodyPartLimits
      },
      'body_parts': <String, dynamic>{}
    };
    
    // Process each body part
    for (final bodyPart in bodyPartLimits.keys) {
      final exercises = allExercises[bodyPart] ?? [];
      totalExercises += exercises.length;
      
      output['body_parts'][bodyPart] = {
        'count': exercises.length,
        'exercises': exercises.map((exercise) => {
          'exerciseId': exercise.exerciseId,
          'name': exercise.name,
          'gifUrl': exercise.imageUrl, // Maps to gifUrl in API
          'targetMuscles': exercise.targetMuscles,
          'bodyParts': exercise.bodyParts,
          'equipments': exercise.equipments,
          'secondaryMuscles': exercise.secondaryMuscles,
          'exerciseType': exercise.exerciseType,
          'instructions': exercise.instructions,
          'overview': exercise.overview,
          'exerciseTips': exercise.exerciseTips,
          'variations': exercise.variations,
          'keywords': exercise.keywords,
          'relatedExerciseIds': exercise.relatedExerciseIds,
          'videoUrl': exercise.videoUrl,
        }).toList()
      };
    }
    
    output['metadata']['total_exercises'] = totalExercises;
    
    // Write to file
    final file = File('common_exercises_database.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(output)
    );
    
    print('✅ Generated common_exercises_database.json');
    print('   📁 File size: ${await _getFileSize(file)}');
  }

  Future<String> _getFileSize(File file) async {
    final bytes = await file.length();
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  void _printExtractionSummary(Map<String, List<Exercise>> allExercises) {
    print('\n🎉 EXTRACTION COMPLETE!');
    print('=' * 50);
    
    int totalExercises = 0;
    int targetTotal = 0;
    
    for (final bodyPart in bodyPartLimits.keys) {
      final exercises = allExercises[bodyPart] ?? [];
      final count = exercises.length;
      final target = bodyPartLimits[bodyPart]!;
      totalExercises += count;
      targetTotal += target;
      
      final status = count >= target ? '✅' : count > 0 ? '⚠️' : '❌';
      print('$status $bodyPart: $count/$target exercises');
      
      if (exercises.isNotEmpty && exercises.length >= 3) {
        print('   Top exercises: ${exercises.take(3).map((e) => e.name).join(', ')}');
      }
    }
    
    print('\n📊 SUMMARY');
    print('Total exercises: $totalExercises');
    print('Target: $targetTotal exercises');
    print('Success rate: ${((totalExercises / targetTotal) * 100).toStringAsFixed(1)}%');
    print('File size estimate: ~${(totalExercises * 1.8).toStringAsFixed(0)}KB');
    
    print('\n📁 OUTPUT');
    print('File: common_exercises_database.json');
    print('Ready for Flutter app integration with 500-exercise database!');
  }
}