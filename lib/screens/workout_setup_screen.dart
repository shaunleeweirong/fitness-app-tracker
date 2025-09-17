import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../services/workout_repository.dart';
import '../services/database_helper.dart';
import 'exercise_selection_screen.dart';

/// Workout customization screen for creating new workouts
/// Allows users to select workout duration and target muscle groups, or start from a template
class WorkoutSetupScreen extends StatefulWidget {
  final WorkoutTemplate? template;
  
  const WorkoutSetupScreen({super.key, this.template});

  @override
  State<WorkoutSetupScreen> createState() => _WorkoutSetupScreenState();
}

class _WorkoutSetupScreenState extends State<WorkoutSetupScreen> {
  final WorkoutRepository _repository = WorkoutRepository();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  // Form state
  int _selectedDuration = 45; // Default 45 minutes
  String? _selectedBodyPart;
  List<String> _targetBodyParts = [];
  final TextEditingController _nameController = TextEditingController();
  
  // UI state
  bool _isCreating = false;
  
  // Workout duration options
  final List<int> _durationOptions = [15, 30, 45, 60, 90];
  
  // Template state
  bool _isFromTemplate = false;
  
  // Exercise management state
  List<UserExercise> _currentExercises = [];
  bool _hasExerciseModifications = false;
  
  // Exercise editing state
  DateTime? _lastEditTap;
  bool _isEditingExercise = false;

  @override
  void initState() {
    super.initState();
    _initializeFromTemplate();
  }

  @override
  void dispose() {
    _nameController.dispose();
    // Don't close the database connection - it's shared across the app
    // _repository.close();
    super.dispose();
  }
  
  void _initializeFromTemplate() {
    if (widget.template != null) {
      final template = widget.template!;
      print('🎯 [SETUP] Initializing from template: ${template.name}');
      print('🎯 [SETUP] Template ID: ${template.templateId}');
      print('🎯 [SETUP] Template exercises count: ${template.exercises.length}');
      print('🎯 [SETUP] Template target body parts: ${template.targetBodyParts}');
      print('🎯 [SETUP] Template duration: ${template.estimatedDurationMinutes} minutes');
      
      // Log each template exercise for debugging
      for (var i = 0; i < template.exercises.length; i++) {
        final exercise = template.exercises[i];
        print('🎯 [SETUP] Template Exercise $i: ${exercise.exerciseName} (${exercise.bodyParts.join(", ")})');
        print('🎯 [SETUP]   Sets: ${exercise.suggestedSets}, Reps: ${exercise.suggestedRepsMin}-${exercise.suggestedRepsMax}');
      }
      
      setState(() {
        _isFromTemplate = true;
        _nameController.text = template.name;
        _selectedDuration = template.estimatedDurationMinutes ?? 45;
        _targetBodyParts = List.from(template.targetBodyParts);
        
        // Convert template exercises to user exercises for customization
        _currentExercises = template.exercises.map((templateExercise) => 
          UserExercise.fromTemplateExercise(templateExercise)).toList();
        print('📋 [SETUP] Loaded ${_currentExercises.length} exercises for customization');
      });
      
      print('🎯 [SETUP] Initialized state - Target body parts: $_targetBodyParts');
    } else {
      print('🎯 [SETUP] No template provided - creating custom workout');
    }
  }

  void _onBodyPartSelected(String bodyPart) {
    print('🎯 [SETUP] Body part selected: $bodyPart');
    print('🎯 [SETUP] Current target body parts before: $_targetBodyParts');
    
    setState(() {
      _selectedBodyPart = bodyPart;
      if (!_targetBodyParts.contains(bodyPart)) {
        _targetBodyParts.add(bodyPart);
        print('🎯 [SETUP] Added body part: $bodyPart');
      } else {
        print('🎯 [SETUP] Body part already selected: $bodyPart');
      }
      
      // Auto-generate workout name if empty
      if (_nameController.text.isEmpty) {
        _nameController.text = _generateWorkoutName();
      }
    });
    
    print('🎯 [SETUP] Current target body parts after: $_targetBodyParts');
    print('🎯 [SETUP] Generated workout name: ${_nameController.text}');
  }

