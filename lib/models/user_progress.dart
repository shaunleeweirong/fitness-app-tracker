import 'package:json_annotation/json_annotation.dart';
import 'workout_session.dart';

part 'user_progress.g.dart';

@JsonSerializable()
class UserProgress {
  final String userId;
  final DateTime lastUpdated;
  final ProgressStats currentStats;
  final List<DailyProgress> dailyProgress; // Last 30 days
  final Map<String, BodyPartProgress> bodyPartProgress;
  final List<Achievement> achievements;
  final StreakData streakData;
  final List<Milestone> milestones;

  const UserProgress({
    required this.userId,
    required this.lastUpdated,
    required this.currentStats,
    required this.dailyProgress,
    required this.bodyPartProgress,
    required this.achievements,
    required this.streakData,
    required this.milestones,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) => _$UserProgressFromJson(json);
  Map<String, dynamic> toJson() => _$UserProgressToJson(this);

  /// Create initial progress for a new user
  factory UserProgress.initial(String userId) {
    return UserProgress(
      userId: userId,
      lastUpdated: DateTime.now(),
      currentStats: const ProgressStats.initial(),
      dailyProgress: [],
      bodyPartProgress: {},
      achievements: [],
      streakData: const StreakData.initial(),
      milestones: [],
    );
  }

  /// Update progress with new workout session
  UserProgress updateWithSession(WorkoutSession session) {
    if (!session.isCompleted) return this;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Update current stats
    final newStats = currentStats.updateWithSession(session);
    
    // Update daily progress
    final updatedDailyProgress = _updateDailyProgress(session, today);
    
    // Update body part progress
    final updatedBodyPartProgress = _updateBodyPartProgress(session);
    
    // Update streak data
    final updatedStreakData = streakData.updateWithWorkout(today);
    
    // Check for new achievements
    final newAchievements = _checkNewAchievements(newStats, updatedBodyPartProgress);
    
    // Update milestones
    final updatedMilestones = _updateMilestones(newStats, updatedBodyPartProgress);
    
    return UserProgress(
      userId: userId,
      lastUpdated: now,
      currentStats: newStats,
      dailyProgress: updatedDailyProgress,
      bodyPartProgress: updatedBodyPartProgress,
      achievements: [...achievements, ...newAchievements],
      streakData: updatedStreakData,
      milestones: updatedMilestones,
    );
  }

  /// Get weekly progress comparison
  ProgressComparison getWeeklyComparison() {
    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = thisWeekStart.subtract(const Duration(days: 1));
    
    final thisWeekProgress = dailyProgress.where((day) => 
      day.date.isAfter(thisWeekStart.subtract(const Duration(days: 1)))).toList();
    
    final lastWeekProgress = dailyProgress.where((day) => 
      day.date.isAfter(lastWeekStart.subtract(const Duration(days: 1))) &&
      day.date.isBefore(lastWeekEnd.add(const Duration(days: 1)))).toList();
    
    final thisWeekVolume = thisWeekProgress.fold(0.0, (sum, day) => sum + day.totalVolume);
    final lastWeekVolume = lastWeekProgress.fold(0.0, (sum, day) => sum + day.totalVolume);
    
    final thisWeekWorkouts = thisWeekProgress.fold(0, (sum, day) => sum + day.workoutCount);
    final lastWeekWorkouts = lastWeekProgress.fold(0, (sum, day) => sum + day.workoutCount);
    
    return ProgressComparison(
      currentValue: thisWeekVolume,
      previousValue: lastWeekVolume,
      currentWorkouts: thisWeekWorkouts,
      previousWorkouts: lastWeekWorkouts,
      period: 'week',
    );
  }

  /// Get monthly progress comparison
  ProgressComparison getMonthlyComparison() {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = thisMonthStart.subtract(const Duration(days: 1));
    
    final thisMonthProgress = dailyProgress.where((day) => 
      day.date.isAfter(thisMonthStart.subtract(const Duration(days: 1)))).toList();
    
    final lastMonthProgress = dailyProgress.where((day) => 
      day.date.isAfter(lastMonthStart.subtract(const Duration(days: 1))) &&
      day.date.isBefore(lastMonthEnd.add(const Duration(days: 1)))).toList();
    
    final thisMonthVolume = thisMonthProgress.fold(0.0, (sum, day) => sum + day.totalVolume);
    final lastMonthVolume = lastMonthProgress.fold(0.0, (sum, day) => sum + day.totalVolume);
    
    final thisMonthWorkouts = thisMonthProgress.fold(0, (sum, day) => sum + day.workoutCount);
    final lastMonthWorkouts = lastMonthProgress.fold(0, (sum, day) => sum + day.workoutCount);
    
    return ProgressComparison(
      currentValue: thisMonthVolume,
      previousValue: lastMonthVolume,
      currentWorkouts: thisMonthWorkouts,
      previousWorkouts: lastMonthWorkouts,
      period: 'month',
    );
  }

  List<DailyProgress> _updateDailyProgress(WorkoutSession session, DateTime today) {
    final existingTodayIndex = dailyProgress.indexWhere(
      (day) => day.date.year == today.year && 
               day.date.month == today.month && 
               day.date.day == today.day
    );
    
    if (existingTodayIndex >= 0) {
      // Update existing day
      final existingDay = dailyProgress[existingTodayIndex];
      final updatedDay = existingDay.addWorkout(session);
      
      final updatedList = [...dailyProgress];
      updatedList[existingTodayIndex] = updatedDay;
      return updatedList;
    } else {
      // Add new day
      final newDay = DailyProgress(
        date: today,
        workoutCount: 1,
        totalVolume: session.totalVolume,
        bodyPartsWorked: session.bodyPartsWorked,
        exerciseCount: session.totalExercises,
      );
      
      // Keep only last 30 days
      final updatedList = [...dailyProgress, newDay];
      updatedList.sort((a, b) => a.date.compareTo(b.date));
      
      final cutoffDate = today.subtract(const Duration(days: 30));
      return updatedList.where((day) => day.date.isAfter(cutoffDate)).toList();
    }
  }

  Map<String, BodyPartProgress> _updateBodyPartProgress(WorkoutSession session) {
    final updated = <String, BodyPartProgress>{...bodyPartProgress};
    
    for (final bodyPart in session.bodyPartVolumeMap.keys) {
      final volumeAdded = session.bodyPartVolumeMap[bodyPart]!;
      
      if (updated.containsKey(bodyPart)) {
        updated[bodyPart] = updated[bodyPart]!.addVolume(volumeAdded);
      } else {
        updated[bodyPart] = BodyPartProgress.initial(bodyPart).addVolume(volumeAdded);
      }
    }
    
    return updated;
  }

  List<Achievement> _checkNewAchievements(ProgressStats stats, Map<String, BodyPartProgress> bodyProgress) {
    final newAchievements = <Achievement>[];
    
    // Check workout count achievements
    if (stats.totalWorkouts == 1) {
      newAchievements.add(Achievement.firstWorkout());
    } else if (stats.totalWorkouts == 10) {
      newAchievements.add(Achievement.tenWorkouts());
    } else if (stats.totalWorkouts == 50) {
      newAchievements.add(Achievement.fiftyWorkouts());
    }
    
    // Check streak achievements
    if (streakData.currentStreak == 7) {
      newAchievements.add(Achievement.weekStreak());
    } else if (streakData.currentStreak == 30) {
      newAchievements.add(Achievement.monthStreak());
    }
    
    // Check body part level achievements
    for (final bodyPartProgress in bodyProgress.values) {
      if (bodyPartProgress.level == 5) {
        newAchievements.add(Achievement.bodyPartLevel5(bodyPartProgress.bodyPart));
      } else if (bodyPartProgress.level == 10) {
        newAchievements.add(Achievement.bodyPartLevel10(bodyPartProgress.bodyPart));
      }
    }
    
    return newAchievements;
  }

  List<Milestone> _updateMilestones(ProgressStats stats, Map<String, BodyPartProgress> bodyProgress) {
    // Implementation for milestone updates
    return milestones; // Simplified for now
  }
}

@JsonSerializable()
class ProgressStats {
  final int totalWorkouts;
  final Duration totalTimeExercised;
  final double totalVolumeLifted;
  final int totalSets;
  final DateTime? lastWorkoutDate;

