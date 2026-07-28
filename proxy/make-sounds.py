#!/usr/bin/env python3
"""Generates the §7 placeholder-but-pleasant signature sounds as 16-bit WAV,
pure-stdlib (no numpy). Each is the audible twin of a FeelKit haptic:

  tik.wav      reel-drag click   → ruler / deks cascade ticks
  damga.wav    dry ink thunk     → İLK YAKALAYIŞ stamp
  yeni-tur.wav brass-paper sting → new-species / line-complete ceremony (<1.2s)

TODO(sound): replace with recorded foley before launch — these are placeholders.
Run:  python3 proxy/make-sounds.py
"""
import math
import struct
import wave
import pathlib

RATE = 44100
OUT = pathlib.Path(__file__).resolve().parent.parent / "Fishigo/Resources/Sounds"
OUT.mkdir(parents=True, exist_ok=True)


def write(name, samples):
    peak = max(1e-9, max(abs(s) for s in samples))
    norm = 0.72 / peak
    with wave.open(str(OUT / name), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(
            struct.pack("<h", int(max(-1, min(1, s * norm)) * 32767)) for s in samples))


def tik():
    # Short filtered noise burst — a reel-drag click. ~18 ms.
    n = int(RATE * 0.018)
    seed = 12345
    out = []
    prev = 0.0
    for i in range(n):
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        white = (seed / 0x3FFFFFFF) - 1.0
        prev = 0.6 * prev + 0.4 * white  # gentle low-pass, softens the hiss
        env = math.exp(-i / (n * 0.28))
        out.append(prev * env)
    return out


def damga():
    # Dry ink thunk — a low body thump + a short woody knock. ~130 ms.
    n = int(RATE * 0.13)
    out = []
    seed = 777
    for i in range(n):
        t = i / RATE
        body = math.sin(2 * math.pi * 92 * t) * math.exp(-t / 0.045)
        knock = math.sin(2 * math.pi * 220 * t) * math.exp(-t / 0.018) * 0.5
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        grit = ((seed / 0x3FFFFFFF) - 1.0) * math.exp(-t / 0.01) * 0.25
        out.append(body + knock + grit)
    return out


def yeni_tur():
    # Brass-paper sting — a warm two-note brass rise with a paper-rustle tail.
    # Under 1.2 s.
    n = int(RATE * 1.05)
    out = []
    seed = 4242
    for i in range(n):
        t = i / RATE
        # Two brass partials, a perfect-fifth apart, second entering slightly late.
        f1, f2 = 392.0, 587.33  # G4, D5
        a1 = math.exp(-t / 0.6)
        a2 = math.exp(-max(0, t - 0.12) / 0.5) if t > 0.12 else 0.0
        brass = (0.6 * math.sin(2 * math.pi * f1 * t)
                 + 0.3 * math.sin(2 * math.pi * f1 * 2 * t) * 0.5
                 + 0.55 * math.sin(2 * math.pi * f2 * t) * a2 / max(a1, 1e-6))
        env = a1
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        paper = ((seed / 0x3FFFFFFF) - 1.0) * math.exp(-t / 0.25) * 0.06
        out.append(brass * env * 0.5 + paper)
    return out


write("tik.wav", tik())
write("damga.wav", damga())
write("yeni-tur.wav", yeni_tur())
print("3 ses üretildi →", OUT)
