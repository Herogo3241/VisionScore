#include "aaudio_engine.h"
#include "audio_engine.h"
#include <aaudio/AAudio.h>
#include <android/log.h>

#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, "AAUDIO", __VA_ARGS__)

AAudioEngine::~AAudioEngine() {
    stop();
}

bool AAudioEngine::start() {
    if (stream) stop();

    AAudioStreamBuilder* builder = nullptr;
    AAudio_createStreamBuilder(&builder);

    AAudioStreamBuilder_setFormat(builder, AAUDIO_FORMAT_PCM_FLOAT);
    AAudioStreamBuilder_setSampleRate(builder, SAMPLE_RATE);
    AAudioStreamBuilder_setChannelCount(builder, 2);
    AAudioStreamBuilder_setSharingMode(builder, AAUDIO_SHARING_MODE_EXCLUSIVE);
    AAudioStreamBuilder_setPerformanceMode(builder, AAUDIO_PERFORMANCE_MODE_LOW_LATENCY);

    AAudioStreamBuilder_setDataCallback(builder, dataCallback, this);

    aaudio_result_t result = AAudioStreamBuilder_openStream(builder, &stream);
    AAudioStreamBuilder_delete(builder);

    if (result != AAUDIO_OK) {
        LOGE("Failed to open AAudio stream: %d", result);
        return false;
    }

    result = AAudioStream_requestStart(stream);
    if (result != AAUDIO_OK) {
        LOGE("Failed to start AAudio stream: %d", result);
        return false;
    }

    return true;
}

void AAudioEngine::stop() {
    if (!stream) return;

    AAudioStream_requestStop(stream);
    AAudioStream_close(stream);
    stream = nullptr;
}

void AAudioEngine::generateRealtime(float* output, int frames) {
    generateLiveFrame(output, frames);
}

aaudio_data_callback_result_t AAudioEngine::dataCallback(
        AAudioStream*,
        void* userData,
        void* audioData,
        int32_t numFrames
) {
    auto* engine = static_cast<AAudioEngine*>(userData);
    float* out = reinterpret_cast<float*>(audioData);

    engine->generateRealtime(out, numFrames);
    return AAUDIO_CALLBACK_RESULT_CONTINUE;
}
