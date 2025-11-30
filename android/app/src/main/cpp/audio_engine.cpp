#include "audio_engine.h"
#include <vector>
#include <cmath>
#include <algorithm>
#include <cstdlib>
#include <iostream>








static inline float clampf(float v, float lo, float hi) {
    return std::max(lo, std::min(hi, v));
}


std::vector<float> adsr(int length, float mood) {
    std::vector<float> env(length, 0.0f);
    if (length <= 0) return env;

    int a = length * 0.1f;
    int d = length * 0.1f;
    float s = 0.7f + mood * 0.2f;
    int r = length * 0.2f;
    int s_len = length - (a + d + r);
    if (s_len < 0) s_len = 0;

    int idx = 0;

    // Attack
    for (int i = 0; i < a; i++)
        env[idx++] = (float)i / a;

    // Decay
    for (int i = 0; i < d; i++)
        env[idx++] = 1.0f - (1.0f - s) * (float)i / d;

    // Sustain
    for (int i = 0; i < s_len; i++)
        env[idx++] = s;

    // Release
    for (int i = 0; i < r; i++) {
        float start = (idx > 0 ? env[idx - 1] : s);
        env[idx++] = start * (1.0f - (float)i / r);
    }

    return env;
}


inline std::vector<float> sine(float freq, int length) {
    std::vector<float> out(length);
    for (int i = 0; i < length; i++) {
        float t = (float)i / SAMPLE_RATE;
        out[i] = sinf(2.0f * M_PI * freq * t);
    }
    return out;
}

inline std::vector<float> tri(float freq, int length) {
    std::vector<float> out(length);
    for (int i = 0; i < length; i++) {
        float t = (float)i / SAMPLE_RATE;
        out[i] = fabsf(fmodf(freq * t, 1.0f) * 2.0f - 1.0f) * 2.0f - 1.0f;
    }
    return out;
}

inline std::vector<float> saw(float freq, int length) {
    std::vector<float> out(length);
    for (int i = 0; i < length; i++) {
        float t = (float)i / SAMPLE_RATE;
        out[i] = 2.0f * (fmodf(freq * t, 1.0f)) - 1.0f;
    }
    return out;
}


std::vector<float> lowpass(const std::vector<float>& x, float alpha) {
    if (x.empty()) return {};
    std::vector<float> out(x.size());
    out[0] = x[0];
    for (size_t i = 1; i < x.size(); i++)
        out[i] = alpha * x[i] + (1 - alpha) * out[i - 1];
    return out;
}


std::vector<float> simple_reverb(const std::vector<float>& x, float decay, int delay) {
    int n = x.size();
    std::vector<float> out(n);


    for (int i = 0; i < n; i++)
        out[i] = x[i];

   
    for (int i = delay; i < n; i++)
        out[i] += x[i - delay] * decay;

    return out;
}


std::vector<float> karplus_strong(float freq, int length) {
    int N = (int)(SAMPLE_RATE / freq);
    if (N < 2) N = 2;

    std::vector<float> buffer(N);
    std::vector<float> out(length);

   
    for (int i = 0; i < N; i++)
        buffer[i] = (rand() / (float)RAND_MAX) * 2.0f - 1.0f;

    int idx = 0;
    for (int i = 0; i < length; i++) {
        float next = 0.5f * (buffer[idx] + buffer[(idx + 1) % N]);
        buffer[idx] = next;

        out[i] = next;
        idx = (idx + 1) % N;
    }

    return out;
}

std::vector<float> add_shimmer(int length, float mood) {
    std::vector<float> out(length);

    float brightness = 0.2f + 0.6f * mood;   // brighter on happy mood
    float speed = 0.00005f + mood * 0.00005f;

    float phase = 0.0f;
    for (int i = 0; i < length; i++) {

        float n = ((float)rand() / RAND_MAX - 0.5f) * 2.0f;


        float lfo = 0.5f + 0.5f * sinf(phase);

        out[i] = n * brightness * lfo * 0.1f; 

        phase += speed;
    }


    out = lowpass(out, 0.15f);

    return out;
}


