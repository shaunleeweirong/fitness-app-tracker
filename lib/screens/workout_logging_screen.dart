import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/personal_record.dart';
import '../services/workout_repository.dart';
import '../services/exercise_service.dart';
import '../services/personal_record_service.dart';
import '../widgets/rest_timer.dart';

/// Workout logging screen for active workout sessions
/// Allows users to select exercises and log sets with weights and reps
class WorkoutLoggingScreen extends StatefulWidget {
  final String workoutId;
  
  const WorkoutLoggingScreen({
    super.key,
    required this.workoutId,
  });

  @override
  State<WorkoutLoggingScreen> createState() => _WorkoutLoggingScreenState();
}

class _WorkoutLoggingScreenState extends State<WorkoutLoggingScreen> {
  final WorkoutRepository _workoutRepository = WorkoutRepository();
  final ExerciseService _exerciseService = ExerciseService();
  final PersonalRecordService _prService = PersonalRecordService();
  
  // State
  Workout? _workout;
  List<Exercise> _availableExercises = [];
  bool _isLoading = true;
  bool _isLoadingExercises = false;
  
  // Current exercise being logged
  Exercise? _selectedExercise;
  List<WorkoutSet> _currentSets = [];
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  
  // Rest timer state
  bool _showRestTimer = false;
  bool _autoStartTimer = true;
  
  // Personal Records state
  List<PersonalRecord> _newPRs = [];

  @override
  void initState() {
    super.initState();
    _loadWorkout();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    // Don't close the database connection - it's shared across the app
    // _workoutRepository.close();
    _exerciseService.dispose();
    super.dispose();
  }

