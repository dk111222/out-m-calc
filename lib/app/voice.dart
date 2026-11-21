import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../domain/engine.dart';

class VoiceCue {
  AudioPlayer? _cues;
  AudioPlayer? _speech;
  FlutterTts? _tts;
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
    final token = ++_token;
    final locale = PlatformDispatcher.instance.locale;
    final zh = locale.languageCode.toLowerCase() == 'zh';
    final spoken = spokenPrompt(prompt, language: zh ? 'zh' : 'en');
    try {
      final tts = _tts ??= FlutterTts();
      await tts.awaitSpeakCompletion(true);
      await tts.stop();
      final tag = ttsLanguageTag(
        locale.languageCode,
        countryCode: locale.countryCode,
        scriptCode: locale.scriptCode,
      );
      var ready = await tts.setLanguage(tag);
      if (ready != 1 && zh) ready = await tts.setLanguage('zh-CN');
      if (token != _token) return;
      if (ready == 1) {
        await tts.speak(spoken);
        return;
      }
    } catch (_) {
      // The system voice is missing in tests and on some devices.
    }
    if (!zh) await _speakClips(prompt, token);
  }

  Future<void> _speakClips(String prompt, int token) async {
    try {
      final player = _player(true);
      await player.stop();
      for (final clip in speechClips(prompt)) {
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
    await _tts?.stop();
    await _speech?.stop();
    await _cues?.stop();
  }

  void dispose() {
    _tts?.stop();
    _cues?.dispose();
    _speech?.dispose();
  }
}
