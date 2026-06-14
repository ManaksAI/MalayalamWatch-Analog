#!/usr/bin/env python3
"""
Generate a Connect IQ bitmap font (AngelCode BMFont .fnt + PNG atlas) containing
the glyphs needed for traditional ("old") Malayalam numerals.

Glyphs:
  U+0D67..U+0D6F  ->  1..9   (the Malayalam digit glyphs, shared with the old system)
  U+0D70          ->  ൰ TEN  (the archaic place symbol for ten)
  U+2014          ->  —      (em dash, used as a "zero / on-the-hour" placeholder,
                              since the old system has no zero glyph)

Run:  python3 tools/gen_font.py
Outputs into resources/fonts/: ml_numerals.png, ml_numerals.fnt
"""
import os
from PIL import Image, ImageDraw, ImageFont

FONT_PATH = "/System/Library/Fonts/Supplemental/Malayalam Sangam MN.ttc"
PAD = 3                        # transparent padding around each glyph cell
GAP = 2                        # gap between cells in the atlas
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "resources", "fonts")

# (basename, glyph size px): ml_numerals -> big stacked numerals for the digital face.
# (Analog hour numerals are pre-rotated PNGs built by tools/gen_dial.py instead.)
BUILDS = [("ml_numerals", 66)]

# codepoint -> source character (None = draw manually)
GLYPHS = {}
for d in range(1, 10):
    GLYPHS[0x0D66 + d] = chr(0x0D66 + d)   # 1..9
GLYPHS[0x0D70] = chr(0x0D70)               # ൰ ten
GLYPHS[0x2014] = None                      # em dash (drawn manually)


def build(basename, size):
    png_name = basename + ".png"
    fnt_name = basename + ".fnt"
    font = ImageFont.truetype(FONT_PATH, size)
    ascent, descent = font.getmetrics()
    cell_h = ascent + descent + 2 * PAD

    # Render each glyph into its own RGBA cell (constant height -> shared baseline).
    cells = {}   # cp -> (image, xadvance)
    for cp, ch in GLYPHS.items():
        if ch is None:
            # em dash: a horizontal bar roughly at x-height, sized like a digit
            adv = int(round(font.getlength(chr(0x0D68))))  # use "2" advance as ref
            w = adv + 2 * PAD
            img = Image.new("RGBA", (w, cell_h), (0, 0, 0, 0))
            dr = ImageDraw.Draw(img)
            bar_w = int(adv * 0.62)
            bar_h = max(3, size // 14)
            x0 = (w - bar_w) // 2
            y0 = PAD + ascent - size // 3
            dr.rectangle([x0, y0, x0 + bar_w, y0 + bar_h], fill=(255, 255, 255, 255))
            cells[cp] = (img, adv)
            continue
        adv = int(round(font.getlength(ch)))
        # actual ink box to size the cell width generously
        bbox = font.getbbox(ch)            # (l, t, r, b) relative to pen origin/top
        right = max(adv, bbox[2])
        w = right + 2 * PAD
        img = Image.new("RGBA", (w, cell_h), (0, 0, 0, 0))
        dr = ImageDraw.Draw(img)
        dr.text((PAD, PAD), ch, font=font, fill=(255, 255, 255, 255))
        cells[cp] = (img, adv)

    # Pack cells left-to-right into a single-row atlas.
    total_w = sum(im.width for im, _ in cells.values()) + GAP * (len(cells) + 1)
    atlas = Image.new("RGBA", (total_w, cell_h), (0, 0, 0, 0))
    records = []
    x = GAP
    for cp in sorted(cells.keys()):
        im, adv = cells[cp]
        atlas.paste(im, (x, 0))
        records.append((cp, x, 0, im.width, cell_h, 0, 0, adv))
        x += im.width + GAP

    os.makedirs(OUT_DIR, exist_ok=True)
    atlas.save(os.path.join(OUT_DIR, png_name))

    # Write the .fnt descriptor (AngelCode text format).
    line_height = cell_h
    base = ascent + PAD
    lines = []
    lines.append(
        'info face="Malayalam Sangam MN" size=%d bold=0 italic=0 charset="" unicode=1 '
        'stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing=%d,%d outline=0' % (size, GAP, GAP)
    )
    lines.append(
        'common lineHeight=%d base=%d scaleW=%d scaleH=%d pages=1 packed=0 '
        'alphaChnl=1 redChnl=0 greenChnl=0 blueChnl=0' % (line_height, base, atlas.width, atlas.height)
    )
    lines.append('page id=0 file="%s"' % png_name)
    lines.append('chars count=%d' % len(records))
    for (cp, gx, gy, gw, gh, xo, yo, adv) in records:
        lines.append(
            'char id=%d x=%d y=%d width=%d height=%d xoffset=%d yoffset=%d '
            'xadvance=%d page=0 chnl=15' % (cp, gx, gy, gw, gh, xo, yo, adv)
        )
    lines.append('kernings count=0')
    with open(os.path.join(OUT_DIR, fnt_name), "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    print("%-12s atlas %dx%d  glyphs %d  lineHeight %d  base %d"
          % (basename, atlas.width, atlas.height, len(records), line_height, base))


for name, sz in BUILDS:
    build(name, sz)
