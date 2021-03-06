function [abort,P] = calibStimVASRating(P,O,calibStep,cuff,trial,trialPressure)

abort = 0;

while ~abort
    
    [abort,finalRating,reactionTime,keyId,keyTime,response] = singleratingScale_bigger(P,2);
    
    VASFile = fullfile(P.out.dirCalib, [P.out.file.VAS '_calibration.mat']);
    
    if exist(VASFile,'file')
        VASData = load(VASFile);
        VAS = VASData.VAS;
    end
    
    clear calibData
    calibData.trialPressure = trialPressure;
    calibData.finalRating = finalRating;
    calibData.reactionTime = reactionTime;
    calibData.keyId = keyId;
    calibData.keyTime = keyTime;
    calibData.response = response;
    
    if calibStep == 1
        if size(P.pain.calibration.pressure) == P.pain.psychScaling.trials
            P.pain.PEEP.pressure(cuff,P.pain.psychScaling.trials+trial) = trialPressure;
            P.pain.PEEP.rating(cuff,P.pain.psychScaling.trials+trial) = finalRating;
        else
            P.pain.calibration.pressure(cuff,trial) = trialPressure;
            P.pain.calibration.rating(cuff,trial) = finalRating;
        end
    elseif calibStep == 2
        itemNo = size(P.pain.calibration.pressure,2) + 1; 
%         itemNo = P.pain.psychScaling.trials+trial; % start from after Psychometric Scaling trials
        P.pain.calibration.pressure(cuff,itemNo) = trialPressure;
        P.pain.calibration.rating(cuff,itemNo) = finalRating;
    elseif calibStep == 3
        itemNo = size(P.pain.calibration.pressure,2) + 1; 
%         itemNo = P.pain.psychScaling.trials+numel(P.pain.Calibration.VASTargetsFixed)+trial; % start from after Psychometric Scaling and Fixed Intensity trials
        P.pain.calibration.pressure(cuff,itemNo) = trialPressure;
        P.pain.calibration.rating(cuff,itemNo) = finalRating;
    end
    
    VAS(calibStep,cuff).calibStep(trial) = calibData;
    P.VAS = VAS;
    % Save on every trial
    % fprintf(' Saving VAS data... ')
    save(VASFile, 'VAS');
    
    if ~O.debug.toggleVisual
        Screen('Flip',P.display.w);
    end
    
    break;
    
end

end