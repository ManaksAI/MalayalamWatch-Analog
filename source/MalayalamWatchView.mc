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

    // E-paper palette: dark ink on a warm paper background, flat and monochrome.
    private const BG   = 0xC9C6BB;   // paper
    private const INK  = 0x111111;   // dark ink (numerals/hands)
    private const SOFT = 0x6E6B61;   // muted ink (ring, ticks, date)
    private const SEC  = 0x444038;   // second hand (monochrome accent)

    private var cx;
    private var cy;
    private var radius;
    private var bigFont;      // stacked digital numerals
    private var smallFont;    // small numerals for the day-of-month
    private var dialBmps;     // pre-rotated hour numerals 1..12 (current style)
    private var loadedStyle = -1;
    private var wdBmp;        // cached weekday-name bitmap
    private var monBmp;       // cached month-name bitmap
    private var dateKey = -1; // month*32 + day_of_week, to refresh the cache
    private var isAwake = true;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
        cx = dc.getWidth() / 2;
        cy = dc.getHeight() / 2;
        radius = (cx < cy) ? cx : cy;
        bigFont   = WatchUi.loadResource(Rez.Fonts.MlNumerals);
        smallFont = WatchUi.loadResource(Rez.Fonts.MlSmall);
        loadDial(prop("NumeralStyle", 0));
    }

    // Load the 12 hour-numeral bitmaps for the chosen orientation style
    // (0 = upright, 1 = radial, 2 = tangential).
    function loadDial(style) {
        dialBmps = new [13];   // index 1..12
        if (style == 1) {
            dialBmps[1]  = WatchUi.loadResource(Rez.Drawables.DialR1);
            dialBmps[2]  = WatchUi.loadResource(Rez.Drawables.DialR2);
            dialBmps[3]  = WatchUi.loadResource(Rez.Drawables.DialR3);
            dialBmps[4]  = WatchUi.loadResource(Rez.Drawables.DialR4);
            dialBmps[5]  = WatchUi.loadResource(Rez.Drawables.DialR5);
            dialBmps[6]  = WatchUi.loadResource(Rez.Drawables.DialR6);
            dialBmps[7]  = WatchUi.loadResource(Rez.Drawables.DialR7);
            dialBmps[8]  = WatchUi.loadResource(Rez.Drawables.DialR8);
            dialBmps[9]  = WatchUi.loadResource(Rez.Drawables.DialR9);
            dialBmps[10] = WatchUi.loadResource(Rez.Drawables.DialR10);
            dialBmps[11] = WatchUi.loadResource(Rez.Drawables.DialR11);
            dialBmps[12] = WatchUi.loadResource(Rez.Drawables.DialR12);
        } else if (style == 2) {
            dialBmps[1]  = WatchUi.loadResource(Rez.Drawables.DialT1);
            dialBmps[2]  = WatchUi.loadResource(Rez.Drawables.DialT2);
            dialBmps[3]  = WatchUi.loadResource(Rez.Drawables.DialT3);
            dialBmps[4]  = WatchUi.loadResource(Rez.Drawables.DialT4);
            dialBmps[5]  = WatchUi.loadResource(Rez.Drawables.DialT5);
            dialBmps[6]  = WatchUi.loadResource(Rez.Drawables.DialT6);
            dialBmps[7]  = WatchUi.loadResource(Rez.Drawables.DialT7);
            dialBmps[8]  = WatchUi.loadResource(Rez.Drawables.DialT8);
            dialBmps[9]  = WatchUi.loadResource(Rez.Drawables.DialT9);
            dialBmps[10] = WatchUi.loadResource(Rez.Drawables.DialT10);
            dialBmps[11] = WatchUi.loadResource(Rez.Drawables.DialT11);
            dialBmps[12] = WatchUi.loadResource(Rez.Drawables.DialT12);
        } else {
            dialBmps[1]  = WatchUi.loadResource(Rez.Drawables.DialU1);
            dialBmps[2]  = WatchUi.loadResource(Rez.Drawables.DialU2);
            dialBmps[3]  = WatchUi.loadResource(Rez.Drawables.DialU3);
            dialBmps[4]  = WatchUi.loadResource(Rez.Drawables.DialU4);
            dialBmps[5]  = WatchUi.loadResource(Rez.Drawables.DialU5);
            dialBmps[6]  = WatchUi.loadResource(Rez.Drawables.DialU6);
            dialBmps[7]  = WatchUi.loadResource(Rez.Drawables.DialU7);
            dialBmps[8]  = WatchUi.loadResource(Rez.Drawables.DialU8);
            dialBmps[9]  = WatchUi.loadResource(Rez.Drawables.DialU9);
            dialBmps[10] = WatchUi.loadResource(Rez.Drawables.DialU10);
            dialBmps[11] = WatchUi.loadResource(Rez.Drawables.DialU11);
            dialBmps[12] = WatchUi.loadResource(Rez.Drawables.DialU12);
        }
        loadedStyle = style;
    }

    function onUpdate(dc) {
        dc.setColor(INK, BG);
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

        var style = prop("NumeralStyle", 0);
        if (style != loadedStyle) {
            loadDial(style);
        }

        drawRingAndTicks(dc, r);
        drawDialNumerals(dc, r);
        drawDate(dc, cx, cy + (r * 0.42).toNumber(), true);

        // Hands. Angles measured clockwise from 12 o'clock.
        var hourA = (hour + min / 60.0) * Math.PI / 6.0;
        var minA  = (min + sec / 60.0) * Math.PI / 30.0;

        // Boat-paddle hands (outline). Lengths kept short so the tips stop
        // before the numeral ring. Args: angle, length, bladeLen,
        // bladeHalfW, shaftHalfW, tail, loopR, pen, color.
        drawPaddle(dc, hourA, r * 0.46, r * 0.46 * 0.46, r * 0.088, r * 0.018,
                   r * 0.20, r * 0.052, 3, INK);
        drawPaddle(dc, minA,  r * 0.60, r * 0.60 * 0.38, r * 0.066, r * 0.016,
                   r * 0.22, r * 0.044, 2, INK);

        var showSec = prop("ShowSeconds", true);
        if (showSec && isAwake) {
            var secA = sec * Math.PI / 30.0;
            drawSecondHand(dc, secA, r * 0.62, r * 0.20, SEC);
        }

        // Centre hub.
        dc.setColor(INK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 5);
        dc.setColor(BG, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 2);
    }

    // Outer border ring + minute ticks pointing inward from the rim.
    function drawRingAndTicks(dc, r) {
        dc.setColor(SOFT, Graphics.COLOR_TRANSPARENT);
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
        var rNum = r - 30;
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

        drawDate(dc, cx, cy - fh - 18, false);

        dc.setColor(INK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - sep - fh, bigFont, mlNumber(hour),
            Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, cy + sep, bigFont, mlNumber(clock.min),
            Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(SOFT, Graphics.COLOR_TRANSPARENT);
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

    // ── Malayalam date (two lines centred on y) ─────────────────
    //   line 1:  weekday            e.g. ഞായർ
    //   line 2:  <day> <month>      e.g. ൰൪ മേയ്
    function drawDate(dc, x, y, full) {
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var key = today.month * 32 + today.day_of_week;
        if (key != dateKey) {
            wdBmp  = loadWeekday(today.day_of_week);
            monBmp = loadMonth(today.month);
            dateKey = key;
        }

        // Day-of-month: Malayalam numeral font, or standard digits in a system font.
        var dayStr;
        var dayFont;
        if (prop("DayNumerals", 0) == 1) {
            dayStr  = today.day.toString();
            dayFont = Graphics.FONT_SMALL;
        } else {
            dayStr  = mlNumber(today.day);
            dayFont = smallFont;
        }
        var dayW   = dc.getTextWidthInPixels(dayStr, dayFont);
        var gap    = 6;
        var wdW = wdBmp.getWidth();
        var wdH = wdBmp.getHeight();

        dc.setColor(INK, Graphics.COLOR_TRANSPARENT);

        if (!full) {
            // Compact one line: weekday + day  (e.g. ഞായർ ൰൪)
            var tW = wdW + gap + dayW;
            var sX = x - tW / 2;
            dc.drawBitmap(sX, y - wdH / 2, wdBmp);
            dc.drawText(sX + wdW + gap, y, dayFont, dayStr,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        // Two lines: weekday  /  day + month
        var monH = monBmp.getHeight();
        var lineGap = 4;
        var y1 = y - (monH + lineGap) / 2;     // weekday line centre
        var y2 = y + (wdH + lineGap) / 2;      // day+month line centre

        dc.drawBitmap(x - wdW / 2, y1 - wdH / 2, wdBmp);

        var totalW = dayW + gap + monBmp.getWidth();
        var startX = x - totalW / 2;
        dc.drawText(startX, y2, dayFont, dayStr,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawBitmap(startX + dayW + gap, y2 - monH / 2, monBmp);
    }

    function loadWeekday(dow) {
        if (dow == 1) { return WatchUi.loadResource(Rez.Drawables.Wd1); }
        if (dow == 2) { return WatchUi.loadResource(Rez.Drawables.Wd2); }
        if (dow == 3) { return WatchUi.loadResource(Rez.Drawables.Wd3); }
        if (dow == 4) { return WatchUi.loadResource(Rez.Drawables.Wd4); }
        if (dow == 5) { return WatchUi.loadResource(Rez.Drawables.Wd5); }
        if (dow == 6) { return WatchUi.loadResource(Rez.Drawables.Wd6); }
        return WatchUi.loadResource(Rez.Drawables.Wd7);
    }

    function loadMonth(m) {
        if (m == 1)  { return WatchUi.loadResource(Rez.Drawables.Mon1); }
        if (m == 2)  { return WatchUi.loadResource(Rez.Drawables.Mon2); }
        if (m == 3)  { return WatchUi.loadResource(Rez.Drawables.Mon3); }
        if (m == 4)  { return WatchUi.loadResource(Rez.Drawables.Mon4); }
        if (m == 5)  { return WatchUi.loadResource(Rez.Drawables.Mon5); }
        if (m == 6)  { return WatchUi.loadResource(Rez.Drawables.Mon6); }
        if (m == 7)  { return WatchUi.loadResource(Rez.Drawables.Mon7); }
        if (m == 8)  { return WatchUi.loadResource(Rez.Drawables.Mon8); }
        if (m == 9)  { return WatchUi.loadResource(Rez.Drawables.Mon9); }
        if (m == 10) { return WatchUi.loadResource(Rez.Drawables.Mon10); }
        if (m == 11) { return WatchUi.loadResource(Rez.Drawables.Mon11); }
        return WatchUi.loadResource(Rez.Drawables.Mon12);
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
