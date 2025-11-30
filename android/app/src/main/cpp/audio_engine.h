#ifndef AUDIO_ENGINE_H
#define AUDIO_ENGINE_H

#include <vector>
#include <cstdint>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

static const int SAMPLE_RATE = 44100;


struct LiveParams {
    float tempo = 90.0f;
    int keyIndex = 0;
    bool isMinor = false;
    float mood = 0.5f;
    float rhythm = 0.5f;
    int patternId = 0;
    float percLevel = 0.5f;


    float curTempo = 90.0f;
    float curMood = 0.5f;
    float curRhythm = 0.5f;
    float curPerc = 0.5f;


    float phaseMel = 0.0f;
    float phaseBass = 0.0f;
    float phasePerc = 0.0f;
    int sampleIndex;
};


extern LiveParams gLive;
extern bool gLiveMode;



std::vector<int16_t> generate_music(
    float duration,
    float tempo,
    int keyIndex,
    bool isMinor,
    float mood,
    float rhythm,
    int patternId,
    float percLevel
);



void startLiveMode();
void stopLiveMode();


void updateLiveParams(
    float tempo,
    int keyIndex,
    bool isMinor,
    float mood,
    float rhythm,
    int patternId,
    float percLevel
);


void generateLiveFrame(float* outStereo, int numFrames);

#endif
