using Toybox.Application;
using Toybox.WatchUi;

class MalayalamWatchApp extends Application.AppBase {
    function initialize() { AppBase.initialize(); }
    function onStart(state) {}
    function onStop(state) {}

    function getInitialView() {
        return [new MalayalamWatchView()];
    }

    // Redraw immediately when the user changes the clock-format setting.
    function onSettingsChanged() {
        WatchUi.requestUpdate();
    }
}