std::vector<float> add_arpeggio(float* scale, int numSamples, float tempo, float mood) {
    std::vector<float> out(numSamples, 0.0f);

    float bps = tempo / 60.0f;
    int noteLen = (int)(SAMPLE_RATE / (bps * 4)); 
    int idx = 0;
    int step = 0;

    while (idx < numSamples) {
        float freq = scale[(step % 7)] * 2.0f; 
        int nl = std::min(noteLen, numSamples - idx);

        auto wave = tri(freq, nl);
        auto env  = adsr(nl, mood);

        for (int i = 0; i < nl; i++)
            out[idx + i] += wave[i] * env[i] * 0.2f; 

        idx += nl;
        step++;
    }

    return lowpass(out, 0.25f); 
}

std::vector<float> kick(int length) {
    std::vector<float> out(length);
    float freq = 100.0f;
    float decay = 0.00025f;

    float phase = 0.0f;
    float amp = 1.0f;

    for (int i = 0; i < length; i++) {
        float t = (float)i / SAMPLE_RATE;


        float f = freq * expf(-t * 15.0f);

        phase += 2.0f * M_PI * f / SAMPLE_RATE;
        float tone = sinf(phase);


        amp = expf(-t * 30.0f);

        out[i] = tone * amp;
    }

    return out;
}

std::vector<float> snare(int length) {
    std::vector<float> out(length);

    for (int i = 0; i < length; i++) {
        float t = (float)i / SAMPLE_RATE;


        float noise = ((rand() / (float)RAND_MAX) * 2.0f - 1.0f);
        float tone  = sinf(2.0f * M_PI * 180.0f * t);


        float env = expf(-t * 40.0f);

        out[i] = (tone * 0.3f + noise * 0.7f) * env;
    }

    return lowpass(out, 0.2f);
}

std::vector<float> hihat(int length) {
    std::vector<float> out(length);

    for (int i = 0; i < length; i++) {
        float t = (float)i / SAMPLE_RATE;


        float n = ((rand() / (float)RAND_MAX) * 2.0f - 1.0f);


        float env = expf(-t * 100.0f);

        out[i] = n * env * 0.6f;
    }

    return lowpass(out, 0.15f);
}



