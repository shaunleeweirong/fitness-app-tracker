import 'package:flutter/material.dart';
import 'models/exercise.dart';
import 'models/workout.dart';
import 'models/user_progress.dart';
import 'models/progress_dashboard_data.dart';
import 'services/exercise_service.dart';
import 'services/mock_progress_service.dart';
import 'services/workout_recommendation_service.dart';
import 'services/progress_service.dart';
import 'screens/exercise_detail_screen.dart';
import 'screens/workout_setup_screen.dart';
import 'screens/workout_logging_screen.dart';
import 'screens/workout_history_screen.dart';
import 'screens/workout_plans_screen.dart';
import 'widgets/body_silhouette.dart';
import 'widgets/progress_overview_widget.dart';
import 'widgets/enhanced_stats_row.dart';
import 'widgets/personal_records_widget.dart';

void main() {
  runApp(const FitnessTrackerApp());
}

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

class FitnessTrackerApp extends StatelessWidget {
  const FitnessTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Tracker',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFB74D), // Warmer orange/yellow accent
          brightness: Brightness.dark,
          surface: const Color(0xFF1A1A1A), // Rich dark surface
          surfaceContainerHighest: const Color(0xFF2A2A2A), // Elevated surface
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        // Large tap targets for workout environment
        materialTapTargetSize: MaterialTapTargetSize.padded,
        // Enhanced text styles for gym readability
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            height: 1.2,
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            height: 1.2,
          ),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.0,
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            letterSpacing: 0.15,
            height: 1.4,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            letterSpacing: 0.25,
            height: 1.4,
          ),
          labelLarge: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        // Enhanced card theme
        cardTheme: const CardThemeData(
          elevation: 4,
          shadowColor: Colors.black54,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          color: Color(0xFF1A1A1A),
        ),
        // Enhanced AppBar theme
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Color(0xFF0A0A0A),
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: Colors.white,
          ),
        ),
        // Enhanced button themes
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFB74D),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Enhanced chip theme
        chipTheme: const ChipThemeData(
          backgroundColor: Color(0xFF2A2A2A),
          labelStyle: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
      ),
      home: const MainNavigationScreen(),
      routes: {
        '/workout-logging': (context) {
          final workoutId = ModalRoute.of(context)?.settings.arguments as String?;
          if (workoutId == null) {
            return const Scaffold(
              body: Center(child: Text('Error: No workout ID provided')),
            );
          }
          return WorkoutLoggingScreen(workoutId: workoutId);
        },
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const WorkoutHistoryScreen(),
    const WorkoutPlansScreen(),
    const ExerciseLibraryScreen(),
    const ProgressScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void onItemTapped(int index) => _onItemTapped(index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A1A),
              Color(0xFF0A0A0A),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFFFFB74D),
          unselectedItemColor: Colors.white.withValues(alpha: 0.6),
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_outlined),
              activeIcon: Icon(Icons.fitness_center),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_outline),
              activeIcon: Icon(Icons.bookmark),
              label: 'Plans',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books_outlined),
              activeIcon: Icon(Icons.library_books),
              label: 'Exercises',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up_outlined),
              activeIcon: Icon(Icons.trending_up),
              label: 'Progress',
            ),
          ],
        ),
      ),
    );
  }
}

