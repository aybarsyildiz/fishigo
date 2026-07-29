#!/usr/bin/env python3
"""Compose App Store marketing screenshots for Fishigo — the ToneAmp method,
skinned in the app's "naturalist specimen archive" language.

WORKFLOW:
  1. Capture raw iPhone screenshots (on your phone or the simulator) and drop
     them into appstore/raw/ named 01.png, 02.png, … in the order of CAPTIONS
     below. Any iPhone screenshot size works — the script scales them.
  2. Run:  python3 tools/frame_screenshots.py
  3. Upload appstore/framed/*.png to App Store Connect (iPhone 6.9" slot).

Output is 1290x2796 (iPhone 6.9" display — the size App Store Connect asks for
now). Flat ink background, Fraunces caption (2nd line in stamp red), faint
chart contours, a paper-bordered rounded screenshot. No gradients (§6).

Needs Pillow:  pip install pillow
"""
import math
import os
import sys
from PIL import Image, ImageDraw, ImageFont

W, H = 1290, 2796
BG = (15, 34, 44)        # --murekkep-koyu  #0F222C
FG = (237, 229, 209)     # --kagit          #EDE5D1
ACCENT = (194, 64, 47)   # --muhur          #C2402F
LINE = (40, 65, 78)      # --cizgi          #28414E
RADIUS = 54

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRAUNCES = os.path.join(ROOT, "Fishigo/Resources/Fonts/Fraunces-Variable.ttf")

# 2-line captions; the 2nd line renders in stamp red. Keep them short.
CAPTIONS = [
    ("Balığını fotoğrafla,", "türü anında öğren."),
    ("Her yakalayış,", "bir koleksiyon kartı."),
    ("70 tür seni bekliyor.", "Balıkdeks'ini doldur."),
    ("Boy ve sezon kuralları,", "tek bakışta."),
    ("Yakaladığın nokta", "sende kalır."),
    ("Bugün ne tutulur?", "Koşullar hazır."),
]


def font(size):
    if os.path.exists(FRAUNCES):
        try:
            f = ImageFont.truetype(FRAUNCES, size)
            try:
                f.set_variation_by_name("Black")  # heaviest instance for display
            except Exception:
                pass
            return f
        except OSError:
            pass
    for path in ("/System/Library/Fonts/SFNS.ttf", "/System/Library/Fonts/Helvetica.ttc"):
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def draw_contours(draw):
    """Faint nautical-chart depth contours — the app's ChartFragment motif."""
    for base, phase in ((0.10, 0.0), (0.86, 2.3), (0.55, 4.1)):
        pts = []
        for s in [i / 120 for i in range(-2, 123)]:
            x = s * W
            y = base * H + math.sin(s * 5.2 + phase) * 34 + math.sin(s * 11.7 + phase * 2) * 13
            pts.append((x, y))
        draw.line(pts, fill=(*LINE, 120), width=2)


def frame(shot_path, caption, out_path):
    canvas = Image.new("RGB", (W, H), BG)
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw_contours(ImageDraw.Draw(overlay))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), overlay).convert("RGB")
    draw = ImageDraw.Draw(canvas)

    # Caption
    f = font(96)
    y = 160
    for i, line in enumerate(caption):
        box = draw.textbbox((0, 0), line, font=f)
        draw.text(((W - (box[2] - box[0])) / 2, y), line, font=f,
                  fill=ACCENT if i == 1 else FG)
        y += 122

    # Screenshot: scale to width, round corners, paste with a paper border.
    shot = Image.open(shot_path).convert("RGB")
    target_w = 1120
    target_h = round(shot.height * target_w / shot.width)
    max_h = H - 620
    shot = shot.resize((target_w, target_h), Image.LANCZOS)
    if target_h > max_h:
        shot = shot.crop((0, 0, target_w, max_h))
        target_h = max_h

    mask = Image.new("L", (target_w, target_h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, target_w, target_h), radius=RADIUS, fill=255)
    x = (W - target_w) // 2
    top = 520
    canvas.paste(shot, (x, top), mask)
    draw.rounded_rectangle((x, top, x + target_w, top + target_h),
                           radius=RADIUS, outline=FG, width=3)
    canvas.save(out_path, "PNG")
    print("wrote", out_path)


def main():
    raw_dir = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "appstore/raw")
    out_dir = sys.argv[2] if len(sys.argv) > 2 else os.path.join(ROOT, "appstore/framed")
    if not os.path.isdir(raw_dir):
        sys.exit(f"Put raw screenshots in {raw_dir}/ as 01.png, 02.png, … then rerun.")
    os.makedirs(out_dir, exist_ok=True)
    shots = sorted(f for f in os.listdir(raw_dir) if f.lower().endswith(".png"))
    if not shots:
        sys.exit(f"No .png files in {raw_dir}/ yet. Add 01.png, 02.png, …")
    for i, name in enumerate(shots):
        frame(os.path.join(raw_dir, name), CAPTIONS[i % len(CAPTIONS)],
              os.path.join(out_dir, f"{i + 1:02d}.png"))


if __name__ == "__main__":
    main()
