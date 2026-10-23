function P = subject_params(P, x, D, i, calibration)
%SUBJECT_PARAMS Apply the parameters of one virtual subject.
%   P = SUBJECT_PARAMS(P, X, D, I) sets dopamine D (with the gains that
%   depend on it), then applies the row X of COHORT_DESIGN: the gain
%   multiplier g on the GPe-STN, STN-GPe and STN-GPi gains, the noise
%   multiplier a_n, the time-constant and delay multipliers, the
%   stimulation gain G_DBS and the observation delay and noise. P must hold
%   the nominal values of these parameters (SET_SCENARIO). Subject I uses
%   the noise seeds 5000+I, 6000+I and 7000+I (cortex, STN, observation).
%   SUBJECT_PARAMS(..., true) uses the calibration seeds 15000+I, 16000+I
%   and 17000+I instead.

if nargin < 5, calibration = false; end
P = apply_dopamine(P, D);
P.w_GPeSTN = P.w_GPeSTN * x(2);
P.w_STNGPe = P.w_STNGPe * x(2);
P.w_STNGPi = P.w_STNGPi * x(2);
P.noiseAmpC = P.noiseAmpC * x(3);
P.noiseAmpSTN = P.noiseAmpSTN * x(3);
taus = {'tauC', 'tauD1', 'tauD2', 'tauGPe', 'tauSTN', 'tauGPi', 'tauTH'};
for k = 1:7, P.(taus{k}) = P.(taus{k}) * x(3 + k); end
delays = {'delay_TC', 'delay_CSTN', 'delay_GPeSTN', 'delay_STNGPe', 'delay_STNGPi', 'delay_GPiTH'};
for k = 1:6, P.(delays{k}) = P.(delays{k}) * x(10 + k); end
P.DBS_effect_gain = x(17);
P.sensorDelay = x(18);
P.sensorNoise = x(19);
off = 0;
if calibration, off = 10000; end
P.seedC = 5000 + off + i; P.seedSTN = 6000 + off + i; P.seedSens = 7000 + off + i;
end
