using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Application;
using Toybox.Math;
using Toybox.Lang;

class MalayalamWatchView extends WatchUi.WatchFace {

    // Traditional ("old") Malayalam numerals.
    // 1..9 share the digit glyphs ൧..൯ ; ൰ is the archaic "ten" symbol.
    // The old system has no zero, so a dash stands in for an empty/zero value.
    private const ML_TEN  = "൰";
    private const ML_ZERO = "—";
    private var mlDigits = ["", "൧", "൨", "൩", "൪", "൫", "൬", "൭", "൮", "൯"];

    private var cx;
    private var cy;
    private var radius;
    private var bigFont;      // stacked digital numerals
    private var dialBmps;     // pre-rotated radial hour numerals 1..12
    private var isAwake = true;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
        cx = dc.getWidth() / 2;
        cy = dc.getHeight() / 2;
        radius = (cx < cy) ? cx : cy;
        bigFont  = WatchUi.loadResource(Rez.Fonts.MlNumerals);

        dialBmps = new [13];   // index 1..12
        dialBmps[1]  = WatchUi.loadResource(Rez.Drawables.Dial1);
        dialBmps[2]  = WatchUi.loadResource(Rez.Drawables.Dial2);
        dialBmps[3]  = WatchUi.loadResource(Rez.Drawables.Dial3);
        dialBmps[4]  = WatchUi.loadResource(Rez.Drawables.Dial4);
        dialBmps[5]  = WatchUi.loadResource(Rez.Drawables.Dial5);
        dialBmps[6]  = WatchUi.loadResource(Rez.Drawables.Dial6);
        dialBmps[7]  = WatchUi.loadResource(Rez.Drawables.Dial7);
        dialBmps[8]  = WatchUi.loadResource(Rez.Drawables.Dial8);
        dialBmps[9]  = WatchUi.loadResource(Rez.Drawables.Dial9);
        dialBmps[10] = WatchUi.loadResource(Rez.Drawables.Dial10);
        dialBmps[11] = WatchUi.loadResource(Rez.Drawables.Dial11);
        dialBmps[12] = WatchUi.loadResource(Rez.Drawables.Dial12);
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if (prop("FaceStyle", 0) == 1) {
            drawDigital(dc);
        } else {
            drawAnalog(dc);
        }
    }

    // ════════════════════════════════════════════════════════════
    //  ANALOG FACE
    // ════════════════════════════════════════════════════════════
    function drawAnalog(dc) {
        var clock = System.getClockTime();
        var hour  = clock.hour % 12;
        var min   = clock.min;
        var sec   = clock.sec;
        var r     = radius;

        drawRingAndTicks(dc, r);
        drawDialNumerals(dc, r);
        drawDate(dc, cx, cy + (r * 0.40).toNumber());

        // Hands. Angles measured clockwise from 12 o'clock.
        var hourA = (hour + min / 60.0) * Math.PI / 6.0;
        var minA  = (min + sec / 60.0) * Math.PI / 30.0;

        // Boat-paddle hands (outline). Args: angle, length, bladeLen,
        // bladeHalfW, shaftHalfW, tail, loopR, pen, color.
        drawPaddle(dc, hourA, r * 0.52, r * 0.52 * 0.44, r * 0.090, r * 0.018,
                   r * 0.22, r * 0.055, 3, Graphics.COLOR_WHITE);
        drawPaddle(dc, minA,  r * 0.76, r * 0.76 * 0.36, r * 0.068, r * 0.016,
                   r * 0.24, r * 0.048, 2, Graphics.COLOR_WHITE);

        var showSec = prop("ShowSeconds", true);
        if (showSec && isAwake) {
            var secA = sec * Math.PI / 30.0;
            drawSecondHand(dc, secA, r * 0.82, r * 0.24, Graphics.COLOR_RED);
        }

        // Centre hub.
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 5);
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 2);
    }

    // Outer border ring + minute ticks pointing inward from the rim.
    function drawRingAndTicks(dc, r) {
        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(cx, cy, r - 2);
        for (var i = 0; i < 60; i++) {
            var a = i * Math.PI / 30.0;
            var sinA = Math.sin(a);
            var cosA = Math.cos(a);
            var outer = r - 3;
            var inner = (i % 5 == 0) ? r - 12 : r - 7;
            dc.setPenWidth((i % 5 == 0) ? 3 : 1);
            dc.drawLine(cx + inner * sinA, cy - inner * cosA,
                        cx + outer * sinA, cy - outer * cosA);
        }
    }

    // Malayalam hour numerals 1..12 along the border ring, each pre-rotated to
    // sit radially (see tools/gen_dial.py).
    function drawDialNumerals(dc, r) {
        var rNum = r - 32;
        for (var n = 1; n <= 12; n++) {
            var a = n * Math.PI / 6.0;
            var x = cx + rNum * Math.sin(a);
            var y = cy - rNum * Math.cos(a);
            var bmp = dialBmps[n];
            dc.drawBitmap((x - bmp.getWidth() / 2.0).toNumber(),
                          (y - bmp.getHeight() / 2.0).toNumber(), bmp);
        }
    }

    // ── Boat-paddle shaped hand (outline) ───────────────────────
    // A long shaft, a leaf-shaped blade at the tip, and a small grip
    // loop at the tail — drawn as a stroked silhouette.
    function drawPaddle(dc, angle, length, bladeLen, bw, sw, tail, loopR, pen, color) {
        var sinA = Math.sin(angle);
        var cosA = Math.cos(angle);
        var b = length - bladeLen;   // blade base distance from centre

        // Local (along, perp) outline points, tail -> tip up the right
        // side, then back down the left side.
        var local = [
            [-tail, sw],
            [b, sw],
            [b + 0.12 * bladeLen, bw],
            [b + 0.70 * bladeLen, bw],
            [b + 0.90 * bladeLen, bw * 0.55],
            [length, bw * 0.16],
            [length, -bw * 0.16],
            [b + 0.90 * bladeLen, -bw * 0.55],
            [b + 0.70 * bladeLen, -bw],
            [b + 0.12 * bladeLen, -bw],
            [b, -sw],
            [-tail, -sw]
        ];

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(pen);
        var n = local.size();
        for (var i = 0; i < n; i++) {
            var p0 = local[i];
            var p1 = local[(i + 1) % n];
            dc.drawLine(cx + p0[0] * sinA + p0[1] * cosA,
                        cy - p0[0] * cosA + p0[1] * sinA,
                        cx + p1[0] * sinA + p1[1] * cosA,
                        cy - p1[0] * cosA + p1[1] * sinA);
        }

        // Grip loop at the tail end.
        var lx = cx - (tail) * sinA;
        var ly = cy + (tail) * cosA;
        dc.drawCircle(lx, ly, loopR);
    }

    // Thin paddle-style second hand: a line tip + a small grip loop tail.
    function drawSecondHand(dc, angle, length, tail, color) {
        var sinA = Math.sin(angle);
        var cosA = Math.cos(angle);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(cx - tail * sinA, cy + tail * cosA,
                    cx + length * sinA, cy - length * cosA);
        dc.drawCircle(cx - tail * sinA, cy + tail * cosA, 4);
    }

    // ════════════════════════════════════════════════════════════
    //  DIGITAL FACE (stacked old numerals)
    // ════════════════════════════════════════════════════════════
    function drawDigital(dc) {
        var clock = System.getClockTime();
        var hour  = resolveHour(clock.hour);

        var fh  = dc.getFontHeight(bigFont);
        var sep = 6;

        drawDate(dc, cx, cy - fh - 24);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - sep - fh, bigFont, mlNumber(hour),
            Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, cy + sep, bigFont, mlNumber(clock.min),
            Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(cx - 34, cy, cx + 34, cy);
    }

    // ClockMode: 0 = device setting, 1 = force 12h, 2 = force 24h (digital only).
    function resolveHour(h24) {
        var mode = prop("ClockMode", 0);
        var is24;
        if (mode == 1) {
            is24 = false;
        } else if (mode == 2) {
            is24 = true;
        } else {
            is24 = System.getDeviceSettings().is24Hour;
        }
        if (is24) {
            return h24;
        }
        var h = h24 % 12;
        if (h == 0) { h = 12; }
        return h;
    }

    // Old-Malayalam numeral string for 0..99 (multiplicative system).
    function mlNumber(n) {
        if (n <= 0) {
            return ML_ZERO;
        }
        var tens  = n / 10;
        var units = n % 10;
        if (tens == 0) {
            return mlDigits[units];
        }
        if (tens == 1) {
            return (units == 0) ? ML_TEN : ML_TEN + mlDigits[units];
        }
        var s = mlDigits[tens] + ML_TEN;
        if (units > 0) {
            s = s + mlDigits[units];
        }
        return s;
    }

    // ── shared helpers ──────────────────────────────────────────
    function drawDate(dc, x, y) {
        var today   = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var dateStr = Lang.format("$1$ $2$", [today.day_of_week, today.day]);
        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, Graphics.FONT_XTINY, dateStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function prop(key, dflt) {
        var v = Application.Properties.getValue(key);
        return (v == null) ? dflt : v;
    }

    function onShow() {}
    function onHide() {}
    function onExitSleep() { isAwake = true;  WatchUi.requestUpdate(); }
    function onEnterSleep() { isAwake = false; WatchUi.requestUpdate(); }
}
