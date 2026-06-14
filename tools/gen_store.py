#!/usr/bin/env python3
"""
Generate Connect IQ Store listing assets into ../store/:
  - icon_512.png                 marketing icon (512x512)
  - screenshot_*.png             square device-style screenshots (round dial on black)

Reuses the faithful renderers in preview.py (same fonts/geometry as the watch).
Run:  python3 tools/gen_store.py
"""
import os
from PIL import Image
import preview as P   # importing renders the tmp preview as a harmless side effect

STORE = os.path.join(os.path.dirname(__file__), "..", "store")
os.makedirs(STORE, exist_ok=True)


def on_black(face):
    """Composite an RGBA round face onto an opaque black square (watch screen)."""
    bg = Image.new("RGBA", face.size, (0, 0, 0, 255))
    bg.alpha_composite(face)
    return bg.convert("RGB")


def analog(style, h, m, s, size):
    P.DIAL_STYLE = style
    return on_black(P.analog(h, m, s, size=size))


def digital(h, m, size):
    return on_black(P.digital(h, m, size=size))


# Marketing icon (a clean upright dial)
analog("u", 10, 10, 30, 512).save(os.path.join(STORE, "icon_512.png"))

# Screenshots (454 = AMOLED round resolution)
SS = 454
analog("u", 10, 9, 33, SS).save(os.path.join(STORE, "screenshot_1_upright.png"))
analog("r", 1, 51, 40, SS).save(os.path.join(STORE, "screenshot_2_radial.png"))
analog("t", 7, 8, 18, SS).save(os.path.join(STORE, "screenshot_3_tangential.png"))
digital(10, 25, SS).save(os.path.join(STORE, "screenshot_4_digital.png"))

print("wrote store assets to", os.path.normpath(STORE))
for f in sorted(os.listdir(STORE)):
    print("  ", f)
