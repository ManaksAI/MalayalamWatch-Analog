#!/usr/bin/env python3
"""
Pre-render the 12 analog hour numerals (old Malayalam) already rotated to their
radial angle, as PNG drawables. Connect IQ's drawText can't rotate text, and the
dial positions are fixed, so we bake the rotation in at build time and just blit.

A numeral at clock position n (1..12) sits at angle n*30° clockwise from 12, and is
rotated by that same angle so its base faces the centre (radial orientation):
12 upright, 3 turned 90° CW, 6 upside-down, 9 turned 90° CCW.

Run:  python3 tools/gen_dial.py
Outputs: resources/drawables/dial_1.png .. dial_12.png
"""
import os
from PIL import Image, ImageDraw, ImageFont

FONT_PATH = "/System/Library/Fonts/Supplemental/Malayalam Sangam MN.ttc"
SIZE = 30
PAD = 4
OUT = os.path.join(os.path.dirname(__file__), "..", "resources", "drawables")
font = ImageFont.truetype(FONT_PATH, SIZE)


def label(n):
    if n < 10:
        return chr(0x0D66 + n)          # 1..9
    if n == 10:
        return chr(0x0D70)              # ൰
    return chr(0x0D70) + chr(0x0D66 + (n - 10))   # 11 -> ൰൧, 12 -> ൰൨


os.makedirs(OUT, exist_ok=True)
for n in range(1, 13):
    s = label(n)
    bbox = font.getbbox(s)
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    img = Image.new("RGBA", (w + 2 * PAD, h + 2 * PAD), (0, 0, 0, 0))
    ImageDraw.Draw(img).text((PAD - bbox[0], PAD - bbox[1]), s, font=font,
                             fill=(255, 255, 255, 255))
    rot = img.rotate(-n * 30, expand=True, resample=Image.BICUBIC)
    rot.save(os.path.join(OUT, "dial_%d.png" % n))
    print("dial_%d (%s) -> %dx%d" % (n, s, rot.width, rot.height))
