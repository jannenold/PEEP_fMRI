function [abort,P,expVAS]=ApplyStimulusPain_heat(P,O,trialTemp,block,trial,expVAS,mod,t0_scan)

% be sure to never go higher than 49°C and never lower than
% baseline, otherwise the "cold" can hurt as well
if trialTemp > P.pain.thermoino.maxSaveTemp
    trialTemp = P.pain.thermoino.maxSaveTemp;
elseif trialTemp < P.pain.thermoino.bT
    trialTemp = P.pain.thermoino.bT;
end

abort=0;
[stimDuration]=CalcStimDuration_heat(P,trialTemp,P.presentation.sStimPlateau);

if P.pain.calibration.heat.PeriThrN==1 % Turn on the fixation cross for the first trial (no ITI to cover this)
    InitialTrial(P,O);
elseif P.pain.calibration.heat.PeriThrN == 4
    InitialTrial(P,O);
end

fprintf('%1.1f°C stimulus initiated.',trialTemp);

tHeatOn = GetSecs;
countedDown=1;



tStimStart = GetSecs;
tPlateauStart = tStimStart + stimDuration(1);

if P.devices.thermoino
    UseThermoino('Trigger'); % start next stimulus
    UseThermoino('Set',trialTemp); % open channel for arduino to ramp up

    % Send Trigger to Spike PC
    SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.painOn);

    while GetSecs < tHeatOn + sum(stimDuration(1:2))
        [countedDown]=CountDown(P,GetSecs-tHeatOn,countedDown,'.');
        [abort]=LoopBreaker(P);
        if abort; break; end
    end

    fprintf('\n');
    UseThermoino('Set',P.pain.thermoino.bT); % open channel for arduino to ramp down

    if ~abort
        while GetSecs < tHeatOn + sum(stimDuration)
            [countedDown]=CountDown(P,GetSecs-tHeatOn,countedDown,'.');
            [abort]=LoopBreaker(P);
            if abort; return; end
        end
    else
        return;
    end
else
    

    while GetSecs < tHeatOn + sum(stimDuration)
        [countedDown]=CountDown(GetSecs-tHeatOn,countedDown,'.');
        [abort]=LoopBreaker(P);
        if abort; return; end
    end
end
fprintf(' concluded.\n');

tPlateauStop = GetSecs - stimDuration(3);
tStimStop = GetSecs;

% Send Trigger to Spike PC
SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.restOn);

% Log stimulus
P = log_all_event(P, tStimStart, 'start_heat',trial,t0_scan);
P = log_all_event(P, tPlateauStart, 'start_plateau_heat',trial,t0_scan);
P = log_all_event(P, tPlateauStop, 'stop_plateau_heat',trial,t0_scan);
P = log_all_event(P, tStimStop, 'stop_heat',trial,t0_scan);


% VAS Rating and Output

tVASStart = GetSecs;

if ~O.debug.toggleVisual
    cuff = 0;
    [abort,P,expVAS] = expStimVASRating(P,O,block,cuff,trial,trialTemp,expVAS,mod);
end

tVASstop = GetSecs;

% Log VAS
P = log_all_event(P, tVASStart, 'start_VAS',trial,t0_scan);
P = log_all_event(P, tVASstop, 'stop_VAS',trial,t0_scan);

% Save CPAR Data
end