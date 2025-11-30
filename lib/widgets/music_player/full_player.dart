import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vision_score/controller/player_controller.dart';
import 'package:vision_score/utils/helper/permission_handler.dart';
import 'package:vision_score/widgets/audio_visualizer.dart';

class FullPlayerScreen extends StatelessWidget {
  final PlayerController controller;

  const FullPlayerScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Scaffold(
          backgroundColor: const Color(0xFF0D0F14),

          body: SafeArea(
            child: Column(
              children: [
                // ---- TOP BAR ----
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        LucideIcons.chevronDown,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.download,
                        color: Colors.white70,
                      ),
                      onPressed: () async {
                        await requestStoragePermission();
                        final path = await controller.downloadTrack();
                        if (path != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${controller.trackTitle} saved!"),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),

                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // ---- Background Image (blurred) ----
                      if (controller.imagePath != null)
                        Positioned.fill(
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: 2,
                              sigmaY: 2,
                            ),
                            child: Opacity(
                              opacity: 0.60,
                              child: Image.file(
                                File(controller.imagePath!),
                                fit: BoxFit
                                    .contain, // contain → shows borders, cover is better
                              ),
                            ),
                          ),
                        ),

  
                      CircularWaveform(
                        samples: controller.getCurrentPCMWindow(),
                        size: 320,
                        strokeWidth: 6,
                        color: Colors.white,
                        pointCount: 100,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // ---- SEEK BAR ----
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white30,
                          thumbColor: Colors.white,
                          trackHeight: 3,
                        ),
                        child: Slider(
                          value: controller.duration.inMilliseconds == 0
                              ? 0
                              : controller.position.inMilliseconds /
                                    controller.duration.inMilliseconds,
                          onChanged: (v) {
                            final newPos = Duration(
                              milliseconds:
                                  (controller.duration.inMilliseconds * v)
                                      .toInt(),
                            );
                            controller.seek(newPos);
                          },
                        ),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _format(controller.position),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _format(controller.duration),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ---- MAIN CONTROLS ----
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: controller.rewind,
                      icon: const Icon(
                        LucideIcons.rewind,
                        color: Colors.white70,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 30),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: GestureDetector(
                        onTap: controller.togglePlay,
                        child: Icon(
                          controller.isPlaying
                              ? LucideIcons.pause
                              : LucideIcons.play,
                          color: Colors.black,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  String _format(Duration d) {
    if (d.inMilliseconds <= 0) return "00:00";
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }
}
