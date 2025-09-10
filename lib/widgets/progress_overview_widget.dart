import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/user_progress.dart';

enum TimeFrame { weekly, monthly, quarterly }

class ProgressOverviewWidget extends StatefulWidget {
  final UserProgress userProgress;

  const ProgressOverviewWidget({
    super.key,
    required this.userProgress,
  });

  @override
  State<ProgressOverviewWidget> createState() => _ProgressOverviewWidgetState();
}

class _ProgressOverviewWidgetState extends State<ProgressOverviewWidget> {
  TimeFrame _selectedTimeFrame = TimeFrame.weekly;

  @override
  Widget build(BuildContext context) {
    final comparison = _getComparisonForTimeFrame();
    
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
          // Header with timeframe selector and trend indicator
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeframe tabs
              _buildTimeFrameTabs(),
              const SizedBox(height: 12),
              
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
                      '${_getTimeFrameDisplayName()} Volume Progress',
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
                      color: comparison.isImproving 
                          ? const Color(0xFFFFB74D).withOpacity(0.2) // Orange to match app theme
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          comparison.isImproving ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                          color: comparison.isImproving ? const Color(0xFFFFB74D) : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${comparison.volumeChangePercentage.abs().toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: comparison.isImproving ? const Color(0xFFFFB74D) : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                _getPeriodDisplayName(),
                '${comparison.currentWorkouts} workouts',
                comparison.workoutChangeIndicator,
                comparison.isWorkoutCountImproving,
              ),
              _buildQuickStat(
                context,
                'Volume',
                '${(comparison.currentValue / 1000).toStringAsFixed(1)}K kg',
                comparison.changeIndicator,
                comparison.isImproving,
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
              interval: 1.0,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                
                // Use switch-case pattern like official fl_chart examples
                switch (_selectedTimeFrame) {
                  case TimeFrame.weekly:
                    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    if (index >= 0 && index < days.length) {
                      return Text(
                        days[index],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      );
                    }
                    break;
                  case TimeFrame.monthly:
                    if (index >= 0 && index < 6) {
                      return Text(
                        'M${index + 1}',  // M1, M2, M3, M4, M5, M6 (oldest to newest)
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      );
                    }
                    break;
                  case TimeFrame.quarterly:
                    final maxX = _getMaxXForTimeFrame().toInt();
                    if (index >= 0 && index <= maxX) {
                      return Text(
                        'W${index + 1}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      );
                    }
                    break;
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
        maxX: _getMaxXForTimeFrame(),
        minY: 0,
        backgroundColor: Colors.transparent,
      ),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  List<FlSpot> _getChartData() {
    final now = DateTime.now();
    final spots = <FlSpot>[];
    
    switch (_selectedTimeFrame) {
      case TimeFrame.weekly:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        for (int i = 0; i < 7; i++) {
          final date = startOfWeek.add(Duration(days: i));
          final dayProgress = widget.userProgress.dailyProgress.where((day) =>
            day.date.year == date.year &&
            day.date.month == date.month &&
            day.date.day == date.day
          ).firstOrNull;
          
          final volume = dayProgress?.totalVolume ?? 0.0;
          spots.add(FlSpot(i.toDouble(), volume / 1000));
        }
        break;
        
      case TimeFrame.monthly:
        // Show last 6 months of data (oldest to newest)
        for (int i = 5; i >= 0; i--) {
          final targetMonth = DateTime(now.year, now.month - i, 1);
          final nextMonth = DateTime(targetMonth.year, targetMonth.month + 1, 1);
          
          // Aggregate all workouts in that month
          double monthVolume = 0.0;
          int daysWithWorkouts = 0;
          
          for (final dayProgress in widget.userProgress.dailyProgress) {
            if (dayProgress.date.isAfter(targetMonth.subtract(const Duration(days: 1))) &&
                dayProgress.date.isBefore(nextMonth)) {
              monthVolume += dayProgress.totalVolume;
              if (dayProgress.totalVolume > 0) {
                daysWithWorkouts++;
              }
            }
          }
          
          // Show as daily average for that month
          final dailyAverage = daysWithWorkouts > 0 ? monthVolume / daysWithWorkouts : 0.0;
          spots.add(FlSpot((5 - i).toDouble(), dailyAverage / 1000));
        }
        break;
        
      case TimeFrame.quarterly:
        final startOfQuarter = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
        
        for (int i = 0; i < 12; i++) { // Weekly data points over 3 months
          final date = startOfQuarter.add(Duration(days: i * 7));
          if (date.isAfter(now)) break;
          
          // Aggregate week's volume
          double weekVolume = 0.0;
          for (int j = 0; j < 7; j++) {
            final dayDate = date.add(Duration(days: j));
            final dayProgress = widget.userProgress.dailyProgress.where((day) =>
              day.date.year == dayDate.year &&
              day.date.month == dayDate.month &&
              day.date.day == dayDate.day
            ).firstOrNull;
            
            weekVolume += dayProgress?.totalVolume ?? 0.0;
          }
          
          spots.add(FlSpot(i.toDouble(), weekVolume / 1000));
        }
        break;
    }
    
    return spots;
  }

  double _getMaxXForTimeFrame() {
    switch (_selectedTimeFrame) {
      case TimeFrame.weekly:
        return 6;  // 7 days (0-6)
      case TimeFrame.monthly:
        return 5.0; // 6 months (0-5)
      case TimeFrame.quarterly:
        // Calculate actual weeks from start of quarter to now (matching data generation logic)
        final now = DateTime.now();
        final startOfQuarter = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
        int actualWeeks = 0;
        for (int i = 0; i < 12; i++) {
          final date = startOfQuarter.add(Duration(days: i * 7));
          if (date.isAfter(now)) break;
          actualWeeks++;
        }
        return (actualWeeks - 1).toDouble(); // Last index
    }
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

  // Helper methods for timeframe management
  dynamic _getComparisonForTimeFrame() {
    switch (_selectedTimeFrame) {
      case TimeFrame.weekly:
        return widget.userProgress.getWeeklyComparison();
      case TimeFrame.monthly:
        return widget.userProgress.getMonthlyComparison();
      case TimeFrame.quarterly:
        // For now, use monthly comparison as quarterly isn't implemented in UserProgress
        return widget.userProgress.getMonthlyComparison();
    }
  }

  String _getTimeFrameDisplayName() {
    switch (_selectedTimeFrame) {
      case TimeFrame.weekly:
        return 'Weekly';
      case TimeFrame.monthly:
        return 'Monthly';
      case TimeFrame.quarterly:
        return 'Quarterly';
    }
  }

  String _getPeriodDisplayName() {
    switch (_selectedTimeFrame) {
      case TimeFrame.weekly:
        return 'This Week';
      case TimeFrame.monthly:
        return 'This Month';
      case TimeFrame.quarterly:
        return 'This Quarter';
    }
  }

  Widget _buildTimeFrameTabs() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTimeFrameTab('Week', TimeFrame.weekly),
        const SizedBox(width: 4),
        _buildTimeFrameTab('Month', TimeFrame.monthly),
        const SizedBox(width: 4),
        _buildTimeFrameTab('Quarter', TimeFrame.quarterly),
      ],
    );
  }

  Widget _buildTimeFrameTab(String label, TimeFrame timeFrame) {
    final isSelected = _selectedTimeFrame == timeFrame;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeFrame = timeFrame;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFFFB74D).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFFFFB74D)
                : const Color(0xFF2A2A2A),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFFB74D) : Colors.white60,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
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