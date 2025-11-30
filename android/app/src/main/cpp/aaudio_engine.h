#pragma once
#include <aaudio/AAudio.h>

class AAudioEngine {
public:
    ~AAudioEngine();
    bool start();
    void stop();

    void generateRealtime(float* output, int frames);

    static aaudio_data_callback_result_t dataCallback(
            AAudioStream* stream,
            void* userData,
            void* audioData,
            int32_t numFrames);

private:
    AAudioStream* stream = nullptr;
};
