import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../services/workout_template_repository.dart';
import '../services/database_helper.dart';
import 'create_workout_plan_screen.dart';
import 'workout_setup_screen.dart';

/// Screen for managing and browsing workout templates
/// Allows users to view, create, edit, and delete workout plans
class WorkoutPlansScreen extends StatefulWidget {
  const WorkoutPlansScreen({super.key});

  @override
  State<WorkoutPlansScreen> createState() => _WorkoutPlansScreenState();
}

class _WorkoutPlansScreenState extends State<WorkoutPlansScreen> with SingleTickerProviderStateMixin {
  final WorkoutTemplateRepository _templateRepository = WorkoutTemplateRepository();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  // State
  List<WorkoutTemplate> _templates = [];
  List<WorkoutTemplate> _filteredTemplates = [];
  bool _isLoading = true;
  String _searchQuery = '';
  TemplateCategory? _selectedCategory;
  final bool _showFavoritesOnly = false;
  
  // UI state
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTemplates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    // Don't close the database connection - it's shared across the app
    // _templateRepository.close();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    try {
      final userId = await _dbHelper.createMockUser();
      
      // Load both user templates and system templates
      final userTemplates = await _templateRepository.getTemplates(userId: userId);
      final systemTemplates = await _templateRepository.getTemplates(userId: 'system_templates');
      
      // Combine all templates
      final allTemplates = [...systemTemplates, ...userTemplates];
      
      if (mounted) {
        setState(() {
          _templates = allTemplates;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      print('Error loading templates: $e');
      
      // If database connection issue, try to retry once
      if (e.toString().contains('database_closed')) {
        print('Database connection closed, attempting retry...');
        try {
          // Wait a moment and retry
          await Future.delayed(const Duration(milliseconds: 500));
          await _loadTemplatesRetry();
          return;
        } catch (retryError) {
          print('Retry failed: $retryError');
        }
      }
      
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load templates: $e');
      }
    }
  }

