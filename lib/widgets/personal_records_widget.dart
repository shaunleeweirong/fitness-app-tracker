/// Widget for displaying personal records on the progress dashboard

import 'package:flutter/material.dart';
import '../models/personal_record.dart';
import '../services/personal_record_service.dart';

class PersonalRecordsWidget extends StatefulWidget {
  final String? userId;

  const PersonalRecordsWidget({
    super.key,
    this.userId,
  });

  @override
  State<PersonalRecordsWidget> createState() => _PersonalRecordsWidgetState();
}

class _PersonalRecordsWidgetState extends State<PersonalRecordsWidget> {
  final PersonalRecordService _prService = PersonalRecordService();
  List<PersonalRecord> _recentPRs = [];
  Map<String, dynamic> _prStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPRData();
  }

  Future<void> _loadPRData() async {
    try {
      final recentPRs = await _prService.getRecentPRs(widget.userId);
      final prStats = await _prService.getPRStats(widget.userId);

      if (mounted) {
        setState(() {
          _recentPRs = recentPRs;
          _prStats = prStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingCard();
    }

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
          // Header with PR icon and stats
          _buildHeader(),
          const SizedBox(height: 16),
          
          // Recent PRs or empty state
          if (_recentPRs.isEmpty) 
            _buildEmptyState()
          else
            _buildRecentPRs(),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
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
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFFB74D),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final totalPRs = _prStats['totalPRs'] ?? 0;
    final monthlyPRs = _prStats['monthlyPRs'] ?? 0;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB74D).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.emoji_events,
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
                'Personal Records',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$totalPRs total • $monthlyPRs this month',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (totalPRs > 0)
          GestureDetector(
            onTap: _showAllPRs,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB74D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFB74D).withOpacity(0.3),
                ),
              ),
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFFFFB74D),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF2A2A2A),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 32,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 8),
              Text(
                'No Personal Records Yet',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white60,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Complete workouts to start tracking PRs',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentPRs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Achievements',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        
        ..._recentPRs.take(3).map((pr) => _buildPRItem(pr)).toList(),
        
        if (_recentPRs.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: GestureDetector(
                onTap: _showAllPRs,
                child: Text(
                  'View ${_recentPRs.length - 3} more PRs',
                  style: const TextStyle(
                    color: Color(0xFFFFB74D),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPRItem(PersonalRecord pr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFFB74D).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              _getTypeIcon(pr.type),
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
                  pr.exerciseName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  pr.shortDescription,
                  style: const TextStyle(
                    color: Color(0xFFFFB74D),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(pr.achievedAt),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(PersonalRecordType type) {
    switch (type) {
      case PersonalRecordType.weight:
        return Icons.fitness_center;
      case PersonalRecordType.volume:
        return Icons.trending_up;
      case PersonalRecordType.reps:
        return Icons.repeat;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  void _showAllPRs() {
    // TODO: Navigate to detailed PR screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Detailed PR view coming soon!'),
        backgroundColor: Color(0xFFFFB74D),
      ),
    );
  }

  @override
  void dispose() {
    _prService.dispose();
    super.dispose();
  }
}