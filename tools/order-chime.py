"""Generate the original, quiet two-note waiting-order bell (Python standard library)."""
import math
import wave
from array import array
from pathlib import Path

rate = 22050
samples = []
for i in range(int(rate * 0.65)):
    t = i / rate
    value = 0.0
    for start, frequency in [(0.0, 880), (0.18, 1174.66)]:
        age = t - start
        if age >= 0:
            envelope = min(1, age * 400) * math.exp(-age * 12)
            value += 0.35 * envelope * (math.sin(math.tau * frequency * age) + 0.2 * math.sin(math.tau * frequency * 2 * age))
    samples.append(int(max(-1, min(1, value)) * 32767))
with wave.open(str(Path(__file__).resolve().parents[1] / "assets/order_waiting.wav"), "wb") as output:
    output.setparams((1, 2, rate, 0, "NONE", "not compressed"))
    output.writeframes(array("h", samples).tobytes())