  void _removeBodyPart(String bodyPart) {
    print('🎯 [SETUP] Removing body part: $bodyPart');
    print('🎯 [SETUP] Target body parts before removal: $_targetBodyParts');
    
    setState(() {
      _targetBodyParts.remove(bodyPart);
      if (_selectedBodyPart == bodyPart) {
        _selectedBodyPart = null;
      }
      
      // Update workout name
      if (_nameController.text == _generateWorkoutName()) {
        _nameController.text = _generateWorkoutName();
      }
    });
    
    print('🎯 [SETUP] Target body parts after removal: $_targetBodyParts');
    print('🎯 [SETUP] Updated workout name: ${_nameController.text}');
  }

  String _generateWorkoutName() {
    if (_targetBodyParts.isEmpty) {
      return 'Custom Workout';
    }
    
    if (_targetBodyParts.length == 1) {
      final bodyPart = _targetBodyParts.first;
      return '${_capitalizeFirst(bodyPart)} Workout';
    }
    
    if (_targetBodyParts.length <= 3) {
      final formatted = _targetBodyParts
          .map((part) => _capitalizeFirst(part))
          .join(' & ');
      return '$formatted Workout';
    }
    
    return 'Full Body Workout';
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<void> _createWorkout() async {
    print('🎯 [SETUP] Starting workout creation...');
    print('🎯 [SETUP] Selected target body parts: $_targetBodyParts');
    print('🎯 [SETUP] Selected duration: $_selectedDuration minutes');
    print('🎯 [SETUP] Workout name: ${_nameController.text}');
    print('🎯 [SETUP] Is from template: $_isFromTemplate');
    
    if (_currentExercises.isEmpty) {
      print('🎯 [SETUP] ERROR: No exercises selected');
      _showError('Please add at least one exercise to your workout');
      return;
    }
    
    setState(() {
      _isCreating = true;
    });
    
    try {
      // Get or create mock user
      final userId = await _dbHelper.createMockUser();
      print('🎯 [SETUP] User ID: $userId');
      
      // Create UserWorkout with customized exercise list
      UserWorkout userWorkout;
      
      if (_isFromTemplate && widget.template != null) {
        print('🎯 [SETUP] Creating UserWorkout from template...');
        final template = widget.template!;
        
        // Detect modifications
        WorkoutCustomizations? modifications;
        if (_hasExerciseModifications) {
          print('🎯 [SETUP] Detected exercise modifications');
          modifications = _createWorkoutCustomizations(template);
        }
        
        // Get current target body parts from current exercises
        final currentTargetBodyParts = _currentExercises
            .expand((exercise) => exercise.bodyParts)
            .toSet()
            .toList();
        
        userWorkout = UserWorkout.fromTemplate(
          template,
          userId: userId,
          customName: _nameController.text.isNotEmpty ? _nameController.text : null,
          customExercises: List.from(_currentExercises),
          modifications: modifications,
        );
        
        // Apply user customizations
        userWorkout = userWorkout.copyWith(
          targetBodyParts: currentTargetBodyParts,
          plannedDurationMinutes: _selectedDuration,
        );
        
        print('🎯 [SETUP] UserWorkout created from template:');
        print('🎯 [SETUP]   Name: ${userWorkout.name}');
        print('🎯 [SETUP]   Base template: ${userWorkout.baseTemplateId}');
        print('🎯 [SETUP]   Exercises: ${userWorkout.exercises.length}');
        print('🎯 [SETUP]   Has modifications: ${userWorkout.hasModifications}');
        
      } else {
        print('🎯 [SETUP] Creating custom UserWorkout...');
        
        // Get current target body parts from current exercises
        final currentTargetBodyParts = _currentExercises.isEmpty 
            ? _targetBodyParts
            : _currentExercises
                .expand((exercise) => exercise.bodyParts)
                .toSet()
                .toList();
        
        userWorkout = UserWorkout.custom(
          userId: userId,
          name: _nameController.text.isNotEmpty ? _nameController.text : _generateWorkoutName(),
          targetBodyParts: currentTargetBodyParts,
          plannedDurationMinutes: _selectedDuration,
          exercises: List.from(_currentExercises),
        );
        
        print('🎯 [SETUP] Custom UserWorkout created with ${userWorkout.exercises.length} exercises');
      }
      
      // Convert UserWorkout to standard Workout for execution
      print('🎯 [SETUP] Converting UserWorkout to executable Workout...');
      final workout = userWorkout.toWorkout();
      
      print('🎯 [SETUP] Final workout details:');
      print('🎯 [SETUP]   ID: ${workout.workoutId}');
      print('🎯 [SETUP]   Name: ${workout.name}');
      print('🎯 [SETUP]   Target body parts: ${workout.targetBodyParts}');
      print('🎯 [SETUP]   Duration: ${workout.plannedDurationMinutes} minutes');
      print('🎯 [SETUP]   Exercise count: ${workout.exercises.length}');
      print('🎯 [SETUP]   Status: ${workout.status}');
      
      // Log each exercise in the final workout
      for (var i = 0; i < workout.exercises.length; i++) {
        final exercise = workout.exercises[i];
        print('🎯 [SETUP]   Exercise $i: ${exercise.exerciseName} (${exercise.bodyParts.join(", ")})');
      }
      
      // Save workout to database (using existing repository)
      print('🎯 [SETUP] Saving workout to database...');
      await _repository.saveWorkout(workout);
      print('🎯 [SETUP] Workout saved successfully');
      
      // Navigate to workout logging screen
      if (mounted) {
        print('🎯 [SETUP] Navigating to workout logging screen with ID: ${workout.workoutId}');
        Navigator.of(context).pushReplacementNamed(
          '/workout-logging',
          arguments: workout.workoutId,
        );
      }
    } catch (e) {
      print('🎯 [SETUP] ERROR creating workout: $e');
      _showError('Failed to create workout: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isFromTemplate ? 'Customize Workout' : 'Create Workout',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template info banner
            if (_isFromTemplate && widget.template != null)
              _buildTemplateBanner(),
            
            // Workout Name Section
            _buildSectionHeader('Workout Name', Icons.fitness_center),
            const SizedBox(height: 12),
            _buildNameInput(),
            const SizedBox(height: 32),
            
            // Duration Selection
            _buildSectionHeader('Workout Duration', Icons.timer),
            const SizedBox(height: 12),
            _buildDurationSelector(),
            const SizedBox(height: 32),
            
            // Exercise Preview & Customization
            _buildSectionHeader('Exercise Plan', Icons.fitness_center),
            const SizedBox(height: 12),
            _buildExerciseList(),
            const SizedBox(height: 32),
            
            // Workout Summary
            if (_targetBodyParts.isNotEmpty) ...[
              _buildSectionHeader('Workout Summary', Icons.summarize),
              const SizedBox(height: 12),
              _buildWorkoutSummary(),
              const SizedBox(height: 32),
            ],
            
            // Create Workout Button
            _buildCreateWorkoutButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTemplateBanner() {
    final template = widget.template!;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB74D).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bookmark, color: Color(0xFFFFB74D), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Using Template',
                style: TextStyle(
                  color: Color(0xFFFFB74D),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            template.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (template.description != null) ...[
            const SizedBox(height: 4),
            Text(
              template.description!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTemplateInfoChip('${template.exercises.length} exercises'),
              const SizedBox(width: 8),
              _buildTemplateInfoChip(template.categoryName),
              const SizedBox(width: 8),
              _buildTemplateInfoChip(template.difficultyName),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTemplateInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFFB74D), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildNameInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: TextField(
        controller: _nameController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Enter workout name (optional)',
          hintStyle: TextStyle(color: Color(0xFF666666)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: _durationOptions.map((duration) {
          final isSelected = duration == _selectedDuration;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDuration = duration;
                });
              },
              child: Container(
                margin: const EdgeInsets.all(2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFB74D) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${duration}min',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectedBodyParts() {
    if (_targetBodyParts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: const Text(
          'Tap on the body silhouette to select target muscles',
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _targetBodyParts.map((bodyPart) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB74D),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _capitalizeFirst(bodyPart),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _removeBodyPart(bodyPart),
                child: const Icon(
                  Icons.close,
                  color: Colors.black,
                  size: 16,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWorkoutSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB74D), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: Color(0xFFFFB74D), size: 16),
              const SizedBox(width: 8),
              Text(
                'Duration: $_selectedDuration minutes',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.fitness_center, color: Color(0xFFFFB74D), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Target: ${_targetBodyParts.map((p) => _capitalizeFirst(p)).join(", ")}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    print('📋 [EXERCISE_LIST] Building exercise list with ${_currentExercises.length} exercises');
    
    if (_currentExercises.isEmpty) {
      return _buildEmptyExerciseList();
    }
    
    return Column(
      children: [
        // Exercise list header
        Row(
          children: [
            const Icon(Icons.fitness_center, color: Color(0xFFFFB74D), size: 20),
            const SizedBox(width: 8),
            Text(
              'Planned Exercises (${_currentExercises.length})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (_isFromTemplate && _hasExerciseModifications)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.3)),
                ),
                child: const Text(
                  'Modified',
                  style: TextStyle(
                    color: Color(0xFFFFB74D),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Exercise cards
        ...List.generate(_currentExercises.length, (index) {
          final exercise = _currentExercises[index];
          return _buildExerciseCard(exercise, index);
        }),
        
        const SizedBox(height: 16),
        
        // Add exercise button
        _buildAddExerciseButton(),
      ],
    );
  }
  
  Widget _buildExerciseCard(UserExercise exercise, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise header with remove button
          Row(
            children: [
              Expanded(
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.accessibility_new, 
                          color: Colors.grey[400], size: 14),
                        const SizedBox(width: 4),
                        Text(
                          exercise.bodyParts.join(', '),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Remove exercise button
              IconButton(
                onPressed: () => _removeExercise(index),
                icon: const Icon(Icons.close, color: Colors.red, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Exercise details
          Row(
            children: [
              _buildExerciseDetailChip(
                '${exercise.suggestedSets} sets',
                Icons.repeat,
              ),
              const SizedBox(width: 8),
              _buildExerciseDetailChip(
                exercise.repsRange,
                Icons.fitness_center,
              ),
              if (exercise.suggestedWeight != null) ...[
                const SizedBox(width: 8),
                _buildExerciseDetailChip(
                  exercise.weightDisplay,
                  Icons.scale,
                ),
              ],
              const Spacer(),
              // Edit exercise button
              GestureDetector(
                onTap: () => _editExercise(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB74D).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      color: Color(0xFFFFB74D),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildExerciseDetailChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFFFB74D), size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyExerciseList() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center,
            color: Colors.grey[600],
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No exercises selected',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding exercises to your workout',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          _buildAddExerciseButton(),
        ],
      ),
    );
  }
  
  Widget _buildAddExerciseButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _addExercise,
        icon: const Icon(Icons.add, color: Color(0xFFFFB74D)),
        label: const Text(
          'Add Exercise',
          style: TextStyle(
            color: Color(0xFFFFB74D),
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFFB74D)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
  
  // Exercise management methods (placeholder implementations)
  void _removeExercise(int index) {
    print('❌ [EXERCISE_REMOVE] Removing exercise at index $index: ${_currentExercises[index].exerciseName}');
    setState(() {
      _currentExercises.removeAt(index);
      _hasExerciseModifications = true;
      
      // Reorder remaining exercises
      for (int i = 0; i < _currentExercises.length; i++) {
        _currentExercises[i] = _currentExercises[i].copyWith(orderIndex: i);
      }
    });
    print('✅ [EXERCISE_REMOVE] Exercise removed, remaining: ${_currentExercises.length}');
  }
  
  void _editExercise(int index) {
    print('✏️ [EXERCISE_EDIT] Edit button tapped for index $index: ${_currentExercises[index].exerciseName}');
    
    // Debounce rapid taps
    final now = DateTime.now();
    if (_lastEditTap != null && now.difference(_lastEditTap!) < const Duration(milliseconds: 500)) {
      print('⚠️ [EXERCISE_EDIT] Ignoring rapid tap (debounced)');
      return;
    }
    _lastEditTap = now;
    
    // Prevent multiple simultaneous edits
    if (_isEditingExercise) {
      print('⚠️ [EXERCISE_EDIT] Already editing an exercise, ignoring tap');
      return;
    }
    
    print('✅ [EXERCISE_EDIT] Opening exercise editor for: ${_currentExercises[index].exerciseName}');
    _showExerciseEditModal(index);
  }
  
  Future<void> _showExerciseEditModal(int index) async {
    setState(() => _isEditingExercise = true);
    
    try {
      final exercise = _currentExercises[index];
      print('🔧 [EXERCISE_MODAL] Opening edit modal for: ${exercise.exerciseName}');
      
      final editedExercise = await showDialog<UserExercise>(
        context: context,
        builder: (context) => ExerciseEditDialog(
          exercise: exercise,
          exerciseIndex: index,
        ),
      );
      
      if (editedExercise != null) {
        print('💾 [EXERCISE_MODAL] Exercise updated: ${editedExercise.exerciseName}');
        print('💾 [EXERCISE_MODAL]   Sets: ${editedExercise.suggestedSets}');
        print('💾 [EXERCISE_MODAL]   Reps: ${editedExercise.suggestedRepsMin}-${editedExercise.suggestedRepsMax}');
        print('💾 [EXERCISE_MODAL]   Weight: ${editedExercise.weightDisplay}');
        
        setState(() {
          _currentExercises[index] = editedExercise;
          _hasExerciseModifications = true;
        });
        
        print('✅ [EXERCISE_MODAL] Exercise saved and modifications marked');
      } else {
        print('❌ [EXERCISE_MODAL] Edit cancelled by user');
      }
      
    } catch (e) {
      print('❌ [EXERCISE_MODAL] Error showing edit modal: $e');
      _showError('Failed to open exercise editor: $e');
    } finally {
      setState(() => _isEditingExercise = false);
    }
  }
  
  void _addExercise() async {
    print('➕ [EXERCISE_ADD] Add exercise button clicked');
    
    try {
      // Get list of already selected exercise IDs to exclude from selection
      final excludeIds = _currentExercises.map((e) => e.exerciseId).toList();
      print('📋 [EXERCISE_ADD] Excluding ${excludeIds.length} already selected exercises');
      
      // Navigate to exercise selection screen
      final selectedExercises = await Navigator.of(context).push<List<Exercise>>(
        MaterialPageRoute(
          builder: (context) => ExerciseSelectionScreen(
            excludeExerciseIds: excludeIds,
          ),
        ),
      );
      
      if (selectedExercises != null && selectedExercises.isNotEmpty) {
        print('✅ [EXERCISE_ADD] User selected ${selectedExercises.length} exercises');
        
        setState(() {
          _isCreating = true;
        });
        
        try {
          // Convert selected exercises to UserExercise format and add to workout
          for (final exercise in selectedExercises) {
            final userExercise = UserExercise(
              userExerciseId: 'user_ex_${DateTime.now().millisecondsSinceEpoch}_${exercise.exerciseId}',
              exerciseId: exercise.exerciseId,
              exerciseName: exercise.name,
              bodyParts: exercise.bodyParts,
              orderIndex: _currentExercises.length, // Add at end
              suggestedSets: 3, // Default sets
              suggestedRepsMin: 8, // Default rep range
              suggestedRepsMax: 12,
            );
            
            _currentExercises.add(userExercise);
            print('➕ [EXERCISE_ADD] Added exercise: ${exercise.name}');
          }
          
          // Mark workout as having modifications
          _hasExerciseModifications = true;
          print('📝 [EXERCISE_ADD] Marked workout as modified');
          
          // Show success feedback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  selectedExercises.length == 1
                      ? 'Added ${selectedExercises.first.name}'
                      : 'Added ${selectedExercises.length} exercises',
                ),
                backgroundColor: Colors.green.shade800,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          
        } catch (e) {
          print('❌ [EXERCISE_ADD] Error adding exercises: $e');
          if (mounted) {
            _showError('Failed to add exercises: $e');
          }
        } finally {
          if (mounted) {
            setState(() {
              _isCreating = false;
            });
          }
        }
      } else {
        print('❌ [EXERCISE_ADD] No exercises selected or user cancelled');
      }
      
    } catch (e) {
      print('❌ [EXERCISE_ADD] Error opening exercise selection: $e');
      if (mounted) {
        _showError('Failed to open exercise selection: $e');
      }
    }
  }
  
  WorkoutCustomizations _createWorkoutCustomizations(WorkoutTemplate template) {
    print('📝 [MODIFICATIONS] Creating workout customizations...');
    
    final originalExerciseIds = template.exercises.map((e) => e.exerciseId).toSet();
    final currentExerciseIds = _currentExercises.map((e) => e.exerciseId).toSet();
    
    final removedIds = originalExerciseIds.difference(currentExerciseIds).toList();
    final addedExercises = _currentExercises
        .where((exercise) => !originalExerciseIds.contains(exercise.exerciseId))
        .toList();
    
    print('📝 [MODIFICATIONS] Removed exercises: ${removedIds.length}');
    print('📝 [MODIFICATIONS] Added exercises: ${addedExercises.length}');
    
    // TODO: Detect modified exercises (sets/reps changes)
    final modifiedExercises = <String, ExerciseModification>{};
    
    return WorkoutCustomizations(
      removedExerciseIds: removedIds,
      addedExercises: addedExercises,
      modifiedExercises: modifiedExercises,
      modifiedAt: DateTime.now(),
    );
  }

  Widget _buildCreateWorkoutButton() {
    print('🎯 [SETUP] Building create workout button - isCreating: $_isCreating, targetBodyParts: $_targetBodyParts');
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isCreating ? null : () {
          print('🎯 [SETUP] 🔥 CREATE WORKOUT BUTTON CLICKED!');
          _createWorkout();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFB74D),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isCreating
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            )
          : Text(
              _isFromTemplate ? 'Start Workout' : 'Create Workout',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
      ),
    );
  }
}

/// Modal dialog for editing exercise parameters (sets, reps, weight, rest time)
class ExerciseEditDialog extends StatefulWidget {
  final UserExercise exercise;
  final int exerciseIndex;

  const ExerciseEditDialog({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
  });

  @override
  State<ExerciseEditDialog> createState() => _ExerciseEditDialogState();
}

class _ExerciseEditDialogState extends State<ExerciseEditDialog> {
  late TextEditingController _setsController;
  late TextEditingController _repsMinController;
  late TextEditingController _repsMaxController;
  late TextEditingController _weightController;
  late TextEditingController _restTimeController;
  
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    
    final exercise = widget.exercise;
    _setsController = TextEditingController(text: exercise.suggestedSets.toString());
    _repsMinController = TextEditingController(text: exercise.suggestedRepsMin.toString());
    _repsMaxController = TextEditingController(text: exercise.suggestedRepsMax.toString());
    _weightController = TextEditingController(
      text: exercise.suggestedWeight?.toString() ?? '',
    );
    _restTimeController = TextEditingController(text: exercise.restTimeSeconds.toString());
    
    // Add listeners to detect changes
    _setsController.addListener(_onValueChanged);
    _repsMinController.addListener(_onValueChanged);
    _repsMaxController.addListener(_onValueChanged);
    _weightController.addListener(_onValueChanged);
    _restTimeController.addListener(_onValueChanged);
    
    print('🔧 [EXERCISE_DIALOG] Initialized edit dialog for: ${exercise.exerciseName}');
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsMinController.dispose();
    _repsMaxController.dispose();
    _weightController.dispose();
    _restTimeController.dispose();
    super.dispose();
  }

  void _onValueChanged() {
    setState(() {
      _hasChanges = _checkForChanges();
    });
  }

  bool _checkForChanges() {
    final exercise = widget.exercise;
    
    final currentSets = int.tryParse(_setsController.text) ?? exercise.suggestedSets;
    final currentRepsMin = int.tryParse(_repsMinController.text) ?? exercise.suggestedRepsMin;
    final currentRepsMax = int.tryParse(_repsMaxController.text) ?? exercise.suggestedRepsMax;
    final currentWeight = double.tryParse(_weightController.text);
    final currentRestTime = int.tryParse(_restTimeController.text) ?? exercise.restTimeSeconds;
    
    return currentSets != exercise.suggestedSets ||
           currentRepsMin != exercise.suggestedRepsMin ||
           currentRepsMax != exercise.suggestedRepsMax ||
           currentWeight != exercise.suggestedWeight ||
           currentRestTime != exercise.restTimeSeconds;
  }

  UserExercise? _createUpdatedExercise() {
    try {
      final exercise = widget.exercise;
      
      final sets = int.tryParse(_setsController.text);
      final repsMin = int.tryParse(_repsMinController.text);
      final repsMax = int.tryParse(_repsMaxController.text);
      final weight = _weightController.text.isEmpty ? null : double.tryParse(_weightController.text);
      final restTime = int.tryParse(_restTimeController.text);
      
      // Validation
      if (sets == null || sets < 1 || sets > 10) {
        _showValidationError('Sets must be between 1 and 10');
        return null;
      }
      
      if (repsMin == null || repsMin < 1 || repsMin > 100) {
        _showValidationError('Minimum reps must be between 1 and 100');
        return null;
      }
      
      if (repsMax == null || repsMax < repsMin || repsMax > 100) {
        _showValidationError('Maximum reps must be between minimum reps and 100');
        return null;
      }
      
      if (weight != null && (weight < 0 || weight > 1000)) {
        _showValidationError('Weight must be between 0 and 1000 kg');
        return null;
      }
      
      if (restTime == null || restTime < 30 || restTime > 600) {
        _showValidationError('Rest time must be between 30 and 600 seconds');
        return null;
      }
      
      print('✅ [EXERCISE_DIALOG] Creating updated exercise with validation passed');
      
      return exercise.copyWith(
        suggestedSets: sets,
        suggestedRepsMin: repsMin,
        suggestedRepsMax: repsMax,
        suggestedWeight: weight,
        restTimeSeconds: restTime,
      );
      
    } catch (e) {
      print('❌ [EXERCISE_DIALOG] Error creating updated exercise: $e');
      _showValidationError('Invalid input values');
      return null;
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.edit, color: Color(0xFFFFB74D), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Exercise',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        exercise.exerciseName,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Exercise parameters
            _buildParameterRow(
              'Sets',
              _setsController,
              Icons.repeat,
              'Number of sets to perform',
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildParameterRow(
                    'Min Reps',
                    _repsMinController,
                    Icons.fitness_center,
                    'Minimum repetitions',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildParameterRow(
                    'Max Reps',
                    _repsMaxController,
                    Icons.fitness_center,
                    'Maximum repetitions',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildParameterRow(
              'Weight (kg)',
              _weightController,
              Icons.scale,
              'Weight to use (optional)',
              isOptional: true,
            ),
            
            const SizedBox(height: 16),
            
            _buildParameterRow(
              'Rest Time (seconds)',
              _restTimeController,
              Icons.timer,
              'Rest time between sets',
            ),
            
            const SizedBox(height: 32),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[600]!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _hasChanges ? _saveChanges : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasChanges ? const Color(0xFFFFB74D) : Colors.grey[700],
                      foregroundColor: _hasChanges ? Colors.black : Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      _hasChanges ? 'Save Changes' : 'No Changes',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterRow(
    String label,
    TextEditingController controller,
    IconData icon,
    String hint, {
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFFFFB74D), size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isOptional) ...[
              const SizedBox(width: 4),
              Text(
                '(optional)',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFFFB74D)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  void _saveChanges() {
    print('💾 [EXERCISE_DIALOG] Saving changes...');
    
    final updatedExercise = _createUpdatedExercise();
    if (updatedExercise != null) {
      print('✅ [EXERCISE_DIALOG] Exercise updated successfully');
      Navigator.of(context).pop(updatedExercise);
    } else {
      print('❌ [EXERCISE_DIALOG] Validation failed, not saving');
    }
  }
}