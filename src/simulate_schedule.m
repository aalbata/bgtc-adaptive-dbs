function S = simulate_schedule(Ps, Tseg)
%SIMULATE_SCHEDULE Run consecutive segments that continue from the saved state.
%   S = SIMULATE_SCHEDULE(PS, TSEG) simulates the DBS model through the
%   segments [0, TSEG], [TSEG, 2 TSEG], ..., using the parameter structure
%   PS{s} in segment s. Each segment starts from the complete simulation
%   state at the end of the previous one (populations, delay buffers,
%   controller integrator and noise generators), so only the parameters
%   that differ between the PS{s} change at the segment boundaries. Returns
%   the concatenated time, TH, GPi and command u, with the duplicated
%   boundary sample removed.

mdl = Ps{1}.modelDBS;
set_param(mdl, 'SaveFinalState', 'on', 'FinalStateName', 'xFinal', 'SaveOperatingPoint', 'on');
restore = onCleanup(@() set_param(mdl, 'LoadInitialState', 'off', 'SaveFinalState', 'off', ...
    'SaveOperatingPoint', 'off'));
S = struct('t', [], 'TH', [], 'GPi', [], 'u', []);
for s = 1:numel(Ps)
    P = Ps{s};
    P.StopTime = s * Tseg;
    if s == 1
        set_param(mdl, 'LoadInitialState', 'off');
    else
        set_param(mdl, 'LoadInitialState', 'on', 'InitialState', 'xOP');
    end
    X = simulate(P, 'dbs');
    assignin('base', 'xOP', X.xFinal);
    k = 1:numel(X.t);
    if s > 1, k = k(2:end); end
    S.t = [S.t; X.t(k)]; S.TH = [S.TH; X.TH(k)]; S.GPi = [S.GPi; X.GPi(k)]; S.u = [S.u; X.u(k)];
end
end
