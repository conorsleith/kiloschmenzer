//
// Copyright 2015-2021 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

import Toybox.FitContributor;
import Toybox.Lang;
import Toybox.Activity;
import Toybox.System;

public const MILE_CONVERSTION_FACTOR = 0.621371;

class KschmFitContributor {

    // Variables for computing averages
    private var _sessionDistance as Float = 0.0;
    private var _sessionElapsedMs as Number = 0;
    private var _sessionVert as Number = 0;
    private var _lapDistance as Float = 0.0;
    private var _lapElapsedMs as Number = 0;
    private var _lapVert as Number = 0;
    private var _sumPreviousLapsDistance as Float = 0.0;
    private var _sumPreviousLapsMs as Number = 0;
    private var _sumPreviousLapsVert as Number = 0;
    private var _timerRunning as Boolean = false;

    // FIT Contributions variables
    private var _sessionKschmField as Field;
    private var _lapKschmField as Field;
    private var _sessionKschmPaceField as Field;
    private var _lapKschmPaceField as Field;

    private var _conversionFactor as Float;

    public var lapKschm as Float?;
    public var lapKschmPace as String?;
    public var sessionKschm as Float?;
    public var sessionKschmPace as String?;

    //! Constructor
    //! @param dataField Data field to use to create fields
    public function initialize(dataField as KiloschmenzerQuadrantView) {
        if (System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE) {
            _conversionFactor = MILE_CONVERSTION_FACTOR;
        } else {
            _conversionFactor = 1.0;
        }

        var kschmUnitLabel;
        if (_conversionFactor == 1) {
            kschmUnitLabel = "Kiloschmenzers";
        } else {
            kschmUnitLabel = "Kiloschmenzers"; // TODO come up with a funny name that fits
        }
        _sessionKschmField = dataField.createField("Session Kiloschmenzers", 0, FitContributor.DATA_TYPE_FLOAT, { :nativeNum=>0.0, :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>kschmUnitLabel });
        _sessionKschmPaceField = dataField.createField("Session Kiloschmenzer Pace", 1 , FitContributor.DATA_TYPE_STRING, { :count=>10, :nativeNum=>0.0, :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"s/Kschm" });
        _lapKschmPaceField = dataField.createField("Lap Kiloschmenzer Pace", 2, FitContributor.DATA_TYPE_STRING, { :count=>10, :nativeNum=>0.0, :mesgType=>FitContributor.MESG_TYPE_LAP, :units=>"s/Kschm" });
        _lapKschmField = dataField.createField("Lap Kiloschmenzers", 3, FitContributor.DATA_TYPE_FLOAT, { :nativeNum=>0.0, :mesgType=>FitContributor.MESG_TYPE_LAP, :units=>kschmUnitLabel });

        sessionKschm = 0.0;
        lapKschm = 0.0;
        sessionKschmPace = "--:--";
        lapKschmPace = "--:--";
        
    }


    //! Update data and fields
    //! @param sensor The ANT channel and data
    public function compute(info as Activity.Info) as Void {
        if (_timerRunning && info.elapsedDistance != null && info.timerTime != null && info.totalAscent != null) {
            // Update lap/session data and record counts
            _sessionElapsedMs = info.timerTime;
            _lapElapsedMs = _sessionElapsedMs - _sumPreviousLapsMs;
            _sessionDistance = info.elapsedDistance;
            _lapDistance = _sessionDistance - _sumPreviousLapsDistance;
            _sessionVert = info.totalAscent;
            _lapVert = _sessionVert - _sumPreviousLapsVert;
    
            lapKschm = computeKschm(_lapDistance, _lapVert) * _conversionFactor as Float;
            _lapKschmField.setData(lapKschm);
            sessionKschm = computeKschm(_sessionDistance, _sessionVert) * _conversionFactor as Float;
            _sessionKschmField.setData(sessionKschm);
            
            var secsPerKschm;

            if (lapKschm != 0 && lapKschm != null) {
                secsPerKschm = ((_lapElapsedMs / 1000) / lapKschm).toNumber(); // seconds per kiloschmenzer
                lapKschmPace = toMinSec(secsPerKschm);
                _lapKschmPaceField.setData(lapKschmPace);
            } else {
                lapKschmPace = "--:--";
            }

            if (sessionKschm != 0 && sessionKschm != null) {
                secsPerKschm = ((_sessionElapsedMs / 1000) / sessionKschm).toNumber(); // seconds per kiloschmenzer
                sessionKschmPace = toMinSec(secsPerKschm);
                _sessionKschmPaceField.setData(sessionKschmPace);
            } else{
                sessionKschmPace = "--:--";
            }
        }
    }

    private function computeKschm(distanceMeters as Float, vertMeters as Number) as Float {
        var Kschm = (distanceMeters / 1000.0) + (vertMeters / 100.0);
        return Kschm;
    }

    //! Convert to fixed value
    //! @param value Value to fix
    //! @param scale Scale to use
    //! @return Fixed value
    private function toFixed(value as Numeric, scale as Number) as Number {
        return ((value * scale) + 0.5).toNumber();
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

    //! Set whether the timer is running
    //! @param state Whether the timer is running
    public function setTimerRunning(state as Boolean) as Void {
        _timerRunning = state;
    }

    //! Handle lap event
    public function onTimerLap() as Void {
        var info = Activity.getActivityInfo();
        if (info == null) {
            return;
        }

        _sumPreviousLapsMs = info.timerTime;
        _sumPreviousLapsVert = info.totalAscent;
        _sumPreviousLapsDistance = info.elapsedDistance;
        _lapElapsedMs = 0;
        _lapVert = 0;
        _lapDistance = 0.0;
    }

    //! Handle timer reset
    public function onTimerReset() as Void {
        _sumPreviousLapsMs = 0;
        _sumPreviousLapsVert = 0;
        _sumPreviousLapsDistance = 0.0;
        _lapElapsedMs = 0;
        _lapVert = 0;
        _lapDistance = 0.0;
    }

}
