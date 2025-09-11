import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../services/workout_template_repository.dart';
import '../services/database_helper.dart';
import '../services/common_exercise_service.dart';
import '../widgets/body_silhouette.dart';

/// Screen for creating new workout templates
/// Allows users to build custom workout plans with exercise selection
class CreateWorkoutPlanScreen extends StatefulWidget {
  const CreateWorkoutPlanScreen({super.key});

  @override
  State<CreateWorkoutPlanScreen> createState() => _CreateWorkoutPlanScreenState();
}

class _CreateWorkoutPlanScreenState extends State<CreateWorkoutPlanScreen> with SingleTickerProviderStateMixin {
  final WorkoutTemplateRepository _templateRepository = WorkoutTemplateRepository();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final CommonExerciseService _exerciseService = CommonExerciseService();
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  
  // State
  bool _isLoading = false;
  bool _isSaving = false;
  List<Exercise> _availableExercises = [];
  final List<TemplateExercise> _selectedExercises = [];
  final Set<String> _selectedBodyParts = {};
  String? _selectedBodyPart; // For filtering exercises
  
  // Form fields
  TemplateDifficulty _difficulty = TemplateDifficulty.beginner;
  TemplateCategory _category = TemplateCategory.custom;
  
  // UI state
  late TabController _tabController;
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExercises();
    
