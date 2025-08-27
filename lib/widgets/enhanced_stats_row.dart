import 'package:flutter/material.dart';
import '../models/user_progress.dart';

class EnhancedStatsRow extends StatelessWidget {
  final UserProgress userProgress;

  const EnhancedStatsRow({
    super.key,
    required this.userProgress,
  });

  @override
  Widget build(BuildContext context) {
    final weeklyComparison = userProgress.getWeeklyComparison();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildEnhancedStatCard(
              context,
              'Workouts',
              'This Week',
              weeklyComparison.currentWorkouts.toString(),
              weeklyComparison.previousWorkouts.toString(),
              weeklyComparison.workoutChangePercentage,
              weeklyComparison.isWorkoutCountImproving,
              Icons.fitness_center,
              const Color(0xFFFFB74D),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildEnhancedStatCard(
              context,
              'Total Time',
              'This Week',
              _formatWeeklyTime(weeklyComparison),
              _formatDuration(_getPreviousWeekTime(weeklyComparison)),
              _calculateTimeChangePercentage(weeklyComparison),
              _isTimeImproving(weeklyComparison),
              Icons.timer,
              const Color(0xFFFFB74D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatCard(
    BuildContext context,
    String title,
    String subtitle,
    String currentValue,
    String previousValue,
    double changePercentage,
    bool isImproving,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2A2A2A),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and trend indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              if (changePercentage != 0) 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Match Weekly Progress
                  decoration: BoxDecoration(
                    color: isImproving 
                        ? const Color(0xFFFFB74D).withOpacity(0.2) // Orange to match app theme
                        : Colors.red.withOpacity(0.2), // Match Weekly Progress red background
                    borderRadius: BorderRadius.circular(8), // Match Weekly Progress
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isImproving ? Icons.arrow_upward : Icons.arrow_downward, // Match Weekly Progress icons
                        size: 12, // Match Weekly Progress size
                        color: isImproving ? const Color(0xFFFFB74D) : Colors.red, // Orange for improvement, red for decline
                      ),
                      const SizedBox(width: 4), // Match Weekly Progress spacing
                      Text(
                        '${changePercentage.abs().toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 11, // Match Weekly Progress font size
                          fontWeight: FontWeight.w600, // Match Weekly Progress font weight
                          color: isImproving ? const Color(0xFFFFB74D) : Colors.red, // Orange for improvement, red for decline
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Current value with comparison
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentValue,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: color,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
              if (previousValue != '0' && previousValue.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  isImproving 
                      ? '(+${_calculateDifference(currentValue, previousValue)})'
                      : '(${_calculateDifference(currentValue, previousValue)})',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isImproving ? const Color(0xFFFFB74D) : Colors.white70, // Orange to match app theme
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 6),
          
          // Labels
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white60,
              height: 1.2,
            ),
          ),
          
          // Previous period comparison
          if (previousValue != '0' && previousValue.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Last week: $previousValue',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.4),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '0m';
    }
  }

  Duration _getPreviousWeekTime(ProgressComparison comparison) {
    // Calculate previous week time based on the comparison data
    if (comparison.previousWorkouts == 0) return Duration.zero;
    
    // Estimate average time per workout and calculate previous week total
    final avgTimePerWorkout = comparison.currentWorkouts > 0 
        ? (45 * comparison.currentWorkouts) // Assume 45 min average per workout
        : 45;
    final estimatedPreviousTime = (avgTimePerWorkout * comparison.previousWorkouts).round();
    
    return Duration(minutes: estimatedPreviousTime);
  }

  String _formatWeeklyTime(ProgressComparison comparison) {
    // Calculate this week's total time based on workouts
    final thisWeekMinutes = comparison.currentWorkouts * 45; // Assume 45 min per workout
    final duration = Duration(minutes: thisWeekMinutes);
    return _formatDuration(duration);
  }

  String _calculateDifference(String currentValue, String previousValue) {
    // Handle volume values (with K suffix)
    if (currentValue.contains('K') && previousValue.contains('K')) {
      final current = double.tryParse(currentValue.replaceAll('K', '')) ?? 0;
      final previous = double.tryParse(previousValue.replaceAll('K', '')) ?? 0;
      final diff = current - previous;
      return '${diff.toStringAsFixed(1)}K';
    }
    
    // Handle integer values (workouts, time)
    final current = int.tryParse(currentValue.split(' ')[0]) ?? 0; // Get number part only
    final previous = int.tryParse(previousValue.split(' ')[0]) ?? 0;
    final diff = current - previous;
    return diff.toString();
  }

  double _calculateTimeChangePercentage(ProgressComparison comparison) {
    final currentWeekMinutes = comparison.currentWorkouts * 45; // This week's estimated time
    final previousTime = _getPreviousWeekTime(comparison);
    
    if (previousTime.inMinutes == 0) {
      return currentWeekMinutes > 0 ? 100.0 : 0.0;
    }
    
    return ((currentWeekMinutes - previousTime.inMinutes) / previousTime.inMinutes) * 100;
  }

  bool _isTimeImproving(ProgressComparison comparison) {
    final currentWeekMinutes = comparison.currentWorkouts * 45;
    final previousTime = _getPreviousWeekTime(comparison);
    
    return currentWeekMinutes > previousTime.inMinutes;
  }
}

// Volume Progress Card for detailed volume tracking
class VolumeProgressCard extends StatelessWidget {
  final UserProgress userProgress;

  const VolumeProgressCard({
    super.key,
    required this.userProgress,
  });

  @override
  Widget build(BuildContext context) {
    final weeklyComparison = userProgress.getWeeklyComparison();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7E57C2).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.show_chart,
                  color: Color(0xFF7E57C2),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Volume Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Volume stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVolumeStat(
                context,
                'Total Volume',
                '${(userProgress.currentStats.totalVolumeLifted / 1000).toStringAsFixed(1)}K',
                'kg',
                const Color(0xFF7E57C2),
              ),
              _buildVolumeStat(
                context,
                'This Week',
                '${(weeklyComparison.currentValue / 1000).toStringAsFixed(1)}K',
                weeklyComparison.changeIndicator,
                weeklyComparison.isImproving ? const Color(0xFFFFB74D) : Colors.red,
              ),
              _buildVolumeStat(
                context,
                'Personal Best',
                _getPersonalBest(),
                'single workout',
                const Color(0xFFFFB74D),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeStat(
    BuildContext context,
    String label,
    String value,
    String suffix,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white70,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          suffix,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withOpacity(0.4),
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getPersonalBest() {
    // Find the highest single workout volume from daily progress
    double maxVolume = 0;
    for (final day in userProgress.dailyProgress) {
      if (day.workoutCount == 1 && day.totalVolume > maxVolume) {
        maxVolume = day.totalVolume;
      }
    }
    
    if (maxVolume == 0) return '0';
    return '${(maxVolume / 1000).toStringAsFixed(1)}K';
  }
}