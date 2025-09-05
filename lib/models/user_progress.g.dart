// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProgress _$UserProgressFromJson(Map<String, dynamic> json) => UserProgress(
      userId: json['userId'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      currentStats:
          ProgressStats.fromJson(json['currentStats'] as Map<String, dynamic>),
      dailyProgress: (json['dailyProgress'] as List<dynamic>)
          .map((e) => DailyProgress.fromJson(e as Map<String, dynamic>))
          .toList(),
      bodyPartProgress: (json['bodyPartProgress'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, BodyPartProgress.fromJson(e as Map<String, dynamic>)),
      ),
      achievements: (json['achievements'] as List<dynamic>)
          .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
          .toList(),
      streakData:
          StreakData.fromJson(json['streakData'] as Map<String, dynamic>),
      milestones: (json['milestones'] as List<dynamic>)
          .map((e) => Milestone.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UserProgressToJson(UserProgress instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
      'currentStats': instance.currentStats,
      'dailyProgress': instance.dailyProgress,
      'bodyPartProgress': instance.bodyPartProgress,
      'achievements': instance.achievements,
      'streakData': instance.streakData,
      'milestones': instance.milestones,
    };

ProgressStats _$ProgressStatsFromJson(Map<String, dynamic> json) =>
    ProgressStats(
      totalWorkouts: (json['totalWorkouts'] as num).toInt(),
      totalTimeExercised:
          Duration(microseconds: (json['totalTimeExercised'] as num).toInt()),
      totalVolumeLifted: (json['totalVolumeLifted'] as num).toDouble(),
      totalSets: (json['totalSets'] as num).toInt(),
      lastWorkoutDate: json['lastWorkoutDate'] == null
          ? null
          : DateTime.parse(json['lastWorkoutDate'] as String),
    );

Map<String, dynamic> _$ProgressStatsToJson(ProgressStats instance) =>
    <String, dynamic>{
      'totalWorkouts': instance.totalWorkouts,
      'totalTimeExercised': instance.totalTimeExercised.inMicroseconds,
      'totalVolumeLifted': instance.totalVolumeLifted,
      'totalSets': instance.totalSets,
      'lastWorkoutDate': instance.lastWorkoutDate?.toIso8601String(),
    };

DailyProgress _$DailyProgressFromJson(Map<String, dynamic> json) =>
    DailyProgress(
      date: DateTime.parse(json['date'] as String),
      workoutCount: (json['workoutCount'] as num).toInt(),
      totalVolume: (json['totalVolume'] as num).toDouble(),
      bodyPartsWorked: (json['bodyPartsWorked'] as List<dynamic>)
          .map((e) => e as String)
          .toSet(),
      exerciseCount: (json['exerciseCount'] as num).toInt(),
    );

Map<String, dynamic> _$DailyProgressToJson(DailyProgress instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'workoutCount': instance.workoutCount,
      'totalVolume': instance.totalVolume,
      'bodyPartsWorked': instance.bodyPartsWorked.toList(),
      'exerciseCount': instance.exerciseCount,
    };

BodyPartProgress _$BodyPartProgressFromJson(Map<String, dynamic> json) =>
    BodyPartProgress(
      bodyPart: json['bodyPart'] as String,
      totalVolume: (json['totalVolume'] as num).toDouble(),
      workoutCount: (json['workoutCount'] as num).toInt(),
      level: (json['level'] as num).toInt(),
      xp: (json['xp'] as num).toDouble(),
      xpToNextLevel: (json['xpToNextLevel'] as num).toDouble(),
      lastWorked: DateTime.parse(json['lastWorked'] as String),
    );

Map<String, dynamic> _$BodyPartProgressToJson(BodyPartProgress instance) =>
    <String, dynamic>{
      'bodyPart': instance.bodyPart,
      'totalVolume': instance.totalVolume,
      'workoutCount': instance.workoutCount,
      'level': instance.level,
      'xp': instance.xp,
      'xpToNextLevel': instance.xpToNextLevel,
      'lastWorked': instance.lastWorked.toIso8601String(),
    };

StreakData _$StreakDataFromJson(Map<String, dynamic> json) => StreakData(
      currentStreak: (json['currentStreak'] as num).toInt(),
      longestStreak: (json['longestStreak'] as num).toInt(),
      lastWorkoutDate: json['lastWorkoutDate'] == null
          ? null
          : DateTime.parse(json['lastWorkoutDate'] as String),
    );

Map<String, dynamic> _$StreakDataToJson(StreakData instance) =>
    <String, dynamic>{
      'currentStreak': instance.currentStreak,
      'longestStreak': instance.longestStreak,
      'lastWorkoutDate': instance.lastWorkoutDate?.toIso8601String(),
    };

Achievement _$AchievementFromJson(Map<String, dynamic> json) => Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconName: json['iconName'] as String,
      dateEarned: DateTime.parse(json['dateEarned'] as String),
      xpReward: (json['xpReward'] as num).toInt(),
    );

Map<String, dynamic> _$AchievementToJson(Achievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'iconName': instance.iconName,
      'dateEarned': instance.dateEarned.toIso8601String(),
      'xpReward': instance.xpReward,
    };

Milestone _$MilestoneFromJson(Map<String, dynamic> json) => Milestone(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      targetValue: (json['targetValue'] as num).toDouble(),
      currentValue: (json['currentValue'] as num).toDouble(),
      valueType: json['valueType'] as String,
      isCompleted: json['isCompleted'] as bool,
      completedDate: json['completedDate'] == null
          ? null
          : DateTime.parse(json['completedDate'] as String),
    );

Map<String, dynamic> _$MilestoneToJson(Milestone instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'targetValue': instance.targetValue,
      'currentValue': instance.currentValue,
      'valueType': instance.valueType,
      'isCompleted': instance.isCompleted,
      'completedDate': instance.completedDate?.toIso8601String(),
    };

ProgressComparison _$ProgressComparisonFromJson(Map<String, dynamic> json) =>
    ProgressComparison(
      currentValue: (json['currentValue'] as num).toDouble(),
      previousValue: (json['previousValue'] as num).toDouble(),
      currentWorkouts: (json['currentWorkouts'] as num).toInt(),
      previousWorkouts: (json['previousWorkouts'] as num).toInt(),
      period: json['period'] as String,
    );

Map<String, dynamic> _$ProgressComparisonToJson(ProgressComparison instance) =>
    <String, dynamic>{
      'currentValue': instance.currentValue,
      'previousValue': instance.previousValue,
      'currentWorkouts': instance.currentWorkouts,
      'previousWorkouts': instance.previousWorkouts,
      'period': instance.period,
    };
