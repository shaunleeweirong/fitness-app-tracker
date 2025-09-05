import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/user_progress.dart';

class ProgressOverviewWidget extends StatelessWidget {
  final UserProgress userProgress;

  const ProgressOverviewWidget({
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
          // Header with trend indicator
          Row(
            children: [
              const Icon(
                Icons.trending_up,
                color: Color(0xFFFFB74D),
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Weekly Volume Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: weeklyComparison.isImproving 
                      ? const Color(0xFFFFB74D).withOpacity(0.2) // Orange to match app theme
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      weeklyComparison.isImproving ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: weeklyComparison.isImproving ? const Color(0xFFFFB74D) : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${weeklyComparison.volumeChangePercentage.abs().toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: weeklyComparison.isImproving ? const Color(0xFFFFB74D) : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Mini line chart
          SizedBox(
            height: 80,
            child: _buildMiniLineChart(context),
          ),
          
          const SizedBox(height: 12),
          
          // Quick stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickStat(
                context,
                'This Week',
                '${weeklyComparison.currentWorkouts} workouts',
                weeklyComparison.workoutChangeIndicator,
                weeklyComparison.isWorkoutCountImproving,
              ),
              _buildQuickStat(
                context,
                'Volume',
                '${(weeklyComparison.currentValue / 1000).toStringAsFixed(1)}K kg',
                weeklyComparison.changeIndicator,
                weeklyComparison.isImproving,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniLineChart(BuildContext context) {
    final chartData = _getChartData();
    
    if (chartData.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'No data yet',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white54,
            ),
          ),
        ),
      );
    }
    
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            axisNameWidget: Text(
              'Volume (kg)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
            sideTitles: const SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (value, meta) {
                const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                if (value.toInt() >= 0 && value.toInt() < days.length) {
                  return Text(
                    days[value.toInt()],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: chartData,
            color: const Color(0xFFFFB74D),
            barWidth: 2.5,
            isStrokeCapRound: true,
            isCurved: true,
            curveSmoothness: 0.35,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 3,
                color: const Color(0xFFFFB74D),
                strokeColor: const Color(0xFF2A2A2A),
                strokeWidth: 1,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFFB74D).withOpacity(0.3),
                  const Color(0xFFFFB74D).withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
        minX: 0,
        maxX: 6,
        minY: 0,
        backgroundColor: Colors.transparent,
      ),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  List<FlSpot> _getChartData() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    final spots = <FlSpot>[];
    
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final dayProgress = userProgress.dailyProgress.where((day) =>
        day.date.year == date.year &&
        day.date.month == date.month &&
        day.date.day == date.day
      ).firstOrNull;
      
      final volume = dayProgress?.totalVolume ?? 0.0;
      spots.add(FlSpot(i.toDouble(), volume / 1000)); // Convert to thousands
    }
    
    return spots;
  }

  Widget _buildQuickStat(
    BuildContext context,
    String label,
    String value,
    String indicator,
    bool isPositive,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              indicator,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isPositive ? const Color(0xFFFFB74D) : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Achievement Summary Card
class AchievementSummaryCard extends StatelessWidget {
  final UserProgress userProgress;

  const AchievementSummaryCard({
    super.key,
    required this.userProgress,
  });

  @override
  Widget build(BuildContext context) {
    final streakData = userProgress.streakData;
    final recentAchievements = userProgress.achievements.take(2).toList();
    
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
          // Current Streak
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: Color(0xFFFFB74D),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Streak',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${streakData.currentStreak} days',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFFB74D),
                      ),
                    ),
                  ],
                ),
              ),
              if (streakData.longestStreak > streakData.currentStreak)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Best: ${streakData.longestStreak}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          if (recentAchievements.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF2A2A2A), height: 1),
            const SizedBox(height: 16),
            
            // Recent Achievements
            Text(
              'Recent Achievements',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            
            ...recentAchievements.map((achievement) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getIconFromName(achievement.iconName),
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          achievement.title,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '+${achievement.xpReward} XP',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFFFB74D),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'fitness_center': return Icons.fitness_center;
      case 'trending_up': return Icons.trending_up;
      case 'emoji_events': return Icons.emoji_events;
      case 'local_fire_department': return Icons.local_fire_department;
      case 'whatshot': return Icons.whatshot;
      case 'military_tech': return Icons.military_tech;
      case 'workspace_premium': return Icons.workspace_premium;
      default: return Icons.star;
    }
  }
}