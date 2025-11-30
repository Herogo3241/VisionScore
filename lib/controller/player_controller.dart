import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vision_score/utils/helper/permission_handler.dart';

class PlayerController extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  bool isPlaying = false;
  bool hasTrack = false;
  bool isPlayerVisible = false;
  List<double> pcmSamples = [];

  String? imagePath;
  String trackTitle = "Generated Track";
  String? audioFilePath;
  String? pcmFilePath;

  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  PlayerController() {
    // Duration updates
    _player.onDurationChanged.listen((d) {
      duration = d;
      notifyListeners();
    });

    // Position updates
    _player.onPositionChanged.listen((p) {
      position = p;
      notifyListeners();
    });

    // Playback finished
    _player.onPlayerComplete.listen((_) {
      isPlaying = false;
      position = Duration.zero;
      notifyListeners();
    });
  }
  List<double> _convertPCM16ToDouble(Uint8List pcm) {
    final data = ByteData.view(pcm.buffer);
    final sampleCount = pcm.lengthInBytes ~/ 2;

    final result = List<double>.filled(sampleCount, 0.0);
    for (int i = 0; i < sampleCount; i++) {
      // read 16-bit signed integer
      final v = data.getInt16(i * 2, Endian.little);
      result[i] = v / 32768.0;
    }
    return result;
  }

  List<double> getCurrentPCMWindow() {
    if (pcmSamples.isEmpty || duration.inMilliseconds == 0) return [];

    final total = pcmSamples.length;
    final ratio = position.inMilliseconds / duration.inMilliseconds;

    int center = (total * ratio).toInt();
    const int window = 400;

    int start = (center - window ~/ 2).clamp(0, total - 1);
    int end = (start + window).clamp(0, total - 1);

    return pcmSamples.sublist(start, end);
  }

  Future<void> loadFromFile(
    String path,
    String pcmPath, {
    String? image,
    String? title,
  }) async {
    audioFilePath = path;
    pcmFilePath = pcmPath;

    if (pcmPath.isNotEmpty && File(pcmPath).existsSync()) {
      final rawPCM = await File(pcmPath).readAsBytes();
      pcmSamples = _convertPCM16ToDouble(rawPCM);
    }

    if (image != null) imagePath = image;
    if (title != null) trackTitle = title;

    await _player.stop();
    await _player.play(DeviceFileSource(path));

    hasTrack = true;
    isPlayerVisible = true;
    isPlaying = true;
    notifyListeners();
  }

  Future<String?> downloadTrack() async {
    if (audioFilePath == null) return null;

    try {
      final original = File(audioFilePath!);

      if (!original.existsSync()) return null;

      final dir = Directory("/storage/emulated/0/VisionScore");
      await requestStoragePermission();
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      final savePath = "${dir.path}/${trackTitle}.wav";
      print(savePath);

      await original.copy(savePath);

      return savePath; // return the file path for UI/Toast
    } catch (e) {
      print("Download failed: $e");
      return null;
    }
  }

  void play() async {
    if (audioFilePath == null) return;

    // If finished (pos == 0 and not playing), restart fully
    if (position == Duration.zero && !isPlaying) {
      await _player.play(DeviceFileSource(audioFilePath!));
    } else {
      await _player.resume();
    }

    isPlaying = true;
    notifyListeners();
  }

  void pause() {
    _player.pause();
    isPlaying = false;
    notifyListeners();
  }

  void togglePlay() async {
    if (isPlaying) {
      pause();
      return;
    }

    if (position == Duration.zero) {
      if (audioFilePath != null) {
        await _player.play(DeviceFileSource(audioFilePath!));
        isPlaying = true;
        notifyListeners();
        return;
      }
    }

    // If paused in middle → resume
    play();
  }

  Future<void> seek(Duration pos) async {
    await _player.seek(pos);
    position = pos;
    notifyListeners();
  }

  void reset() async {
    if (audioFilePath == null) return;

    await _player.stop();
    await _player.seek(Duration.zero);

    isPlaying = false;
    hasTrack = false;

    position = Duration.zero;

    pcmSamples = [];
    pcmFilePath = null;

    audioFilePath = null;
    imagePath = null;

    notifyListeners();
  }

  void rewind() async {
    if (audioFilePath == null) return;

    await _player.pause();
    await _player.seek(Duration.zero);

    isPlaying = false;
    position = Duration.zero;

    notifyListeners();
  }

  void closePlayer() async {
    await _player.pause();
    isPlaying = false;
    hasTrack = false;
    isPlayerVisible = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
