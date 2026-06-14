# Malayalam Watch

A Garmin Connect IQ watch face that tells the time in **traditional ("old") Malayalam
numerals** — the pre-reform multiplicative system that uses the archaic place symbol
൰ (ten) rather than positional digits with a zero.

## Face styles (setting: **Face Style**)

- **Analog** (default): a round dial with the Malayalam hour numerals 1–12 (൧ … ൰൨)
  placed around the rim, minute ticks, and hour / minute / second hands.
  The red second hand animates while the watch is awake (`ShowSeconds` toggle).
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

Garmin's built-in fonts have no Malayalam glyphs, so the needed glyphs (൧–൯, ൰, and a
dash placeholder) are baked into custom bitmap fonts under `resources/fonts/`:
`ml_numerals.*` (large, digital) and `ml_dial.*` (small, analog markers), both
generated from *Malayalam Sangam MN*.

Regenerate the font (e.g. to change size — edit `SIZE` in the script):

```sh
python3 tools/gen_font.py        # needs Pillow
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
