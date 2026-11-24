"""Rebuild the original music loop and combat sounds with Python and FFmpeg."""
import math
import random
import subprocess
import wave
from array import array
from pathlib import Path
from tempfile import TemporaryDirectory

ASSETS = Path(__file__).resolve().parents[1] / "assets"
RATE = 22050
rng = random.Random(2038)

def write(path, samples):
    pcm = array("h", (int(max(-1, min(1, x)) * 32767) for x in samples))
    with wave.open(str(path), "wb") as out:
        out.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        out.writeframes(pcm.tobytes())

def note(midi, time):
    return math.sin(math.tau * 440 * 2 ** ((midi - 69) / 12) * time)

beat = .48
samples = []
roots = [45, 41, 48, 43, 45, 41, 48, 40]
figure = [0, 7, 10, 12, 7, 3, 10, 7]
for i in range(round(len(roots) * 4 * beat * RATE)):
    t = i / RATE
    bar = min(len(roots) - 1, int(t / (4 * beat)))
    root = roots[bar]
    pulse = t % beat
    eighth = t % (beat / 2)
    kick = math.sin(math.tau * (53 * pulse + 4 * (1 - math.exp(-30 * pulse)))) * math.exp(-pulse * 23) * .26
    bass = (note(root - 12, pulse) + .25 * note(root, pulse)) * math.exp(-pulse * 8) * .22
    bell = note(root + 12 + figure[int(t / (beat / 2)) % 8], eighth) * math.exp(-13 * eighth) * .16
    noise = rng.uniform(-1, 1) * math.exp(-eighth * 43) * .08
    fade = min(1, t * 85, (len(roots) * 4 * beat - t) * 85)
    samples.append((kick + bass + bell + noise) * fade)
with TemporaryDirectory() as tmp:
    path = Path(tmp) / "music.wav"
    write(path, samples)
    subprocess.run(["ffmpeg","-y","-loglevel","error","-i",str(path),"-c:a","libvorbis",str(ASSETS / "after_hours.ogg")],check=True)
for name, length, freq, grit in [("click",.065,880,.08),("impact",.15,135,.45),("block",.11,450,.22),("gong",.63,280,.06)]:
    effect = []
    for i in range(round(length * RATE)):
        t = i / RATE
        oscillator = math.sin(math.tau * (freq * t - freq * t * t * .55))
        decay = math.exp(-t * (5 if name == "gong" else 25))
        effect.append((oscillator * .48 + rng.uniform(-grit, grit)) * decay * min(1, t * 500))
    write(ASSETS / (name + ".wav"), effect)
