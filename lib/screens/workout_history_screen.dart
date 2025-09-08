import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../services/workout_repository.dart';
import '../services/database_helper.dart';
import 'workout_logging_screen.dart';

/// Workout history screen displaying past workouts and statistics
/// Allows users to view completed workouts, track progress, and access workout details
class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  final WorkoutRepository _workoutRepository = WorkoutRepository();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  // State
  List<Workout> _workouts = [];
  WorkoutStats? _stats;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  
  // Pagination
  int _currentPage = 0;
  static const int _pageSize = 10;
  bool _hasMoreWorkouts = true;
  
  // Filters
  WorkoutStatus? _selectedStatus;
  String? _selectedBodyPart;
  DateTimeRange? _selectedDateRange;
  
  // Controllers
  final ScrollController _scrollController = ScrollController();
  
  // Filter options
  final List<WorkoutStatus> _statusOptions = [
    WorkoutStatus.completed,
    WorkoutStatus.inProgress,
    WorkoutStatus.planned,
    WorkoutStatus.cancelled,
  ];
  
  final List<String> _bodyPartOptions = [
    'chest', 'back', 'shoulders', 'arms', 'upper legs', 'lower legs', 'waist', 'cardio'
  ];

  @override
  void initState() {
    super.initState();
    _loadWorkoutHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Don't close the database connection - it's shared across the app
    // _workoutRepository.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreWorkouts();
    }
  }

  Future<void> _loadWorkoutHistory() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _workouts.clear();
    });
    
    try {
      // Get mock user
      final userId = await _dbHelper.createMockUser();
      
      // Load initial workouts and stats
      final workouts = await _workoutRepository.getWorkouts(
        userId: userId,
        status: _selectedStatus,
        limit: _pageSize,
        offset: 0,
      );
      
      final stats = await _workoutRepository.getWorkoutStats(userId);
      
      if (mounted) {
        setState(() {
          _workouts = workouts;
          _stats = stats;
          _isLoading = false;
          _hasMoreWorkouts = workouts.length == _pageSize;
        });
      }
      
    } catch (e) {
      print('Error loading workout history: $e');
      
      // If database connection issue, try to retry once
      if (e.toString().contains('database_closed')) {
        print('Database connection closed, attempting retry...');
        try {
          // Wait a moment and retry
          await Future.delayed(const Duration(milliseconds: 500));
          await _loadWorkoutHistoryRetry();
          return;
        } catch (retryError) {
          print('Retry failed: $retryError');
        }
      }
      
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load workout history: $e');
      }
    }
  }

  Future<void> _loadWorkoutHistoryRetry() async {
    // Get mock user
    final userId = await _dbHelper.createMockUser();
    
    // Load initial workouts and stats
    final workouts = await _workoutRepository.getWorkouts(
      userId: userId,
      status: _selectedStatus,
      limit: _pageSize,
      offset: 0,
    );
    
    final stats = await _workoutRepository.getWorkoutStats(userId);
    
    if (mounted) {
      setState(() {
        _workouts = workouts;
        _stats = stats;
        _isLoading = false;
        _hasMoreWorkouts = workouts.length == _pageSize;
      });
    }
  }

  Future<void> _loadMoreWorkouts() async {
    if (_isLoadingMore || !_hasMoreWorkouts || !mounted) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      final userId = await _dbHelper.createMockUser();
      final nextPage = _currentPage + 1;
      
      final moreWorkouts = await _workoutRepository.getWorkouts(
        userId: userId,
        status: _selectedStatus,
        limit: _pageSize,
        offset: nextPage * _pageSize,
      );
      
      if (mounted) {
        setState(() {
          _workouts.addAll(moreWorkouts);
          _currentPage = nextPage;
          _isLoadingMore = false;
          _hasMoreWorkouts = moreWorkouts.length == _pageSize;
        });
      }
      
    } catch (e) {
      print('Error loading more workouts: $e');
      
      // If database connection issue, try to retry once
      if (e.toString().contains('database_closed')) {
        print('Database connection closed for pagination, attempting retry...');
        try {
          await Future.delayed(const Duration(milliseconds: 500));
          // Retry the same operation
          final userId = await _dbHelper.createMockUser();
          final nextPage = _currentPage + 1;
          
          final moreWorkouts = await _workoutRepository.getWorkouts(
            userId: userId,
            status: _selectedStatus,
            limit: _pageSize,
            offset: nextPage * _pageSize,
          );
          
          if (mounted) {
            setState(() {
              _workouts.addAll(moreWorkouts);
              _currentPage = nextPage;
              _isLoadingMore = false;
              _hasMoreWorkouts = moreWorkouts.length == _pageSize;
            });
          }
          return;
        } catch (retryError) {
          print('Pagination retry failed: $retryError');
        }
      }
      
      if (mounted) {
        setState(() => _isLoadingMore = false);
        _showError('Failed to load more workouts: $e');
      }
    }
  }

  Future<void> _applyFilters() async {
    await _loadWorkoutHistory();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFFFFB74D),
              surface: const Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      await _applyFilters();
    }
  }

  Future<void> _clearFilters() async {
    setState(() {
      _selectedStatus = null;
      _selectedBodyPart = null;
      _selectedDateRange = null;
    });
    await _loadWorkoutHistory();
  }

  void _navigateToWorkout(Workout workout) {
    if (workout.status == WorkoutStatus.planned || workout.status == WorkoutStatus.inProgress) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WorkoutLoggingScreen(workoutId: workout.workoutId),
        ),
      ).then((_) => _loadWorkoutHistory()); // Refresh after returning
    } else {
      _showWorkoutDetails(workout);
    }
  }

  void _showWorkoutDetails(Workout workout) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _buildWorkoutDetailsSheet(workout, scrollController),
        ),
      ),
    );
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

  /// Show appropriate delete confirmation based on workout status
  Future<bool?> _showDeleteConfirmation(Workout workout) async {
    if (workout.status == WorkoutStatus.inProgress) {
      return await _showInProgressDeleteConfirmation(workout);
    } else {
      return await _showCompletedDeleteConfirmation(workout);
    }
  }

  /// Show simple confirmation for in-progress workouts
  Future<bool?> _showInProgressDeleteConfirmation(Workout workout) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Delete Incomplete Workout',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to delete "${workout.name}"? This incomplete workout will be permanently removed.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show two-step confirmation for completed workouts
  Future<bool?> _showCompletedDeleteConfirmation(Workout workout) async {
    // First dialog - general warning
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Delete Completed Workout',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Delete "${workout.name}"? This will affect your progress statistics and cannot be undone.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Continue',
                style: TextStyle(color: Color(0xFFFFB74D)),
              ),
            ),
          ],
        );
      },
    );

    if (firstConfirm != true) return false;

    // Second dialog - detailed impact warning
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Final Confirmation',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will permanently remove:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                '• ${workout.totalVolume.toStringAsFixed(0)} kg from your total volume',
                style: const TextStyle(color: Color(0xFFFFB74D)),
              ),
              Text(
                '• ${workout.exercises.length} exercise${workout.exercises.length == 1 ? '' : 's'} from your history',
                style: const TextStyle(color: Color(0xFFFFB74D)),
              ),
              Text(
                '• ${workout.actualDuration.inMinutes} minute${workout.actualDuration.inMinutes == 1 ? '' : 's'} of training time',
                style: const TextStyle(color: Color(0xFFFFB74D)),
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you absolutely sure?',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Keep Workout',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete Forever',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Delete workout and refresh the list
  Future<void> _deleteWorkout(Workout workout) async {
    try {
      await _workoutRepository.deleteWorkout(workout.workoutId);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${workout.name} deleted successfully'),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
      // Refresh the workout list and statistics
      await _loadWorkoutHistory();
      
    } catch (e) {
      debugPrint('Error deleting workout: $e');
      _showError('Failed to delete workout. Please try again.');
    }
  }

  /// Build status-aware menu items for workout cards
  List<PopupMenuEntry<String>> _buildWorkoutMenuItems(Workout workout) {
    final List<PopupMenuEntry<String>> items = [];
    
    // Delete option (always available)
    items.add(
      PopupMenuItem<String>(
        value: 'delete',
        child: Row(
          children: [
            const Icon(
              Icons.delete,
              color: Colors.red,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              workout.status == WorkoutStatus.inProgress 
                  ? 'Clean up workout' 
                  : 'Delete workout',
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
    
    // Add divider if more items will be added in future
    // items.add(const PopupMenuDivider());
    
    // Future menu items can be added here:
    // - Edit workout (for in-progress)
    // - Duplicate workout (for completed)
    // - Share workout
    // - Export workout data
    
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Workout History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: Icon(
              _hasActiveFilters() ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _hasActiveFilters() ? const Color(0xFFFFB74D) : Colors.white,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFB74D)),
            )
          : RefreshIndicator(
              onRefresh: _loadWorkoutHistory,
              color: const Color(0xFFFFB74D),
              backgroundColor: const Color(0xFF1A1A1A),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Statistics Section
                  if (_stats != null) ...[
                    SliverToBoxAdapter(
                      child: _buildStatsSection(),
                    ),
                  ],
                  
                  // Active Filters
                  if (_hasActiveFilters()) ...[
                    SliverToBoxAdapter(
                      child: _buildActiveFilters(),
                    ),
                  ],
                  
                  // Workouts List
                  _workouts.isEmpty
                      ? SliverFillRemaining(
                          child: _buildEmptyState(),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index < _workouts.length) {
                                return _buildWorkoutTile(_workouts[index]);
                              } else if (_isLoadingMore) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFFFB74D),
                                    ),
                                  ),
                                );
                              }
                              return null;
                            },
                            childCount: _workouts.length + (_isLoadingMore ? 1 : 0),
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights, color: Color(0xFFFFB74D), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Your Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Workouts',
                  '${_stats!.totalWorkouts}',
                  Icons.fitness_center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Completed',
                  '${_stats!.completedWorkouts}',
                  Icons.check_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Volume',
                  _stats!.formattedTotalVolume,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Avg Duration',
                  _stats!.formattedAvgDuration,
                  Icons.timer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFFFB74D), size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Filters:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text(
                  'Clear All',
                  style: TextStyle(color: Color(0xFFFFB74D)),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (_selectedStatus != null)
                _buildFilterChip('Status: ${_selectedStatus!.name}'),
              if (_selectedBodyPart != null)
                _buildFilterChip('Body Part: $_selectedBodyPart'),
              if (_selectedDateRange != null)
                _buildFilterChip(
                  'Date: ${_selectedDateRange!.start.month}/${_selectedDateRange!.start.day} - ${_selectedDateRange!.end.month}/${_selectedDateRange!.end.day}',
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB74D).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFFFB74D),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _hasActiveFilters() ? Icons.search_off : Icons.fitness_center_outlined,
            size: 64,
            color: Colors.white30,
          ),
          const SizedBox(height: 16),
          Text(
            _hasActiveFilters() ? 'No workouts match your filters' : 'No workouts yet',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasActiveFilters()
                ? 'Try adjusting your filter settings'
                : 'Start your fitness journey by creating your first workout!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (!_hasActiveFilters()) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.add),
              label: const Text('Create Workout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB74D),
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkoutTile(Workout workout) {
    final statusColor = _getStatusColor(workout.status);
    final statusIcon = _getStatusIcon(workout.status);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Dismissible(
        key: Key(workout.workoutId),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
            size: 28,
          ),
        ),
        confirmDismiss: (direction) async {
          return await _showDeleteConfirmation(workout);
        },
        onDismissed: (direction) {
          _deleteWorkout(workout);
        },
        child: Card(
        color: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: workout.status == WorkoutStatus.inProgress
                ? const Color(0xFFFFB74D)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () => _navigateToWorkout(workout),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        workout.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor, width: 1),
                      ),
                      child: Text(
                        workout.status.name.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Colors.white70,
                        size: 20,
                      ),
                      color: const Color(0xFF1A1A1A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF2A2A2A)),
                      ),
                      onSelected: (value) async {
                        if (value == 'delete') {
                          final confirmed = await _showDeleteConfirmation(workout);
                          if (confirmed == true) {
                            _deleteWorkout(workout);
                          }
                        }
                      },
                      itemBuilder: (context) => _buildWorkoutMenuItems(workout),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Body Parts
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: workout.targetBodyParts.map((bodyPart) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        bodyPart,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                
                // Cleanup hint for in-progress workouts
                if (workout.status == WorkoutStatus.inProgress)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cleaning_services,
                          size: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Swipe left or tap ⋮ to clean up',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Statistics
                Row(
                  children: [
                    _buildWorkoutStat(
                      Icons.timer,
                      workout.status == WorkoutStatus.completed
                          ? '${workout.actualDuration.inMinutes}min'
                          : '${workout.plannedDurationMinutes}min',
                    ),
                    const SizedBox(width: 16),
                    _buildWorkoutStat(
                      Icons.fitness_center,
                      '${workout.exercises.length} exercises',
                    ),
                    if (workout.totalVolume > 0) ...[
                      const SizedBox(width: 16),
                      _buildWorkoutStat(
                        Icons.trending_up,
                        '${workout.totalVolume.toStringAsFixed(0)} kg',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                
                // Date
                Text(
                  _formatDate(workout.createdAt),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildWorkoutStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFFFB74D), size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutDetailsSheet(Workout workout, ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header
          Row(
            children: [
              Icon(
                _getStatusIcon(workout.status),
                color: _getStatusColor(workout.status),
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  workout.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Statistics
          if (workout.status == WorkoutStatus.completed) ...[
            Row(
              children: [
                Expanded(
                  child: _buildDetailStat(
                    'Duration',
                    '${workout.actualDuration.inMinutes}:${(workout.actualDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                    Icons.timer,
                  ),
                ),
                Expanded(
                  child: _buildDetailStat(
                    'Exercises',
                    '${workout.exercises.length}',
                    Icons.fitness_center,
                  ),
                ),
                Expanded(
                  child: _buildDetailStat(
                    'Total Volume',
                    '${workout.totalVolume.toStringAsFixed(0)} kg',
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          
          // Exercises
          if (workout.exercises.isNotEmpty) ...[
            const Text(
              'Exercises',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            ...workout.exercises.map((exercise) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(8),
                ),
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
                      '${exercise.sets.length} sets • ${exercise.totalVolume.toStringAsFixed(0)} kg total',
                      style: const TextStyle(
                        color: Color(0xFFFFB74D),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
          
          const SizedBox(height: 20),
          Text(
            'Created ${_formatDate(workout.createdAt)}',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          
          // Delete Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the modal first
                final confirmed = await _showDeleteConfirmation(workout);
                if (confirmed == true) {
                  _deleteWorkout(workout);
                }
              },
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text(
                'Delete Workout',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildDetailStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFFB74D), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Workouts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Status Filter
                const Text(
                  'Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterOption(
                      'All',
                      _selectedStatus == null,
                      () => setModalState(() => _selectedStatus = null),
                    ),
                    ..._statusOptions.map((status) {
                      return _buildFilterOption(
                        status.name,
                        _selectedStatus == status,
                        () => setModalState(() => _selectedStatus = status),
                      );
                    }).toList(),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Date Range Filter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Date Range',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _selectDateRange();
                      },
                      child: Text(
                        _selectedDateRange == null
                            ? 'Select Range'
                            : '${_selectedDateRange!.start.month}/${_selectedDateRange!.start.day} - ${_selectedDateRange!.end.month}/${_selectedDateRange!.end.day}',
                        style: const TextStyle(color: Color(0xFFFFB74D)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _clearFilters();
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFFB74D)),
                        ),
                        child: const Text(
                          'Clear',
                          style: TextStyle(color: Color(0xFFFFB74D)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _applyFilters();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB74D),
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFB74D) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFB74D) : const Color(0xFF2A2A2A),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedStatus != null || 
           _selectedBodyPart != null || 
           _selectedDateRange != null;
  }

  Color _getStatusColor(WorkoutStatus status) {
    switch (status) {
      case WorkoutStatus.completed:
        return Colors.green;
      case WorkoutStatus.inProgress:
        return const Color(0xFFFFB74D);
      case WorkoutStatus.planned:
        return Colors.blue;
      case WorkoutStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(WorkoutStatus status) {
    switch (status) {
      case WorkoutStatus.completed:
        return Icons.check_circle;
      case WorkoutStatus.inProgress:
        return Icons.play_circle;
      case WorkoutStatus.planned:
        return Icons.schedule;
      case WorkoutStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      return '${weekdays[date.weekday % 7]} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}