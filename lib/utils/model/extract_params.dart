import 'dart:typed_data';
import 'package:image/image.dart' as img; // Add this back for Gallery mode
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:vision_score/services/app_settings.dart';

class ExtractParams {
  late final Interpreter _featOpt;
  late final Interpreter _mlpOpt;
  late final Interpreter _featUnopt;
  late final Interpreter _mlpUnopt;
  
  final int inputSize;
  bool useOptimized = AppSettings.useOptimized;

  late Float32List _inputBuffer;

  ExtractParams({
    this.inputSize = 224,
  }) {
    _inputBuffer = Float32List(inputSize * inputSize * 3);
  }

  Future<void> init() async {
    final options = InterpreterOptions()..threads = 2;
    _featOpt = await Interpreter.fromAsset("assets/model/feature_model.tflite", options: options);
    _featUnopt = await Interpreter.fromAsset("assets/model/feature_model_unopt.tflite", options: options);
    _mlpOpt = await Interpreter.fromAsset("assets/model/music_model.tflite");
    _mlpUnopt = await Interpreter.fromAsset("assets/model/music_model_unopt.tflite");
  }


  Future<Map<String, dynamic>> extractParamsFromImage(Uint8List imageFileBytes) async {

    final img.Image? decoded = img.decodeImage(imageFileBytes);
    if (decoded == null) throw Exception("Image decode failed");


    final img.Image resized = img.copyResize(decoded, width: inputSize, height: inputSize);

    final rawRgb = Uint8List(inputSize * inputSize * 3);
    int index = 0;
    

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);
   

        rawRgb[index++] = pixel.r.toInt();
        rawRgb[index++] = pixel.g.toInt();
        rawRgb[index++] = pixel.b.toInt();
      }
    }

    // Pass the clean data to the raw extractor
    return extractParamsRaw(rawRgb);
  }


  Future<Map<String, dynamic>> extractParamsRaw(Uint8List rgbBytes) async {
    final featModel = useOptimized ? _featOpt : _featUnopt;
    final musicModel = useOptimized ? _mlpOpt : _mlpUnopt;

    if (rgbBytes.length != _inputBuffer.length) {
      return {}; 
    }

    for (int i = 0; i < rgbBytes.length; i++) {
      _inputBuffer[i] = rgbBytes[i].toDouble();
    }

    final featOutBuffer = Float32List(64);
    
    final t0 = DateTime.now().millisecondsSinceEpoch; 
    featModel.run(_inputBuffer.buffer, featOutBuffer.buffer);
    final t1 = DateTime.now().millisecondsSinceEpoch;
    
    final featMs = t1 - t0;

  
    final musicOutBuffer = Float32List(7);
    
    final t2 = DateTime.now().millisecondsSinceEpoch;
    musicModel.run(featOutBuffer.buffer, musicOutBuffer.buffer);
    final t3 = DateTime.now().millisecondsSinceEpoch;
    
    final musicMs = t3 - t2;

    return {
      "tempo": musicOutBuffer[0],
      "keyIndex": musicOutBuffer[1].round().clamp(0, 11),
      "isMinor": (musicOutBuffer[2] > 0.5) ? 1 : 0,
      "mood": musicOutBuffer[3].clamp(0.0, 1.0),
      "rhythm": musicOutBuffer[4].clamp(0.0, 1.0),
      "patternId": musicOutBuffer[5].round().clamp(0, 3),
      "percLevel": musicOutBuffer[6].clamp(0.0, 1.0),
      "feat_ms": featMs,  
      "music_ms": musicMs,
    };
  }
}