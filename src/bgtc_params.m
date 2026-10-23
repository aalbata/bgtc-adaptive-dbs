function P = bgtc_params()
%BGTC_PARAMS Nominal parameters of the seven-population BGTC model.
%   P = BGTC_PARAMS() returns the parameter structure used by every
%   simulation. Activities, connection gains, dopamine and stimulation
%   commands are normalized (a.u.). The dopamine-dependent gains are set for
%   the moderate-PD level D = 0.35; use APPLY_DOPAMINE to change D.

P.modelBaseline = 'bgtc_baseline';
P.modelDBS      = 'bgtc_dbs';

% Numerical settings
P.StopTime = 15;              % s
P.Solver   = 'ode45';         % Dormand-Prince 4(5), variable step
P.MaxStep  = 0.001;           % s
P.RelTol   = 1e-3;            % relative tolerance of the solver
P.psdStartTime = 3.0;         % s, start of the post-transient spectral window
P.psdFs = 500;                % Hz, uniform resampling rate for the PSD
P.betaBand = [13 30];         % Hz
P.steadyFraction = 0.20;      % late window [(1 - 0.20) T, T] of a run of length T
P.onTargetTol = 0.01;         % on target: |TH late mean - TH_ref| < 0.01
P.randomSeed = 20260905;      % generator seed of the virtual-cohort design

% Dopamine
P.D = 0.35;                   % normalized dopamine, 1 = healthy reference
P.kD1 = 0.8;
P.kD2 = 0.8;

% Population time constants (s)
P.tauC   = 0.030;
P.tauD1  = 0.040;
P.tauD2  = 0.040;
P.tauGPe = 0.050;
P.tauSTN = 0.020;
P.tauGPi = 0.040;
P.tauTH  = 0.030;

% Connection gains (magnitudes; inhibitory signs are applied in the model)
P.w_TC          = 1.20;       % thalamus -> cortex (+)
P.w_CD1         = 1.00;       % cortex -> D1 (+)
P.w_CD2         = 1.00;       % cortex -> D2 (+)
P.w_CSTN        = 0.80;       % cortex -> STN (+)
P.w_D1GPi       = 1.20;       % D1 -> GPi (-)
P.w_D2GPe       = 1.00;       % D2 -> GPe (-)
P.w_GPeSTN_base = 1.15;       % GPe -> STN (-), value at D = 1
P.w_STNGPe_base = 0.85;       % STN -> GPe (+), value at D = 1
P.w_STNGPi_base = 1.30;       % STN -> GPi (+), value at D = 1
P.w_GPeGPi      = 0.60;       % GPe -> GPi (-)
P.w_GPiTH_base  = 1.45;       % GPi -> thalamus (-), value at D = 1

% Severity coefficients of the dopamine-dependent gains
P.betaCouplingGain  = 0.55;   % reciprocal GPe-STN gains
P.stnGpiDiseaseGain = 0.30;   % STN -> GPi gain
P.gpiThDiseaseGain  = 0.25;   % GPi -> thalamus gain

% Prescribed 20-Hz beta input at the STN
P.betaDriveFreq        = 20;     % Hz
P.betaDriveHealthy     = 0.002;  % amplitude at D = 1
P.betaDriveDiseaseGain = 0.10;   % increment at complete depletion
P.betaDriveExponent    = 1.50;   % severity exponent
P.betaDriveAmp = P.betaDriveHealthy;

P.w_GPeSTN = P.w_GPeSTN_base;
P.w_STNGPe = P.w_STNGPe_base;
P.w_STNGPi = P.w_STNGPi_base;
P.w_GPiTH  = P.w_GPiTH_base;

% Tonic thalamic input and transmission delays (s)
P.I_tonic      = 0.30;
P.delay_TC     = 0.020;
P.delay_CSTN   = 0.015;
P.delay_GPeSTN = 0.012;
P.delay_STNGPe = 0.010;
P.delay_STNGPi = 0.015;
P.delay_GPiTH  = 0.020;

% Motor-command step
P.cmdAmplitude = 1.0;
P.cmdStepTime  = 0.5;         % s

% Stimulation: effective suppressive input to the STN
P.TH_ref  = 0.45;             % closed-loop thalamic reference
P.Kp      = 0.80;
P.Ki      = 0.15;             % 1/s
P.Kd      = 0.00;
P.DBS_max = 0.60;             % saturation of the closed-loop command
P.DBS_effect_gain = 1.0;      % STN suppression per unit command
P.DBS_mode = 1;               % 0 = fixed (open-loop) command, 1 = PI feedback
P.DBS_open_effective = 0.12;  % fixed open-loop command

% Disturbances (DBS model only)
P.noiseAmpC   = 0.03;         % standard deviation, cortical input
P.noiseAmpSTN = 0.04;         % standard deviation, STN input
P.noiseSampleTime = 0.002;    % s, zero-order hold of each noise sample
P.seedC   = 101;              % seed of the cortical noise sequence
P.seedSTN = 202;              % seed of the STN noise sequence

% Observation of the thalamic output by the controller (DBS model only):
% y(t) = TH(t - sensorDelay) + sensorBias + sensorNoise * n_y(t)
P.sensorDelay = 0;            % s
P.sensorBias  = 0;            % a.u.
P.sensorNoise = 0;            % standard deviation, a.u.
P.seedSens    = 303;          % seed of the observation-noise sequence

P = apply_dopamine(P, P.D);
end
