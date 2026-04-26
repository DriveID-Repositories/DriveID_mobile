import wave
import struct
import math
import os

os.makedirs('assets/sounds', exist_ok=True)

def generate_tone(filename, frequency, duration_ms, wave_type='sine', volume=0.5):
    sample_rate = 44100
    num_samples = int(sample_rate * (duration_ms / 1000.0))
    
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            t = float(i) / sample_rate
            
            if wave_type == 'sine':
                # Success beep: 2 short high-pitched sine waves
                val = math.sin(2.0 * math.pi * frequency * t)
            elif wave_type == 'sawtooth':
                # Harsh buzzer: low-pitched sawtooth wave
                val = 2.0 * (t * frequency - math.floor(t * frequency + 0.5))
            else:
                val = 0.0
                
            # Envelope to avoid clicks
            envelope = 1.0
            attack = 0.05 * sample_rate
            release = 0.1 * sample_rate
            if i < attack:
                envelope = i / attack
            elif i > num_samples - release:
                envelope = (num_samples - i) / release
                
            sample = int(val * volume * envelope * 32767.0)
            wav_file.writeframes(struct.pack('h', sample))

# Success: 1000 Hz, 200ms
generate_tone('assets/sounds/success_beep.mp3', 1200, 200, 'sine', 0.5)

# Error: 150 Hz sawtooth, 400ms
generate_tone('assets/sounds/error_buzzer.mp3', 150, 400, 'sawtooth', 0.8)

print("Sounds generated in assets/sounds/")
