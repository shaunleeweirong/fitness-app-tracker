// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_dashboard_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProgressDashboardData _$ProgressDashboardDataFromJson(
        Map<String, dynamic> json) =>
    ProgressDashboardData(
      totalWorkouts: (json['totalWorkouts'] as num).toInt(),
      totalVolumeLifted: (json['totalVolumeLifted'] as num).toDouble(),
      totalTimeExercised:
          Duration(microseconds: (json['totalTimeExercised'] as num).toInt()),
      currentStreak: (json['currentStreak'] as num).toInt(),
      longestStreak: (json['longestStreak'] as num).toInt(),
      totalAchievements: (json['totalAchievements'] as num).toInt(),
      weeklyComparison: ProgressComparison.fromJson(
          json['weeklyComparison'] as Map<String, dynamic>),
      monthlyComparison: ProgressComparison.fromJson(
          json['monthlyComparison'] as Map<String, dynamic>),
      bodyPartProgress: (json['bodyPartProgress'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, BodyPartProgress.fromJson(e as Map<String, dynamic>)),
      ),
      recentAchievements: (json['recentAchievements'] as List<dynamic>)
          .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
          .toList(),
      allAchievements: (json['allAchievements'] as List<dynamic>)
          .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
          .toList(),
      closeToLevelUp: (json['closeToLevelUp'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      needsAttention: (json['needsAttention'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      lastWorkoutDate: json['lastWorkoutDate'] == null
          ? null
          : DateTime.parse(json['lastWorkoutDate'] as String),
      averageWorkoutDuration:
          (json['averageWorkoutDuration'] as num).toDouble(),
      totalSets: (json['totalSets'] as num).toInt(),
    );

Map<String, dynamic> _$ProgressDashboardDataToJson(
        ProgressDashboardData instance) =>
    <String, dynamic>{
      'totalWorkouts': instance.totalWorkouts,
      'totalVolumeLifted': instance.totalVolumeLifted,
      'totalTimeExercised': instance.totalTimeExercised.inMicroseconds,
      'currentStreak': instance.currentStreak,
      'longestStreak': instance.longestStreak,
      'totalAchievements': instance.totalAchievements,
      'weeklyComparison': instance.weeklyComparison,
      'monthlyComparison': instance.monthlyComparison,
      'bodyPartProgress': instance.bodyPartProgress,
      'recentAchievements': instance.recentAchievements,
      'allAchievements': instance.allAchievements,
      'closeToLevelUp': instance.closeToLevelUp,
      'needsAttention': instance.needsAttention,
      'lastWorkoutDate': instance.lastWorkoutDate?.toIso8601String(),
      'averageWorkoutDuration': instance.averageWorkoutDuration,
      'totalSets': instance.totalSets,
    };
