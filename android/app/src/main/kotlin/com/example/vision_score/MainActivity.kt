package com.example.vision_score

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val bridge = NativeBridge()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "audio_channel"
        ).setMethodCallHandler { call, result ->

            when (call.method) {
                "generateAudio" -> {
                    val args = call.arguments as Map<*, *>

                    val audio = bridge.generateAudio(
                        (args["duration"] as Double).toFloat(),
                        (args["tempo"] as Double).toFloat(),
                        args["keyIndex"] as Int,
                        args["isMinor"] as Boolean,
                        (args["mood"] as Double).toFloat(),
                        (args["rhythm"] as Double).toFloat(),
                        args["pattern"] as Int,
                        (args["perc"] as Double).toFloat()
                    )

                    result.success(audio.toList())
                }


                "startLive" -> {
                    try {
                        bridge.startLiveMode()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERR", e.toString(), null)
                    }
                }


                "stopLive" -> {
                    bridge.stopLiveMode()
                    result.success(true)
                }


                "updateLiveParams" -> {
                    val args = call.arguments as Map<*, *>

                    bridge.updateLiveParams(
                        (args["tempo"] as Double).toFloat(),
                        (args["keyIndex"] as Int),
                        (args["isMinor"] as Boolean),
                        (args["mood"] as Double).toFloat(),
                        (args["rhythm"] as Double).toFloat(),
                        (args["patternId"] as Int),
                        (args["percLevel"] as Double).toFloat()
                    )

                    result.success(true)
                }





                else -> result.notImplemented()
            }
        }
    }
}
