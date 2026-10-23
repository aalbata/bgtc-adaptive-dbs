function build_models(outDir)
%BUILD_MODELS Build the baseline and DBS Simulink models of the BGTC loop.
%   BUILD_MODELS(OUTDIR) creates bgtc_baseline.slx and bgtc_dbs.slx in
%   OUTDIR and leaves both models loaded. Block parameters refer to the
%   structure P in the base workspace, so every simulation reads the values
%   assigned there immediately before the call to SIM.
%
%   Baseline model: seven populations, motor-command step, prescribed beta
%   input, no noise and no stimulation.
%   DBS model: the baseline model plus cortical and STN noise and an
%   effective suppressive stimulation input to the STN, selected between a
%   fixed command (P.DBS_mode = 0) and a saturated PI controller acting on
%   the error between TH_ref and the observed thalamic output (P.DBS_mode
%   = 1). The observation is the thalamic output delayed by P.sensorDelay,
%   shifted by P.sensorBias, and corrupted by a held Gaussian sequence of
%   standard deviation P.sensorNoise; with the default values it equals
%   the thalamic output.

if nargin < 1, outDir = pwd; end
if ~exist(outDir, 'dir'), mkdir(outDir); end
w = warning('off', 'Simulink:blocks:TDelayDirectThroughAutoSet');
restore = onCleanup(@() warning(w));
assignin('base', 'P', bgtc_params());
P = bgtc_params();
build_one(P.modelBaseline, false, P, outDir);
build_one(P.modelDBS, true, P, outDir);
end

function build_one(model, withDBS, P, outDir)
if bdIsLoaded(model), close_system(model, 0); end
file = fullfile(outDir, [model '.slx']);
if exist(file, 'file'), delete(file); end
new_system(model);
set_param(model, 'StopTime', 'P.StopTime', 'Solver', P.Solver, ...
    'MaxStep', num2str(P.MaxStep));

add_block('simulink/Sources/Step', [model '/CommandStep'], ...
    'Time', 'P.cmdStepTime', 'Before', '0', 'After', 'P.cmdAmplitude');
add_block('simulink/Sources/Constant', [model '/TonicTH'], 'Value', 'P.I_tonic');
add_block('simulink/Sources/Constant', [model '/D1_scale'], 'Value', '1 + P.kD1*P.D');
add_block('simulink/Sources/Constant', [model '/D2_scale'], 'Value', '1 - P.kD2*P.D');
add_block('simulink/Sources/Sine Wave', [model '/BetaDrive_STN'], ...
    'Amplitude', 'P.betaDriveAmp', 'Frequency', '2*pi*P.betaDriveFreq', ...
    'Phase', '0', 'Bias', '0', 'SampleTime', '0');

if withDBS
    add_block('simulink/Math Operations/Sum', [model '/Sum_Cortex'], 'Inputs', '+++');
    add_block('simulink/Math Operations/Sum', [model '/Sum_STN'], 'Inputs', '+++++');
else
    add_block('simulink/Math Operations/Sum', [model '/Sum_Cortex'], 'Inputs', '++');
    add_block('simulink/Math Operations/Sum', [model '/Sum_STN'], 'Inputs', '+++');
end
add_block('simulink/Math Operations/Sum', [model '/Sum_GPe'], 'Inputs', '++');
add_block('simulink/Math Operations/Sum', [model '/Sum_GPi'], 'Inputs', '+++');
add_block('simulink/Math Operations/Sum', [model '/Sum_TH'], 'Inputs', '++');

gains = {
    'Gain_TC',     'P.w_TC';
    'Gain_CD1',    'P.w_CD1';
    'Gain_CD2',    'P.w_CD2';
    'Gain_D2GPe',  '-P.w_D2GPe';
    'Gain_STNGPe', 'P.w_STNGPe';
    'Gain_CSTN',   'P.w_CSTN';
    'Gain_GPeSTN', '-P.w_GPeSTN';
    'Gain_STNGPi', 'P.w_STNGPi';
    'Gain_D1GPi',  '-P.w_D1GPi';
    'Gain_GPeGPi', '-P.w_GPeGPi';
    'Gain_GPiTH',  '-P.w_GPiTH'};
for k = 1:size(gains, 1)
    add_block('simulink/Math Operations/Gain', [model '/' gains{k,1}], 'Gain', gains{k,2});
end
add_block('simulink/Math Operations/Product', [model '/Prod_D1']);
add_block('simulink/Math Operations/Product', [model '/Prod_D2']);

delays = {'Delay_TC', 'P.delay_TC'; 'Delay_CSTN', 'P.delay_CSTN';
    'Delay_GPeSTN', 'P.delay_GPeSTN'; 'Delay_STNGPe', 'P.delay_STNGPe';
    'Delay_STNGPi', 'P.delay_STNGPi'; 'Delay_GPiTH', 'P.delay_GPiTH'};