    // Set default duration
    _durationController.text = '45';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    // Don't close the database connection - it's shared across the app
    // _templateRepository.close();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    
    try {
      final exercises = await _exerciseService.getAllExercises();
      if (mounted) {
        setState(() {
          _availableExercises = exercises;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load exercises: $e');
      }
    }
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedExercises.isEmpty) {
      _showError('Please select at least one exercise');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = await _dbHelper.createMockUser();
      final templateId = _dbHelper.generateWorkoutTemplateId();
      final now = DateTime.now();

      // Create template exercises
      final templateExercises = <TemplateExercise>[];
      for (int i = 0; i < _selectedExercises.length; i++) {
        final exercise = _selectedExercises[i];
        templateExercises.add(exercise.copyWith(
          templateExerciseId: _dbHelper.generateTemplateExerciseId(templateId, exercise.exerciseId),
          templateId: templateId,
          orderIndex: i,
        ));
      }

      final template = WorkoutTemplate(
        templateId: templateId,
        userId: userId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        targetBodyParts: _selectedBodyParts.toList(),
        estimatedDurationMinutes: int.tryParse(_durationController.text) ?? 45,
        difficulty: _difficulty,
        category: _category,
        createdAt: now,
        updatedAt: now,
        exercises: templateExercises,
      );

      await _templateRepository.saveTemplate(template);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workout plan "${template.name}" created successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showError('Failed to save workout plan: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _addExercise(Exercise exercise) {
    final templateExercise = TemplateExercise(
      templateExerciseId: '', // Will be set when saving
      templateId: '',
      exerciseId: exercise.exerciseId,
      exerciseName: exercise.name,
      bodyParts: exercise.bodyParts,
      orderIndex: _selectedExercises.length,
      suggestedSets: 3,
      suggestedRepsMin: 8,
      suggestedRepsMax: 12,
      restTimeSeconds: 90,
    );

    setState(() {
      _selectedExercises.add(templateExercise);
      _selectedBodyParts.addAll(exercise.bodyParts);
    });
  }

  void _removeExercise(int index) {
    final exercise = _selectedExercises[index];
    
    setState(() {
      _selectedExercises.removeAt(index);
      
      // Update order indexes
      for (int i = index; i < _selectedExercises.length; i++) {
        _selectedExercises[i] = _selectedExercises[i].copyWith(orderIndex: i);
      }
      
      // Recalculate selected body parts
      _selectedBodyParts.clear();
      for (final ex in _selectedExercises) {
        _selectedBodyParts.addAll(ex.bodyParts);
      }
    });
  }

  void _updateExercise(int index, TemplateExercise updatedExercise) {
    setState(() {
      _selectedExercises[index] = updatedExercise;
    });
  }

  void _onBodyPartSelected(String bodyPart) {
    setState(() {
      _selectedBodyPart = _selectedBodyPart == bodyPart ? null : bodyPart;
    });
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
        title: const Text(
          'Create Workout Plan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
        actions: [
          if (_currentStep == _totalSteps - 1)
            TextButton(
              onPressed: _isSaving ? null : _saveTemplate,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Color(0xFFFFB74D),
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: Color(0xFFFFB74D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFB74D)),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildBasicInfoStep(),
          _buildExerciseSelectionStep(),
          _buildReviewStep(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: TextButton(
                onPressed: _previousStep,
                child: const Text(
                  'Previous',
                  style: TextStyle(color: Colors.white60),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _currentStep == _totalSteps - 1 ? _saveTemplate : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB74D),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep == _totalSteps - 1 ? 'Create Plan' : 'Next',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Give your workout plan a name and description',
              style: TextStyle(color: Colors.white60, fontSize: 16),
            ),
            const SizedBox(height: 32),

            // Plan name
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Plan Name *',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: 'e.g., Upper Body Strength',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFFB74D)),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Plan name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Description
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: 'Describe your workout plan...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFFB74D)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Duration
            TextFormField(
              controller: _durationController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Estimated Duration (minutes)',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: '45',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFFB74D)),
                ),
                suffixText: 'min',
                suffixStyle: const TextStyle(color: Colors.white60),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final duration = int.tryParse(value);
                  if (duration == null || duration <= 0) {
                    return 'Please enter a valid duration';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Difficulty
            const Text(
              'Difficulty Level',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: TemplateDifficulty.values.map((difficulty) {
                final isSelected = _difficulty == difficulty;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: difficulty == TemplateDifficulty.values.last ? 0 : 8,
                    ),
                    child: GestureDetector(
                      onTap: () => setState(() => _difficulty = difficulty),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFB74D) : const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected ? null : Border.all(color: const Color(0xFF444444)),
                        ),
                        child: Text(
                          difficulty.name.substring(0, 1).toUpperCase() + difficulty.name.substring(1),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Category
            const Text(
              'Category',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TemplateCategory>(
              initialValue: _category,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFFB74D)),
                ),
              ),
              dropdownColor: const Color(0xFF2A2A2A),
              items: TemplateCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(
                    _getCategoryDisplayName(category),
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (category) {
                if (category != null) {
                  setState(() => _category = category);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseSelectionStep() {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Exercises',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose exercises for your workout plan (${_selectedExercises.length} selected)',
                style: const TextStyle(color: Colors.white60, fontSize: 16),
              ),
            ],
          ),
        ),

        // Exercise selection tabs
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  labelColor: const Color(0xFFFFB74D),
                  unselectedLabelColor: Colors.white60,
                  indicatorColor: const Color(0xFFFFB74D),
                  tabs: const [
                    Tab(text: 'By Body Part'),
                    Tab(text: 'All Exercises'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildBodyPartSelection(),
                      _buildExerciseList(_availableExercises),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Selected exercises summary
        if (_selectedExercises.isNotEmpty) _buildSelectedExercisesSummary(),
      ],
    );
  }

  Widget _buildBodyPartSelection() {
    return Column(
      children: [
        // Body silhouettes
        Padding(
          padding: const EdgeInsets.all(16),
          child: BodySilhouette(
            selectedBodyPart: _selectedBodyPart,
            onBodyPartSelected: _onBodyPartSelected,
            showLabels: false,
          ),
        ),

        // Exercise list filtered by selected body part
        Expanded(
          child: _selectedBodyPart != null
              ? _buildExerciseList(
                  _availableExercises
                      .where((ex) => ex.bodyParts.contains(_selectedBodyPart))
                      .toList(),
                )
              : const Center(
                  child: Text(
                    'Select a body part above to see exercises',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildExerciseList(List<Exercise> exercises) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFB74D)),
      );
    }

    if (exercises.isEmpty) {
      return const Center(
        child: Text(
          'No exercises available',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        final isSelected = _selectedExercises.any((ex) => ex.exerciseId == exercise.exerciseId);

        return Card(
          color: const Color(0xFF1A1A1A),
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      exercise.gifUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 50,
                        height: 50,
                        color: const Color(0xFF2A2A2A),
                        child: const Icon(Icons.fitness_center, color: Colors.white60),
                      ),
                    ),
                  ),
            title: Text(
              exercise.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              exercise.bodyParts.join(', '),
              style: const TextStyle(color: Colors.white60),
            ),
            trailing: IconButton(
              onPressed: () => _addExercise(exercise),
              icon: Icon(
                isSelected ? Icons.check_circle : Icons.add_circle_outline,
                color: isSelected ? Colors.green : const Color(0xFFFFB74D),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedExercisesSummary() {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Exercises (${_selectedExercises.length})',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedExercises.length,
              itemBuilder: (context, index) {
                final exercise = _selectedExercises[index];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        exercise.exerciseName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _removeExercise(index),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review Your Plan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Review your workout plan before creating it',
            style: TextStyle(color: Colors.white60, fontSize: 16),
          ),
          const SizedBox(height: 32),

          // Plan details
          _buildReviewCard(
            'Plan Details',
            [
              _buildReviewItem('Name', _nameController.text.trim()),
              if (_descriptionController.text.trim().isNotEmpty)
                _buildReviewItem('Description', _descriptionController.text.trim()),
              _buildReviewItem('Duration', '${_durationController.text} minutes'),
              _buildReviewItem('Difficulty', _difficulty.name.substring(0, 1).toUpperCase() + _difficulty.name.substring(1)),
              _buildReviewItem('Category', _getCategoryDisplayName(_category)),
              _buildReviewItem('Target Body Parts', _selectedBodyParts.join(', ')),
            ],
          ),

          const SizedBox(height: 16),

          // Exercises
          _buildReviewCard(
            'Exercises (${_selectedExercises.length})',
            _selectedExercises.map((exercise) => _buildExerciseReviewItem(exercise)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(String title, List<Widget> children) {
    return Card(
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseReviewItem(TemplateExercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exerciseName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${exercise.suggestedSets} sets × ${exercise.suggestedRepsRange}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            exercise.bodyParts.join(', '),
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _getCategoryDisplayName(TemplateCategory category) {
    switch (category) {
      case TemplateCategory.custom:
        return 'Custom';
      case TemplateCategory.strength:
        return 'Strength';
      case TemplateCategory.cardio:
        return 'Cardio';
      case TemplateCategory.fullBody:
        return 'Full Body';
      case TemplateCategory.upperBody:
        return 'Upper Body';
      case TemplateCategory.lowerBody:
        return 'Lower Body';
      case TemplateCategory.push:
        return 'Push';
      case TemplateCategory.pull:
        return 'Pull';
      case TemplateCategory.legs:
        return 'Legs';
    }
  }
}