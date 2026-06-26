"""Unit tests for the digital-face battery indicator fill geometry.

These cover the proportional-fill / clamping logic shared between
tools/preview.py and source/MalayalamWatchView.mc (drawBattery). Stdlib
unittest only, so they run without third-party dependencies.
"""
import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "tools"))

from battery import battery_fill


class BatteryFillTest(unittest.TestCase):
    INNER_W = 24

    def test_full_battery_fills_entire_width(self):
        self.assertEqual(battery_fill(100, self.INNER_W), self.INNER_W)

    def test_empty_battery_has_no_fill(self):
        self.assertEqual(battery_fill(0, self.INNER_W), 0)

    def test_half_battery_fills_half(self):
        self.assertEqual(battery_fill(50, self.INNER_W), self.INNER_W // 2)

    def test_fill_is_monotonic_in_level(self):
        widths = [battery_fill(lvl, self.INNER_W) for lvl in range(0, 101, 10)]
        self.assertEqual(widths, sorted(widths))

    def test_drained_portion_is_remainder(self):
        # Charged + drained must always reconstruct the full inner width.
        for lvl in (0, 12, 37, 50, 88, 100):
            charged = battery_fill(lvl, self.INNER_W)
            drained = self.INNER_W - charged
            self.assertEqual(charged + drained, self.INNER_W)
            self.assertGreaterEqual(drained, 0)

    def test_level_is_clamped_to_valid_range(self):
        self.assertEqual(battery_fill(-10, self.INNER_W), 0)
        self.assertEqual(battery_fill(150, self.INNER_W), self.INNER_W)


if __name__ == "__main__":
    unittest.main()
