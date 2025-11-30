// native_bridge.cpp
#include <jni.h>
#include "audio_engine.h"
#include "aaudio_engine.h"
#include <android/log.h>

#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, "JNI", __VA_ARGS__)
static AAudioEngine gEngine;

extern "C"
JNIEXPORT jbyteArray JNICALL
Java_com_example_vision_1score_NativeBridge_generateAudio(
        JNIEnv *env,
        jobject /* this */,
        jfloat duration,
        jfloat tempo,
        jint keyIndex,
        jboolean isMinor,
        jfloat mood,
        jfloat rhythm,
        jint patternId,
        jfloat percLevel
) {

    auto pcm = generate_music(
        duration,
        tempo,
        keyIndex,
        isMinor == JNI_TRUE,
        mood,
        rhythm,
        patternId,
        percLevel
    );

    // 2. Calculate sizes
    const jsize sampleCount = static_cast<jsize>(pcm.size());            
    const jsize byteCount   = static_cast<jsize>(pcm.size() * sizeof(int16_t));




    jbyteArray out = env->NewByteArray(byteCount);
    if (!out) {
        return nullptr;
    }

    env->SetByteArrayRegion(
            out,
            0,
            byteCount,
            reinterpret_cast<const jbyte*>(pcm.data())
    );

    return out;
}


extern "C"
JNIEXPORT void JNICALL
Java_com_example_vision_1score_NativeBridge_startLiveMode(
        JNIEnv* env,
        jobject thiz
) {
    startLiveMode();
    if (!gEngine.start()) {
        LOGE("Failed to start AAudio engine!");
    }
}


extern "C"
JNIEXPORT void JNICALL
Java_com_example_vision_1score_NativeBridge_updateLiveParams(
        JNIEnv* env,
        jobject thiz,
        jfloat tempo,
        jint keyIndex,
        jboolean isMinor,
        jfloat mood,
        jfloat rhythm,
        jint patternId,
        jfloat perc
) {
    updateLiveParams(
        tempo,
        keyIndex,
        isMinor == JNI_TRUE,
        mood,
        rhythm,
        patternId,
        perc
    );
}


extern "C"
JNIEXPORT void JNICALL
Java_com_example_vision_1score_NativeBridge_stopLiveMode(
        JNIEnv* env,
        jobject thiz
) {
    stopLiveMode();
    gEngine.stop();
}