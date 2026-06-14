#!/usr/bin/env python3
"""
Faithful preview of the Malayalam Watch face (analog + digital styles).

Reads the SAME font atlases (resources/fonts/ml_*.png + .fnt) and mirrors the
geometry / numeral rules in source/MalayalamWatchView.mc. This is not the Connect IQ
renderer, but it reflects what the watch composes on screen.

Run:  python3 tools/preview.py   ->  /tmp/malayalam_watch_preview.png
"""
import math, os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(__file__)
FONTS = os.path.join(HERE, "..", "resources", "fonts")


def load_font(basename):
    glyphs, lh = {}, 0
    with open(os.path.join(FONTS, basename + ".fnt"), encoding="utf-8") as f:
        for ln in f:
            p = dict(t.split("=", 1) for t in ln.split() if "=" in t)
            if ln.startswith("common"):
                lh = int(p["lineHeight"])
            elif ln.startswith("char "):
                glyphs[int(p["id"])] = (int(p["x"]), int(p["y"]), int(p["width"]),
                                        int(p["height"]), int(p["xadvance"]))
    atlas = Image.open(os.path.join(FONTS, basename + ".png")).convert("RGBA")
    return atlas, glyphs, lh


BIG  = load_font("ml_numerals")
DIAL = load_font("ml_dial")

ML_TEN, ML_ZERO = 0x0D70, 0x2014


def number_cps(n):                      # mirror of mlNumber()
    if n <= 0:
        return [ML_ZERO]
    tens, units = n // 10, n % 10
    if tens == 0:
        return [0x0D66 + units]
    if tens == 1:
        return [ML_TEN] if units == 0 else [ML_TEN, 0x0D66 + units]
    seq = [0x0D66 + tens, ML_TEN]
    if units > 0:
        seq.append(0x0D66 + units)
    return seq


def dial_cps(n):                        # mirror of dialLabel()
    if n < 10:
        return [0x0D66 + n]
    if n == 10:
        return [ML_TEN]
    return [ML_TEN, 0x0D66 + (n - 10)]


def render(font, cps, color):
    atlas, glyphs, lh = font
    total = sum(glyphs[c][4] for c in cps)
    img = Image.new("RGBA", (max(1, total), lh), (0, 0, 0, 0))
    x = 0
    for c in cps:
        gx, gy, gw, gh, adv = glyphs[c]
        sprite = atlas.crop((gx, gy, gx + gw, gy + gh)).copy()
        px = sprite.load()
        for yy in range(sprite.height):
            for xx in range(sprite.width):
                a = px[xx, yy][3]
                px[xx, yy] = (color[0], color[1], color[2], a)
        img.alpha_composite(sprite, (x, 0))
        x += adv
    return img


def paste_centered(dst, img, cx, cy):
    dst.alpha_composite(img, (int(cx - img.width / 2), int(cy - img.height / 2)))


def hand(dr, cx, cy, angle, length, tail, width, color):
    s, c = math.sin(angle), math.cos(angle)
    dr.line([cx - tail * s, cy + tail * c, cx + length * s, cy - length * c],
            fill=color, width=width)


def _xy(cx, cy, s, c, a, p):
    return (cx + a * s + p * c, cy - a * c + p * s)


def paddle(dr, cx, cy, angle, length, blade_len, bw, sw, tail, loop_r, pen, color):
    s, c = math.sin(angle), math.cos(angle)
    b = length - blade_len
    local = [
        (-tail, sw), (b, sw),
        (b + 0.12 * blade_len, bw), (b + 0.70 * blade_len, bw),
        (b + 0.90 * blade_len, bw * 0.55), (length, bw * 0.16),
        (length, -bw * 0.16), (b + 0.90 * blade_len, -bw * 0.55),
        (b + 0.70 * blade_len, -bw), (b + 0.12 * blade_len, -bw),
        (b, -sw), (-tail, -sw),
    ]
    pts = [_xy(cx, cy, s, c, a, p) for (a, p) in local]
    dr.line(pts + [pts[0]], fill=color, width=pen, joint="curve")
    lx, ly = cx - tail * s, cy + tail * c
    dr.ellipse([lx - loop_r, ly - loop_r, lx + loop_r, ly + loop_r],
               outline=color, width=pen)


