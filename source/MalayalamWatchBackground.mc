using Toybox.WatchUi;
using Toybox.Graphics;

class Background extends WatchUi.Drawable {
    function initialize() {
        var params = {};
        Drawable.initialize(params);
    }
    function draw(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
    }
}
