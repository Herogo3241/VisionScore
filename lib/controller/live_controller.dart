import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';

import '../utils/model/extract_params.dart';
import '../services/live_audio.dart';
import 'package:image/image.dart' as img;

class LiveController {
  final ExtractParams extractor;
  CameraController? cam;

  bool running = false;

  CameraImage? _latestImage; 
  bool _isProcessing = false; 
  Timer? _processingTimer;

  LiveController(this.extractor);


  Future<void> startCamera(List<CameraDescription> cams) async {
    cam = CameraController(
      cams.first,
      ResolutionPreset.medium, 
      enableAudio: false,
    );

    await cam!.initialize();

   
    await cam!.startImageStream((img) {
      _latestImage = img;
    });
  }


  Future<void> startLive() async {
    running = true;
    await LiveAudio.start();

 
    _processingTimer = Timer.periodic(
      const Duration(milliseconds: 80),
      (_) => _processLatestFrame(),
    );
  }

  Future<void> stopLive() async {
    running = false;
    _processingTimer?.cancel();
    await LiveAudio.stop();
  }


  Future<void> _processLatestFrame() async {
    if (!running) return;
    if (_isProcessing) return;
    if (_latestImage == null) return;

    _isProcessing = true;


    final CameraImage img = _latestImage!;
    _latestImage = null;

    try {
      final Uint8List rgbBytes = await _convertToRGB(img);

      final params = await extractor.extractParamsRaw(rgbBytes);

      // update audio engine
      await LiveAudio.updateParams(
        tempo: params["tempo"],
        keyIndex: params["keyIndex"],
        isMinor: params["isMinor"] == 1,
        mood: params["mood"],
        rhythm: params["rhythm"],
        patternId: params["patternId"],
        percLevel: params["percLevel"],
      );
    } catch (e) {
      print("LiveController error: $e");
    }

    _isProcessing = false;
  }



  Future<Uint8List> _convertToRGB(CameraImage image) async {
    final int width = image.width;
    final int height = image.height;

    // Flutter camera delivers YUV420 with 3 planes
    final Plane yPlane = image.planes[0];
    final Plane uPlane = image.planes[1];
    final Plane vPlane = image.planes[2];

    final int yRowStride = yPlane.bytesPerRow;
    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel!;

    final img.Image rgbImage = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      final int yOffset = y * yRowStride;

      final int uvRow = (y ~/ 2) * uvRowStride;

      for (int x = 0; x < width; x++) {
        final int uvCol = (x ~/ 2) * uvPixelStride;

        final int yp = yOffset + x;

        final int up = uvRow + uvCol;
        final int vp = uvRow + uvCol;

        final int Y = yPlane.bytes[yp];
        final int U = uPlane.bytes[up];
        final int V = vPlane.bytes[vp];

        // Convert YUV → RGB (fast integer math)
        int R = (Y + 1.402 * (V - 128)).round();
        int G = (Y - 0.344136 * (U - 128) - 0.714136 * (V - 128)).round();
        int B = (Y + 1.772 * (U - 128)).round();

        // clamp
        if (R < 0) R = 0;
        if (R > 255) R = 255;
        if (G < 0) G = 0;
        if (G > 255) G = 255;
        if (B < 0) B = 0;
        if (B > 255) B = 255;

        rgbImage.setPixelRgb(x, y, R, G, B);
      }
    }


    return Uint8List.fromList(img.encodePng(rgbImage));
  }
}