def second_hand(dr, cx, cy, angle, length, tail, color):
    s, c = math.sin(angle), math.cos(angle)
    dr.line([cx - tail * s, cy + tail * c, cx + length * s, cy - length * c],
            fill=color, width=2)
    lx, ly = cx - tail * s, cy + tail * c
    dr.ellipse([lx - 4, ly - 4, lx + 4, ly + 4], outline=color, width=2)


def small_font(sz):
    try:
        return ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", sz)
    except Exception:
        return ImageFont.load_default()


def analog(h, m, sec, size=320):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    dr = ImageDraw.Draw(img)
    cx = cy = size / 2
    r = size / 2
    dr.ellipse([0, 0, size - 1, size - 1], fill=(0, 0, 0, 255))

    # border ring
    dr.ellipse([cx - (r - 2), cy - (r - 2), cx + (r - 2), cy + (r - 2)],
               outline=(85, 85, 85, 255), width=2)
    for i in range(60):
        a = i * math.pi / 30.0
        s, c = math.sin(a), math.cos(a)
        outer = r - 3
        inner = r - 12 if i % 5 == 0 else r - 7
        dr.line([cx + inner * s, cy - inner * c, cx + outer * s, cy - outer * c],
                fill=(85, 85, 85, 255), width=3 if i % 5 == 0 else 1)

    rnum = r - 28
    for n in range(1, 13):
        a = n * math.pi / 6.0
        x = cx + rnum * math.sin(a)
        y = cy - rnum * math.cos(a)
        paste_centered(img, render(DIAL, dial_cps(n), (255, 255, 255)), x, y)

    df = small_font(15)
    dr.text((cx, cy + r * 0.40), "WED 14", font=df, fill=(136, 136, 136, 255), anchor="mm")

    hourA = (h % 12 + m / 60.0) * math.pi / 6.0
    minA = (m + sec / 60.0) * math.pi / 30.0
    secA = sec * math.pi / 30.0
    paddle(dr, cx, cy, hourA, r * 0.52, r * 0.52 * 0.44, r * 0.090, r * 0.018,
           r * 0.22, r * 0.055, 3, (255, 255, 255, 255))
    paddle(dr, cx, cy, minA, r * 0.76, r * 0.76 * 0.36, r * 0.068, r * 0.016,
           r * 0.24, r * 0.048, 2, (255, 255, 255, 255))
    second_hand(dr, cx, cy, secA, r * 0.82, r * 0.24, (230, 40, 40, 255))

    dr.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=(255, 255, 255, 255))
    dr.ellipse([cx - 2, cy - 2, cx + 2, cy + 2], fill=(230, 40, 40, 255))
    return img


def digital(h, m, size=320):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    dr = ImageDraw.Draw(img)
    cx = cy = size / 2
    dr.ellipse([0, 0, size - 1, size - 1], fill=(0, 0, 0, 255))
    lh = BIG[2]
    sep = 6
    paste_centered(img, render(BIG, number_cps(h), (255, 255, 255)), cx, cy - sep - lh / 2)
    paste_centered(img, render(BIG, number_cps(m), (255, 255, 255)), cx, cy + sep + lh / 2)
    dr.line([cx - 34, cy, cx + 34, cy], fill=(85, 85, 85, 255), width=2)
    dr.text((cx, cy - lh - 24), "WED 14", font=small_font(15),
            fill=(136, 136, 136, 255), anchor="mm")
    return img


# ── compose: 3 analog faces + 1 digital (the alternate setting) ──
faces = [
    ("Analog  10:09", analog(10, 9, 33)),
    ("Analog  03:47", analog(3, 47, 18)),
    ("Analog  12:55", analog(12, 55, 50)),
    ("Digital  10:25", digital(10, 25)),
]
S = 320
gap = 26
W = S * len(faces) + gap * (len(faces) + 1)
H = S + 2 * gap + 24
canvas = Image.new("RGB", (W, H), (28, 28, 34))
cdr = ImageDraw.Draw(canvas)
cap = small_font(16)
x = gap
for label, face in faces:
    canvas.paste(face.convert("RGB"), (x, gap))
    cdr.text((x + S / 2, gap + S + 4), label, font=cap, fill=(205, 205, 215), anchor="ma")
    x += S + gap
out = "/tmp/malayalam_watch_preview.png"
canvas.save(out)
print("wrote", out)
