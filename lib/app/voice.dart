import 'package:audioplayers/audioplayers.dart';

import '../domain/engine.dart';

class VoiceCue {
  AudioPlayer? _cues;
  AudioPlayer? _speech;
  int _token = 0;

  AudioPlayer _player(bool speech) {
    if (speech) {
      return _speech ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    }
    return _cues ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  }

  Future<void> cue(String name) async {
    try {
      final player = _player(false);
      await player.stop();
      await player.play(AssetSource('audio/$name.wav'));
    } catch (_) {
      // A missing clip should not block the round.
    }
  }

  Future<void> speak(String prompt) async {
    final clips = speechClips(prompt);
    final token = ++_token;
    try {
      final player = _player(true);
      await player.stop();
      for (final clip in clips) {
        if (token != _token) return;
        await player.play(AssetSource('audio/$clip.wav'));
        await player.onPlayerComplete.first.timeout(
          const Duration(seconds: 2),
          onTimeout: () {},
        );
      }
    } catch (_) {
      // Read-aloud is optional when a clip is missing.
    }
  }

  Future<void> stop() async {
    _token += 1;
    await _speech?.stop();
    await _cues?.stop();
  }

  void dispose() {
    _cues?.dispose();
    _speech?.dispose();
  }
}
