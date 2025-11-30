import 'package:flutter/services.dart';

class NativeAudio {
  static const MethodChannel _channel = MethodChannel("audio_channel");

  static Future<Uint8List> generateAudio({
    required double duration,
    required double tempo,
    required int keyIndex,
    required bool isMinor,
    required double mood,
    required double rhythm,
    required int pattern,
    required double perc,
  }) async {
    final result = await _channel.invokeMethod("generateAudio", {
      "duration": duration,
      "tempo": tempo,
      "keyIndex": keyIndex,
      "isMinor": isMinor,
      "mood": mood,
      "rhythm": rhythm,
      "pattern": pattern,
      "perc": perc,
    });

    return Uint8List.fromList((result as List).cast<int>());
  }
}