  Future<void> _loadTemplatesRetry() async {
    final userId = await _dbHelper.createMockUser();
    
    // Load both user templates and system templates
    final userTemplates = await _templateRepository.getTemplates(userId: userId);
    final systemTemplates = await _templateRepository.getTemplates(userId: 'system_templates');
    
    // Combine all templates
    final allTemplates = [...systemTemplates, ...userTemplates];
    
    if (mounted) {
      setState(() {
        _templates = allTemplates;
        _isLoading = false;
      });
      _applyFilters();
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredTemplates = _templates.where((template) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!template.name.toLowerCase().contains(query) &&
              !(template.description?.toLowerCase().contains(query) ?? false)) {
            return false;
          }
        }
        
        // Category filter
        if (_selectedCategory != null && template.category != _selectedCategory) {
          return false;
        }
        
        // Favorites filter
        if (_showFavoritesOnly && !template.isFavorite) {
          return false;
        }
        
        return true;
      }).toList();
      
      // Sort by usage count and then by updated date
      _filteredTemplates.sort((a, b) {
        final usageComparison = b.usageCount.compareTo(a.usageCount);
        if (usageComparison != 0) return usageComparison;
        return b.updatedAt.compareTo(a.updatedAt);
      });
    });
  }

  /// Apply unified filtering for any tab (search + category + tab-specific filters)
  List<WorkoutTemplate> _applyTabFilters(List<WorkoutTemplate> templates, {bool favoritesOnly = false, bool recentOnly = false}) {
    return templates.where((template) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!template.name.toLowerCase().contains(query) &&
            !(template.description?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }
      
      // Category filter
      if (_selectedCategory != null && template.category != _selectedCategory) {
        return false;
      }
      
      // Tab-specific filters
      if (favoritesOnly && !template.isFavorite) {
        return false;
      }
      
      return true;
    }).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  Future<void> _toggleFavorite(String templateId) async {
    try {
      await _templateRepository.toggleFavorite(templateId);
      _loadTemplates();
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Favorite updated'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to update favorite: $e');
    }
  }

  Future<void> _deleteTemplate(String templateId, String templateName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Delete Template',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "$templateName"? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _templateRepository.deleteTemplate(templateId);
        _loadTemplates();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Template "$templateName" deleted'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        _showError('Failed to delete template: $e');
      }
    }
  }

  Future<void> _useTemplate(WorkoutTemplate template) async {
    try {
      await _templateRepository.recordTemplateUsage(template.templateId);
      
      // Navigate to workout setup with template
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WorkoutSetupScreen(template: template),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to use template: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Workout Plans',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => const CreateWorkoutPlanScreen(),
                ),
              );
              if (result == true) {
                _loadTemplates();
              }
            },
            icon: const Icon(Icons.add, color: Color(0xFFFFB74D)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFFB74D),
          unselectedLabelColor: Colors.white60,
          indicatorColor: const Color(0xFFFFB74D),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Favorites'),
            Tab(text: 'Recent'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and Filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search workout plans...',
                    hintStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFFFB74D)),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 12),
                
                // Category filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // All categories chip
                      _buildFilterChip(
                        label: 'All',
                        isSelected: _selectedCategory == null,
                        onTap: () {
                          setState(() => _selectedCategory = null);
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 8),
                      
                      // Category chips
                      ...TemplateCategory.values.map((category) {
                        if (category == TemplateCategory.custom) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildFilterChip(
                            label: _getCategoryDisplayName(category),
                            isSelected: _selectedCategory == category,
                            onTap: () {
                              setState(() => _selectedCategory = category);
                              _applyFilters();
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Templates list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTemplatesList(_filteredTemplates),
                _buildTemplatesList(_applyTabFilters(_templates, favoritesOnly: true)),
                _buildRecentTemplatesList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFB74D) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? null : Border.all(color: const Color(0xFF444444)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTemplatesList(List<WorkoutTemplate> templates) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFB74D)),
      );
    }

    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No templates match your search' : 'No workout plans yet',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty ? 'Try different keywords' : 'Create your first workout plan to get started',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => const CreateWorkoutPlanScreen(),
                  ),
                );
                if (result == true) {
                  _loadTemplates();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Workout Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB74D),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Separate system templates from user templates
    final systemTemplates = templates.where((t) => t.userId == 'system_templates').toList();
    final userTemplates = templates.where((t) => t.userId != 'system_templates').toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // System Templates Section
        if (systemTemplates.isNotEmpty) ...[
          _buildSectionHeader('Default Workouts', systemTemplates.length),
          ...systemTemplates.map((template) => _buildTemplateCard(template)),
          if (userTemplates.isNotEmpty) const SizedBox(height: 24),
        ],
        
        // User Templates Section
        if (userTemplates.isNotEmpty) ...[
          _buildSectionHeader('My Custom Plans', userTemplates.length),
          ...userTemplates.map((template) => _buildTemplateCard(template)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB74D).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.3)),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Color(0xFFFFB74D),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTemplatesList() {
    return FutureBuilder<List<WorkoutTemplate>>(
      future: _loadRecentTemplates(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFB74D)),
          );
        }

        final recentTemplates = snapshot.data ?? [];
        final filteredRecentTemplates = _applyTabFilters(recentTemplates);
        return _buildTemplatesList(filteredRecentTemplates);
      },
    );
  }

  Future<List<WorkoutTemplate>> _loadRecentTemplates() async {
    try {
      final userId = await _dbHelper.createMockUser();
      return await _templateRepository.getRecentTemplates(userId: userId);
    } catch (e) {
      print('Error loading recent templates: $e');
      return [];
    }
  }

  Widget _buildTemplateCard(WorkoutTemplate template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _useTemplate(template),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildInfoChip(template.categoryName, Colors.blue),
                                const SizedBox(width: 8),
                                _buildInfoChip(template.difficultyName, _getDifficultyColor(template.difficulty)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _toggleFavorite(template.templateId),
                          icon: Icon(
                            template.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: template.isFavorite ? Colors.red : Colors.white60,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white60),
                          color: const Color(0xFF2A2A2A),
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                // TODO: Navigate to edit screen
                                break;
                              case 'delete':
                                _deleteTemplate(template.templateId, template.name);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit', style: TextStyle(color: Colors.white)),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Description
                if (template.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    template.description!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // Workout details
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Icon(Icons.fitness_center, size: 16, color: Colors.white.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(
                        '${template.exercises.length} exercises',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.schedule, size: 16, color: Colors.white.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(
                        '${template.estimatedDurationMinutes ?? 45} min',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Use button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _useTemplate(template),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB74D),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Use This Plan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getDifficultyColor(TemplateDifficulty difficulty) {
    switch (difficulty) {
      case TemplateDifficulty.beginner:
        return Colors.green;
      case TemplateDifficulty.intermediate:
        return Colors.orange;
      case TemplateDifficulty.advanced:
        return Colors.red;
    }
  }

  String _getCategoryDisplayName(TemplateCategory category) {
    switch (category) {
      case TemplateCategory.custom:
        return 'Custom';
      case TemplateCategory.strength:
        return 'Strength';
      case TemplateCategory.cardio:
        return 'Cardio';
      case TemplateCategory.fullBody:
        return 'Full Body';
      case TemplateCategory.upperBody:
        return 'Upper Body';
      case TemplateCategory.lowerBody:
        return 'Lower Body';
      case TemplateCategory.push:
        return 'Push';
      case TemplateCategory.pull:
        return 'Pull';
      case TemplateCategory.legs:
        return 'Legs';
    }
  }
}