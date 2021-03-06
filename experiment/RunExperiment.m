function [abort] = RunExperiment(P,O,dev)
% This function inititates the 5 minute cycling on screen with a fixation
% cross and a countdown (300 - 0). It will not have any output apart from
% the seconds the exercise lasted.
%
% Author: Janne Nold
% based on the script by Björn Höring, Uli Bromberg, Lukas Neugebauer
% Last modified: 02.12.21

% Retrieve text
strings = GetText;
abort = 0;
fprintf('\n==========================\nRunning Experiment.\n==========================\n');


%% Retrieve predicted pressure intensity levels from calibration

% retrieve predicted pressures (linear)
if isfield(P.pain.calibration.results.fitData,'predPressureLinear')
    predPressure = P.pain.calibration.results.fitData.predPressureLinear;
else
    warning('No predicted pressures found, using DEFAULT instead');
    predPressure = P.pain.calibration.defaultpredPressureLinear;
end

% Low Low Pressure
%P.pain.PEEP.VASindex = P.pain.calibration.VASTargetsVisual == 10;
%preVAS = predPressure(P.pain.PEEP.VASindex);
%low_low_pressure = preVAS;

% Medium Low Pressure
P.pain.PEEP.VASindex = P.pain.calibration.VASTargetsVisual == 30;
preVAS = predPressure(P.pain.PEEP.VASindex);
med_low_pressure = preVAS;

% Medium High Pressure
P.pain.PEEP.VASindex = P.pain.calibration.VASTargetsVisual == 50;
preVAS = predPressure(P.pain.PEEP.VASindex);
med_high_pressure = preVAS;

% High High Pressure
P.pain.PEEP.VASindex = P.pain.calibration.VASTargetsVisual == 70;
preVAS = predPressure(P.pain.PEEP.VASindex);
high_high_pressure = preVAS;


%% Retrieve predicted heat intensity levels from calibration

% retrieve predicted pressures (linear)
if isfield(P.pain.calibration.thermode.results.fitData,'predPressureLinear')
    predPressure = P.pain.calibration.thermode.results.fitData.predPressureLinear;
else
    warning('No predicted pressures found, using DEFAULT instead');
    predPressure = P.pain.calibration.thermode.defaultpredPressureLinear;
end


% Medium Low Pressure
P.pain.PEEP.thermode.VASindex = P.pain.calibration.VASTargetsVisual == 30;
preVAS = predPressure(P.pain.PEEP.thermode.VASindex);
med_low_pressure_heat = preVAS;

% Medium High Pressure
P.pain.PEEP.thermode.VASindex = P.pain.calibration.VASTargetsVisual == 50;
preVAS = predPressure(P.pain.PEEP.thermode.VASindex);
med_high_pressure_heat = preVAS;

% High High Pressure
P.pain.PEEP.thermode.VASindex = P.pain.calibration.VASTargetsVisual == 70;
preVAS = predPressure(P.pain.PEEP.thermode.VASindex);
high_high_pressure_heat = preVAS;



%% Run through exercise and pain blocks (6 blocks)
expVAS = [];
exerciseVAS = [];

