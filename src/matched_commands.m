function [u, names] = matched_commands(M)
%MATCHED_COMMANDS Constant commands matched to a closed-loop run.
%   [U, NAMES] = MATCHED_COMMANDS(M) returns, for the outcome measures M of
%   a closed-loop run over [0, T] (SIGNAL_METRICS), the constant commands
%     late_command   u_late, the time-weighted mean command of the late window
%     mean_command   U1 / T, equal cumulative command int_0^T u dt
%     effort         sqrt(Ju / T), equal stimulation use Ju(T) = int_0^T u^2 dt
%   in that order. The performance-matched command, equal full-horizon
%   error Je(T), needs simulations and is found by PERF_MATCH.

names = {'late_command', 'mean_command', 'effort'};
u = [M.u_late, M.U1 / M.T, sqrt(M.Ju / M.T)];
end