// Dashboard Screen
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final WorkoutRecommendationService _recommendationService = WorkoutRecommendationService();
  WorkoutTemplate? _recommendedWorkout;
  bool _isLoadingRecommendation = true;
  String _recommendationReason = '';
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _loadRecommendation();
  }

  @override
  void dispose() {
    // Don't close recommendation service - it uses shared database connection
    // _recommendationService.close();
    super.dispose();
  }

  Future<void> _loadRecommendation() async {
    if (mounted) {
      setState(() {
        _isLoadingRecommendation = true;
      });
    }
    
    try {
      print('📱 Loading workout recommendation (attempt ${_retryCount + 1}/$_maxRetries)...');
      final recommendation = await _recommendationService.getTodaysRecommendation();
      
      if (mounted) {
        // Try to get cached reason first, then generate if not available
        final cachedReason = await _recommendationService.getCachedRecommendationReason();
        final reason = recommendation != null 
            ? (cachedReason ?? _recommendationService.getRecommendationReason(recommendation))
            : '';
        
        setState(() {
          _recommendedWorkout = recommendation;
          _recommendationReason = reason;
          _isLoadingRecommendation = false;
          _retryCount = 0; // Reset retry count on success
        });
        
        print('✅ Recommendation loaded: ${recommendation?.name ?? 'No recommendation'}');
      }
    } catch (e) {
      print('❌ Failed to load recommendation: $e');
      
      if (mounted) {
        if (_retryCount < _maxRetries - 1) {
          _retryCount++;
          print('🔄 Retrying recommendation load in 2 seconds...');
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            await _loadRecommendation();
            return;
          }
        }
        
        setState(() {
          _isLoadingRecommendation = false;
        });
        
        // Try fallback recommendation as last resort
        _loadFallbackRecommendation();
      }
    }
  }

  Future<void> _loadFallbackRecommendation() async {
    try {
      print('🔄 Attempting fallback recommendation...');
      final fallback = await _recommendationService.getFallbackRecommendation();
      
      if (mounted && fallback != null) {
        setState(() {
          _recommendedWorkout = fallback;
          _recommendationReason = _recommendationService.getRecommendationReason(fallback);
        });
        print('✅ Fallback recommendation loaded: ${fallback.name}');
      }
    } catch (e) {
      print('❌ Fallback recommendation also failed: $e');
    }
  }

  Future<void> _refreshRecommendation() async {
    print('🔄 Manual refresh triggered');
    _retryCount = 0;
    
    // Clear cache and force fresh load for debugging
    final freshRecommendation = await _recommendationService.getDebugFreshRecommendation();
    
    if (mounted) {
      final reason = freshRecommendation != null 
          ? _recommendationService.getRecommendationReason(freshRecommendation)
          : '';
      
      setState(() {
        _recommendedWorkout = freshRecommendation;
        _recommendationReason = reason;
        _isLoadingRecommendation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get mock progress data
    final userProgress = MockProgressService.getMockProgress();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A0A),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshRecommendation,
            color: const Color(0xFFFFB74D),
            backgroundColor: const Color(0xFF1A1A1A),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(), // Enables pull-to-refresh even when content doesn't scroll
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Home',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Featured Workout Card
                _buildWorkoutRecommendationCard(context),
                
                const SizedBox(height: 24),
                
                // NEW: Visual Progress Section
                ProgressOverviewWidget(userProgress: userProgress),
                
                // Enhanced: Stats with Trends
                EnhancedStatsRow(userProgress: userProgress),
                
                // NEW: Achievements & Streaks
                AchievementSummaryCard(userProgress: userProgress),
                
                const SizedBox(height: 32),
                
                // Quick Actions Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionCard(
                              context,
                              'Create Workout',
                              Icons.add_circle_outline,
                              () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const WorkoutSetupScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickActionCard(
                              context,
                              'View History',
                              Icons.history,
                              () {
                                // Navigate to workout history (tab index 1)
                                final mainState = context.findAncestorStateOfType<_MainNavigationScreenState>();
                                mainState?.onItemTapped(1);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Recent Activity
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Activity',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF2A2A2A),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.fitness_center_outlined,
                              size: 48,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No workouts yet',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start your fitness journey today!\nYour first workout will appear here.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white60,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 100), // Bottom padding for navigation
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMetadataChip(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutRecommendationCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A2A2A),
            Color(0xFF1A1A1A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isLoadingRecommendation
          ? _buildLoadingWorkoutCard(context)
          : _buildRecommendationContent(context),
    );
  }

  Widget _buildLoadingWorkoutCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Loading badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB74D),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'LOADING RECOMMENDATION...',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Loading shimmer effect
        Container(
          height: 32,
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 12),
        
        // Loading chips
        Row(
          children: [
            Container(
              height: 24,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 24,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Loading buttons
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecommendationContent(BuildContext context) {
    if (_recommendedWorkout == null) {
      return _buildFallbackContent(context);
    }

    final workout = _recommendedWorkout!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge and title section
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB74D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'TODAY\'S RECOMMENDATION',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            Icon(
              workout.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: workout.isFavorite ? Colors.red : Colors.white60,
              size: 20,
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Text(
          workout.name,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            height: 1.2,
          ),
        ),
        
        const SizedBox(height: 8),
        
        if (_recommendationReason.isNotEmpty) ...[
          Text(
            _recommendationReason,
            style: const TextStyle(
              color: Color(0xFFFFB74D),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Workout metadata
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildMetadataChip(context, '${workout.estimatedDurationMinutes ?? 45} min', Icons.timer_outlined),
            _buildMetadataChip(context, workout.targetBodyParts.isNotEmpty ? workout.targetBodyParts.first.capitalize() : 'Mixed', Icons.fitness_center),
            _buildMetadataChip(context, workout.difficultyName, Icons.trending_up),
            _buildMetadataChip(context, '${workout.exercises.length} exercises', Icons.list),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Action buttons row
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => WorkoutSetupScreen(template: workout),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow, size: 20),
                label: const Text('START THIS WORKOUT'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const WorkoutPlansScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.bookmark, size: 20),
                label: const Text('CHOOSE DIFFERENT WORKOUT'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFB74D)),
                  foregroundColor: const Color(0xFFFFB74D),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFallbackContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB74D),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'READY TO WORKOUT?',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        Text(
          'Create Your Workout',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            height: 1.2,
          ),
        ),
        
        const SizedBox(height: 8),
        
        const Text(
          'Start building your fitness journey with a custom workout',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Refresh hint row
        Row(
          children: [
            Icon(
              Icons.refresh,
              size: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 6),
            Text(
              'Pull down to refresh for workout recommendations',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _refreshRecommendation,
              icon: Icon(
                Icons.refresh,
                size: 16,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Action buttons row
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const WorkoutSetupScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text('CREATE WORKOUT'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const WorkoutPlansScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.bookmark, size: 20),
                label: const Text('BROWSE PLANS'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFB74D)),
                  foregroundColor: const Color(0xFFFFB74D),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildQuickActionCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF2A2A2A),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFFFB74D), size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Exercise Library Screen
class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Exercise> _exercises = [];
  List<String> _bodyParts = [];
  String? _selectedBodyPart;
  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = '';
  bool _showBodySilhouette = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _exerciseService.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text != _searchQuery) {
      setState(() {
        _searchQuery = _searchController.text;
        _isSearching = _searchQuery.isNotEmpty;
      });
      _searchExercises(_searchQuery);
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load body parts and initial exercises in parallel
      final futures = await Future.wait([
        _exerciseService.getBodyParts(),
        _exerciseService.getExercises(limit: 20),
      ]);
      
      setState(() {
        _bodyParts = futures[0] as List<String>;
        _exercises = futures[1] as List<Exercise>;
        _isLoading = false;
      });
      
      // Preload popular exercises in background
      _exerciseService.preloadPopularExercises();
      
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load exercises');
    }
  }

  Future<void> _loadExercisesByBodyPart(String? bodyPart) async {
    setState(() {
      _selectedBodyPart = bodyPart;
      _isLoading = true;
    });

    try {
      final exercises = await _exerciseService.getExercises(
        bodyPart: bodyPart,
        limit: 50,
      );
      
      setState(() {
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load exercises for $bodyPart');
    }
  }

  Future<void> _searchExercises(String query) async {
    if (query.isEmpty) {
      _loadExercisesByBodyPart(_selectedBodyPart);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final exercises = await _exerciseService.searchExercises(query, limit: 30);
      setState(() {
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Search failed');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () => _loadInitialData(),
        ),
      ),
    );
    
    // Also debug print to console for debugging
    debugPrint('🚨 ERROR: $message');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              if (_showBodySilhouette) ...[
                _buildBodySilhouetteView(),
              ] else ...[
                _buildBodyPartFilters(),
                Expanded(child: _buildExerciseList()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exercise Library',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Row(
                children: [
                  // Body silhouette toggle
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showBodySilhouette = !_showBodySilhouette;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _showBodySilhouette 
                          ? const Color(0xFFFFB74D) 
                          : const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.accessibility_new, 
                        size: 24,
                        color: _showBodySilhouette 
                          ? Colors.black 
                          : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.tune, size: 24),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Create Workout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const WorkoutSetupScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Create Workout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB74D),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
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
              onBodyPartSelected: (bodyPart) {
                _loadExercisesByBodyPart(bodyPart);
              },
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
                                '${_exercises.length} exercises available',
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
          bodyPart.capitalize(),
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
      return _buildLoadingView();
    }

    if (_exercises.isEmpty) {
      return _buildEmptyView();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _exercises.length,
      itemBuilder: (context, index) => _buildExerciseCard(_exercises[index]),
    );
  }

  Widget _buildLoadingView() {
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

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 64,
            color: Colors.white30,
          ),
          const SizedBox(height: 16),
          Text(
            _isSearching ? 'No exercises found' : 'No exercises available',
            style: const TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            _isSearching ? 'Try a different search term' : 'Pull to refresh',
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  IconData _getEquipmentIcon(String equipment) {
    final equipmentLower = equipment.toLowerCase();
    switch (equipmentLower) {
      case 'barbell':
        return Icons.fitness_center;
      case 'dumbbell':
        return Icons.sports_gymnastics;
      case 'body weight':
      case 'bodyweight':
        return Icons.accessibility_new;
      case 'cable':
        return Icons.linear_scale;
      case 'machine':
        return Icons.precision_manufacturing;
      case 'kettlebell':
        return Icons.sports_kabaddi;
      default:
        return Icons.fitness_center;
    }
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

  Widget _buildExerciseCard(Exercise exercise) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseDetailScreen(exercise: exercise),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Row(
          children: [
            // Exercise Image/GIF with network loading and popular badge
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: exercise.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            exercise.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.fitness_center,
                                color: Color(0xFFFFB74D),
                                size: 28,
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB74D)),
                                ),
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.fitness_center,
                          color: Color(0xFFFFB74D),
                          size: 28,
                        ),
                ),
                // Popular badge overlay
                if (_isPopularExercise(exercise))
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB74D),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Text(
                        'POPULAR',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Exercise Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (exercise.targetMuscles.isNotEmpty)
                    Text(
                      'Primary: ${exercise.targetMuscles.first}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (exercise.secondaryMuscles.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Secondary: ${exercise.secondaryMuscles.take(2).join(", ")}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _getEquipmentIcon(exercise.equipments.isNotEmpty ? exercise.equipments.first : ''),
                        size: 12,
                        color: const Color(0xFFFFB74D),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          exercise.equipments.isNotEmpty ? exercise.equipments.first : 'No equipment',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // View Detail Indicator
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFFFFB74D),
            ),
          ],
        ),
      ),
    );
  }
}


