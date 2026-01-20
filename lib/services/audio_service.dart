// lib/services/audio_service.dart
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isLoaded = false;

  static Future<void> loadSound() async {
    if (!_isLoaded) {
      await _player.setSourceAsset('sounds/click.mp3');
      _isLoaded = true;
    }
  }

  static Future<void> playClickSound() async {
    if (!_isLoaded) {
      await loadSound();
    }
    // Rewind to the beginning and play
    await _player.seek(Duration.zero);
    await _player.resume();
  }
}
