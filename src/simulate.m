function S = simulate(P, model)
%SIMULATE Run one simulation and return the recorded signals.
%   S = SIMULATE(P, MODEL) assigns P in the base workspace, sets the solver
%   tolerance P.RelTol and maximum step P.MaxStep, simulates MODEL
%   ('baseline' or 'dbs') and returns a structure with the time vector t
%   (one entry per integration step) and the population outputs C, D1, D2,
%   GPe, STN, GPi and TH. For the DBS model it also returns the stimulation
%   command u. The simulation state at the stop time is returned in S.xFinal
%   when the model is set to save it.

switch model
    case 'baseline', name = P.modelBaseline;
    case 'dbs',      name = P.modelDBS;
    otherwise, error('Unknown model: %s', model);
end
assignin('base', 'P', P);
set_param(name, 'RelTol', num2str(P.RelTol, 17), 'MaxStep', num2str(P.MaxStep, 17));
% A zero observation delay makes the sensor delay block a direct
% feedthrough; the thalamic output is a state, so no algebraic loop forms.
w = warning('off', 'Simulink:blocks:TDelayDirectThroughAutoSet');
restore = onCleanup(@() warning(w));
out = sim(name);
TH = out.get('TH');
S.t = TH.time(:);
vars = {'C', 'D1', 'D2', 'GPe', 'STN', 'GPi', 'TH'};
if strcmp(model, 'dbs'), vars{end+1} = 'DBS'; end
for k = 1:numel(vars)
    x = out.get(vars{k});
    S.(vars{k}) = x.signals.values(:);
end
if strcmp(model, 'dbs'), S.u = S.DBS; S = rmfield(S, 'DBS'); end
if any(strcmp(out.who, 'xFinal')), S.xFinal = out.get('xFinal'); end
end