// Progress Screen  
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late ProgressService _progressService;
  ProgressDashboardData? _progressData;
  ProgressLoadingState _loadingState = ProgressLoadingState.idle;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _progressService = ProgressService();
    _loadProgressData();
  }

  @override
  void dispose() {
    _progressService.dispose();
    super.dispose();
  }

  Future<void> _loadProgressData() async {
    setState(() {
      _loadingState = ProgressLoadingState.loading;
      _errorMessage = null;
    });

    final result = await _progressService.getProgressData();
    
    setState(() {
      _loadingState = result.state;
      _progressData = result.data;
      _errorMessage = result.errorMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📈 Progress'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A0A),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_loadingState) {
      case ProgressLoadingState.loading:
        return _buildLoadingView();
      case ProgressLoadingState.error:
        return _buildErrorView();
      case ProgressLoadingState.success:
        return _progressData != null 
            ? _buildProgressDashboard(_progressData!)
            : _buildEmptyState();
      case ProgressLoadingState.idle:
      default:
        return _buildLoadingView();
    }
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB74D)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading your progress...',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Progress',
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProgressData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB74D),
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 64,
              color: Colors.white54,
            ),
            SizedBox(height: 16),
            Text(
              'No Progress Yet',
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Complete your first workout to see your progress!',
              style: TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDashboard(ProgressDashboardData data) {
    return RefreshIndicator(
      onRefresh: _loadProgressData,
      color: const Color(0xFFFFB74D),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lifetime Stats Card
            _buildLifetimeStatsCard(data),
            
            const SizedBox(height: 20),
            
            // Weekly Progress (existing functionality)
            ProgressOverviewWidget(userProgress: MockProgressService.getMockProgress()),
            
            const SizedBox(height: 20),
            
            // Personal Records Section (NEW)
            const PersonalRecordsWidget(),
            
            const SizedBox(height: 20),
            
            // Body Part Progress Visualization (NEW)
            _buildBodyProgressSection(data),
            
            const SizedBox(height: 20),
            
            // Achievements Section
            _buildAchievementsSection(data),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLifetimeStatsCard(ProgressDashboardData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A2A2A),
            Color(0xFF1A1A1A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFB74D).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: Color(0xFFFFB74D),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'LIFETIME TOTALS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFB74D),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.4, // Final adjustment to eliminate remaining 4.7px overflow
            mainAxisSpacing: 12, // Reduced spacing to fit better
            crossAxisSpacing: 12,
            children: [
              _buildStatTile(
                icon: Icons.fitness_center,
                label: 'Workouts',
                value: data.totalWorkouts.toString(),
                color: const Color(0xFF4CAF50),
              ),
              _buildStatTile(
                icon: Icons.schedule,
                label: 'Time',
                value: data.formattedTotalTime,
                color: const Color(0xFF2196F3),
              ),
              _buildStatTile(
                icon: Icons.trending_up,
                label: 'Volume',
                value: data.formattedTotalVolume,
                color: const Color(0xFFFFB74D),
              ),
              _buildStatTile(
                icon: Icons.local_fire_department,
                label: 'Streak',
                value: '${data.currentStreak} days',
                color: const Color(0xFFFF5722),
              ),
              _buildStatTile(
                icon: Icons.emoji_events,
                label: 'Achievements',
                value: data.totalAchievements.toString(),
                color: const Color(0xFF9C27B0),
              ),
              _buildStatTile(
                icon: Icons.data_usage,
                label: 'Sets',
                value: data.totalSets.toString(),
                color: const Color(0xFF607D8B),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 22, // Increased for better visibility
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17, // Increased for better readability
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12, // Improved for better readability
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(ProgressDashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                color: Color(0xFFFFB74D),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Recent Achievements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        data.recentAchievements.isNotEmpty
            ? ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.recentAchievements.length,
                itemBuilder: (context, index) {
                  final achievement = data.recentAchievements[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFB74D).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB74D).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.emoji_events,
                            color: Color(0xFFFFB74D),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                achievement.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                achievement.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '+${achievement.xpReward} XP',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFB74D),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
            : Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 48,
                      color: Colors.white54,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No achievements yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Complete workouts to unlock achievements!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
      ],
    );
  }

  /// Build body part progress visualization with level badges and heat mapping
  Widget _buildBodyProgressSection(ProgressDashboardData data) {
    // Convert BodyPartProgress map to level map for BodySilhouette
    final bodyPartLevels = <String, int>{};
    for (final entry in data.bodyPartProgress.entries) {
      bodyPartLevels[entry.key] = entry.value.level;
    }

    // Debug logging
    print('DEBUG: bodyPartProgress entries: ${data.bodyPartProgress.length}');
    print('DEBUG: bodyPartLevels: $bodyPartLevels');
    
    // Add mock data for testing if no real data exists
    if (bodyPartLevels.isEmpty) {
      bodyPartLevels.addAll({
        'chest': 8,
        'shoulders': 12,
        'upper arms': 6,
        'lower arms': 4,
        'back': 15,
        'waist': 3,
        'upper legs': 10,
        'lower legs': 5,
      });
      print('DEBUG: Added mock body part levels: $bodyPartLevels');
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A2A2A),
            Color(0xFF1A1A1A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFB74D).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Row(
              children: [
                Icon(
                  Icons.accessibility_new,
                color: Color(0xFFFFB74D),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'MUSCLE GROUP PROGRESS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFB74D),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Body silhouette with level badges
          if (bodyPartLevels.isNotEmpty)
            Center(
              child: BodySilhouette(
                selectedBodyPart: null, // No selection for progress view
                onBodyPartSelected: (bodyPart) {
                  // Handle tap to show detailed progress for this body part
                  _showBodyPartDetails(bodyPart, data.bodyPartProgress[bodyPart]);
                },
                showLevelBadges: true,
                bodyPartLevels: bodyPartLevels,
              ),
            )
          else
            // Empty state
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.accessibility_new_outlined,
                    size: 48,
                    color: Colors.white54,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No progress data yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Complete workouts to see muscle group progress!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          // Level legend
          if (bodyPartLevels.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildLevelLegend(),
          ],
        ],
      ),
    );
  }

  /// Build level legend showing color coding
  Widget _buildLevelLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Level Badges',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildLegendItem('1-4', const Color(0xFF4CAF50), 'Beginner'),
              _buildLegendItem('5-9', const Color(0xFF2196F3), 'Intermediate'),
              _buildLegendItem('10-14', const Color(0xFF9C27B0), 'Advanced'),
              _buildLegendItem('15-19', const Color(0xFFE91E63), 'Expert'),
              _buildLegendItem('20+', const Color(0xFFFFD700), 'Master'),
            ],
          ),
        ],
      ),
    );
  }

  /// Build individual legend item
  Widget _buildLegendItem(String levelRange, Color color, String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$levelRange ($title)',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  /// Show detailed progress for a specific body part
  void _showBodyPartDetails(String bodyPart, BodyPartProgress? progress) {
    // Handle mock data case - create temporary progress for demo
    if (progress == null) {
      // Create mock progress data for demonstration
      final mockLevels = {'chest': 8, 'shoulders': 12, 'upper arms': 6, 'lower arms': 4, 'back': 15, 'waist': 3, 'upper legs': 10, 'lower legs': 5};
      final level = mockLevels[bodyPart] ?? 1;
      
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white54,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Body part title
              Text(
                bodyPart.toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFB74D),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Mock progress details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDetailStat('Level', level.toString()),
                  _buildDetailStat('XP', '${level * 1500}'), // Mock XP calculation
                  _buildDetailStat('Progress', '${(level % 10) * 10}%'), // Mock progress
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Close button
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Body part title
            Text(
              bodyPart.toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFB74D),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Progress details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDetailStat('Level', progress.level.toString()),
                _buildDetailStat('XP', progress.xp.toInt().toString()),
                _buildDetailStat('Progress', '${(progress.progressPercentage * 100).toInt()}%'),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Close button
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build detail stat widget
  Widget _buildDetailStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

// Profile Screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person,
              size: 64,
              color: Colors.orange,
            ),
            SizedBox(height: 16),
            Text(
              'Profile & Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Coming in Phase 1B',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}