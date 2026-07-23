import 'package:audioplayers/audioplayers.dart';
import '../data/storage.dart';

/// 音效类型枚举
enum SoundType {
  completeSet,
  completeTraining,
  restStart,
  restEnd,
  tick,
  achievement,
  points,
  buttonTap,
}

/// 音效服务（单例）
class SoundService {
  static final SoundService instance = SoundService._();
  SoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;
  bool _enabled = true;

  static const Map<SoundType, String> _soundPaths = {
    SoundType.completeSet: 'sounds/complete_set.wav',
    SoundType.completeTraining: 'sounds/complete_training.wav',
    SoundType.restStart: 'sounds/rest_start.wav',
    SoundType.restEnd: 'sounds/rest_end.wav',
    SoundType.tick: 'sounds/tick.wav',
    SoundType.achievement: 'sounds/achievement.wav',
    SoundType.points: 'sounds/points.wav',
    SoundType.buttonTap: 'sounds/button_tap.wav',
  };

  Future<void> init() async {
    if (_initialized) return;
    final settings = Storage.getSettings();
    _enabled = settings['soundEnabled'] != false;
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(0.6);
    } catch (_) {}
    _initialized = true;
  }

  Future<void> play(SoundType type) async {
    if (!_enabled) return;
    if (!_initialized) await init();
    try {
      final path = _soundPaths[type];
      if (path == null) return;
      await _player.stop();
      await _player.play(AssetSource(path));
    } catch (_) {
      // 忽略播放错误
    }
  }

  void setEnabled(bool enabled) {
    _enabled = enabled;
    final settings = Storage.getSettings();
    settings['soundEnabled'] = enabled;
    Storage.saveSettings(settings);
  }

  bool get isEnabled => _enabled;
}
