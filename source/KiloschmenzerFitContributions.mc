//
// Copyright 2015-2021 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

import Toybox.FitContributor;
import Toybox.Lang;
import Toybox.Activity;


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

    //! Constructor
    //! @param dataField Data field to use to create fields
    public function initialize(dataField as KiloschmenzerField) {
        _sessionKschmField = DataField.createField("sessKschm", FIELD_SESSION_KILOSCHMENZERS, FitContributor.DATA_TYPE_FLOAT, { :nativeNum=>0.0, :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"kiloschmenzers" });
        _lapKschmField = DataField.createField("lapKschm", FIELD_LAP_KILOSCHMENZERS, FitContributor.DATA_TYPE_FLOAT, { :nativeNum=>0.0, :mesgType=>FitContributor.MESG_TYPE_LAP, :units=>"seconds per Kiloschmenzer" });
        _sessionKschmPaceField = DataField.createField("sessKschmPace", FIELD_SESSION_KILOSCHMENZER_PACE , FitContributor.DATA_TYPE_FLOAT, { :nativeNum=>0.0, :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"kiloschmenzers" });
        _lapKschmPaceField = DataField.createField("lapKschmPace", FIELD_LAP_KILOSCHMENZER_PACE, FitContributor.DATA_TYPE_FLOAT, { :nativeNum=>0.0, :mesgType=>FitContributor.MESG_TYPE_LAP, :units=>"seconds per kiloschmenzer" });

        _sessionKschmField.setData(0.0);
        _lapKschmField.setData(0.0);
        _sessionKschmPaceField.setData(0.0);
        _lapKschmPaceField.setData(0.0);
    }


    //! Update data and fields
    //! @param sensor The ANT channel and data
    public function compute(info as Activity.info) as Void {
        if (_timerRunning && info.elapsedDistance != null && info.elapsedTime != null && info.totalAscent != null) {
            // Update lap/session data and record counts
            _sessionElapsedMs = info.elapsedTime;
            _lapElapsedMs = _sessionElapsedMs - _sumPreviousLapsMs;
            _sessionDistance = info.elapsedDistance;
            _lapDistance = _sessionDistance - _sumPreviousLapsDistance;
            _sessionVert = info.totalAscent;
            _lapVert = _sessionVert - _sumPreviousLapsVert;

            lapKschm = computeKschm(_lapDistance, _lapVert);
            lapKschmPace = ((_lapElapsedMs / lapKschm) / 1000).toNumber(); // seconds per kiloschmenzer
            sessionKschm = computeKschm(_sessionDistance, _sessionVert);
            sessionKschmPace = ((_sessionElapsedMs / sessionKschm) / 1000).toNumber(); // seconds per kiloschmenzer

            _sessionKschmField.setData(sessionKschm);
            _lapKschmField.setData(lapKschm);
            _sessionKschmPaceField.setData(sessionKschmPace);
            _lapKschmPaceField.setDAta(lapKschmPace);
            // TODO return some data structure w/ all these values to the DataField
            // TODO add stuff to resources.xml
        }
    }

    private function computeKschm(distanceMeters as Float, vertMeters as Number) as Float {
        return (distanceMeters / 1000.0) + (vertMeters / 100.0)
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
        info = getActivityInfo();
        if (info == null) {
            return
        }

        _sumPreviousLapsMs += (info.elapsedTime - _lapElapsedMs);
        _sumPreviousLapsVert += (info.totalAscent - _lapVert);
        _sumPreviousLapsDistance += (info.elapsedDistance - _lapElapsedDistance)
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
    // private var _sessionDistance as Float = 0.0;
    // private var _lapDistance as Float = 0.0;
    // private var _lapElapsedMs as Number = 0;
    // private var _sessionElapsedMs as Number = 0;
    // private var _sessionVert as Number = 0;
    // private var _lapVert as Number = 0;
    // private var _sumPreviousLapsMs as Number = 0;
    // private var _sumPreviousLapsDistance as Float = 0.0;
    // private var _sumPreviousLapsVert as Number = 0;
    // private var _timerRunning as Boolean = false;
