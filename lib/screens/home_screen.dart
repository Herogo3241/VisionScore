import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onPickImage;

  const HomeScreen({super.key, required this.onPickImage});

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;


    final isPortrait = orientation == Orientation.portrait;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          "VisionScore",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0D16),
              Color(0xFF131A29),
            ],
          ),
        ),

        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: isPortrait
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [

                        const SizedBox(height: 40),

                        // Glow Icon
                        Center(
                          child: Container(
                            padding: EdgeInsets.all(
                              isPortrait ? 32 : 20,
                            ),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.blueAccent.withOpacity(0.35),
                                  Colors.transparent,
                                ],
                                radius: 0.8,
                              ),
                            ),
                            child: Icon(
                              LucideIcons.audioWaveform,
                              color: Colors.white,
                              size: isPortrait ? 80 : 60,
                            ),
                          ),
                        ),

                        SizedBox(height: isPortrait ? 24 : 12),

                        // Title
                        const Text(
                          "Turn Images Into Music",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "AI-powered audio generation\nfrom your photos",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 15,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: isPortrait ? 40 : 20),

                        // Generate Button
                        GestureDetector(
                          onTap: onPickImage,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5A5CFF),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(LucideIcons.image, color: Colors.white),
                                SizedBox(width: 12),
                                Text(
                                  "Choose Image",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Live Mode Button
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, "/live"),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 20,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white30,
                                width: 1.2,
                              ),
                              color: Colors.white.withOpacity(0.05),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(LucideIcons.camera, color: Colors.white),
                                SizedBox(width: 12),
                                Text(
                                  "Live Mode",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
