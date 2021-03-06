function [calibration] = GetRegressionResults(P,cuff)

if P.toggles.doPainOnly
    thresholdVAS = 0;
else
    thresholdVAS = 50;
end
x = P.pain.calibration.pressure(cuff,:);
y = P.pain.calibration.rating(cuff,:);
x2 = x(x > 0 & y > 0);
y2 = y(y > 0 & x > 0);
[predPressureLin,predPressureSig,predPressureRob,betaLin,betaSig,betaRob] = FitData(x2,y2,[thresholdVAS P.pain.calibration.VASTargetsVisual],2);

painThresholdLin = predPressureLin(1);
painThresholdSig = predPressureSig(1);
predPressureLin(1) = []; % remove threshold pressure, retain only VASTargets
predPressureSig(1) = []; % remove threshold pressure, retain only VASTargets

if betaLin(2)<0
    fprintf('\n')
    warning('******************** NEGATIVE SLOPE. This is physiologically highly implausible. Exclude participant.********************');
end

% construct regression results output file
calibration.fitData.interceptLinear = betaLin(1); % lin intercept
calibration.fitData.slopeLinear = betaLin(2); % lin slope
calibration.fitData.interceptSigmoid = betaSig(1); % sig intercept
calibration.fitData.slopeSigmoid = betaSig(2); % sig slope
calibration.fitData.painThresholdAwiszus = P.awiszus.painThresholdFinal; % as per Awiszus thresholding
calibration.fitData.painThresholdLinear = painThresholdLin; % as per linear regression for VAS 0 (pain threshold)
calibration.fitData.painThresholdSigmoid = painThresholdSig; % as per nonlinear regression for VAS 0 (pain threshold)
calibration.fitData.predPressureLinear = predPressureLin;
calibration.fitData.predPressureSigmoid = predPressureSig;

fprintf('\n\n==========REGRESSION RESULTS==========\n');
fprintf('>>> Linear intercept %1.1f, slope %1.1f. <<<\n',betaLin);
fprintf('>>> Sigmoid intercept %1.1f, slope %1.1f. <<<\n',betaSig);
fprintf('To achieve VAS0, use %d kPa (lin) or %d kPa (sig).\n',painThresholdLin,painThresholdSig);
fprintf('This yields for: \n');

for vas = 1:numel(P.pain.calibration.VASTargetsVisual)
    fprintf('- VAS%d: %d kPa (lin), %d kPa (sig)\n',P.pain.calibration.VASTargetsVisual(vas),predPressureLin(vas),predPressureSig(vas));
end

%save(P.out.file.paramCalib, 'P');

end