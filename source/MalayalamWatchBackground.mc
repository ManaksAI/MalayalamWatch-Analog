using Toybox.WatchUi;
using Toybox.Graphics;

class Background extends WatchUi.Drawable {
    function initialize() {
        var params = {};
        Drawable.initialize(params);
    }
    function draw(dc) {
        dc.setColor(0x111111, 0xC9C6BB);   // e-paper: ink on paper
        dc.clear();
    }
}
