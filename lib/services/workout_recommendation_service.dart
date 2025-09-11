import '../models/workout.dart';
import '../services/workout_template_repository.dart';
import '../services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for recommending workouts to users based on various factors
/// Provides intelligent workout suggestions for the homepage and other features
class WorkoutRecommendationService {
  final WorkoutTemplateRepository _templateRepository = WorkoutTemplateRepository();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String _cacheKeyPrefix = 'recommendation_';
  static const String _cacheReasonKeyPrefix = 'recommendation_reason_';

  /// Get a recommended workout for today based on user history and preferences
  Future<WorkoutTemplate?> getTodaysRecommendation() async {
    try {
      // First, try to get cached recommendation for today
      final cachedRecommendation = await _getCachedRecommendation();
      if (cachedRecommendation != null) {
        print('✅ Using cached recommendation: ${cachedRecommendation.name}');
        return cachedRecommendation;
      }
      
      print('📱 No cache found, loading fresh recommendation...');
      
      final userId = await _dbHelper.createMockUser();
      print('👤 Created/found user: $userId');
      
      // Get all available templates (both user-created and system templates)
      print('🔍 Loading user templates...');
      final userTemplates = await _templateRepository.getTemplates(userId: userId);
      print('📋 Found ${userTemplates.length} user templates');
      
      print('🔍 Loading system templates...');
      final systemTemplates = await _templateRepository.getTemplates(userId: 'system_templates');
      print('📋 Found ${systemTemplates.length} system templates');
      
      if (systemTemplates.isNotEmpty) {
        for (final template in systemTemplates) {
          print('   📝 System template: ${template.name} (${template.category.name})');
        }
      }
      
      final allTemplates = [...userTemplates, ...systemTemplates];
      print('📊 Total templates available: ${allTemplates.length}');
      
      if (allTemplates.isEmpty) {
        print('❌ No templates available for recommendation');
        return null;
      }
      
      // Apply recommendation logic
      final recommendation = await _selectRecommendedTemplate(allTemplates, userId);
      print('🎯 Selected recommendation: ${recommendation?.name ?? 'None'}');
      
      // Cache the recommendation for today
      if (recommendation != null) {
        await _cacheRecommendation(recommendation);
        print('💾 Cached recommendation: ${recommendation.name}');
      }
      
      return recommendation;
    } catch (e, stackTrace) {
      print('❌ Error getting workout recommendation: $e');
      print('📚 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get multiple workout recommendations for user choice
  Future<List<WorkoutTemplate>> getMultipleRecommendations({int count = 3}) async {
    try {
      final userId = await _dbHelper.createMockUser();
      
      // Get all available templates
      final userTemplates = await _templateRepository.getTemplates(userId: userId);
      final systemTemplates = await _templateRepository.getTemplates(userId: 'system_templates');
      final allTemplates = [...userTemplates, ...systemTemplates];
      
      if (allTemplates.isEmpty) {
        return [];
      }
      
      // Get diverse recommendations
      return _selectDiverseRecommendations(allTemplates, count);
    } catch (e) {
      print('Error getting multiple recommendations: $e');
      return [];
    }
  }

  /// Select the best recommended template based on various factors
  Future<WorkoutTemplate> _selectRecommendedTemplate(List<WorkoutTemplate> templates, String userId) async {
    // For now, implement a simple rotation strategy
    // In future versions, this can include:
    // - User workout history analysis
    // - Recovery time considerations
    // - Body part training frequency
    // - User preferences and goals
    
    final now = DateTime.now();
    final dayOfWeek = now.weekday;
    
    // Rotate recommendations based on day of week
    final recommendation = _getRecommendationByDay(templates, dayOfWeek);
    
    return recommendation ?? templates.first;
  }

  /// Get recommendation based on day of the week for variety
  WorkoutTemplate? _getRecommendationByDay(List<WorkoutTemplate> templates, int dayOfWeek) {
    // Define preferred categories by day
    final Map<int, List<TemplateCategory>> dayPreferences = {
      1: [TemplateCategory.push, TemplateCategory.upperBody], // Monday - Upper body focus
      2: [TemplateCategory.legs, TemplateCategory.lowerBody], // Tuesday - Legs
      3: [TemplateCategory.pull, TemplateCategory.upperBody], // Wednesday - Pull
      4: [TemplateCategory.fullBody, TemplateCategory.strength], // Thursday - Full body
      5: [TemplateCategory.push, TemplateCategory.upperBody], // Friday - Push
      6: [TemplateCategory.fullBody, TemplateCategory.cardio], // Saturday - Full body/cardio
      7: [TemplateCategory.pull, TemplateCategory.fullBody], // Sunday - Recovery/pull
    };

    final preferredCategories = dayPreferences[dayOfWeek] ?? [TemplateCategory.fullBody];
    
    // Find templates matching preferred categories
    for (final category in preferredCategories) {
      final matchingTemplates = templates.where((t) => t.category == category).toList();
      if (matchingTemplates.isNotEmpty) {
        // Sort by usage count and pick least used for variety
        matchingTemplates.sort((a, b) => a.usageCount.compareTo(b.usageCount));
        return matchingTemplates.first;
      }
    }
    
    return null;
  }

  /// Select diverse recommendations to give users variety
  List<WorkoutTemplate> _selectDiverseRecommendations(List<WorkoutTemplate> templates, int count) {
    final recommendations = <WorkoutTemplate>[];
    final usedCategories = <TemplateCategory>{};
    
    // Sort templates by usage count (prefer less used)
    final sortedTemplates = List<WorkoutTemplate>.from(templates);
    sortedTemplates.sort((a, b) => a.usageCount.compareTo(b.usageCount));
    
    // Select diverse templates by category
    for (final template in sortedTemplates) {
      if (recommendations.length >= count) break;
      
      if (!usedCategories.contains(template.category)) {
        recommendations.add(template);
        usedCategories.add(template.category);
      }
    }
    
    // Fill remaining slots if needed
    for (final template in sortedTemplates) {
      if (recommendations.length >= count) break;
      if (!recommendations.contains(template)) {
        recommendations.add(template);
      }
    }
    
    return recommendations.take(count).toList();
  }

  /// Get a fallback recommendation when no specific recommendation is available
  Future<WorkoutTemplate?> getFallbackRecommendation() async {
    try {
      // Always try to get a system template as fallback
      final systemTemplates = await _templateRepository.getTemplates(userId: 'system_templates');
      
      if (systemTemplates.isNotEmpty) {
        // Return a balanced full-body or push template as safe default
        final preferred = systemTemplates.where((t) => 
          t.category == TemplateCategory.fullBody || 
          t.category == TemplateCategory.push
        ).toList();
        
        return preferred.isNotEmpty ? preferred.first : systemTemplates.first;
      }
      
      return null;
    } catch (e) {
      print('Error getting fallback recommendation: $e');
      return null;
    }
  }

  /// Check if a template is recommended for today
  Future<bool> isRecommendedForToday(String templateId) async {
    final recommendation = await getTodaysRecommendation();
    return recommendation?.templateId == templateId;
  }

  /// Get recommendation reasoning text for display
  String getRecommendationReason(WorkoutTemplate template) {
    final now = DateTime.now();
    final dayOfWeek = now.weekday;
    
    final Map<int, String> dayReasons = {
      1: "Perfect way to start the week strong",
      2: "Build foundation with lower body power", 
      3: "Mid-week back and bicep focus",
      4: "Balanced training for overall fitness",
      5: "End the work week with pushing power",
      6: "Weekend warrior full-body session",
      7: "Active recovery and muscle balance",
    };

    if (template.category == TemplateCategory.push) {
      return dayReasons[dayOfWeek] ?? "Great for building pushing strength";
    } else if (template.category == TemplateCategory.pull) {
      return dayReasons[dayOfWeek] ?? "Perfect for back and bicep development";
    } else if (template.category == TemplateCategory.legs) {
      return "Build powerful legs and glutes";
    } else if (template.category == TemplateCategory.fullBody) {
      return "Complete workout hitting all major muscles";
    } else {
      return "Recommended based on your training schedule";
    }
  }

  /// Get today's date as cache key
  String _getTodaysCacheKey() {
    final today = DateTime.now();
    return '$_cacheKeyPrefix${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  }

  String _getTodaysReasonCacheKey() {
    final today = DateTime.now();
    return '$_cacheReasonKeyPrefix${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  }

  /// Get cached recommendation for today
  Future<WorkoutTemplate?> _getCachedRecommendation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getTodaysCacheKey();
      print('🔍 Looking for cache key: $cacheKey');
      
      final cachedJson = prefs.getString(cacheKey);
      
      if (cachedJson != null) {
        print('✅ Found cached data, length: ${cachedJson.length} chars');
        print('📄 Cached JSON: ${cachedJson.substring(0, cachedJson.length > 200 ? 200 : cachedJson.length)}...');
        
        final cachedMap = jsonDecode(cachedJson) as Map<String, dynamic>;
        print('📋 Decoded cache map keys: ${cachedMap.keys.toList()}');
        
        final template = WorkoutTemplate.fromMap(cachedMap);
        print('✅ Successfully deserialized template: ${template.name}');
        return template;
      } else {
        print('❌ No cached data found for key: $cacheKey');
        // List all cache keys to see what's stored
        final allKeys = prefs.getKeys();
        final cacheKeys = allKeys.where((k) => k.startsWith(_cacheKeyPrefix)).toList();
        print('📋 Available cache keys: $cacheKeys');
      }
      
      return null;
    } catch (e, stackTrace) {
      print('❌ Error reading cached recommendation: $e');
      print('📚 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Cache recommendation for today
  Future<void> _cacheRecommendation(WorkoutTemplate template) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getTodaysCacheKey();
      final reasonCacheKey = _getTodaysReasonCacheKey();
      
      print('💾 Caching recommendation with key: $cacheKey');
      print('📋 Template details: ${template.name} (${template.category.name})');
      
      // Cache the template
      final templateMap = template.toMap();
      print('🗃️ Template map keys: ${templateMap.keys.toList()}');
      
      final templateJson = jsonEncode(templateMap);
      print('📝 JSON length: ${templateJson.length} chars');
      print('📄 JSON preview: ${templateJson.substring(0, templateJson.length > 200 ? 200 : templateJson.length)}...');
      
      await prefs.setString(cacheKey, templateJson);
      print('✅ Template cached successfully');
      
      // Cache the reason
      final reason = getRecommendationReason(template);
      await prefs.setString(reasonCacheKey, reason);
      print('✅ Reason cached: $reason');
      
      // Clean up old cache entries (keep last 7 days)
      await _cleanupOldCacheEntries();
    } catch (e, stackTrace) {
      print('❌ Error caching recommendation: $e');
      print('📚 Stack trace: $stackTrace');
    }
  }

  /// Get cached recommendation reason for today
  Future<String?> getCachedRecommendationReason() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reasonCacheKey = _getTodaysReasonCacheKey();
      return prefs.getString(reasonCacheKey);
    } catch (e) {
      print('Error reading cached recommendation reason: $e');
      return null;
    }
  }

  /// Clean up old cache entries to prevent storage bloat
  Future<void> _cleanupOldCacheEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().toList();
      final now = DateTime.now();
      
      for (final key in keys) {
        if (key.startsWith(_cacheKeyPrefix) || key.startsWith(_cacheReasonKeyPrefix)) {
          // Extract date from key (e.g., "recommendation_2025-09-11")
          final datePart = key.split('_').last;
          try {
            final cacheDate = DateTime.parse(datePart);
            final daysDifference = now.difference(cacheDate).inDays;
            
            // Remove entries older than 7 days
            if (daysDifference > 7) {
              await prefs.remove(key);
              print('🧹 Cleaned up old cache entry: $key');
            }
          } catch (e) {
            // Invalid date format, remove the key
            await prefs.remove(key);
            print('🧹 Cleaned up invalid cache entry: $key');
          }
        }
      }
    } catch (e) {
      print('Error cleaning up cache: $e');
    }
  }

  /// Clear today's recommendation cache (for testing or manual refresh)
  Future<void> clearTodaysCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getTodaysCacheKey());
      await prefs.remove(_getTodaysReasonCacheKey());
      print('🧹 Cleared today\'s recommendation cache');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// DEBUG: Force fresh recommendation by bypassing cache
  Future<WorkoutTemplate?> getDebugFreshRecommendation() async {
    try {
      await clearTodaysCache();
      return await getTodaysRecommendation();
    } catch (e) {
      print('❌ Debug fresh recommendation failed: $e');
      return null;
    }
  }

  /// Close database connections
  /// Note: Don't close shared database connection used by repository
  Future<void> close() async {
    // Repository uses shared database connection - don't close it
    // await _templateRepository.close();
  }
}