for k = 1:size(delays, 1)
    add_block('simulink/Continuous/Transport Delay', [model '/' delays{k,1}], ...
        'DelayTime', delays{k,2});
end

nodes = {'Cortex', 'P.tauC'; 'D1', 'P.tauD1'; 'D2', 'P.tauD2'; 'GPe', 'P.tauGPe';
    'STN', 'P.tauSTN'; 'GPi', 'P.tauGPi'; 'Thalamus', 'P.tauTH'};
for k = 1:size(nodes, 1)
    make_node(model, nodes{k,1}, nodes{k,2});
end

% Loop wiring common to both models
line(model, 'CommandStep/1', 'Sum_Cortex/1');
line(model, 'Thalamus/1', 'Gain_TC/1');
line(model, 'Gain_TC/1', 'Delay_TC/1');
line(model, 'Delay_TC/1', 'Sum_Cortex/2');
line(model, 'Sum_Cortex/1', 'Cortex/1');
line(model, 'Cortex/1', 'Gain_CD1/1');
line(model, 'Gain_CD1/1', 'Prod_D1/1');
line(model, 'D1_scale/1', 'Prod_D1/2');
line(model, 'Prod_D1/1', 'D1/1');
line(model, 'Cortex/1', 'Gain_CD2/1');
line(model, 'Gain_CD2/1', 'Prod_D2/1');
line(model, 'D2_scale/1', 'Prod_D2/2');
line(model, 'Prod_D2/1', 'D2/1');
line(model, 'D2/1', 'Gain_D2GPe/1');
line(model, 'Gain_D2GPe/1', 'Sum_GPe/1');
line(model, 'Sum_GPe/1', 'GPe/1');
line(model, 'Cortex/1', 'Delay_CSTN/1');
line(model, 'Delay_CSTN/1', 'Gain_CSTN/1');
line(model, 'Gain_CSTN/1', 'Sum_STN/1');
line(model, 'GPe/1', 'Delay_GPeSTN/1');
line(model, 'Delay_GPeSTN/1', 'Gain_GPeSTN/1');
line(model, 'Gain_GPeSTN/1', 'Sum_STN/2');
line(model, 'STN/1', 'Delay_STNGPe/1');
line(model, 'Delay_STNGPe/1', 'Gain_STNGPe/1');
line(model, 'Gain_STNGPe/1', 'Sum_GPe/2');
line(model, 'Sum_STN/1', 'STN/1');
line(model, 'STN/1', 'Delay_STNGPi/1');
line(model, 'Delay_STNGPi/1', 'Gain_STNGPi/1');
line(model, 'Gain_STNGPi/1', 'Sum_GPi/1');
line(model, 'D1/1', 'Gain_D1GPi/1');
line(model, 'Gain_D1GPi/1', 'Sum_GPi/2');
line(model, 'GPe/1', 'Gain_GPeGPi/1');
line(model, 'Gain_GPeGPi/1', 'Sum_GPi/3');
line(model, 'Sum_GPi/1', 'GPi/1');
line(model, 'GPi/1', 'Delay_GPiTH/1');
line(model, 'Delay_GPiTH/1', 'Gain_GPiTH/1');
line(model, 'Gain_GPiTH/1', 'Sum_TH/1');
line(model, 'TonicTH/1', 'Sum_TH/2');
line(model, 'Sum_TH/1', 'Thalamus/1');