for block = 1:P.pain.PEEP.nBlocks

    while ~abort

        % White Fixcross
        if ~O.debug.toggleVisual
            Screen('FillRect', P.display.w, P.style.white, P.fixcross.Fix1);
            Screen('FillRect', P.display.w, P.style.white, P.fixcross.Fix2);
            tCrossOn = Screen('Flip',P.display.w);
        else
            tCrossOn = GetSecs;
        end


        for cuff = P.experiment.cuff_arm

            fprintf(['\n' 'Thermode Left Arm' ...
                '\n CPAR Left Arm' ]);

            fprintf(['\nBlock ' num2str(P.pain.PEEP.blocks(block))]);

            if ~O.debug.toggleVisual
                upperHalf = P.display.screenRes.height/2;
                Screen('TextSize', P.display.w, 70);
                introTextOn = Screen('Flip',P.display.w);
            else
                introTextOn = GetSecs;
            end

            % Abort Block if neccesary at start
            while GetSecs < introTextOn + P.pain.calibration.blockstopWait
                [abort]=LoopBreaker(P);
                if abort; break; end
            end

            % Give experimenter chance to abort if neccesary
            fprintf('\nContinue [%s], or abort [%s].\n',upper(char(P.keys.keyList(P.keys.name.confirm))),upper(char(P.keys.keyList(P.keys.name.esc))));

            while 1
                [keyIsDown, ~, keyCode] = KbCheck();
                if keyIsDown
                    if find(keyCode) == P.keys.name.confirm
                        break;
                    elseif find(keyCode) == P.keys.name.esc
                        abort = 1;
                        break;
                    end
                end
            end
            if abort; return; end

            WaitSecs(0.2);


            %% ------------------Exercise -----------------------------

            if ~O.debug.toggleVisual
                upperHalf = P.display.screenRes.height/2;
                Screen('TextSize', P.display.w, 100);

                % Display on screen which arm and what is happening
                if strcmp(P.language,'de')
                    [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, ['Block ' num2str(P.pain.PEEP.blocks(block))], 'center', upperHalf, P.style.white);
                    Screen('Flip',P.display.w);
                    WaitSecs(3);

                    % Display to participant whether high or low intensity
                    % cycling
                    if P.exercise.condition(block) == 1
                        int = 1;

                        % save the condition in log file
                        P.exercise.results(block).condition = 1;
                        [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w,'Hohe Intensität', 'center', upperHalf, P.style.white);

                    elseif P.exercise.condition(block) == 0
                        int = 0;

                        % save the condition in log file
                        P.exercise.results(block).condition = 0;
                        [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'Niedrige Intensität', 'center', upperHalf, P.style.white);

                    end
                    Screen('Flip',P.display.w);
                    WaitSecs(3);
                end

                Screen('TextSize', P.display.w, 30);
                introTextOn = Screen('Flip',P.display.w);

            end

            % Ready... Exercise Intro
            Screen('TextSize',P.display.w, 50);
            DrawFormattedText(P.display.w, strings.exercise1, 'center', 'center',P.style.white2,[],[],[],2,[]);
            Screen('Flip',P.display.w);

            tStartCycle = GetSecs;

            % Wait 5 Seconds before starting the cycling
            countedDown = 1;
            while GetSecs < tStartCycle + P.exercise.wait
                tmp=num2str(SecureRound(GetSecs-tStartCycle,0));
                [abort,countedDown] = CountDown(P,GetSecs-tStartCycle,countedDown,[tmp ' ']);
                if abort; break; end
            end


            % Run Countdown for participant (3...2...1..0... Los!)
            fprintf('\nRunning Countdown....\n');
            RunCountDown(P);
            Screen('Flip',P.display.w);


            % Display Exercise Start at experimenter screen
            fprintf('=========================================================\n');
            fprintf('Exercise Start\n');
            fprintf('=========================================================\n');

            % Get Timing
            tStartCycle = GetSecs;

            % Apply Exercise Stimulus
            [abort,P,exerciseVAS] = ApplyStimulusExercise(P,O,P.exercise.constPressure,cuff,block,dev,exerciseVAS,int); % run stimulus
            save(P.out.file.paramExp,'P','O'); % Save instantiated parameters and overrides after each trial (includes timing information)
            if abort; break; end

            % Get the end time of exercise block
            P.time.exerciseBlockEnd(block,1) = GetSecs-P.time.scriptStart;
            save(P.out.file.paramExp,'P','O');




            if abort; break; end


            %% Pause/Interval

            % White fixation cross
            if ~O.debug.toggleVisual
                Screen('FillRect', P.display.w, P.style.white, P.fixcross.Fix1);
                Screen('FillRect', P.display.w, P.style.white, P.fixcross.Fix2);
                tCrossOn = Screen('Flip',P.display.w);
            else
                tCrossOn = GetSecs;
            end

            % RunCountdown for experimenter for elapsed time
            durationPause = 420;
            countedDown = 1;

            while GetSecs < tCrossOn + durationPause
                tmp=num2str(SecureRound(GetSecs-tCrossOn,0));
                [countedDown] = CountDown(P,GetSecs-tCrossOn,countedDown,[tmp ' ']);
                if keyIsDown; break; end
            end

            %% ------------------ Pain -----------------------------
          
            % Give experimenter chance to abort if neccesary
            fprintf('\nContinue [%s], or abort [%s].\n',upper(char(P.keys.keyList(P.keys.name.confirm))),upper(char(P.keys.keyList(P.keys.name.esc))));

            while 1
                [keyIsDown, ~, keyCode] = KbCheck();
                if keyIsDown
                    if find(keyCode) == P.keys.name.confirm
                        break;
                    elseif find(keyCode) == P.keys.name.esc
                        abort = 1;
                        break;
                    end
                end
            end
            if abort; return; end

            %(Get Time of Pause)
            P.time.pause_ex_pain(block,1) = GetSecs - P.time.exerciseBlockEnd(block,1);

            WaitSecs(0.2);

          
            % Give two pre exposure stimuli
            fprintf('=========================================================\n');
            fprintf('\Pre Exposure\n');
            fprintf('=========================================================\n');

            PreExposure(P,O,dev);

            % Display Exercise Start at experimenter screen
            fprintf('=========================================================\n');
            fprintf('\nPain Start\n');
            fprintf('=========================================================\n');

            % Loop through the number of pain trials per block
            clear trial
            for trial = 1:P.pain.PEEP.trialsPerBlock

                fprintf('\n\n======= BLOCK %d, PAIN TRIAL %d =======\n',block,trial);

                % retrieve pressure intensitiy from matrix according to level (1,3,5,7)
                if P.pain.PEEP.painconditions_mat(block,trial) == 1 % low intensity

                    %retrieve pressure calibrated for 10 VAS
                    pressure = low_low_pressure;
                    fprintf(['\nPain: Low-Low Intensity 10 VAS at ',num2str(pressure), ' kPa\n']);

                elseif P.pain.PEEP.painconditions_mat(block,trial) == 3 % mid low intensity

                    %retrieve pressure calibrated for 30 VAS
                    pressure = med_low_pressure;
                    fprintf(['\nPain: Medium-Low Intensity 30 VAS at ',num2str(pressure), ' kPa\n']);

                elseif P.pain.PEEP.painconditions_mat(block,trial) == 5 % mid high intensity

                    %retrieve pressure calibrated for 50 VAS
                    pressure = med_high_pressure;
                    fprintf(['\nPain: Medium-High Intensity 50 VAS at ',num2str(pressure), ' kPa\n']);

                elseif P.pain.PEEP.painconditions_mat(block,trial) == 7 % intensity high high

                    %retrieve pressure calibrated for 70 VAS
                    pressure = high_high_pressure;
                    fprintf(['\nPain: High-High Intensity 70 VAS at ',num2str(pressure), ' kPa\n']);
                end

                % Red fixation cross
                if ~O.debug.toggleVisual
                    Screen('FillRect', P.display.w, P.style.red, P.fixcross.Fix1);
                    Screen('FillRect', P.display.w, P.style.red, P.fixcross.Fix2);
                    Screen('Flip',P.display.w);
                end


                % Apply the pain after correct pressure was selected
                [abort,P,expVAS] = ApplyStimulusPain(P,O,pressure,cuff,block,trial,expVAS);

                if abort; break; end

                % White fixation cross
                if ~O.debug.toggleVisual
                    Screen('FillRect', P.display.w, P.style.white, P.fixcross.Fix1);
                    Screen('FillRect', P.display.w, P.style.white, P.fixcross.Fix2);
                    tCrossOn = Screen('Flip',P.display.w);
                else
                    tCrossOn = GetSecs;
                end

                % Save instantiated parameters and overrides after each trial
                save(P.out.file.paramExp,'P','O');

                % Wait for xx ITI before continuing
                iti = P.project.ITI_rand(P.project.ITI_start);
                fprintf(['ITI: ',num2str(iti), ' seconds'])
                WaitSecs(iti);
                tITIafterRating = GetSecs;

                % Calculate ITI after 7 sec rating:
                tITI = tITIafterRating - tCrossOn;
                P.experiment.tITI(block,trial) = tITI;

                % update trial counter
                P.project.ITI_start = P.project.ITI_start + 1; 
                trial = trial + 1;

            end



        end

        %display fixation cross
        Screen('FillRect', P.display.w, P.style.white, P.fixcross.Fix1);
        Screen('FillRect', P.display.w, P.style.white, P.fixcross.Fix2);
        Screen('Flip',P.display.w);
        WaitSecs(1);

        block = block + 1;

        if block > 4
            abort = 1;
            break;
        end
    end
end

end