std::vector<int16_t> generate_music(
        float duration,
        float tempo,
        int keyIndex,
        bool isMinor,
        float mood,
        float rhythm,
        int patternId,
        float percLevel
) {
    const float durationSec = duration;
    const int numSamples = (int)(SAMPLE_RATE * durationSec);


    int majorScale[7] = {0, 2, 4, 5, 7, 9, 11};
    int minorScale[7] = {0, 2, 3, 5, 7, 8, 10};
    int* intervals = isMinor ? minorScale : majorScale;

    float baseC = 261.63f;
    float root = baseC * powf(2.0f, keyIndex / 12.0f);

    float scale[7];
    for (int i = 0; i < 7; i++) {
        int st = intervals[i];
        scale[i] = root * powf(2.0f, st / 12.0f);
    }


    std::vector<float> mel(numSamples, 0.0f);

    float bps = tempo / 60.0f;
    int beatLen = (int)(SAMPLE_RATE / bps);
    int notesPerBeat = (int)(1 + rhythm * 3.0f);
    int noteLen = std::max(200, beatLen / std::max(1, notesPerBeat));

    int patterns[12][4] = {
        {0, 2, 4, 5}, {5, 3, 2, 0}, {0, 4, 6, 3}, {6, 5, 3, 2},
        {1, 3, 5, 6}, {6, 4, 1, 0}, {2, 5, 1, 4}, {0, 3, 6, 4},
        {4, 1, 2, 6}, {3, 0, 5, 2}, {1, 6, 4, 2}, {4, 2, 0, 3}
    };
    int* pat = patterns[patternId % 12];

    int idx = 0;
    int pi = 0;
    while (idx < numSamples) {
        float octave = (rand() % 3 - 1); // -1,0,1
        float freq = scale[pat[pi % 4]] * powf(2.0f, octave);

        int nl = std::min(noteLen, numSamples - idx);

        auto s1 = sine(freq, nl);
        auto s2 = saw(freq, nl);
        auto s3 = tri(freq * 2, nl);
        auto env = adsr(nl, mood);

        for (int i = 0; i < nl; i++) {
            float tone =
                s1[i] * 0.7f +
                s2[i] * 0.3f * (0.3f + mood * 0.7f) +
                s3[i] * 0.2f * (1.0f - mood);

            mel[idx + i] += tone * env[i] * (0.4f + 0.4f * mood);
        }

        idx += nl;
        pi++;
    }

    mel = lowpass(mel, 0.2f);
    mel = simple_reverb(mel, 0.4f, (int)(0.12f * SAMPLE_RATE));


    std::vector<float> bass(numSamples, 0.0f);
    int bass_len = beatLen * 2;
    float bassFreq = scale[0] / 2.0f;

    int bIdx = 0;
    while(bIdx < numSamples){
        int nl = std::min(bass_len, numSamples - bIdx);

        auto w = sine(bassFreq, nl);
        auto env = adsr(nl, mood);

        for(int i = 0; i < nl; i++)
            bass[bIdx + i] += w[i] * env[i] * 0.3f;

        bIdx += bass_len;
    }

    bass = lowpass(bass, 0.1f);


    std::vector<float> perc(numSamples, 0.0f);
    int hitLen = std::max(400, beatLen / 3);

    for(int i = 0; i < numSamples; i += beatLen){
        if (rand() / (float)RAND_MAX < percLevel) {

            int nl = std::min(hitLen, numSamples - i);
            std::vector<float> drum;


            int type = rand() % 3;  

            if (type == 0) drum = kick(nl);
            if (type == 1) drum = snare(nl);
            if (type == 2) drum = hihat(nl);

            for (int j = 0; j < nl; j++)
                perc[i + j] += drum[j] * 0.9f;
        }
    }


    perc = simple_reverb(perc, 0.3f, (int)(0.12f * SAMPLE_RATE));


    std::vector<float> mix(numSamples);
    for (int i = 0; i < numSamples; i++)
        mix[i] = mel[i] + bass[i] + perc[i];

    float maxAbs = 0.000001f;
    for (float f : mix)
        maxAbs = std::max(maxAbs, fabsf(f));

    for (float& f : mix)
        f /= maxAbs;

    auto shimmer = add_shimmer(numSamples, mood);
    for (int i = 0; i < numSamples; i++)
        mix[i] += shimmer[i] * 0.3f;

    auto arp = add_arpeggio(scale, numSamples, tempo, mood);
    for (int i = 0; i < numSamples; i++)
        mix[i] += arp[i] * 0.25f;




    const int shift = 200;
    std::vector<float> left(numSamples), right(numSamples);

    float panPhase = 0.0f;
    float panSpeed = 0.00015f + mood * 0.0001f;  

    for (int i = 0; i < numSamples; i++) {

        float base   = mix[i];
        float ahead  = (i + shift < numSamples) ? mix[i + shift] : 0.0f;
        float behind = (i - shift >= 0)        ? mix[i - shift] : 0.0f;

   
        float L = base * 0.9f + ahead  * 0.1f;
        float R = base * 0.9f + behind * 0.1f;

 
        float pan = sinf(panPhase);
        panPhase += panSpeed;

        float panL = 1.0f - 0.4f * pan;
        float panR = 1.0f + 0.4f * pan;


        left[i]  = L * panL;
        right[i] = R * panR;
    }


    float maxLR = 0.000001f;
    for (int i = 0; i < numSamples; i++) {
        maxLR = std::max(maxLR, fabsf(left[i]));
        maxLR = std::max(maxLR, fabsf(right[i]));
    }


    std::vector<int16_t> pcm(numSamples * 2);
    for (int i = 0; i < numSamples; i++) {
        pcm[2*i]     = (int16_t)(left[i]  / maxLR * 32767);
        pcm[2*i + 1] = (int16_t)(right[i] / maxLR * 32767);
    }

    


    return pcm;
}