if withDBS
    % Disturbances: zero-mean unit-variance sequences held over
    % P.noiseSampleTime and scaled by the standard deviations
    add_block('simulink/Sources/Random Number', [model '/NoiseSrc_Cortex'], ...
        'Mean', '0', 'Variance', '1', 'SampleTime', 'P.noiseSampleTime', 'Seed', 'P.seedC');
    add_block('simulink/Sources/Random Number', [model '/NoiseSrc_STN'], ...
        'Mean', '0', 'Variance', '1', 'SampleTime', 'P.noiseSampleTime', 'Seed', 'P.seedSTN');
    add_block('simulink/Math Operations/Gain', [model '/NoiseGain_Cortex'], 'Gain', 'P.noiseAmpC');
    add_block('simulink/Math Operations/Gain', [model '/NoiseGain_STN'], 'Gain', 'P.noiseAmpSTN');

    % Observed thalamic output y = TH(t - sensorDelay) + sensorBias + noise
    add_block('simulink/Continuous/Transport Delay', [model '/Sensor_Delay'], ...
        'DelayTime', 'P.sensorDelay');
    add_block('simulink/Sources/Random Number', [model '/NoiseSrc_Sensor'], ...
        'Mean', '0', 'Variance', '1', 'SampleTime', 'P.noiseSampleTime', 'Seed', 'P.seedSens');
    add_block('simulink/Math Operations/Gain', [model '/NoiseGain_Sensor'], 'Gain', 'P.sensorNoise');
    add_block('simulink/Sources/Constant', [model '/Sensor_Bias'], 'Value', 'P.sensorBias');
    add_block('simulink/Math Operations/Sum', [model '/Sum_Sensor'], 'Inputs', '+++');

    % Stimulation command: PI on e = TH_ref - y, saturated to [0, DBS_max],
    % or a constant command, selected by P.DBS_mode
    add_block('simulink/Sources/Constant', [model '/TH_ref'], 'Value', 'P.TH_ref');
    add_block('simulink/Math Operations/Sum', [model '/Sum_DBS_Error'], 'Inputs', '+-');
    add_block('simulink/Continuous/PID Controller', [model '/PID_DBS'], ...
        'P', 'P.Kp', 'I', 'P.Ki', 'D', 'P.Kd');
    add_block('simulink/Discontinuities/Saturation', [model '/Sat_DBS'], ...
        'UpperLimit', 'P.DBS_max', 'LowerLimit', '0');
    add_block('simulink/Sources/Constant', [model '/OpenLoop_DBS'], 'Value', 'P.DBS_open_effective');
    add_block('simulink/Sources/Constant', [model '/DBS_mode'], 'Value', 'P.DBS_mode');
    add_block('simulink/Signal Routing/Switch', [model '/DBS_Switch'], ...
        'Threshold', '0.5', 'Criteria', 'u2 >= Threshold');
    add_block('simulink/Math Operations/Gain', [model '/DBS_Effect'], 'Gain', '-P.DBS_effect_gain');

    line(model, 'NoiseSrc_Cortex/1', 'NoiseGain_Cortex/1');
    line(model, 'NoiseSrc_STN/1', 'NoiseGain_STN/1');
    line(model, 'NoiseGain_Cortex/1', 'Sum_Cortex/3');
    line(model, 'TH_ref/1', 'Sum_DBS_Error/1');
    line(model, 'Thalamus/1', 'Sensor_Delay/1');
    line(model, 'Sensor_Delay/1', 'Sum_Sensor/1');
    line(model, 'Sensor_Bias/1', 'Sum_Sensor/2');
    line(model, 'NoiseSrc_Sensor/1', 'NoiseGain_Sensor/1');
    line(model, 'NoiseGain_Sensor/1', 'Sum_Sensor/3');
    line(model, 'Sum_Sensor/1', 'Sum_DBS_Error/2');
    line(model, 'Sum_DBS_Error/1', 'PID_DBS/1');
    line(model, 'PID_DBS/1', 'Sat_DBS/1');
    line(model, 'Sat_DBS/1', 'DBS_Switch/1');
    line(model, 'DBS_mode/1', 'DBS_Switch/2');
    line(model, 'OpenLoop_DBS/1', 'DBS_Switch/3');
    line(model, 'DBS_Switch/1', 'DBS_Effect/1');
    line(model, 'DBS_Effect/1', 'Sum_STN/3');
    line(model, 'BetaDrive_STN/1', 'Sum_STN/4');
    line(model, 'NoiseGain_STN/1', 'Sum_STN/5');
else
    line(model, 'BetaDrive_STN/1', 'Sum_STN/3');
end

names = {'Cortex', 'D1', 'D2', 'GPe', 'STN', 'GPi', 'Thalamus'};
vars  = {'C', 'D1', 'D2', 'GPe', 'STN', 'GPi', 'TH'};
if withDBS
    names{end+1} = 'DBS_Switch'; vars{end+1} = 'DBS';
end
for k = 1:numel(names)
    add_block('simulink/Sinks/To Workspace', [model '/ToWs_' vars{k}], ...
        'VariableName', vars{k}, 'SaveFormat', 'StructureWithTime');
    line(model, [names{k} '/1'], ['ToWs_' vars{k} '/1']);
end

Simulink.BlockDiagram.arrangeSystem(model);
save_system(model, file);
end

function make_node(model, name, tauExpr)
% Population node: static sigmoid followed by a first-order lag,
% tau*dx/dt = -x + F(u), F(u) = 1/(1 + exp(-4(u - 0.2)))
blk = [model '/' name];
add_block('simulink/Ports & Subsystems/Subsystem', blk);
try, delete_line(blk, 'In1/1', 'Out1/1'); catch, end
try, delete_block([blk '/In1']); catch, end
try, delete_block([blk '/Out1']); catch, end
add_block('simulink/Ports & Subsystems/In1', [blk '/u']);
add_block('simulink/User-Defined Functions/Fcn', [blk '/actfun'], 'Expr', '1/(1+exp(-4*(u-0.2)))');
add_block('simulink/Continuous/Transfer Fcn', [blk '/Dyn'], ...
    'Numerator', '1', 'Denominator', ['[' tauExpr ' 1]']);
add_block('simulink/Ports & Subsystems/Out1', [blk '/y']);
line(blk, 'u/1', 'actfun/1');
line(blk, 'actfun/1', 'Dyn/1');
line(blk, 'Dyn/1', 'y/1');
end

function line(sys, from, to)
add_line(sys, from, to, 'autorouting', 'on');
end
