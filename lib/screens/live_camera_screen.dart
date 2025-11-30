import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vision_score/services/live_audio.dart';
import 'package:vision_score/utils/model/extract_params.dart';

// Add this new function
Future<Uint8List?> convertYuvToModelInput(Map<String, dynamic> data) async {
  try {
    final width = data['width'] as int;
    final height = data['height'] as int;
    final yBytes = data['plane0'] as Uint8List;
    final uBytes = data['plane1'] as Uint8List;
    final vBytes = data['plane2'] as Uint8List;
    final yRowStride = data['yRowStride'] as int;
    final uvRowStride = data['uvRowStride'] as int;
    final uvPixelStride = data['uvPixelStride'] as int;

    // TARGET SIZE: Change this to exactly what your model expects (e.g. 224)
    const int targetSize = 224; 
    
    // Create a buffer for the raw RGB data (targetSize * targetSize * 3 bytes)
    final outputBytes = Uint8List(targetSize * targetSize * 3);
    
    // Calculate scaling factors to resize "on the fly" (Nearest Neighbor)
    final double scaleX = width / targetSize;
    final double scaleY = height / targetSize;

    int pixelIndex = 0;

    for (int y = 0; y < targetSize; y++) {
      for (int x = 0; x < targetSize; x++) {
        final sourceX = (x * scaleX).toInt();
        final sourceY = (y * scaleY).toInt();

        final uvRow = (sourceY ~/ 2) * uvRowStride;
        final yp = sourceY * yRowStride + sourceX;
        final uvp = uvRow + (sourceX ~/ 2) * uvPixelStride;

        final Yv = yBytes[yp];
        final Uv = uBytes[uvp];
        final Vv = vBytes[uvp];

        int r = (Yv + 1.370705 * (Vv - 128)).toInt();
        int g = (Yv - 0.698001 * (Vv - 128) - 0.337633 * (Uv - 128)).toInt();
        int b = (Yv + 1.732446 * (Uv - 128)).toInt();

        // Write directly to our small output buffer
        outputBytes[pixelIndex++] = r.clamp(0, 255);
        outputBytes[pixelIndex++] = g.clamp(0, 255);
        outputBytes[pixelIndex++] = b.clamp(0, 255);
      }
    }
    return outputBytes;
  } catch (e) {
    print("Conversion error: $e");
    return null;
  }
}

class LiveCameraScreen extends StatefulWidget {
  final ExtractParams extractor;
  const LiveCameraScreen({super.key, required this.extractor});

  @override
  State<LiveCameraScreen> createState() => _LiveCameraScreenState();
}

class _LiveCameraScreenState extends State<LiveCameraScreen> {
  CameraController? cam;
  bool running = false;

  Map<String, dynamic>? lastParams;
  int lastUpdate = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    cam?.dispose();
    LiveAudio.stop();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    cam = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await cam!.initialize();
    await cam!.startImageStream(_onFrame);

    setState(() {});
  }

  bool isProcessing = false; 

  void _onFrame(CameraImage img) async {
   
    if (!running || isProcessing) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastUpdate < 120) return;

  
    isProcessing = true;
    lastUpdate = now;

    try {
      final rawData = {
        'width': img.width,
        'height': img.height,
        // Clone the bytes lists so they are safe to pass
        'plane0': img.planes[0].bytes,
        'plane1': img.planes[1].bytes,
        'plane2': img.planes[2].bytes,
        'yRowStride': img.planes[0].bytesPerRow,
        'uvRowStride': img.planes[1].bytesPerRow,
        'uvPixelStride': img.planes[1].bytesPerPixel,
      };


      final bytes = await compute(convertYuvToModelInput, rawData);

      if (bytes == null) {
        isProcessing = false;
        return;
      }

 
      final params = await widget.extractor.extractParamsRaw(bytes);

      if (mounted) {
        setState(() => lastParams = params);
      }

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
      print("Live extract failed: $e");
    } finally {
      isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Live Camera Mode"),
      ),
      body: cam == null || !cam!.value.isInitialized
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: cam!.value.aspectRatio,
                    child: CameraPreview(cam!),
                  ),
                ),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1E28),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                  ),
                  child: lastParams == null
                      ? const Text(
                          "Waiting for live data...",
                          style: TextStyle(color: Colors.white54),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(
                              "Tempo",
                              lastParams!["tempo"].toStringAsFixed(1),
                            ),
                            _label(
                              "Mood",
                              lastParams!["mood"].toStringAsFixed(2),
                            ),
                            _label(
                              "Rhythm",
                              lastParams!["rhythm"].toStringAsFixed(2),
                            ),
                            _label(
                              "Perc Level",
                              lastParams!["percLevel"].toStringAsFixed(2),
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: lastParams!["mood"],
                              backgroundColor: Colors.white12,
                              color: Colors.pinkAccent,
                            ),
                          ],
                        ),
                ),

                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: running
                                ? Colors.red
                                : Colors.greenAccent,
                          ),
                          onPressed: running ? stopLive : startLive,
                          child: Text(
                            running ? "Stop Live Mode" : "Start Live Mode",
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _label(String name, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        "$name: $val",
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  Future<void> startLive() async {
    await LiveAudio.start();
    setState(() => running = true);
  }

  Future<void> stopLive() async {
    await LiveAudio.stop();
    setState(() => running = false);
  }
}
