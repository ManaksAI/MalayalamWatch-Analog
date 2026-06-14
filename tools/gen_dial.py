#!/usr/bin/env python3
"""
Pre-render the 12 analog hour numerals (old Malayalam) as PNG drawables, in THREE
orientation styles the watch face lets the user choose between:

  u (upright)     - every numeral horizontal / fully readable
  r (radial)      - radial, tops pointing outward; the bottom 4..8 flipped up so
                    they are not upside-down
  t (tangential)  - numerals follow the rim tangent, kept readable

Connect IQ's drawText can't rotate text, and the dial positions are fixed, so the
rotation (and dark e-paper ink colour) is baked in here and the watch just blits.

Run:  python3 tools/gen_dial.py
Outputs: resources/drawables/dial_<u|r|t>_1.png .. dial_<u|r|t>_12.png
"""
import os
from PIL import Image, ImageDraw, ImageFont

FONT_PATH = os.path.join(os.path.dirname(__file__), "fonts", "NotoSansMalayalam.ttf")
FONT_WEIGHT = "SemiBold"
SIZE = 30
PAD = 4
INK = (17, 17, 17, 255)        # e-paper ink
OUT = os.path.join(os.path.dirname(__file__), "..", "resources", "drawables")
font = ImageFont.truetype(FONT_PATH, SIZE)
try:
    font.set_variation_by_name(FONT_WEIGHT)
except Exception:
    pass


def label(n):
    if n < 10:
        return chr(0x0D66 + n)          # 1..9
    if n == 10:
        return chr(0x0D70)              # ൰
    return chr(0x0D70) + chr(0x0D66 + (n - 10))   # 11 -> ൰൧, 12 -> ൰൨


def rot_upright(n):
    return 0


def rot_radial(n):                      # tops outward; flip the bottom half
    a = n * 30
    return a - 180 if 90 < a < 270 else a


def rot_tangential(n):                  # follow the rim tangent, kept readable
    a = (n * 30 + 90) % 360
    return a - 180 if 90 < a < 270 else a


SCHEMES = {"u": rot_upright, "r": rot_radial, "t": rot_tangential}

os.makedirs(OUT, exist_ok=True)
for key, fn in SCHEMES.items():
    for n in range(1, 13):
        s = label(n)
        bbox = font.getbbox(s)
        w = bbox[2] - bbox[0]
        h = bbox[3] - bbox[1]
        img = Image.new("RGBA", (w + 2 * PAD, h + 2 * PAD), (0, 0, 0, 0))
        ImageDraw.Draw(img).text((PAD - bbox[0], PAD - bbox[1]), s, font=font, fill=INK)
        rot = img.rotate(-fn(n), expand=True, resample=Image.BICUBIC)
        rot.save(os.path.join(OUT, "dial_%s_%d.png" % (key, n)))
    print("style '%s' -> 12 glyphs" % key)
