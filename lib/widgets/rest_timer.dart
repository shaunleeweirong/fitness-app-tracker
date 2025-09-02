import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/timer_sound_service.dart';

/// Rest timer widget for tracking rest periods between sets
/// Provides countdown functionality with audio/vibration notifications
class RestTimer extends StatefulWidget {
  final int initialDurationSeconds;
  final VoidCallback? onTimerComplete;
  final VoidCallback? onTimerStart;
  final VoidCallback? onTimerStop;
  
  const RestTimer({
    super.key,
    this.initialDurationSeconds = 90, // Default 90 seconds
    this.onTimerComplete,
    this.onTimerStart,
    this.onTimerStop,
  });

  @override
  State<RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<RestTimer> with TickerProviderStateMixin {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _hasPlayedWarning = false;
  
  // Services
  final TimerSoundService _soundService = TimerSoundService();
  
  // Preset timer durations (in seconds)
  final List<int> _presetDurations = [60, 90, 120, 180, 300]; // 1min, 1.5min, 2min, 3min, 5min
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialDurationSeconds;
    
    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _progressController = AnimationController(
      duration: Duration(seconds: widget.initialDurationSeconds),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_remainingSeconds <= 0) {
      _remainingSeconds = widget.initialDurationSeconds;
      _progressController.reset();
    }
    
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _hasPlayedWarning = false;
    });
    
    // Start progress animation
    _progressController.forward();
    
    // Start countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });
      
      // Warning notifications for last 10 seconds
      if (_remainingSeconds <= 10 && _remainingSeconds > 0) {
        _pulseController.repeat(reverse: true);
        
        // Play warning sound on 10-second mark
        if (_remainingSeconds == 10 && !_hasPlayedWarning) {
          _hasPlayedWarning = true;
          _soundService.playWarningSound();
          HapticFeedback.mediumImpact();
        }
        
        // Additional warning beeps for last 3 seconds
        if (_remainingSeconds <= 3) {
          _soundService.playWarningSound();
          HapticFeedback.mediumImpact();
        }
      }
      
      // Timer complete
      if (_remainingSeconds <= 0) {
        _completeTimer();
      }
    });
    
    // Start notification
    _soundService.playStartSound();
    HapticFeedback.lightImpact();
    widget.onTimerStart?.call();
  }

  void _pauseTimer() {
    _timer?.cancel();
    _progressController.stop();
    _pulseController.stop();
    
    setState(() {
      _isRunning = false;
      _isPaused = true;
    });
    
    _soundService.playPauseSound();
    HapticFeedback.lightImpact();
  }

  void _resetTimer() {
    _timer?.cancel();
    _progressController.reset();
    _pulseController.stop();
    _pulseController.reset();
    
    setState(() {
      _remainingSeconds = widget.initialDurationSeconds;
      _isRunning = false;
      _isPaused = false;
      _hasPlayedWarning = false;
    });
    
    HapticFeedback.lightImpact();
    widget.onTimerStop?.call();
  }

  void _completeTimer() {
    _timer?.cancel();
    _progressController.stop();
    _pulseController.stop();
    
    setState(() {
      _remainingSeconds = 0;
      _isRunning = false;
      _isPaused = false;
    });
    
    // Completion feedback
    _soundService.playCompleteSound();
    HapticFeedback.heavyImpact();
    
    widget.onTimerComplete?.call();
    
    // Show completion dialog
    _showTimerCompleteDialog();
  }

  void _setPresetDuration(int seconds) {
    if (_isRunning) return; // Can't change duration while running
    
    setState(() {
      _remainingSeconds = seconds;
      _hasPlayedWarning = false;
    });
    
    _progressController.reset();
    _progressController.duration = Duration(seconds: seconds);
  }

  void _showTimerCompleteDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Rest Complete! 💪',
          style: TextStyle(
            color: Color(0xFFFFB74D),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Time for your next set!',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetTimer();
            },
            child: const Text(
              'Ready',
              style: TextStyle(
                color: Color(0xFFFFB74D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor() {
    if (_remainingSeconds <= 10) {
      return Colors.red;
    } else if (_remainingSeconds <= 30) {
      return Colors.orange;
    } else {
      return const Color(0xFFFFB74D);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer Title
          const Text(
            'Rest Timer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          
          // Circular Progress Timer
          SizedBox(
            height: 200,
            width: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2A2A2A),
                      width: 8,
                    ),
                  ),
                ),
                
                // Progress circle
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return SizedBox(
                      height: 200,
                      width: 200,
                      child: CircularProgressIndicator(
                        value: _progressAnimation.value,
                        strokeWidth: 8,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(_getTimerColor()),
                      ),
                    );
                  },
                ),
                
                // Time display
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(_remainingSeconds),
                            style: TextStyle(
                              color: _getTimerColor(),
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          if (_isRunning) ...[
                            const SizedBox(height: 4),
                            Text(
                              _isPaused ? 'PAUSED' : 'RESTING',
                              style: TextStyle(
                                color: _getTimerColor().withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Timer Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Reset Button
              _buildControlButton(
                icon: Icons.refresh,
                label: 'Reset',
                onTap: _resetTimer,
                color: Colors.grey,
              ),
              
              // Start/Pause Button
              _buildControlButton(
                icon: _isRunning 
                  ? Icons.pause 
                  : (_isPaused ? Icons.play_arrow : Icons.play_arrow),
                label: _isRunning ? 'Pause' : 'Start',
                onTap: _isRunning ? _pauseTimer : _startTimer,
                color: const Color(0xFFFFB74D),
                isPrimary: true,
              ),
              
              // Skip Button
              _buildControlButton(
                icon: Icons.skip_next,
                label: 'Skip',
                onTap: _isRunning ? _completeTimer : null,
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Preset Duration Buttons
          if (!_isRunning) ...[
            const Text(
              'Quick Set',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _presetDurations.map((duration) {
                final isSelected = _remainingSeconds == duration;
                return GestureDetector(
                  onTap: () => _setPresetDuration(duration),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFFB74D) : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _formatTime(duration),
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required Color color,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? color : color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: isPrimary ? null : Border.all(color: color, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.black : color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.black : color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}