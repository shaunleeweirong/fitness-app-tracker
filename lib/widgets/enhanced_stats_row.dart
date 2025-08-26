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
              const Color(0xFF81C784),
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isImproving 
                        ? Colors.green.withOpacity(0.2)
                        : const Color(0xFFFFB74D).withOpacity(0.2), // Motivational orange instead of red
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isImproving ? Icons.trending_up : Icons.psychology, // Growth mindset icon instead of down arrow
                        size: 10,
                        color: isImproving ? Colors.green : const Color(0xFFFFB74D), // Motivational orange
                      ),
                      const SizedBox(width: 2),
                      Text(
                        isImproving 
                            ? '${changePercentage.abs().toStringAsFixed(0)}%'
                            : 'Grow!', // Shorter growth-focused messaging
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: isImproving ? Colors.green : const Color(0xFFFFB74D), // Motivational orange
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
                      ? '(+${(int.tryParse(currentValue) ?? 0) - (int.tryParse(previousValue) ?? 0)})'
                      : '(opportunity zone)', // Growth-focused language
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isImproving ? Colors.green : const Color(0xFFFFB74D), // Motivational orange
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
                'lbs',
                const Color(0xFF7E57C2),
              ),
              _buildVolumeStat(
                context,
                'This Week',
                '${(weeklyComparison.currentValue / 1000).toStringAsFixed(1)}K',
                weeklyComparison.changeIndicator,
                weeklyComparison.isImproving ? Colors.green : Colors.red,
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