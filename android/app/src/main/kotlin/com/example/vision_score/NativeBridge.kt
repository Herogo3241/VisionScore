package com.example.vision_score

class NativeBridge {
    companion object {
        init {
            System.loadLibrary("audio_engine")
        }
    }

    external fun generateAudio(
        duration: Float,
        tempo: Float,
        keyIndex: Int,
        isMinor: Boolean,
        mood: Float,
        rhythm: Float,
        pattern: Int,
        perc: Float
    ): ByteArray


    external fun startLiveMode()


    external fun updateLiveParams(
        tempo: Float,
        keyIndex: Int,
        isMinor: Boolean,
        mood: Float,
        rhythm: Float,
        patternId: Int,
        percLevel: Float
    )


    external fun stopLiveMode()
}