  Future<void> _loadWorkout() async {
    try {
      final workout = await _workoutRepository.getWorkout(widget.workoutId);
      if (workout == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showError('Workout not found');
        }
        return;
      }
      
      if (mounted) {
        setState(() {
          _workout = workout;
          _isLoading = false;
        });
      }
      
      // Start the workout if it's still planned
      if (workout.status == WorkoutStatus.planned) {
        await _workoutRepository.startWorkout(widget.workoutId);
        if (mounted) {
          setState(() {
            _workout = workout.copyWith(
              status: WorkoutStatus.inProgress,
              startedAt: DateTime.now(),
            );
          });
        }
      }
      
      // Load exercises for the target body parts
      _loadAvailableExercises();
      
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load workout: $e');
      }
    }
  }

  Future<void> _loadAvailableExercises() async {
    if (_workout == null || !mounted) return;
    
    if (mounted) {
      setState(() => _isLoadingExercises = true);
    }
    
    try {
      List<Exercise> exercises = [];
      
      // CRITICAL FIX: Check if this workout has predefined exercises from a template
      // Template workouts will have WorkoutExercise objects with exercise IDs
      if (_workout!.exercises.isNotEmpty) {
        debugPrint('🎯 TEMPLATE WORKOUT DETECTED: ${_workout!.exercises.length} predefined exercises');
        
        // Extract exercise IDs from the template workout exercises
        final exerciseIds = _workout!.exercises.map((we) => we.exerciseId).toList();
        debugPrint('🔍 Looking up exercise IDs: $exerciseIds');
        
        // Get the full Exercise objects for these specific IDs
        exercises = await _exerciseService.getExercisesByIds(exerciseIds);
        debugPrint('📦 Found ${exercises.length} exercises from service');
        
        // If we didn't find all exercises by ID, create Exercise objects from WorkoutExercise data
        if (exercises.length < _workout!.exercises.length) {
          debugPrint('⚠️ Some exercises not found, creating from WorkoutExercise data');
          final foundIds = exercises.map((e) => e.exerciseId).toSet();
          
          for (final workoutExercise in _workout!.exercises) {
            if (!foundIds.contains(workoutExercise.exerciseId)) {
              debugPrint('🔧 Creating Exercise object for: ${workoutExercise.exerciseName}');
              // Create an Exercise object from WorkoutExercise data
              exercises.add(Exercise(
                exerciseId: workoutExercise.exerciseId,
                name: workoutExercise.exerciseName,
                imageUrl: '', // Will be empty for template exercises
                equipments: ['Unknown'], // Template exercises don't store equipment
                bodyParts: workoutExercise.bodyParts,
                targetMuscles: workoutExercise.bodyParts, // Use body parts as target muscles
                secondaryMuscles: [],
                instructions: [],
              ));
            }
          }
        }
        
        // Sort by the order they appear in the template
        exercises.sort((a, b) {
          final aIndex = _workout!.exercises.indexWhere((we) => we.exerciseId == a.exerciseId);
          final bIndex = _workout!.exercises.indexWhere((we) => we.exerciseId == b.exerciseId);
          return aIndex.compareTo(bIndex);
        });
        
        debugPrint('✅ TEMPLATE EXERCISES LOADED: ${exercises.length} exercises ready');
        for (int i = 0; i < exercises.length; i++) {
          debugPrint('  ${i + 1}. ${exercises[i].name}');
        }
      } else {
        debugPrint('🔍 CUSTOM WORKOUT: Loading exercises by body parts');
        
        // Original logic: Load exercises for each target body part (for custom workouts)
        for (final bodyPart in _workout!.targetBodyParts) {
          final bodyPartExercises = await _exerciseService.getExercises(
            bodyPart: bodyPart,
            limit: 20,
          );
          exercises.addAll(bodyPartExercises);
        }
        
        // Remove duplicates and sort by popularity
        final exerciseMap = <String, Exercise>{};
        for (final exercise in exercises) {
          exerciseMap[exercise.exerciseId] = exercise;
        }
        exercises = exerciseMap.values.toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        
        debugPrint('✅ CUSTOM EXERCISES LOADED: ${exercises.length} exercises available');
      }
      
      if (mounted) {
        setState(() {
          _availableExercises = exercises;
          _isLoadingExercises = false;
        });
      }
      
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingExercises = false);
        _showError('Failed to load exercises: $e');
      }
    }
  }

  void _selectExercise(Exercise exercise) {
    debugPrint('🎯 EXERCISE SELECTED: ${exercise.name} (ID: ${exercise.exerciseId})');
    debugPrint('   Body parts: ${exercise.bodyParts}');
    debugPrint('   Current workout exercises count: ${_workout?.exercises.length ?? 0}');
    
    // Check if this exercise is already in the workout
    final existingExercises = _workout?.exercises.where((we) => we.exerciseId == exercise.exerciseId).toList() ?? [];
    if (existingExercises.isNotEmpty) {
      debugPrint('⚠️  WARNING: Exercise ${exercise.name} already exists in workout!');
      debugPrint('   Existing instances: ${existingExercises.length}');
      for (int i = 0; i < existingExercises.length; i++) {
        debugPrint('   Instance ${i + 1}: ${existingExercises[i].exerciseName} with ${existingExercises[i].sets.length} sets');
      }
    }
    
    setState(() {
      _selectedExercise = exercise;
      _currentSets = [];
      _weightController.clear();
      _repsController.clear();
    });
    
    debugPrint('✅ Exercise selection completed');
  }

  void _addSet() async {
    debugPrint('🏋️ ADDING SET to exercise: ${_selectedExercise?.name}');
    
    final weightText = _weightController.text.trim();
    final repsText = _repsController.text.trim();
    
    if (weightText.isEmpty || repsText.isEmpty) {
      debugPrint('❌ Set addition failed: Missing weight or reps');
      _showError('Please enter both weight and reps');
      return;
    }
    
    final weight = double.tryParse(weightText);
    final reps = int.tryParse(repsText);
    
    if (weight == null || weight <= 0) {
      debugPrint('❌ Set addition failed: Invalid weight: $weightText');
      _showError('Please enter a valid weight');
      return;
    }
    
    if (reps == null || reps <= 0) {
      debugPrint('❌ Set addition failed: Invalid reps: $repsText');
      _showError('Please enter valid reps');
      return;
    }
    
    final workoutExerciseId = '${widget.workoutId}_${_selectedExercise!.exerciseId}';
    debugPrint('🏋️ Creating set with workout_exercise_id: $workoutExerciseId');
    debugPrint('   Weight: ${weight}kg, Reps: $reps, Set #: ${_currentSets.length + 1}');
    
    final newSet = WorkoutSet(
      weight: weight,
      reps: reps,
      setNumber: _currentSets.length + 1,
      workoutExerciseId: workoutExerciseId,
    );

    setState(() {
      _currentSets.add(newSet);
      
      // Clear inputs for next set
      _weightController.clear();
      _repsController.clear();
    });
    
    debugPrint('✅ Set added successfully! Current sets: ${_currentSets.length}');
    
    // Check for new Personal Records
    try {
      final newPRs = await _prService.checkAndSaveNewPRs(
        newSet,
        _selectedExercise!.exerciseId,
        _selectedExercise!.name,
        'default_user', // TODO: Get actual user ID
        widget.workoutId,
      );

      if (newPRs.isNotEmpty && mounted) {
        setState(() {
          _newPRs.addAll(newPRs);
        });
        
        // Show PR celebration
        _showPRCelebration(newPRs);
      }
    } catch (e) {
      debugPrint('Error checking PRs: $e');
      // Don't block the user if PR checking fails
    }
    
    // Haptic feedback for successful set addition
    HapticFeedback.lightImpact();
    
    // Show rest timer modal after adding a set (unless it's the last planned set)
    if (_currentSets.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showRestTimerModal();
        }
      });
    }
  }

  void _removeSet(int index) {
    setState(() {
      _currentSets.removeAt(index);
      // Renumber remaining sets
      for (int i = 0; i < _currentSets.length; i++) {
        _currentSets[i] = _currentSets[i].copyWith(setNumber: i + 1);
      }
    });
  }

  Future<void> _saveExercise() async {
    debugPrint('💾 SAVING EXERCISE: ${_selectedExercise?.name}');
    debugPrint('   Exercise ID: ${_selectedExercise?.exerciseId}');
    debugPrint('   Workout ID: ${widget.workoutId}');
    debugPrint('   Current sets to save: ${_currentSets.length}');
    
    if (_selectedExercise == null || _currentSets.isEmpty) {
      debugPrint('❌ Save failed: Missing exercise or sets');
      _showError('Please add at least one set');
      return;
    }
    
    // Log current workout state BEFORE adding new exercise
    debugPrint('📊 CURRENT WORKOUT STATE:');
    debugPrint('   Total exercises: ${_workout!.exercises.length}');
    for (int i = 0; i < _workout!.exercises.length; i++) {
      final ex = _workout!.exercises[i];
      debugPrint('   Exercise ${i + 1}: ${ex.exerciseName} (ID: ${ex.exerciseId}) - ${ex.sets.length} sets');
    }
    
    // Check for duplicate exercises and handle them
    final duplicateExercises = _workout!.exercises.where((we) => we.exerciseId == _selectedExercise!.exerciseId);
    
    try {
      List<WorkoutExercise> updatedExercises;
      
      if (duplicateExercises.isNotEmpty) {
        debugPrint('🔄 HANDLING DUPLICATE: Found ${duplicateExercises.length} existing instances of exercise ${_selectedExercise!.name}');
        
        // Get the first existing exercise to merge with
        final existingExercise = duplicateExercises.first;
        debugPrint('   Merging with existing: ${existingExercise.exerciseName} (${existingExercise.sets.length} existing sets)');
        
        // Create new sets with proper numbering (continuing from existing sets)
        final newSets = _currentSets.map((set) => set.copyWith(
          setNumber: existingExercise.sets.length + set.setNumber,
        )).toList();
        
        debugPrint('   Adding ${_currentSets.length} new sets (numbered ${existingExercise.sets.length + 1}-${existingExercise.sets.length + _currentSets.length})');
        
        // Create merged exercise with combined sets
        final mergedExercise = existingExercise.copyWith(
          sets: [...existingExercise.sets, ...newSets],
        );
        
        debugPrint('🔄 MERGED WorkoutExercise:');
        debugPrint('   Exercise: ${mergedExercise.exerciseName}');
        debugPrint('   Total sets after merge: ${mergedExercise.sets.length}');
        for (int i = 0; i < mergedExercise.sets.length; i++) {
          final set = mergedExercise.sets[i];
          debugPrint('     Set ${set.setNumber}: ${set.weight}kg x ${set.reps} reps');
        }
        
        // Replace the existing exercise in the workout
        updatedExercises = _workout!.exercises.map((we) {
          if (we.exerciseId == _selectedExercise!.exerciseId) {
            return mergedExercise;
          }
          return we;
        }).toList();
        
        debugPrint('✅ Duplicate exercise merged successfully');
        
      } else {
        debugPrint('➕ ADDING NEW EXERCISE: No duplicates found');
        
        // Create new WorkoutExercise (original behavior for new exercises)
        final workoutExercise = WorkoutExercise(
          exerciseId: _selectedExercise!.exerciseId,
          exerciseName: _selectedExercise!.name,
          bodyParts: _selectedExercise!.bodyParts,
          sets: _currentSets,
          orderIndex: _workout!.exercises.length + 1,
          workoutId: widget.workoutId,
        );
        
        debugPrint('🏗️  CREATED WorkoutExercise:');
        debugPrint('   Exercise ID: ${workoutExercise.exerciseId}');
        debugPrint('   Exercise Name: ${workoutExercise.exerciseName}');
        debugPrint('   Sets count: ${workoutExercise.sets.length}');
        
        // Add as new exercise
        updatedExercises = [..._workout!.exercises, workoutExercise];
      }
      
      // Update workout with processed exercises
      final updatedWorkout = _workout!.copyWith(
        exercises: updatedExercises,
      );
      
      debugPrint('🔄 CALLING updateWorkout() with ${updatedWorkout.exercises.length} total exercises');
      await _workoutRepository.updateWorkout(updatedWorkout);
      debugPrint('✅ updateWorkout() completed successfully');
      
      if (mounted) {
        setState(() {
          _workout = updatedWorkout;
          _selectedExercise = null;
          _currentSets = [];
        });
        
        debugPrint('✅ Exercise saved successfully! New total: ${updatedWorkout.exercises.length} exercises');
        _showSuccess('Exercise saved successfully!');
      }
      
    } catch (e) {
      debugPrint('❌ SAVE EXERCISE FAILED: $e');
      _showError('Failed to save exercise: $e');
    }
  }

  Future<void> _finishWorkout() async {
    if (_workout == null) return;
    
    if (_workout!.exercises.isEmpty) {
      _showError('Please add at least one exercise before finishing');
      return;
    }
    
    try {
      await _workoutRepository.completeWorkout(widget.workoutId);
      
      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _buildWorkoutSummaryDialog(),
        );
      }
      
    } catch (e) {
      _showError('Failed to finish workout: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPRCelebration(List<PersonalRecord> newPRs) {
    if (!mounted || newPRs.isEmpty) return;
    
    // Show a special SnackBar for PR achievements
    final prMessage = newPRs.length == 1 
        ? '🏆 NEW PR: ${newPRs.first.shortDescription}!'
        : '🏆 ${newPRs.length} NEW PRs achieved!';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                prMessage,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFFB74D),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4), // Longer duration for celebration
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.black,
          onPressed: () => _showPRDetails(newPRs),
        ),
      ),
    );
    
    // Extra haptic feedback for PR achievement
    HapticFeedback.mediumImpact();
  }

  void _showPRDetails(List<PersonalRecord> prs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Color(0xFFFFB74D)),
            SizedBox(width: 8),
            Text(
              'Personal Records!',
              style: TextStyle(
                color: Color(0xFFFFB74D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: prs.map((pr) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '• ${pr.displayTitle}: ${pr.formattedValue}',
              style: const TextStyle(color: Colors.white),
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Awesome!',
              style: TextStyle(
                color: Color(0xFFFFB74D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _dismissRestTimer() {
    setState(() {
      _showRestTimer = false;
    });
  }

  void _onTimerComplete() {
    // Timer completed - ready for next set
    _showSuccess('Rest complete! Ready for your next set 💪');
  }

  void _showRestTimerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Rest Timer
            Expanded(
              child: RestTimer(
                initialDurationSeconds: 90,
                onTimerComplete: () {
                  Navigator.of(context).pop();
                  _onTimerComplete();
                },
              ),
            ),
            
            // Close button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Continue Workout',
                    style: TextStyle(
                      color: Color(0xFFFFB74D),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      // Timer modal closed
      setState(() {
        _showRestTimer = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFFB74D),
          ),
        ),
      );
    }

    if (_workout == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Workout Not Found'),
        ),
        body: const Center(
          child: Text(
            'Workout not found',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _workout!.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${_getDisplayExerciseCount()} exercises',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _finishWorkout,
            child: const Text(
              'Finish',
              style: TextStyle(
                color: Color(0xFFFFB74D),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workout Progress
            _buildWorkoutProgress(),
            const SizedBox(height: 24),
            
            // Current Exercise Section
            if (_selectedExercise == null) ...[
              _buildExerciseSelection(),
            ] else ...[
              _buildExerciseLogging(),
            ],
            
            const SizedBox(height: 24),
            
            // Completed Exercises
            if (_workout!.exercises.isNotEmpty) ...[
              _buildCompletedExercises(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutProgress() {
    final totalVolume = _workout!.totalVolume;
    final duration = _workout!.startedAt != null 
        ? DateTime.now().difference(_workout!.startedAt!)
        : Duration.zero;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB74D), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Volume',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${totalVolume.toStringAsFixed(0)} kg',
                  style: const TextStyle(
                    color: Color(0xFFFFB74D),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Duration',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Color(0xFFFFB74D),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Exercises',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${_workout!.exercises.length}',
                  style: const TextStyle(
                    color: Color(0xFFFFB74D),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.fitness_center, color: Color(0xFFFFB74D)),
            const SizedBox(width: 8),
            const Text(
              'Select Exercise',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (_isLoadingExercises) ...[
          const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFB74D)),
          ),
        ] else if (_availableExercises.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No exercises found for selected body parts',
              style: TextStyle(color: Colors.white60),
              textAlign: TextAlign.center,
            ),
          ),
        ] else ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _availableExercises.length,
            itemBuilder: (context, index) {
              final exercise = _availableExercises[index];
              return _buildExerciseTile(exercise);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildExerciseTile(Exercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        tileColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          exercise.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          exercise.bodyParts.join(', '),
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFFFFB74D),
          size: 16,
        ),
        onTap: () => _selectExercise(exercise),
      ),
    );
  }

  Widget _buildExerciseLogging() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Exercise Header
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _selectedExercise = null),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedExercise!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _selectedExercise!.bodyParts.join(', '),
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Current Sets
        if (_currentSets.isNotEmpty) ...[
          _buildCurrentSets(),
          const SizedBox(height: 16),
        ],
        
        // Add Set Form
        _buildAddSetForm(),
        const SizedBox(height: 16),
        
        // Action Buttons
        Row(
          children: [
            // Rest Timer Button
            if (_currentSets.isNotEmpty) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showRestTimerModal,
                  icon: const Icon(Icons.timer, size: 20),
                  label: const Text('Rest Timer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFB74D),
                    side: const BorderSide(color: Color(0xFFFFB74D)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            
            // Save Exercise Button
            if (_currentSets.isNotEmpty) ...[
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _saveExercise,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB74D),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Exercise',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Full width rest timer when no sets
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showRestTimerModal,
                  icon: const Icon(Icons.timer, size: 20),
                  label: const Text('Start Rest Timer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFB74D),
                    side: const BorderSide(color: Color(0xFFFFB74D)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentSets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sets',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        ..._currentSets.asMap().entries.map((entry) {
          final index = entry.key;
          final set = entry.value;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  'Set ${set.setNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  set.summary,
                  style: const TextStyle(
                    color: Color(0xFFFFB74D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _removeSet(index),
                  child: const Icon(
                    Icons.close,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAddSetForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Set',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              // Weight Input
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    labelStyle: TextStyle(color: Colors.white60),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF2A2A2A)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFFB74D)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Reps Input
              Expanded(
                child: TextField(
                  controller: _repsController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Reps',
                    labelStyle: TextStyle(color: Colors.white60),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF2A2A2A)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFFB74D)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Add Set Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addSet,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Set'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A2A2A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedExercises() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Completed Exercises',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        ..._workout!.exercises.map((exercise) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exerciseName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                
                ...exercise.sets.map((set) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          'Set ${set.setNumber}: ',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          set.summary,
                          style: const TextStyle(
                            color: Color(0xFFFFB74D),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${set.volume.toStringAsFixed(0)} kg',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                
                const SizedBox(height: 8),
                Text(
                  'Total: ${exercise.totalVolume.toStringAsFixed(0)} kg',
                  style: const TextStyle(
                    color: Color(0xFFFFB74D),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildWorkoutSummaryDialog() {
    final totalVolume = _workout!.totalVolume;
    final duration = _workout!.actualDuration;
    
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text(
        'Workout Complete! 🎉',
        style: TextStyle(
          color: Color(0xFFFFB74D),
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _workout!.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildSummaryRow('Exercises', '${_workout!.exercises.length}'),
          _buildSummaryRow('Total Sets', '${_getTotalSets()}'),
          _buildSummaryRow('Total Volume', '${totalVolume.toStringAsFixed(0)} kg'),
          _buildSummaryRow('Duration', '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          child: const Text(
            'Done',
            style: TextStyle(
              color: Color(0xFFFFB74D),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  int _getTotalSets() {
    return _workout!.exercises.fold(0, (sum, exercise) => sum + exercise.sets.length);
  }

  /// Get exercise count for header display
  /// For template workouts: shows total template exercises available
  /// For custom workouts: shows currently logged exercises
  int _getDisplayExerciseCount() {
    // If this is a template workout (has predefined exercises), show available exercise count
    if (_workout != null && _workout!.exercises.isNotEmpty) {
      // Template workout: show the number of available exercises from template
      return _availableExercises.length;
    }
    // Custom workout: show the number of exercises currently being logged
    return _workout?.exercises.length ?? 0;
  }

  /// Get set count for header display  
  /// For template workouts: shows expected sets based on template data
  /// For custom workouts: shows actual logged sets
  int _getDisplaySetCount() {
    // If this is a template workout, calculate expected sets from template
    if (_workout != null && _workout!.exercises.isNotEmpty) {
      // For now, use 3 sets per exercise as standard for templates
      // TODO: In future, could read suggestedSets from TemplateExercise if available
      return _availableExercises.length * 3;
    }
    // Custom workout: show actual logged sets
    return _getTotalSets();
  }
}