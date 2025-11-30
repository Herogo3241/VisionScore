import 'dart:isolate';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

void yuvEntryPoint(SendPort initialReplyTo) {
  final port = ReceivePort();
  initialReplyTo.send(port.sendPort);

  port.listen((msg) {
    final CameraImage image = msg[0];
    final SendPort reply = msg[1];

    try {
      reply.send(_convert(image));
    } catch (_) {
      reply.send(null);
    }
  });
}

Uint8List _convert(CameraImage image) {
  final width = image.width;
  final height = image.height;

  final Y = image.planes[0];
  final U = image.planes[1];
  final V = image.planes[2];

  final rgb = img.Image(width: width, height: height);

  for (int y = 0; y < height; y++) {
    final uvRow = (y ~/ 2) * U.bytesPerRow;
    for (int x = 0; x < width; x++) {
      final yp = y * Y.bytesPerRow + x;
      final uvp = uvRow + (x ~/ 2) * U.bytesPerPixel!;

      final Yv = Y.bytes[yp];
      final Uv = U.bytes[uvp];
      final Vv = V.bytes[uvp];

      int r = (Yv + 1.370705 * (Vv - 128)).toInt();
      int g = (Yv - 0.698001 * (Vv - 128) - 0.337633 * (Uv - 128)).toInt();
      int b = (Yv + 1.732446 * (Uv - 128)).toInt();

      rgb.setPixelRgb(x, y, r.clamp(0, 255),
          g.clamp(0, 255), b.clamp(0, 255));
    }
  }

  return Uint8List.fromList(img.encodeJpg(rgb, quality: 70));
}