  const ProgressStats({
    required this.totalWorkouts,
    required this.totalTimeExercised,
    required this.totalVolumeLifted,
    required this.totalSets,
    this.lastWorkoutDate,
  });

  const ProgressStats.initial() : this(
    totalWorkouts: 0,
    totalTimeExercised: Duration.zero,
    totalVolumeLifted: 0.0,
    totalSets: 0,
    lastWorkoutDate: null,
  );

  factory ProgressStats.fromJson(Map<String, dynamic> json) => _$ProgressStatsFromJson(json);
  Map<String, dynamic> toJson() => _$ProgressStatsToJson(this);

  ProgressStats updateWithSession(WorkoutSession session) {
    return ProgressStats(
      totalWorkouts: totalWorkouts + 1,
      totalTimeExercised: totalTimeExercised + session.duration,
      totalVolumeLifted: totalVolumeLifted + session.totalVolume,
      totalSets: totalSets + session.totalSets,
      lastWorkoutDate: session.endTime ?? DateTime.now(),
    );
  }

  String get formattedTotalTime {
    final hours = totalTimeExercised.inHours;
    final minutes = totalTimeExercised.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

@JsonSerializable()
class DailyProgress {
  final DateTime date;
  final int workoutCount;
  final double totalVolume;
  final Set<String> bodyPartsWorked;
  final int exerciseCount;

  const DailyProgress({
    required this.date,
    required this.workoutCount,
    required this.totalVolume,
    required this.bodyPartsWorked,
    required this.exerciseCount,
  });

  factory DailyProgress.fromJson(Map<String, dynamic> json) => _$DailyProgressFromJson(json);
  Map<String, dynamic> toJson() => _$DailyProgressToJson(this);

  DailyProgress addWorkout(WorkoutSession session) {
    return DailyProgress(
      date: date,
      workoutCount: workoutCount + 1,
      totalVolume: totalVolume + session.totalVolume,
      bodyPartsWorked: bodyPartsWorked.union(session.bodyPartsWorked),
      exerciseCount: exerciseCount + session.totalExercises,
    );
  }
}

@JsonSerializable()
class BodyPartProgress {
  final String bodyPart;
  final double totalVolume;
  final int workoutCount;
  final int level;
  final double xp;
  final double xpToNextLevel;
  final DateTime lastWorked;

  const BodyPartProgress({
    required this.bodyPart,
    required this.totalVolume,
    required this.workoutCount,
    required this.level,
    required this.xp,
    required this.xpToNextLevel,
    required this.lastWorked,
  });

  factory BodyPartProgress.fromJson(Map<String, dynamic> json) => _$BodyPartProgressFromJson(json);
  Map<String, dynamic> toJson() => _$BodyPartProgressToJson(this);

  factory BodyPartProgress.initial(String bodyPart) {
    return BodyPartProgress(
      bodyPart: bodyPart,
      totalVolume: 0.0,
      workoutCount: 0,
      level: 1,
      xp: 0.0,
      xpToNextLevel: 1000.0, // XP required for level 2
      lastWorked: DateTime.now(),
    );
  }

  BodyPartProgress addVolume(double volume) {
    final newXp = xp + volume;
    final newLevel = _calculateLevel(newXp);
    final newXpToNext = _calculateXpToNextLevel(newLevel);
    
    return BodyPartProgress(
      bodyPart: bodyPart,
      totalVolume: totalVolume + volume,
      workoutCount: workoutCount + 1,
      level: newLevel,
      xp: newXp,
      xpToNextLevel: newXpToNext,
      lastWorked: DateTime.now(),
    );
  }

  int _calculateLevel(double totalXp) {
    // Level formula: each level requires more XP (exponential growth)
    int level = 1;
    double xpRequired = 1000.0;
    double currentXp = totalXp;
    
    while (currentXp >= xpRequired) {
      currentXp -= xpRequired;
      level++;
      xpRequired *= 1.5; // Each level requires 50% more XP
    }
    
    return level;
  }

  double _calculateXpToNextLevel(int currentLevel) {
    double xpRequired = 1000.0;
    for (int i = 1; i < currentLevel; i++) {
      xpRequired *= 1.5;
    }
    return xpRequired;
  }

  double get progressPercentage {
    final xpInCurrentLevel = xp - _getXpForLevel(level);
    return (xpInCurrentLevel / xpToNextLevel).clamp(0.0, 1.0);
  }

  double _getXpForLevel(int targetLevel) {
    double totalXp = 0.0;
    double xpRequired = 1000.0;
    
    for (int i = 1; i < targetLevel; i++) {
      totalXp += xpRequired;
      xpRequired *= 1.5;
    }
    
    return totalXp;
  }
}

@JsonSerializable()
class StreakData {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastWorkoutDate;

  const StreakData({
    required this.currentStreak,
    required this.longestStreak,
    this.lastWorkoutDate,
  });

  const StreakData.initial() : this(
    currentStreak: 0,
    longestStreak: 0,
    lastWorkoutDate: null,
  );

  factory StreakData.fromJson(Map<String, dynamic> json) => _$StreakDataFromJson(json);
  Map<String, dynamic> toJson() => _$StreakDataToJson(this);

  StreakData updateWithWorkout(DateTime workoutDate) {
    if (lastWorkoutDate == null) {
      return StreakData(
        currentStreak: 1,
        longestStreak: 1,
        lastWorkoutDate: workoutDate,
      );
    }

    final daysSinceLastWorkout = workoutDate.difference(lastWorkoutDate!).inDays;
    
    int newCurrentStreak;
    if (daysSinceLastWorkout <= 1) {
      // Consecutive day or same day
      newCurrentStreak = currentStreak + (daysSinceLastWorkout == 0 ? 0 : 1);
    } else {
      // Streak broken
      newCurrentStreak = 1;
    }

    return StreakData(
      currentStreak: newCurrentStreak,
      longestStreak: newCurrentStreak > longestStreak ? newCurrentStreak : longestStreak,
      lastWorkoutDate: workoutDate,
    );
  }
}

@JsonSerializable()
class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final DateTime dateEarned;
  final int xpReward;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.dateEarned,
    required this.xpReward,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) => _$AchievementFromJson(json);
  Map<String, dynamic> toJson() => _$AchievementToJson(this);

