//
// Copyright 2015-2021 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

import Toybox.FitContributor;
import Toybox.Lang;
import Toybox.Activity;
import Toybox.System;

class KschmFitContributor {
    // Field ids
    private enum FieldId {
        FIELD_SESSION_KILOSCHMENZERS,
        FIELD_LAP_KILOSCHMENZERS,
        FIELD_SESSION_KILOSCHMENZER_PACE,
        FIELD_LAP_KILOSCHMENZER_PACE
    }

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

    public var lapKschm as Float?;
    public var lapKschmPace as Number?;
    public var sessionKschm as Float?;
    public var sessionKschmPace as Number?;

    //! Constructor
    //! @param dataField Data field to use to create fields
    public function initialize(dataField as KiloschmenzerQuadrantView) {
        _sessionKschmField = dataField.createField("Session Kiloschmenzers", FIELD_SESSION_KILOSCHMENZERS, FitContributor.DATA_TYPE_FLOAT, { :nativeNum=>0.0, :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"kiloschmenzers" });
        _sessionKschmPaceField = dataField.createField("Session Kiloschmenzer Pace", FIELD_SESSION_KILOSCHMENZER_PACE , FitContributor.DATA_TYPE_SINT32, { :nativeNum=>0.0, :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"s/Kschm" });
        _lapKschmPaceField = dataField.createField("Lap Kiloschmenzer Pace", FIELD_LAP_KILOSCHMENZER_PACE, FitContributor.DATA_TYPE_SINT32, { :nativeNum=>0.0, :mesgType=>FitContributor.MESG_TYPE_LAP, :units=>"s/Kschm" });
        _lapKschmField = dataField.createField("Lap Kiloschmenzers", FIELD_LAP_KILOSCHMENZERS, FitContributor.DATA_TYPE_FLOAT, { :nativeNum=>0.0, :mesgType=>FitContributor.MESG_TYPE_LAP, :units=>"Kiloschmenzers" });

        _sessionKschmField.setData(0.0);
        _lapKschmField.setData(0.0);
        _sessionKschmPaceField.setData(0.0);
        _lapKschmPaceField.setData(0.0);
        lapKschm = 0.0;
        sessionKschm = 0.0;
    }


    //! Update data and fields
    //! @param sensor The ANT channel and data
    public function compute(info as Activity.Info) as Void {
        if (_timerRunning && info.elapsedDistance != null && info.elapsedTime != null && info.totalAscent != null) {
            // Update lap/session data and record counts
            _sessionElapsedMs = info.elapsedTime;
            _lapElapsedMs = _sessionElapsedMs - _sumPreviousLapsMs;
            _sessionDistance = info.elapsedDistance;
            _lapDistance = _sessionDistance - _sumPreviousLapsDistance;
            _sessionVert = info.totalAscent;
            _lapVert = _sessionVert - _sumPreviousLapsVert;

            lapKschm = computeKschm(_lapDistance, _lapVert) as Float;
            sessionKschm = computeKschm(_sessionDistance, _sessionVert) as Float;

            if (lapKschm != 0 && lapKschm != null) {
                lapKschmPace = ((_lapElapsedMs / 1000) / lapKschm).toNumber(); // seconds per kiloschmenzer
            } else {
                lapKschmPace = null;
            }

            if (sessionKschm != 0 && sessionKschm != null) {
                var printer = "Elapsed S: $1$; Elapsed distance: $3$; Session Kschm: $2$; Session vert: $4$;";
                printer = Lang.format(printer, [_sessionElapsedMs/1000, sessionKschm, _sessionDistance/1000, _sessionVert]);

                System.println(printer);
                sessionKschmPace = ((_sessionElapsedMs / 1000) / sessionKschm).toNumber(); // seconds per kiloschmenzer
            } else{
                sessionKschmPace = null;
            }

            _sessionKschmField.setData(sessionKschm);
            _lapKschmField.setData(lapKschm);
            if (sessionKschmPace != null) {_sessionKschmPaceField.setData(sessionKschmPace);}
            if (lapKschmPace != null) {_lapKschmPaceField.setData(lapKschmPace);}
        }
    }

    private function computeKschm(distanceMeters as Float, vertMeters as Number) as Float {
        var Kschm = (distanceMeters / 1000.0) + (vertMeters / 100.0);
        var printer = "computerKschm: distanceMeters = $1$, vertMeters = $2$; Kschm = $3$";
        printer = Lang.format(printer, [distanceMeters, vertMeters, Kschm]);
        System.println(printer);
        return Kschm;
    }

    //! Convert to fixed value
    //! @param value Value to fix
    //! @param scale Scale to use
    //! @return Fixed value
    private function toFixed(value as Numeric, scale as Number) as Number {
        return ((value * scale) + 0.5).toNumber();
    }

    //! Set whether the timer is running
    //! @param state Whether the timer is running
    public function setTimerRunning(state as Boolean) as Void {
        _timerRunning = state;
    }

    //! Handle lap event
    public function onTimerLap() as Void {
        System.println("LAP!");
        var info = Activity.getActivityInfo();
        if (info == null) {
            return;
        }

        _sumPreviousLapsMs = info.elapsedTime;
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
