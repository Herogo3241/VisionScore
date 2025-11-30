import 'package:flutter/services.dart';

class LiveAudio {
  static const MethodChannel _ch = MethodChannel("audio_channel");

  static Future<bool> start() async {
    return await _ch.invokeMethod("startLive");
  }


  static Future<bool> stop() async {
    return await _ch.invokeMethod("stopLive");
  }


  static Future<bool> updateParams({
    required double tempo,
    required int keyIndex,
    required bool isMinor,
    required double mood,
    required double rhythm,
    required int patternId,
    required double percLevel,
  }) async {
    return await _ch.invokeMethod("updateLiveParams", {
      "tempo": tempo,
      "keyIndex": keyIndex,
      "isMinor": isMinor,
      "mood": mood,
      "rhythm": rhythm,
      "patternId": patternId,
      "percLevel": percLevel,
    });
  }
}
