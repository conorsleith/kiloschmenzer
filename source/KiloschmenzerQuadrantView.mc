using Toybox.WatchUi as Ui;
import Toybox.Lang;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Activity;


class KiloschmenzerQuadrantView extends Ui.DataField {
    private const BORDER_PAD = 0;
    private const _labelsFont = Graphics.FONT_TINY;
    private const _dataFont = Graphics.FONT_SMALL;

    private var _fitContributor as KschmFitContributor?;

    private var _width as Number?;
    private var _height as Number?;

    private var _topSepCoords as Array<Number>?;
    private var _midSepCoords as Array<Number>?;
    private var _botSepCoords as Array<Number>?;

    private var _headLabelY as Number?;
    private var _shoulderLabelY as Number?;
    private var _hipLabelY as Number?;
    private var _footLabelY as Number?;

    private var _headDataY as Number?;
    private var _shoulderDataY as Number?;
    private var _hipDataY as Number?;
    private var _footDataY as Number?;

    private var _elapsedKschmsLabel = "Kiloschmenzers";
    private var _lapKschmsLabel = "Lap Kschm";
    private var _kschmPaceLabel = "Avg Pace (Kschm)";
    private var _lapKschmPaceLabel = "Avg Lap Pace (Kschm)";
    
    function initialize() {
        DataField.initialize();
        _fitContributor = new KschmFitContributor(self);
    }

    public function onLayout(dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();

        var topLineY = (_height * .25).toNumber();
        var midLineY = (_height * .5).toNumber();
        var botLineY = (_height * .75).toNumber();

        var labelsFontHeight = Graphics.getFontHeight(_labelsFont);

        _topSepCoords = [0, topLineY, _width, topLineY];
        _midSepCoords = [0, midLineY, _width, midLineY];
        _botSepCoords = [0, botLineY, _width, botLineY];

        _headLabelY = 0;
        _headDataY = _headLabelY + labelsFontHeight + BORDER_PAD;

        _shoulderLabelY = topLineY;
        _shoulderDataY = _shoulderLabelY + labelsFontHeight + BORDER_PAD;

        _hipLabelY = midLineY;
        _hipDataY = _hipLabelY + labelsFontHeight + BORDER_PAD;

        _footLabelY = botLineY;
        _footDataY = _footLabelY + labelsFontHeight + BORDER_PAD;
    }

    function onUpdate(dc) {
        var fgColor = Graphics.COLOR_BLACK;
        var bgColor = Graphics.COLOR_WHITE;

        var lapKschm = _fitContributor.lapKschm;
        var lapKschmPace = _fitContributor.lapKschmPace;
        var sessionKschm = _fitContributor.sessionKschm;
        var sessionKschmPace = _fitContributor.sessionKschmPace;

        dc.setColor(fgColor, bgColor);
        dc.drawLine(_topSepCoords[0], _topSepCoords[1], _topSepCoords[2], _topSepCoords[3]);
        dc.drawLine(_midSepCoords[0], _midSepCoords[1], _midSepCoords[2], _midSepCoords[3]);
        dc.drawLine(_topSepCoords[0], _botSepCoords[1], _botSepCoords[2], _botSepCoords[3]);

        dc.drawText(_width/2, _headLabelY, _labelsFont, _lapKschmsLabel, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(_width/2, _headDataY, _dataFont, lapKschm.format("%.2f"), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(_width/2, _shoulderLabelY, _labelsFont, _elapsedKschmsLabel, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(_width/2, _shoulderDataY, _dataFont, sessionKschm.format("%.2f"), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(_width/2, _hipLabelY, _labelsFont, _kschmPaceLabel, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(_width/2, _hipDataY, _dataFont, toMinSec(sessionKschmPace), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(_width/2, _footLabelY, _labelsFont, _lapKschmPaceLabel, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(_width/2, _footDataY, _dataFont, toMinSec(lapKschmPace), Graphics.TEXT_JUSTIFY_CENTER);
    }

    public function compute(info as Activity.Info) as Void {
        _fitContributor.compute(info);
    }

    //! Handle the activity timer starting
    public function onTimerStart() as Void {
        _fitContributor.setTimerRunning(true);
    }

    //! Handle the activity timer stopping
    public function onTimerStop() as Void {
        _fitContributor.setTimerRunning(false);
    }

    //! Handle an activity timer pause
    public function onTimerPause() as Void {
        _fitContributor.setTimerRunning(false);
    }

    //! Handle the activity timer resuming
    public function onTimerResume() as Void {
        _fitContributor.setTimerRunning(true);
    }

    //! Handle a lap event
    public function onTimerLap() as Void {
        _fitContributor.onTimerLap();
    }

    //! Handle the current activity ending
    public function onTimerReset() as Void {
        _fitContributor.onTimerReset();
    }

    function toMinSec(secs as Number?) {
        if (secs != null && secs > 0) {
            var min = secs / 60;
            var sec = secs % 60;
            return min.format("%01d")+":"+sec.format("%02d");
        } else {
            return "--:--";
        }
    }
}
