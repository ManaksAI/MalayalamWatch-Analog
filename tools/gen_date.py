#!/usr/bin/env python3
"""
Pre-render the Malayalam weekday and month names as PNG drawables, using CoreText
(via tools/render_text.swift) so conjuncts and vowel reordering shape correctly.
The day-of-month is drawn at runtime from the ml_small numeral font, so it is not
rendered here.

Run:  python3 tools/gen_date.py
Outputs: resources/drawables/wd_1..7.png  (1=Sunday .. 7=Saturday, matching
         Gregorian FORMAT_SHORT day_of_week) and mon_1..12.png
"""
import os
import subprocess

HERE = os.path.dirname(__file__)
FONT = os.path.join(HERE, "fonts", "NotoSansMalayalam.ttf")
SWIFT = os.path.join(HERE, "render_text.swift")
OUT = os.path.join(HERE, "..", "resources", "drawables")
SIZE = "16"
INK = "111111"
WGHT = "600"

WEEKDAYS = {            # Gregorian FORMAT_SHORT: 1 = Sunday .. 7 = Saturday
    1: "ഞായർ",
    2: "തിങ്കൾ",
    3: "ചൊവ്വ",
    4: "ബുധൻ",
    5: "വ്യാഴം",
    6: "വെള്ളി",
    7: "ശനി",
}
MONTHS = {
    1: "ജനുവരി", 2: "ഫെബ്രുവരി", 3: "മാർച്ച്", 4: "ഏപ്രിൽ",
    5: "മേയ്", 6: "ജൂൺ", 7: "ജൂലൈ", 8: "ഓഗസ്റ്റ്",
    9: "സെപ്റ്റംബർ", 10: "ഒക്ടോബർ", 11: "നവംബർ", 12: "ഡിസംബർ",
}


def render(text, out):
    subprocess.run(["swift", SWIFT, FONT, SIZE, INK, WGHT, out, text], check=True)


os.makedirs(OUT, exist_ok=True)
for i, name in WEEKDAYS.items():
    render(name, os.path.join(OUT, "wd_%d.png" % i))
for i, name in MONTHS.items():
    render(name, os.path.join(OUT, "mon_%d.png" % i))
print("done: 7 weekdays + 12 months")
