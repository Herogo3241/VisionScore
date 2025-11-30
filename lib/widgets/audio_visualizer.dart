import 'package:flutter/material.dart';
import 'dart:math';

class SmoothValueList {
  final double riseSpeed;
  final double fallSpeed;
  List<double> values = [];

  SmoothValueList({this.riseSpeed = 0.25, this.fallSpeed = 0.20});

  List<double> smooth(List<double> newValues) {
    // Resize internal list if needed
    if (values.length != newValues.length) {
      values = List.filled(newValues.length, 0.0);
    }

    for (int i = 0; i < newValues.length; i++) {
      double target = newValues[i];

      if (target > values[i]) {
        values[i] += (target - values[i]) * riseSpeed;
      } else {
        values[i] += (target - values[i]) * fallSpeed;
      }
    }

    return values;
  }
}

class WaveformVisualizer extends StatelessWidget {
  final List<double> samples;
  final Color color;
  final double barWidth;
  final double barSpacing;
  final int barCount;

  const WaveformVisualizer({
    super.key,
    required this.samples,
    this.color = Colors.white,
    this.barWidth = 3,
    this.barSpacing = 2,
    this.barCount = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WavePainter(
        samples,
        color,
        barWidth,
        barSpacing,
        barCount,
      ),
      size: Size(double.infinity, 60),
    );
  }
}

class _WavePainter extends CustomPainter {
  final List<double> samples;
  final Color color;
  final double barWidth;
  final double barSpacing;
  final int barCount;

  static SmoothValueList smoother = SmoothValueList();

  _WavePainter(
    this.samples,
    this.color,
    this.barWidth,
    this.barSpacing,
    this.barCount,
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    final sliceSize = samples.length ~/ barCount;

    List<double> peaks = List.generate(barCount, (i) {
      int start = (i * sliceSize).clamp(0, samples.length - 1);
      int end = ((i + 1) * sliceSize).clamp(0, samples.length - 1);
      return samples.sublist(start, end).map((e) => e.abs()).fold(0.0, max);
    });

    // Smooth the peaks
    List<double> smoothed = smoother.smooth(peaks);

    for (int i = 0; i < barCount; i++) {
      final barHeight = smoothed[i] * size.height;

      final x = i * (barWidth + barSpacing);
      final y1 = size.height / 2 - barHeight / 2;
      final y2 = size.height / 2 + barHeight / 2;

      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  @override
  bool shouldRepaint(_) => true;
}




class CircularWaveform extends StatelessWidget {
  final List<double> samples;
  final double size;
  final double strokeWidth;
  final Color color;
  final int pointCount;

  const CircularWaveform({
    super.key,
    required this.samples,
    this.size = 250,
    this.strokeWidth = 3,
    this.color = Colors.white,
    this.pointCount = 180, 
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CircularWaveformPainter(
        samples,
        strokeWidth,
        color,
        pointCount,
      ),
    );
  }
}

class _CircularWaveformPainter extends CustomPainter {
  final List<double> samples;
  final double strokeWidth;
  final Color color;
  final int pointCount;

  static SmoothValueList smoother = SmoothValueList();

  _CircularWaveformPainter(
    this.samples,
    this.strokeWidth,
    this.color,
    this.pointCount,
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;
    final angleStep = (2 * pi) / pointCount;

    // Extract amplitude values
    List<double> peaks = List.generate(pointCount, (i) {
      int index = (samples.length * (i / pointCount)).floor();
      return samples[index.clamp(0, samples.length - 1)].abs();
    });


    final smoothPeaks = smoother.smooth(peaks);

    for (int i = 0; i < pointCount; i++) {
      final amp = smoothPeaks[i];
      final theta = angleStep * i;

      double barLength = 120;
      double dynamicRadius = radius + (amp * barLength);

      final xInner = center.dx + radius * cos(theta);
      final yInner = center.dy + radius * sin(theta);

      final xOuter = center.dx + dynamicRadius * cos(theta);
      final yOuter = center.dy + dynamicRadius * sin(theta);

      canvas.drawLine(
        Offset(xInner, yInner),
        Offset(xOuter, yOuter),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => true;
}

