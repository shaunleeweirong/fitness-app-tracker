import 'package:flutter/material.dart';
import '../widgets/body_silhouette.dart';
import '../models/workout.dart';
import '../services/workout_repository.dart';
import '../services/database_helper.dart';

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
      setState(() {
        _isFromTemplate = true;
        _nameController.text = template.name;
        _selectedDuration = template.estimatedDurationMinutes ?? 45;
        _targetBodyParts = List.from(template.targetBodyParts);
      });
    }
  }

  void _onBodyPartSelected(String bodyPart) {
    setState(() {
      _selectedBodyPart = bodyPart;
      if (!_targetBodyParts.contains(bodyPart)) {
        _targetBodyParts.add(bodyPart);
      }
      
      // Auto-generate workout name if empty
      if (_nameController.text.isEmpty) {
        _nameController.text = _generateWorkoutName();
      }
    });
  }

  void _removeBodyPart(String bodyPart) {
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
    if (_targetBodyParts.isEmpty) {
      _showError('Please select at least one target muscle group');
      return;
    }
    
    setState(() {
      _isCreating = true;
    });
    
    try {
      // Get or create mock user
      final userId = await _dbHelper.createMockUser();
      
      Workout workout;
      
      if (_isFromTemplate && widget.template != null) {
        // Convert template to workout
        workout = widget.template!.toWorkout(
          userId: userId,
          customName: _nameController.text.isNotEmpty ? _nameController.text : null,
        );
        
        // Update with user customizations
        workout = workout.copyWith(
          targetBodyParts: List.from(_targetBodyParts),
          plannedDurationMinutes: _selectedDuration,
          createdAt: DateTime.now(),
        );
      } else {
        // Create workout from scratch
        workout = Workout(
          workoutId: 'workout_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          name: _nameController.text.isNotEmpty ? _nameController.text : _generateWorkoutName(),
          targetBodyParts: List.from(_targetBodyParts),
          plannedDurationMinutes: _selectedDuration,
          createdAt: DateTime.now(),
          status: WorkoutStatus.planned,
        );
      }
      
      // Save workout
      await _repository.saveWorkout(workout);
      
      // Navigate to workout logging screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/workout-logging',
          arguments: workout.workoutId,
        );
      }
    } catch (e) {
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
            
            // Target Muscles Selection
            _buildSectionHeader('Target Muscles', Icons.accessibility_new),
            const SizedBox(height: 12),
            _buildSelectedBodyParts(),
            const SizedBox(height: 16),
            
            // Body Silhouette
            BodySilhouette(
              selectedBodyPart: _selectedBodyPart,
              onBodyPartSelected: _onBodyPartSelected,
              showLabels: false,
            ),
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

  Widget _buildCreateWorkoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isCreating ? null : _createWorkout,
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