  factory Achievement.firstWorkout() => Achievement(
    id: 'first_workout',
    title: 'First Steps',
    description: 'Completed your first workout!',
    iconName: 'fitness_center',
    dateEarned: DateTime.now(),
    xpReward: 100,
  );

  factory Achievement.tenWorkouts() => Achievement(
    id: 'ten_workouts',
    title: 'Getting Strong',
    description: 'Completed 10 workouts!',
    iconName: 'trending_up',
    dateEarned: DateTime.now(),
    xpReward: 500,
  );

  factory Achievement.fiftyWorkouts() => Achievement(
    id: 'fifty_workouts',
    title: 'Fitness Enthusiast',
    description: 'Completed 50 workouts!',
    iconName: 'emoji_events',
    dateEarned: DateTime.now(),
    xpReward: 1000,
  );

  factory Achievement.weekStreak() => Achievement(
    id: 'week_streak',
    title: 'Weekly Warrior',
    description: '7-day workout streak!',
    iconName: 'local_fire_department',
    dateEarned: DateTime.now(),
    xpReward: 300,
  );

  factory Achievement.monthStreak() => Achievement(
    id: 'month_streak',
    title: 'Unstoppable',
    description: '30-day workout streak!',
    iconName: 'whatshot',
    dateEarned: DateTime.now(),
    xpReward: 2000,
  );