LiveParams gLive;
bool gLiveMode = false;


void startLiveMode() {
    gLiveMode = true;
    gLive.sampleIndex = 0;

    // set smoothed values initially
    gLive.curTempo  = gLive.tempo;
    gLive.curMood   = gLive.mood;
    gLive.curRhythm = gLive.rhythm;
    gLive.curPerc   = gLive.percLevel;
}


void stopLiveMode() {
    gLiveMode = false;
    gLive.sampleIndex = 0;
}



static inline float smoothParam(float cur, float target, float amt = 0.02f) {
    return cur + (target - cur) * amt;
}



void updateLiveParams(
    float tempo,
    int keyIndex,
    bool isMinor,
    float mood,
    float rhythm,
    int patternId,
    float percLevel
) {
    gLive.tempo = tempo;
    gLive.keyIndex = keyIndex;
    gLive.isMinor = isMinor;
    gLive.mood = mood;
    gLive.rhythm = rhythm;
    gLive.patternId = patternId;
    gLive.percLevel = percLevel;
}


void generateLiveFrame(float* outStereo, int frames) {

    if (!gLiveMode) {
        // Output silence
        for (int i = 0; i < frames * 2; i++)
            outStereo[i] = 0.0f;
        return;
    }


    gLive.curTempo  = smoothParam(gLive.curTempo,  gLive.tempo);
    gLive.curMood   = smoothParam(gLive.curMood,   gLive.mood);
    gLive.curRhythm = smoothParam(gLive.curRhythm, gLive.rhythm);
    gLive.curPerc   = smoothParam(gLive.curPerc,   gLive.percLevel);

    float tempo  = gLive.curTempo;
    float mood   = gLive.curMood;
    float rhythm = gLive.curRhythm;
    float perc   = gLive.curPerc;


    float bps = tempo / 60.0f;
    float beatLen = SAMPLE_RATE / bps;

    int majorScale[7] = {0,2,4,5,7,9,11};
    int minorScale[7] = {0,2,3,5,7,8,10};
    int* intervals = gLive.isMinor ? minorScale : majorScale;

    float baseC = 261.63f;
    float root  = baseC * powf(2.0f, gLive.keyIndex / 12.0f);

    float scale[7];
    for (int i = 0; i < 7; i++)
        scale[i] = root * powf(2.0f, intervals[i] / 12.0f);

    
    int patterns[12][4] = {
        {0,2,4,5},{5,3,2,0},{0,4,6,3},{6,5,3,2},
        {1,3,5,6},{6,4,1,0},{2,5,1,4},{0,3,6,4},
        {4,1,2,6},{3,0,5,2},{1,6,4,2},{4,2,0,3}
    };

    int* pat = patterns[gLive.patternId % 12];


    for (int i = 0; i < frames; i++) {

        float t = (float)gLive.sampleIndex / SAMPLE_RATE;

       
        int noteIdx = pat[(int)(gLive.sampleIndex / beatLen) % 4];
        float freq = scale[noteIdx];

        
        float osc = sinf(2.0f * M_PI * freq * t);

        
        float shimmer = ((rand() / (float)RAND_MAX) - 0.5f) * 0.05f * mood;

        
        float drum = 0.0f;
        if ((gLive.sampleIndex % (int)beatLen) < 300) {
            drum = ((rand()/(float)RAND_MAX) - 0.5f) * perc;
        }

        float mix = osc * 0.5f + shimmer + drum;

        
        float pan = sinf(t * 2.0f);
        float L = mix * (1.0f - 0.35f * pan);
        float R = mix * (1.0f + 0.35f * pan);

        outStereo[i*2]     = L;
        outStereo[i*2 + 1] = R;

        gLive.sampleIndex++;
    }
}



