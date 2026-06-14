# Malayalam Watch

A Garmin Connect IQ watch face that tells the time in **traditional ("old") Malayalam
numerals** — the pre-reform multiplicative system that uses the archaic place symbol
൰ (ten) rather than positional digits with a zero.

## Face styles (setting: **Face Style**)

- **Analog** (default): a round dial with the Malayalam hour numerals 1–12 (൧ … ൰൨)
  along the border ring, **rotated radially** (each pre-rendered to its angle by
  `tools/gen_dial.py`, since Connect IQ can't rotate text), minute ticks, and
  **boat-paddle hands** (leaf blade at the tip, grip-loop handle at the tail). The red
  second hand animates while the watch is awake (`ShowSeconds` toggle).
- **Digital**: hour stacked above minute in old numerals (the forms get too wide to
  sit on one line), respecting the **Clock Format** setting.

## Numeral rules (0–99)

| Value      | Form        | Example          |
|------------|-------------|------------------|
| 1–9        | digit       | 7 → ൭            |
| 10         | ൰           | 10 → ൰           |
| 11–19      | ൰ + unit    | 12 → ൰൨          |
| 20,30,…    | digit + ൰   | 20 → ൨൰          |
| 21–99      | digit ൰ unit| 25 → ൨൰൫         |
| 0          | — (no zero) | 10:00 → ൰ / —    |

For the analog dial: 11 → ൰൧, 12 → ൰൨.

## Settings

| Setting        | Property      | Values                                   |
|----------------|---------------|------------------------------------------|
| Face Style     | `FaceStyle`   | 0 = Analog (default), 1 = Digital        |
| Show Seconds   | `ShowSeconds` | bool (analog second hand, default on)    |
| Clock Format   | `ClockMode`   | 0 = device / 1 = 12h / 2 = 24h (digital) |

## Font

Garmin's built-in fonts have no Malayalam glyphs, so the needed glyphs are baked in from
**Noto Sans Malayalam** (SemiBold), which is licensed under the SIL Open Font License —
safe to redistribute in a published app. The source font and its licence live in
`tools/fonts/` (`NotoSansMalayalam.ttf`, `OFL.txt`).

- `resources/fonts/ml_numerals.*` — large bitmap font for the digital face
  (built by `tools/gen_font.py`).
- `resources/drawables/dial_<u|r|t>_*.png` — the 12 analog hour numerals, pre-rotated
  for each orientation style (built by `tools/gen_dial.py`).

Regenerate the glyph assets (needs Pillow; edit `SIZE`/`FONT_WEIGHT` to tweak):

```sh
python3 tools/gen_font.py        # digital bitmap font
python3 tools/gen_dial.py        # analog hour numerals, all 3 orientation styles
```

Faithful layout preview without the simulator:

```sh
python3 tools/preview.py         # writes /tmp/malayalam_watch_preview.png
```

## Build / run

```sh
SDK=~/Library/Application\ Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b
# compile
"$SDK/bin/monkeyc" -f monkey.jungle -d fenix7 -y ../../developer_key -o /tmp/MalayalamWatch.prg
# run in the simulator
"$SDK/bin/connectiq" &
"$SDK/bin/monkeydo" /tmp/MalayalamWatch.prg fenix7
```