  factory Achievement.bodyPartLevel5(String bodyPart) => Achievement(
    id: 'level_5_$bodyPart',
    title: '${bodyPart.toUpperCase()} Champion',
    description: 'Reached level 5 in $bodyPart training!',
    iconName: 'military_tech',
    dateEarned: DateTime.now(),
    xpReward: 250,
  );

  factory Achievement.bodyPartLevel10(String bodyPart) => Achievement(
    id: 'level_10_$bodyPart',
    title: '${bodyPart.toUpperCase()} Master',
    description: 'Reached level 10 in $bodyPart training!',
    iconName: 'workspace_premium',
    dateEarned: DateTime.now(),
    xpReward: 1000,
  );
}

@JsonSerializable()
class Milestone {
  final String id;
  final String title;
  final String description;
  final double targetValue;
  final double currentValue;
  final String valueType; // 'volume', 'workouts', 'streak'
  final bool isCompleted;
  final DateTime? completedDate;

  const Milestone({
    required this.id,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.valueType,
    required this.isCompleted,
    this.completedDate,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) => _$MilestoneFromJson(json);
  Map<String, dynamic> toJson() => _$MilestoneToJson(this);

  double get progressPercentage => (currentValue / targetValue).clamp(0.0, 1.0);
}

@JsonSerializable()
class ProgressComparison {
  final double currentValue;
  final double previousValue;
  final int currentWorkouts;
  final int previousWorkouts;
  final String period; // 'week' or 'month'

  const ProgressComparison({
    required this.currentValue,
    required this.previousValue,
    required this.currentWorkouts,
    required this.previousWorkouts,
    required this.period,
  });

  factory ProgressComparison.fromJson(Map<String, dynamic> json) => _$ProgressComparisonFromJson(json);
  Map<String, dynamic> toJson() => _$ProgressComparisonToJson(this);

  double get volumeChangePercentage {
    if (previousValue == 0) return currentValue > 0 ? 100.0 : 0.0;
    return ((currentValue - previousValue) / previousValue) * 100;
  }

  double get workoutChangePercentage {
    if (previousWorkouts == 0) return currentWorkouts > 0 ? 100.0 : 0.0;
    return ((currentWorkouts - previousWorkouts) / previousWorkouts) * 100;
  }

  bool get isImproving => currentValue > previousValue;
  bool get isWorkoutCountImproving => currentWorkouts > previousWorkouts;

  String get changeIndicator => isImproving ? '▲' : '▼';
  String get workoutChangeIndicator => isWorkoutCountImproving ? '▲' : '▼';
}