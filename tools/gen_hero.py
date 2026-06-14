#!/usr/bin/env python3
"""
Generate the Connect IQ Store hero/banner image (1440x720) into ../store/.
Reuses the watch renderer in preview.py for a real dial.
Run:  python3 tools/gen_hero.py
"""
import os
import subprocess
from PIL import Image, ImageDraw, ImageFont
import preview as P

HERE = os.path.dirname(__file__)
STORE = os.path.join(HERE, "..", "store")
FONT = os.path.join(HERE, "fonts", "NotoSansMalayalam.ttf")
SWIFT = os.path.join(HERE, "render_text.swift")
os.makedirs(STORE, exist_ok=True)

W, H = 1440, 720
BG = (42, 40, 36)
LIGHT = (232, 229, 220)
DIM = (150, 146, 136)


def ml_text(text, size, hexcol, out):
    subprocess.run(["swift", SWIFT, FONT, str(size), hexcol, "600", out, text], check=True)
    return Image.open(out).convert("RGBA")


def arial(sz, bold=False):
    name = "Arial Bold.ttf" if bold else "Arial.ttf"
    try:
        return ImageFont.truetype("/System/Library/Fonts/Supplemental/" + name, sz)
    except Exception:
        return ImageFont.load_default()


canvas = Image.new("RGBA", (W, H), BG + (255,))
dr = ImageDraw.Draw(canvas)

# big dial on the right
D = 600
P.DIAL_STYLE = "u"
dial = P.analog(10, 9, 33, size=D)          # RGBA, paper circle on transparent
dx, dy = W - D - 90, (H - D) // 2
canvas.alpha_composite(dial, (dx, dy))

# subtle ring around the dial
dr.ellipse([dx - 4, dy - 4, dx + D + 4, dy + D + 4], outline=(70, 67, 60), width=3)

# left-hand title block
x = 96
dr.text((x, 250), "Malayalam Watch", font=arial(62, bold=True), fill=LIGHT)
ml = ml_text("മലയാളം വാച്ച്", 60, "E8E5DC", "/tmp/hero_ml.png")
canvas.alpha_composite(ml, (x, 330))
dr.text((x, 430), "Traditional Malayalam numerals", font=arial(28), fill=DIM)
dr.text((x, 470), "Analog & digital  ·  e-paper style", font=arial(28), fill=DIM)

out = os.path.join(STORE, "hero_1440x720.png")
canvas.convert("RGB").save(out)
print("wrote", os.path.normpath(out), canvas.size)
