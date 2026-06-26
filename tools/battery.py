"""Pure geometry helper for the digital-face battery indicator.

Kept dependency-free (no PIL) so it can be imported by both tools/preview.py
and the unit tests. It mirrors the fill calculation in drawBattery() inside
source/MalayalamWatchView.mc: the battery level is clamped to 0..100 and the
remaining-charge fill is proportional to the inner width.
"""


def battery_fill(level, inner_w):
    """Width (px) of the remaining-charge fill for a battery at `level` (0..100)."""
    level = max(0.0, min(100.0, level))
    return int(inner_w * level / 100.0)
