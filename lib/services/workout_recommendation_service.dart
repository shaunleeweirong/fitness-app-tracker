import '../models/workout.dart';
import '../services/workout_template_repository.dart';
import '../services/database_helper.dart';

/// Service for recommending workouts to users based on various factors
/// Provides intelligent workout suggestions for the homepage and other features
class WorkoutRecommendationService {
  final WorkoutTemplateRepository _templateRepository = WorkoutTemplateRepository();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Get a recommended workout for today based on user history and preferences
  Future<WorkoutTemplate?> getTodaysRecommendation() async {
    try {
      final userId = await _dbHelper.createMockUser();
      
      // Get all available templates (both user-created and system templates)
      final userTemplates = await _templateRepository.getTemplates(userId: userId);
      final systemTemplates = await _templateRepository.getTemplates(userId: 'system_templates');
      final allTemplates = [...userTemplates, ...systemTemplates];
      
      if (allTemplates.isEmpty) {
        return null;
      }
      
      // Apply recommendation logic
      final recommendation = await _selectRecommendedTemplate(allTemplates, userId);
      return recommendation;
    } catch (e) {
      print('Error getting workout recommendation: $e');
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

  /// Close database connections
  Future<void> close() async {
    await _templateRepository.close();
  }
}