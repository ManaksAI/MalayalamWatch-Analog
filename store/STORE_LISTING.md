# Connect IQ Store listing — Malayalam Watch

Everything needed to upload this watch face to the Connect IQ Store. The actual
upload/submission is done by you in the browser at **apps.garmin.com** (sign in,
accept the developer agreement, submit) — these assets are ready to attach.

## Upload file
- **`MalayalamWatch.iq`** — the release package (all 57 supported devices).
  Rebuild any time with:
  `monkeyc -e -f monkey.jungle -o store/MalayalamWatch.iq -y ../../developer_key`

## Listing assets
- **`hero_1440x720.png`** — 1440×720 hero/banner image.
- **`icon_512.png`** — 512×512 marketing icon.
- **`screenshot_1_upright.png` / `_2_radial.png` / `_3_tangential.png` / `_4_digital.png`**
  — 454×454 screenshots showing the styles.

## Suggested metadata

**Name:** Malayalam Watch

**Type / Category:** Watch Face

**Short description:**
Tell the time in traditional Malayalam numerals.

**Description:**
An analog watch face that shows the time in traditional ("old") Malayalam
numerals (൧–൰൨) arranged around the dial, with boat-paddle hands and a clean
e-paper look. The date is shown fully in Malayalam — weekday, day and month.

Settings:
• Face Style — Analog or Digital
• Numeral Orientation — Upright, Radial, or Tangential
• Date Day Numerals — Malayalam or Standard digits
• Second hand — on/off
• Clock format — follow device, 12-hour, or 24-hour

Malayalam glyphs and text use Noto Sans Malayalam (SIL Open Font License).

**Tags / keywords:** malayalam, analog, numerals, kerala, e-paper, paddle, date

**Pricing:** Free

## Upload steps (browser)
1. Go to **apps.garmin.com** → sign in → Developer Dashboard.
2. **Upload App** (or *Create App*) → choose `store/MalayalamWatch.iq`.
3. Fill in name, description, category, tags from above.
4. Upload `icon_512.png` and the screenshots.
5. Set pricing to Free, choose languages/regions.
6. **Submit for review.**

## Notes
- Keep the signing key (`GarminProjects/developer_key`) safe — every future update
  must be signed with the same key.
- Bump the app version (Connect IQ: Edit Application) for each store update.
