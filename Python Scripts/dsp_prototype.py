import numpy as np
from scipy.io.wavfile import write

# =====================================
# CONFIG
# =====================================
SAMPLE_RATE = 44100
DURATION = 12.0
NUM_SAMPLES = int(SAMPLE_RATE * DURATION)

# =====================================
# PARAMETERS (plug in from model)
# =====================================
tempo_bpm = 107.29
key_index = 3
is_minor = 1
mood = 0.138 
rhythm_complexity = 0.793
melody_pattern_id = 3
percussion_level = 0.678



# =====================================
# SCALES
# =====================================
major = [0,2,4,5,7,9,11]
minor = [0,2,3,5,7,8,10]
intervals = minor if is_minor else major

def get_scale(root=261.63):
    return [root * (2 ** (i/12)) for i in intervals]

scale = get_scale()




# =====================================
# BASIC DSP
# =====================================
def lowpass_filter(x, alpha=0.15):
    """Simple one-pole lowpass filter."""
    y = np.zeros_like(x)
    y[0] = x[0]
    for i in range(1, len(x)):
        y[i] = alpha*x[i] + (1-alpha)*y[i-1]
    return y

def simple_reverb(x, decay=0.4, delay_ms=120):
    delay = int(delay_ms * SAMPLE_RATE / 1000)
    out = np.zeros(len(x) + delay)
    out[:len(x)] += x
    out[delay:delay+len(x)] += x * decay
    return out[:len(x)]

def adsr(length):
    if length <= 0:
        return np.zeros(0)

    a = int(length * 0.1)
    d = int(length * 0.1)
    s = 0.7 + mood * 0.2
    r = int(length * 0.2)
    s_len = length - (a + d + r)
    if s_len < 0:
        s_len = 0

    env = np.zeros(length)
    idx = 0

    if a > 0:
        env[:a] = np.linspace(0, 1, a)
        idx += a

    if d > 0:
        env[idx:idx+d] = np.linspace(1, s, d)
        idx += d

    if s_len > 0:
        env[idx:idx+s_len] = s
        idx += s_len

    if r > 0:
        env[idx:idx+r] = np.linspace(s, 0, r)

    return env

def sine(freq, length):
    t = np.linspace(0, length/SAMPLE_RATE, length, False)
    return np.sin(2*np.pi*freq*t)

def tri(freq, length):
    t = np.linspace(0, length/SAMPLE_RATE, length, False)
    return 2*np.abs(2*(t*freq - np.floor(0.5 + t*freq))) - 1

def saw(freq, length):
    t = np.linspace(0, length/SAMPLE_RATE, length, False)
    return 2 * (t*freq - np.floor(0.5 + t*freq))

def generate_melody():
    mel = np.zeros(NUM_SAMPLES)

    bps = tempo_bpm / 60
    beat_len = int(SAMPLE_RATE / bps)
    notes_per_beat = int(1 + rhythm_complexity * 3)
    note_len = max(200, beat_len // notes_per_beat)

    patterns = [
        [0,2,4,5],
        [5,4,2,0],
        [0,4,6,3],
        [6,3,2,0]
    ]

    pattern = patterns[melody_pattern_id % 4]

    idx = 0
    p = 0

    while idx < NUM_SAMPLES:
        freq = scale[pattern[p % len(pattern)] % len(scale)]
        nl = min(note_len, NUM_SAMPLES - idx)

        # richer synth tone
        wave = (
            0.4*sine(freq, nl) +
            0.3*tri(freq, nl) +
            0.3*saw(freq, nl)
        )

        env = adsr(nl)
        mel[idx:idx+nl] += wave * env * (0.4 + 0.4*mood)

        idx += nl
        p += 1

    mel = lowpass_filter(mel, alpha=0.2)
    mel = simple_reverb(mel, decay=0.4)

    return mel


def generate_bass():
    bass = np.zeros(NUM_SAMPLES)

    bps = tempo_bpm / 60
    beat_len = int(SAMPLE_RATE / bps)
    bass_len = beat_len * 2

    freq = scale[0] / 2  # root, one octave down

    idx = 0
    while idx < NUM_SAMPLES:
        nl = min(bass_len, NUM_SAMPLES - idx)
        note = sine(freq, nl) * adsr(nl)
        bass[idx:idx+nl] += note * 0.3
        idx += bass_len

    bass = lowpass_filter(bass, alpha=0.1)
    return bass


def generate_percussion():
    perc = np.zeros(NUM_SAMPLES)

    bps = tempo_bpm / 60
    beat_len = int(SAMPLE_RATE / bps)

    hit_len = max(400, beat_len // 3)

    for i in range(0, NUM_SAMPLES, beat_len):
        if np.random.rand() < percussion_level:
            nl = min(hit_len, NUM_SAMPLES - i)
            noise = np.random.randn(nl)

            # transient spike + filtered noise
            spike = np.exp(-np.linspace(0, 8, nl))
            hit = (noise * 0.2 + spike * 0.8) * adsr(nl)

            hit = lowpass_filter(hit, alpha=0.25)
            perc[i:i+nl] += hit * 0.8

    perc = simple_reverb(perc, decay=0.3)
    return perc


mel = generate_melody()
bass = generate_bass()
perc = generate_percussion()

mix = mel + bass + perc
mix /= np.max(np.abs(mix) + 1e-6)

# Stereo widening
left = mix * 0.9 + np.roll(mix, -200) * 0.1
right = mix * 0.9 + np.roll(mix, 200) * 0.1

stereo = np.stack([left, right], axis=1)
stereo /= np.max(np.abs(stereo) + 1e-6)

write("dsp_output_3.wav", SAMPLE_RATE, (stereo * 32767).astype(np.int16))

