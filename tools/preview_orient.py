#!/usr/bin/env python3
"""Compare numeral-orientation schemes on the dial. -> /tmp/ml_orient.png"""
import math, os
from PIL import Image, ImageDraw, ImageFont

FONT_PATH = "/System/Library/Fonts/Supplemental/Malayalam Sangam MN.ttc"
PAPER = (201, 198, 187, 255); INK = (17, 17, 17, 255)
SOFT = (110, 107, 97, 255); SEC = (68, 64, 56, 255)
font = ImageFont.truetype(FONT_PATH, 30)


def label(n):
    if n < 10:
        return chr(0x0D66 + n)
    if n == 10:
        return chr(0x0D70)
    return chr(0x0D70) + chr(0x0D66 + (n - 10))


def glyph(n, rot_cw):
    bbox = font.getbbox(label(n))
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    im = Image.new("RGBA", (w + 8, h + 8), (0, 0, 0, 0))
    ImageDraw.Draw(im).text((4 - bbox[0], 4 - bbox[1]), label(n), font=font, fill=INK)
    return im.rotate(-rot_cw, expand=True, resample=Image.BICUBIC)


def rot_upright(n):
    return 0


def rot_topout(n):                 # current: radial, flip the bottom 4..8
    a = n * 30
    return a - 180 if 90 < a < 270 else a


def rot_tangential(n):             # text follows the rim tangent, kept readable
    a = (n * 30 + 90) % 360
    return a - 180 if 90 < a < 270 else a


def paddle(dr, cx, cy, ang, L, BL, bw, sw, tail, lr, pen, col):
    s, c = math.sin(ang), math.cos(ang)
    b = L - BL
    loc = [(-tail, sw), (b, sw), (b + .12 * BL, bw), (b + .70 * BL, bw),
           (b + .90 * BL, bw * .55), (L, bw * .16), (L, -bw * .16),
           (b + .90 * BL, -bw * .55), (b + .70 * BL, -bw), (b + .12 * BL, -bw),
           (b, -sw), (-tail, -sw)]
    pts = [(cx + a * s + p * c, cy - a * c + p * s) for (a, p) in loc]
    dr.line(pts + [pts[0]], fill=col, width=pen, joint="curve")
    lx, ly = cx - tail * s, cy + tail * c
    dr.ellipse([lx - lr, ly - lr, lx + lr, ly + lr], outline=col, width=pen)


def face(scheme, size=340):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    dr = ImageDraw.Draw(img)
    cx = cy = size / 2.0
    r = size / 2.0
    dr.ellipse([0, 0, size - 1, size - 1], fill=PAPER)
    dr.ellipse([cx - (r - 2), cy - (r - 2), cx + (r - 2), cy + (r - 2)], outline=SOFT, width=2)
    for i in range(60):
        a = i * math.pi / 30.0
        s, c = math.sin(a), math.cos(a)
        outer, inner = r - 3, (r - 12 if i % 5 == 0 else r - 7)
        dr.line([cx + inner * s, cy - inner * c, cx + outer * s, cy - outer * c],
                fill=SOFT, width=3 if i % 5 == 0 else 1)
    rnum = r - 30
    for n in range(1, 13):
        a = n * math.pi / 6.0
        g = glyph(n, scheme(n))
        img.alpha_composite(g, (int(cx + rnum * math.sin(a) - g.width / 2),
                                int(cy - rnum * math.cos(a) - g.height / 2)))
    # longer hands
    hA = (10 % 12 + 9 / 60.0) * math.pi / 6.0
    mA = (9 + 33 / 60.0) * math.pi / 30.0
    sA = 33 * math.pi / 30.0
    paddle(dr, cx, cy, hA, r * 0.50, r * 0.50 * 0.44, r * 0.085, r * 0.018, r * 0.20, r * 0.052, 3, INK)
    paddle(dr, cx, cy, mA, r * 0.66, r * 0.66 * 0.38, r * 0.064, r * 0.016, r * 0.22, r * 0.044, 2, INK)
    s, c = math.sin(sA), math.cos(sA)
    dr.line([cx - r * 0.20 * s, cy + r * 0.20 * c, cx + r * 0.68 * s, cy - r * 0.68 * c], fill=SEC, width=2)
    dr.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=INK)
    dr.ellipse([cx - 2, cy - 2, cx + 2, cy + 2], fill=PAPER)
    return img


schemes = [("1. All upright", rot_upright),
           ("2. Radial tops-out (current)", rot_topout),
           ("3. Tangential (along rim)", rot_tangential)]
S, gap = 340, 26
W = S * len(schemes) + gap * (len(schemes) + 1)
H = S + 2 * gap + 24
canvas = Image.new("RGB", (W, H), (28, 28, 34))
cdr = ImageDraw.Draw(canvas)
cap = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 17)
x = gap
for name, sch in schemes:
    canvas.paste(face(sch).convert("RGB"), (x, gap))
    cdr.text((x + S / 2, gap + S + 4), name, font=cap, fill=(210, 210, 220), anchor="ma")
    x += S + gap
canvas.save("/tmp/ml_orient.png")
print("wrote /tmp/ml_orient.png")
