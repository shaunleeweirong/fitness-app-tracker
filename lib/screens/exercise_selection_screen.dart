import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../services/exercise_service.dart';
import '../widgets/body_silhouette.dart';

/// Screen for selecting exercises to add to a workout
/// Provides search, filtering, and multi-selection capabilities
class ExerciseSelectionScreen extends StatefulWidget {
  final List<String> excludeExerciseIds; // Already selected exercises to exclude
  
  const ExerciseSelectionScreen({
    super.key,
    this.excludeExerciseIds = const [],
  });

  @override
  State<ExerciseSelectionScreen> createState() => _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Exercise> _exercises = [];
  List<Exercise> _filteredExercises = [];
  Set<String> _selectedExerciseIds = {};
  bool _isLoading = true;
  String? _selectedBodyPart;
  bool _showBodySilhouette = false;
  List<String> _bodyParts = [];

  @override
  void initState() {
    super.initState();
    print('🏋️ [EXERCISE_SELECTION] Initializing exercise selection screen');
    _loadExercises();
    _searchController.addListener(_filterExercises);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    try {
      print('📱 [EXERCISE_SELECTION] Loading exercises...');
      setState(() => _isLoading = true);
      
      final exercises = await _exerciseService.getExercises(limit: 1000);
      final bodyParts = await _exerciseService.getBodyParts();
      
      // Filter out already selected exercises
      final availableExercises = exercises
          .where((exercise) => !widget.excludeExerciseIds.contains(exercise.exerciseId))
          .toList();
      
      print('📊 [EXERCISE_SELECTION] Loaded ${availableExercises.length} available exercises (${exercises.length} total, ${widget.excludeExerciseIds.length} excluded)');
      
      setState(() {
        _exercises = availableExercises;
        _filteredExercises = availableExercises;
        _bodyParts = bodyParts;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [EXERCISE_SELECTION] Error loading exercises: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load exercises: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  void _filterExercises() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredExercises = _exercises.where((exercise) {
        final matchesSearch = query.isEmpty ||
            exercise.name.toLowerCase().contains(query) ||
            exercise.primaryEquipment.toLowerCase().contains(query) ||
            exercise.bodyParts.any((part) => part.toLowerCase().contains(query));
        
        final matchesBodyPart = _selectedBodyPart == null ||
            exercise.bodyParts.contains(_selectedBodyPart!);
        
        return matchesSearch && matchesBodyPart;
      }).toList();
    });
    
    print('🔍 [EXERCISE_SELECTION] Filtered to ${_filteredExercises.length} exercises (query: "$query", bodyPart: $_selectedBodyPart)');
  }

  void _loadExercisesByBodyPart(String? bodyPart) {
    print('🎯 [EXERCISE_SELECTION] Filtering by body part: $bodyPart');
    setState(() {
      _selectedBodyPart = bodyPart;
    });
    _filterExercises();
  }

  void _toggleExerciseSelection(String exerciseId) {
    setState(() {
      if (_selectedExerciseIds.contains(exerciseId)) {
        _selectedExerciseIds.remove(exerciseId);
        print('➖ [EXERCISE_SELECTION] Deselected exercise: $exerciseId');
      } else {
        _selectedExerciseIds.add(exerciseId);
        print('➕ [EXERCISE_SELECTION] Selected exercise: $exerciseId');
      }
    });
  }

  void _addSelectedExercises() {
    if (_selectedExerciseIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one exercise'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedExercises = _exercises
        .where((exercise) => _selectedExerciseIds.contains(exercise.exerciseId))
        .toList();
    
    print('✅ [EXERCISE_SELECTION] Adding ${selectedExercises.length} exercises to workout');
    Navigator.of(context).pop(selectedExercises);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(
          'Add Exercises',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Toggle view mode
          IconButton(
            onPressed: () {
              setState(() {
                _showBodySilhouette = !_showBodySilhouette;
              });
            },
            icon: Icon(
              _showBodySilhouette ? Icons.list : Icons.accessibility_new,
              color: const Color(0xFFFFB74D),
            ),
            tooltip: _showBodySilhouette ? 'List View' : 'Body View',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),
          
          // Body part filters or body silhouette
          if (_showBodySilhouette)
            _buildBodySilhouetteView()
          else
            _buildBodyPartFilters(),
          
          // Exercise list
          Expanded(
            child: _buildExerciseList(),
          ),
        ],
      ),
      floatingActionButton: _selectedExerciseIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _addSelectedExercises,
              backgroundColor: const Color(0xFFFFB74D),
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add),
              label: Text(
                'ADD ${_selectedExerciseIds.length}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : null,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Search exercises or equipment',
          hintStyle: TextStyle(color: Colors.white54),
          prefixIcon: Icon(Icons.search, color: Colors.white54),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildBodySilhouetteView() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          children: [
            // Body Silhouette
            BodySilhouette(
              selectedBodyPart: _selectedBodyPart,
              onBodyPartSelected: _loadExercisesByBodyPart,
              showLabels: false,
            ),
            
            const SizedBox(height: 20),
            
            // Exercise count and quick actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedBodyPart != null 
                                    ? '${_selectedBodyPart!.toUpperCase()} EXERCISES'
                                    : 'ALL EXERCISES',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: const Color(0xFFFFB74D),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_filteredExercises.length} exercises available',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showBodySilhouette = false;
                            });
                          },
                          icon: const Icon(Icons.list, size: 16),
                          label: const Text('LIST'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12, 
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    if (_selectedBodyPart != null) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedBodyPart = null;
                              _showBodySilhouette = false;
                            });
                            _loadExercisesByBodyPart(null);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Color(0xFF2A2A2A)),
                          ),
                          child: const Text('CLEAR SELECTION'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyPartFilters() {
    if (_bodyParts.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _bodyParts.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildBodyPartChip('All', _selectedBodyPart == null);
          }
          
          final bodyPart = _bodyParts[index - 1];
          final isSelected = _selectedBodyPart == bodyPart;
          return _buildBodyPartChip(bodyPart, isSelected);
        },
      ),
    );
  }

  Widget _buildBodyPartChip(String bodyPart, bool isSelected) {
    return GestureDetector(
      onTap: () => _loadExercisesByBodyPart(bodyPart == 'All' ? null : bodyPart),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFB74D) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          bodyPart.split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' '),
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB74D)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading exercises...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_filteredExercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No exercises found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white54,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredExercises.length,
      itemBuilder: (context, index) => _buildExerciseCard(_filteredExercises[index]),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    final isSelected = _selectedExerciseIds.contains(exercise.exerciseId);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _toggleExerciseSelection(exercise.exerciseId),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: const Color(0xFFFFB74D), width: 2)
                : null,
          ),
          child: Row(
            children: [
              // Selection checkbox
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected 
                      ? const Color(0xFFFFB74D) 
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFFFFB74D)
                        : Colors.white54,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.black,
                      )
                    : null,
              ),
              
              const SizedBox(width: 16),
              
              // Exercise info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          exercise.primaryEquipment,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: exercise.bodyParts.map((bodyPart) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          bodyPart,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFFFB74D),
                            fontSize: 10,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}