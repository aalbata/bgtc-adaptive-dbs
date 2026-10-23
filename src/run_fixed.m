function [M, S] = run_fixed(P, u, T)
%RUN_FIXED Open-loop run at a constant command.
%   [M, S] = RUN_FIXED(P, U, T) simulates the DBS model for T seconds with
%   the constant command U (from t = 0) and the remaining parameters of P,
%   and returns the outcome measures M over [0, T] and the signals S.

P.DBS_mode = 0;
P.DBS_open_effective = u;
P.StopTime = T;
S = simulate(P, 'dbs');
M = signal_metrics(S, P, T);
end
