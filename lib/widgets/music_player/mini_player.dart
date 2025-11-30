import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vision_score/controller/player_controller.dart';
import 'package:vision_score/widgets/audio_visualizer.dart';

class MiniPlayer extends StatelessWidget {
  final PlayerController controller;
  final VoidCallback onTap;
  final VoidCallback? onClose;

  const MiniPlayer({
    super.key,
    required this.controller,
    required this.onTap,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = controller.imagePath != null &&
        File(controller.imagePath!).existsSync();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1E28), Color(0xFF121520)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A5CFF).withOpacity(0.25),
              blurRadius: 25,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(color: Colors.transparent),
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 10),

                  // --- Album Art ---
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 48,
                      height: 48,
                      color: Colors.white.withOpacity(0.08),
                      child: hasImage
                          ? Image.file(
                              File(controller.imagePath!),
                              fit: BoxFit.cover,
                            )
                          : const Icon(
                              LucideIcons.music,
                              color: Colors.white70,
                              size: 20,
                            ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // --- Visualizer ---
                  Expanded(
                    child: SizedBox(
                      height: 72,
                      child: WaveformVisualizer(
                        samples: controller.getCurrentPCMWindow(),
                        barCount: 50,
                        barWidth: 3,
                        barSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // --- Play/Pause ---
                  IconButton(
                    onPressed: controller.togglePlay,
                    icon: Icon(
                      controller.isPlaying
                          ? LucideIcons.pause
                          : LucideIcons.play,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),

                  // --- Close ---
                  if (onClose != null)
                    IconButton(
                      onPressed: onClose,
                      icon: Icon(
                        LucideIcons.x,
                        color: Colors.white70,
                        size: 22,
                      ),
                    ),

                  const SizedBox(width: 6),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
