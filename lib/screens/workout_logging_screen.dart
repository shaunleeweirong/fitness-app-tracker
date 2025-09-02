import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../services/workout_repository.dart';
import '../services/exercise_service.dart';
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
      
      // Load exercises for each target body part
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
      
      if (mounted) {
        setState(() {
          _availableExercises = exerciseMap.values.toList()
            ..sort((a, b) => a.name.compareTo(b.name));
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
    setState(() {
      _selectedExercise = exercise;
      _currentSets = [];
      _weightController.clear();
      _repsController.clear();
    });
  }

  void _addSet() {
    final weightText = _weightController.text.trim();
    final repsText = _repsController.text.trim();
    
    if (weightText.isEmpty || repsText.isEmpty) {
      _showError('Please enter both weight and reps');
      return;
    }
    
    final weight = double.tryParse(weightText);
    final reps = int.tryParse(repsText);
    
    if (weight == null || weight <= 0) {
      _showError('Please enter a valid weight');
      return;
    }
    
    if (reps == null || reps <= 0) {
      _showError('Please enter valid reps');
      return;
    }
    
    setState(() {
      _currentSets.add(
        WorkoutSet(
          weight: weight,
          reps: reps,
          setNumber: _currentSets.length + 1,
          workoutExerciseId: '${widget.workoutId}_${_selectedExercise!.exerciseId}',
        ),
      );
      
      // Clear inputs for next set
      _weightController.clear();
      _repsController.clear();
    });
    
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
    if (_selectedExercise == null || _currentSets.isEmpty) {
      _showError('Please add at least one set');
      return;
    }
    
    try {
      // Create WorkoutExercise
      final workoutExercise = WorkoutExercise(
        exerciseId: _selectedExercise!.exerciseId,
        exerciseName: _selectedExercise!.name,
        bodyParts: _selectedExercise!.bodyParts,
        sets: _currentSets,
        orderIndex: _workout!.exercises.length + 1,
        workoutId: widget.workoutId,
      );
      
      // Update workout with new exercise
      final updatedWorkout = _workout!.copyWith(
        exercises: [..._workout!.exercises, workoutExercise],
      );
      
      await _workoutRepository.updateWorkout(updatedWorkout);
      
      if (mounted) {
        setState(() {
          _workout = updatedWorkout;
          _selectedExercise = null;
          _currentSets = [];
        });
        
        _showSuccess('Exercise saved successfully!');
      }
      
    } catch (e) {
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
              '${_workout!.exercises.length} exercises • ${_getTotalSets()} sets',
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
}