#!/usr/bin/env python3
"""生成 FitTrack 所需的 8 个音效文件"""
import struct, math, os

OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'sounds')

def generate_tone(filename, frequency, duration, volume=0.3, waveform='sine'):
    sample_rate = 44100
    num_samples = int(sample_rate * duration)
    samples = []
    for i in range(num_samples):
        t = i / sample_rate
        if waveform == 'sine':
            val = math.sin(2 * math.pi * frequency * t)
        elif waveform == 'square':
            val = 1.0 if math.sin(2 * math.pi * frequency * t) > 0 else -1.0
        else:
            val = math.sin(2 * math.pi * frequency * t)
        fade = min(int(sample_rate * 0.01), num_samples // 4)
        if i < fade:
            val *= i / fade
        elif i > num_samples - fade:
            val *= (num_samples - i) / fade
        samples.append(int(val * volume * 32767))
    filepath = os.path.join(OUTPUT_DIR, filename)
    with open(filepath, 'wb') as f:
        data_size = num_samples * 2
        f.write(b'RIFF')
        f.write(struct.pack('<I', 36 + data_size))
        f.write(b'WAVE')
        f.write(b'fmt ')
        f.write(struct.pack('<IHHIIHH', 16, 1, 1, sample_rate, sample_rate * 2, 2, 16))
        f.write(b'data')
        f.write(struct.pack('<I', data_size))
        for s in samples:
            f.write(struct.pack('<h', s))
    print(f'Generated: {filepath}')

def generate_chime(filename, frequencies, duration=0.3, volume=0.3):
    sample_rate = 44100
    num_samples = int(sample_rate * duration)
    samples = []
    for i in range(num_samples):
        t = i / sample_rate
        val = sum(math.sin(2 * math.pi * f * t) for f in frequencies) / len(frequencies)
        fade = min(int(sample_rate * 0.02), num_samples // 4)
        if i < fade:
            val *= i / fade
        elif i > num_samples - fade:
            val *= (num_samples - i) / fade
        samples.append(int(val * volume * 32767))
    filepath = os.path.join(OUTPUT_DIR, filename)
    with open(filepath, 'wb') as f:
        data_size = num_samples * 2
        f.write(b'RIFF')
        f.write(struct.pack('<I', 36 + data_size))
        f.write(b'WAVE')
        f.write(b'fmt ')
        f.write(struct.pack('<IHHIIHH', 16, 1, 1, sample_rate, sample_rate * 2, 2, 16))
        f.write(b'data')
        f.write(struct.pack('<I', data_size))
        for s in samples:
            f.write(struct.pack('<h', s))
    print(f'Generated: {filepath}')

if __name__ == '__main__':
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    generate_tone('complete_set.wav', 1200, 0.1, volume=0.25)
    generate_chime('complete_training.wav', [523, 659, 784, 1047], duration=0.6, volume=0.3)
    generate_tone('rest_start.wav', 600, 0.2, volume=0.2)
    generate_chime('rest_end.wav', [880, 1100], duration=0.4, volume=0.3)
    generate_tone('tick.wav', 1500, 0.05, volume=0.15, waveform='square')
    generate_chime('achievement.wav', [659, 831, 988], duration=0.5, volume=0.3)
    generate_chime('points.wav', [1319, 1568], duration=0.15, volume=0.25)
    generate_tone('button_tap.wav', 800, 0.03, volume=0.1)
    print('Done!')
