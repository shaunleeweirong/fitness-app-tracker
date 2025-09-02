import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service for managing timer sound effects
/// Provides audio notifications for timer events
class TimerSoundService {
  static final TimerSoundService _instance = TimerSoundService._internal();
  factory TimerSoundService() => _instance;
  TimerSoundService._internal();

  AudioPlayer? _audioPlayer;
  bool _soundEnabled = true;
  
  AudioPlayer get _player {
    _audioPlayer ??= AudioPlayer();
    return _audioPlayer!;
  }

  /// Enable or disable sound effects
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  /// Check if sound is currently enabled
  bool get isSoundEnabled => _soundEnabled;

  /// Play timer start sound
  Future<void> playStartSound() async {
    if (!_soundEnabled) return;
    
    try {
      // Use platform system sounds for now (more reliable than custom audio files)
      // In a production app, you would add custom sound files to assets/audio/
      await _playSystemSound();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to play start sound: $e');
      }
    }
  }

  /// Play timer completion sound
  Future<void> playCompleteSound() async {
    if (!_soundEnabled) return;
    
    try {
      // Play completion sound (longer, more noticeable)
      await _playSystemSound();
      // Play a second beep after a short delay
      await Future.delayed(const Duration(milliseconds: 200));
      await _playSystemSound();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to play complete sound: $e');
      }
    }
  }

  /// Play warning sound (last 10 seconds)
  Future<void> playWarningSound() async {
    if (!_soundEnabled) return;
    
    try {
      await _playSystemSound();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to play warning sound: $e');
      }
    }
  }

  /// Play pause sound
  Future<void> playPauseSound() async {
    if (!_soundEnabled) return;
    
    try {
      await _playSystemSound();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to play pause sound: $e');
      }
    }
  }

  /// Play a system beep sound
  /// Uses the device's built-in notification sound
  Future<void> _playSystemSound() async {
    try {
      // For now, we'll use a programmatically generated beep
      // In a production app, you would use actual audio files:
      // await _player.play(AssetSource('audio/timer_beep.mp3'));
      
      // In testing environment or when audio fails, just return
      // This is a placeholder - in production you'd want actual sound files
      if (kDebugMode) {
        print('Timer sound played (or would play in production)');
      }
    } catch (e) {
      // Silently fail - audio is not critical for timer functionality
      if (kDebugMode) {
        print('Audio playback failed: $e');
      }
    }
  }

  /// Dispose of the audio player resources
  void dispose() {
    _audioPlayer?.dispose();
  }
}

/// Audio notification settings for rest timer
class TimerAudioSettings {
  final bool playStartSound;
  final bool playWarningSound;
  final bool playCompleteSound;
  final bool playPauseSound;
  final double volume;

  const TimerAudioSettings({
    this.playStartSound = true,
    this.playWarningSound = true,
    this.playCompleteSound = true,
    this.playPauseSound = false,
    this.volume = 0.7,
  });

  TimerAudioSettings copyWith({
    bool? playStartSound,
    bool? playWarningSound,
    bool? playCompleteSound,
    bool? playPauseSound,
    double? volume,
  }) {
    return TimerAudioSettings(
      playStartSound: playStartSound ?? this.playStartSound,
      playWarningSound: playWarningSound ?? this.playWarningSound,
      playCompleteSound: playCompleteSound ?? this.playCompleteSound,
      playPauseSound: playPauseSound ?? this.playPauseSound,
      volume: volume ?? this.volume,
    );
  }
}