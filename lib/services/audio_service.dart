// lib/services/audio_service.dart
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  // Create a static player instance, lazily initialized.
  static AudioPlayer? _player;

  static Future<void> playClickSound() async {
    _player ??= AudioPlayer(); // Initialize only when needed
    // The 'play' method is designed for this use case. It stops any current playback
    // from this player and immediately starts the new source. This is ideal for
    // short, repeatable sound effects like button clicks.
    await _player!.play(AssetSource('sounds/click.mp3'));
  }
}
