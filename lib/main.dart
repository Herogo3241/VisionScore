import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:vision_score/controller/player_controller.dart';
import 'package:vision_score/screens/home_screen.dart';
import 'package:vision_score/screens/live_camera_screen.dart';
import 'package:vision_score/screens/settings_screen.dart';
import 'package:vision_score/services/app_settings.dart';
import 'package:vision_score/utils/helper/generate_track_name.dart';
import 'package:vision_score/utils/model/extract_params.dart';

import 'package:vision_score/widgets/music_player/full_player.dart';
import 'package:vision_score/widgets/music_player/mini_player.dart';

import 'utils/dsp/native_audio.dart';
import 'utils/dsp/wav_util.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // lock orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // show splash
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final PlayerController playerController = PlayerController();
  final ImagePicker picker = ImagePicker();

  late ExtractParams extractor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AppSettings.init();

      extractor = ExtractParams();
      await extractor.init();
      FlutterNativeSplash.remove();

      setState(() {});
    });
  }

  Future<void> pickImageAndGenerate() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final imgBytes = await picked.readAsBytes();

    final params = await extractor.extractParamsFromImage(imgBytes);

    // Generate PCM from Native
    final audio = await NativeAudio.generateAudio(
      duration: AppSettings.duration,
      tempo: params["tempo"],
      keyIndex: params["keyIndex"],
      isMinor: params["isMinor"] == 1,
      mood: params["mood"],
      rhythm: params["rhythm"],
      pattern: params["patternId"],
      perc: params["percLevel"],
    );
    final dir = await getTemporaryDirectory();
    final pcm = Uint8List.fromList(audio);
    final pcmFile = File(
      "${dir.path}/generated_${DateTime.now().millisecondsSinceEpoch}.wav",
    );

    pcmFile.writeAsBytes(pcm);

    final wav = pcmToWav(pcm);

    final file = File(
      "${dir.path}/generated_${DateTime.now().millisecondsSinceEpoch}.wav",
    );
    await file.writeAsBytes(wav);

    // Play audio
    await playerController.loadFromFile(
      file.path,
      pcmFile.path,
      image: picked.path,
      title: generateUniqueTrackName(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => Stack(
          children: [
            HomeScreen(onPickImage: pickImageAndGenerate),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: playerController,
                builder: (context, _) {
                  if (!playerController.isPlayerVisible) {
                    return const SizedBox.shrink();
                  }
                  return MiniPlayer(
                    controller: playerController,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FullPlayerScreen(controller: playerController),
                        ),
                      );
                    },
                    onClose: () {
                      playerController.closePlayer();
                    },
                  );
                },
              ),
            ),
          ],
        ),

        '/settings': (context) => SettingsScreen(),

        // LIVE PAGE
        '/live': (context) => LiveCameraScreen(extractor: extractor),
      },
    );
  }

  @override
  void dispose() {
    playerController.dispose();
    super.dispose();
  }
}
