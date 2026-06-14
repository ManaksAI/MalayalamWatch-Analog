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
    private var bigFont;     // stacked digital numerals
    private var dialFont;    // small markers around the analog dial
    private var isAwake = true;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
        cx = dc.getWidth() / 2;
        cy = dc.getHeight() / 2;
        radius = (cx < cy) ? cx : cy;
        bigFont  = WatchUi.loadResource(Rez.Fonts.MlNumerals);
        dialFont = WatchUi.loadResource(Rez.Fonts.MlDial);
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

        drawTicks(dc);
        drawDialNumerals(dc);
        drawDate(dc, cx, cy + (radius * 0.40).toNumber());

        // Hands. Angles measured clockwise from 12 o'clock.
        var hourA = (hour + min / 60.0) * Math.PI / 6.0;
        var minA  = (min + sec / 60.0) * Math.PI / 30.0;

        drawHand(dc, hourA, radius * 0.50, radius * 0.10, 7, Graphics.COLOR_WHITE);
        drawHand(dc, minA,  radius * 0.76, radius * 0.14, 4, Graphics.COLOR_WHITE);

        var showSec = prop("ShowSeconds", true);
        if (showSec && isAwake) {
            var secA = sec * Math.PI / 30.0;
            drawHand(dc, secA, radius * 0.84, radius * 0.20, 2, Graphics.COLOR_RED);
        }

        // Centre hub.
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 5);
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 2);
    }

    // 60 minute ticks, longer/bolder every five minutes.
    function drawTicks(dc) {
        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < 60; i++) {
            var a = i * Math.PI / 30.0;
            var sinA = Math.sin(a);
            var cosA = Math.cos(a);
            var outer = radius - 2;
            var inner = (i % 5 == 0) ? radius - 13 : radius - 7;
            dc.setPenWidth((i % 5 == 0) ? 3 : 1);
            dc.drawLine(cx + inner * sinA, cy - inner * cosA,
                        cx + outer * sinA, cy - outer * cosA);
        }
    }

    // Malayalam hour numerals 1..12 around the rim.
    function drawDialNumerals(dc) {
        var rNum = radius - 32;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (var n = 1; n <= 12; n++) {
            var a = n * Math.PI / 6.0;
            var x = cx + rNum * Math.sin(a);
            var y = cy - rNum * Math.cos(a);
            dc.drawText(x, y, dialFont, dialLabel(n),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // Old-Malayalam form of the hour markers 1..12.
    function dialLabel(n) {
        if (n < 10) {
            return mlDigits[n];
        }
        if (n == 10) {
            return ML_TEN;
        }
        return ML_TEN + mlDigits[n - 10];   // 11 -> ൰൧, 12 -> ൰൨
    }

    // One clock hand: a line from a short tail through the centre to the tip.
    function drawHand(dc, angle, length, tail, width, color) {
        var sinA = Math.sin(angle);
        var cosA = Math.cos(angle);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(width);
        dc.drawLine(cx - tail * sinA, cy + tail * cosA,
                    cx + length * sinA, cy - length * cosA);
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
