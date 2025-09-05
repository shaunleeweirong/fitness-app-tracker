import 'package:json_annotation/json_annotation.dart';
import 'user_progress.dart';

part 'progress_dashboard_data.g.dart';

/// Loading states for progress data
enum ProgressLoadingState {
  idle,
  loading,
  success,
  error,
}

/// Consolidated data model for the progress dashboard
/// Contains all stats and metrics needed for the progress screen
@JsonSerializable()
class ProgressDashboardData {
  // Lifetime totals
  final int totalWorkouts;
  final double totalVolumeLifted;
  final Duration totalTimeExercised;
  final int currentStreak;
  final int longestStreak;
  final int totalAchievements;

  // Weekly/Monthly comparisons
  final ProgressComparison weeklyComparison;
  final ProgressComparison monthlyComparison;

  // Body part progress
  final Map<String, BodyPartProgress> bodyPartProgress;

  // Achievement data
  final List<Achievement> recentAchievements;
  final List<Achievement> allAchievements;

  // Training insights
  final List<String> closeToLevelUp;
  final List<String> needsAttention;

  // Additional metrics
  final DateTime? lastWorkoutDate;
  final double averageWorkoutDuration;
  final int totalSets;

  const ProgressDashboardData({
    required this.totalWorkouts,
    required this.totalVolumeLifted,
    required this.totalTimeExercised,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalAchievements,
    required this.weeklyComparison,
    required this.monthlyComparison,
    required this.bodyPartProgress,
    required this.recentAchievements,
    required this.allAchievements,
    required this.closeToLevelUp,
    required this.needsAttention,
    this.lastWorkoutDate,
    required this.averageWorkoutDuration,
    required this.totalSets,
  });

  factory ProgressDashboardData.fromJson(Map<String, dynamic> json) => 
      _$ProgressDashboardDataFromJson(json);
  Map<String, dynamic> toJson() => _$ProgressDashboardDataToJson(this);

  /// Create empty dashboard data for new users
  factory ProgressDashboardData.empty() {
    return ProgressDashboardData(
      totalWorkouts: 0,
      totalVolumeLifted: 0.0,
      totalTimeExercised: Duration.zero,
      currentStreak: 0,
      longestStreak: 0,
      totalAchievements: 0,
      weeklyComparison: ProgressComparisonExtension.empty('week'),
      monthlyComparison: ProgressComparisonExtension.empty('month'),
      bodyPartProgress: {},
      recentAchievements: [],
      allAchievements: [],
      closeToLevelUp: [],
      needsAttention: [],
      lastWorkoutDate: null,
      averageWorkoutDuration: 0.0,
      totalSets: 0,
    );
  }

  /// Check if user has any workout data
  bool get hasWorkoutData => totalWorkouts > 0;

  /// Get formatted total time string
  String get formattedTotalTime {
    final hours = totalTimeExercised.inHours;
    final minutes = totalTimeExercised.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Get formatted total volume string
  String get formattedTotalVolume {
    if (totalVolumeLifted >= 1000) {
      return '${(totalVolumeLifted / 1000).toStringAsFixed(1)}K kg';
    } else {
      return '${totalVolumeLifted.toStringAsFixed(0)} kg';
    }
  }

  /// Get average workout duration in minutes
  double get averageWorkoutDurationMinutes => averageWorkoutDuration / 60;

  /// Get body parts sorted by level (highest first)
  List<MapEntry<String, BodyPartProgress>> get bodyPartsByLevel {
    final entries = bodyPartProgress.entries.toList();
    entries.sort((a, b) => b.value.level.compareTo(a.value.level));
    return entries;
  }

  /// Get body parts that are close to leveling up (>70% progress)
  List<MapEntry<String, BodyPartProgress>> get closeToLevelUpParts {
    return bodyPartProgress.entries
        .where((entry) => entry.value.progressPercentage > 0.7)
        .toList();
  }

  /// Get body parts that need attention (not worked in 7+ days)
  List<MapEntry<String, BodyPartProgress>> get needsAttentionParts {
    final sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
    return bodyPartProgress.entries
        .where((entry) => entry.value.lastWorked.isBefore(sevenDaysAgo))
        .toList();
  }

  /// Get recent achievements (last 5)
  List<Achievement> get recentAchievementsList {
    final sorted = allAchievements.toList();
    sorted.sort((a, b) => b.dateEarned.compareTo(a.dateEarned));
    return sorted.take(5).toList();
  }
}

/// Result wrapper for progress data operations
class ProgressDataResult {
  final ProgressDashboardData? data;
  final ProgressLoadingState state;
  final String? errorMessage;
  
  const ProgressDataResult({
    this.data,
    required this.state,
    this.errorMessage,
  });
  
  /// Create a loading result
  factory ProgressDataResult.loading() {
    return const ProgressDataResult(state: ProgressLoadingState.loading);
  }
  
  /// Create a success result
  factory ProgressDataResult.success(ProgressDashboardData data) {
    return ProgressDataResult(
      data: data,
      state: ProgressLoadingState.success,
    );
  }
  
  /// Create an error result
  factory ProgressDataResult.error(String message) {
    return ProgressDataResult(
      state: ProgressLoadingState.error,
      errorMessage: message,
    );
  }
  
  /// Check if the result is successful and has data
  bool get isSuccess => state == ProgressLoadingState.success && data != null;
  
  /// Check if the result is in loading state
  bool get isLoading => state == ProgressLoadingState.loading;
  
  /// Check if the result has an error
  bool get hasError => state == ProgressLoadingState.error;
}

/// Extension to add empty factory method to ProgressComparison
extension ProgressComparisonExtension on ProgressComparison {
  static ProgressComparison empty(String period) {
    return ProgressComparison(
      currentValue: 0.0,
      previousValue: 0.0,
      currentWorkouts: 0,
      previousWorkouts: 0,
      period: period,
    );
  }
}