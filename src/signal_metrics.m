function M = signal_metrics(S, P, T)
%SIGNAL_METRICS Outcome measures of one simulation over the horizon [0, T].
%   M = SIGNAL_METRICS(S, P, T) computes, from the signals returned by
%   SIMULATE, the measures below over [0, T] (default: the whole run). The
%   late window is [t_w, T] with t_w = (1 - P.steadyFraction) T. Window
%   means are time averages, X_late = (1/(T - t_w)) int_{t_w}^{T} X(t) dt,
%   evaluated with WIN_INT, so they do not depend on the solver's sampling.
%     TH_mean, GPi_mean   time-weighted late means
%     TH_RMSE             sqrt of the time-weighted late mean of (TH - TH_ref)^2
%     u_late              time-weighted late mean of the command
%     *_s                 the same four measures as unweighted means of the
%                         recorded samples j0..Nt, j0 = max(1, round(0.8 Nt))
%     *_g                 the same four measures as means over a uniform
%                         1-kHz grid of the late window (linear interpolation)
%     Je, Je_start, Je_late   int (TH - TH_ref)^2 dt over [0, T], [0, t_w],
%                             [t_w, T]
%     Ju, Ju_start, Ju_late   int u^2 dt over the same intervals
%     U1                  int u dt over [0, T] (cumulative command)
%     u_end               command at T
%     u_sd_late           time-weighted standard deviation of u in the late window
%     sat_late            fraction of the late window with u at P.DBS_max
%     t_settle            settling time of the 1-s moving mean of TH (SETTLING)
%     TH_smooth_max       largest 1-s moving mean of TH at t >= 5 s
%     Ju_settle           int u^2 dt over [0, t_settle] (NaN if never settled)
%     TH_peak             largest recorded TH in [0, T]
%     TH_beta, GPi_beta   13-30 Hz power of the post-transient Welch PSD on [3 s, T]
%     on_target           |TH_mean - TH_ref| < P.onTargetTol

t = S.t(:);
if nargin < 3 || isempty(T), T = t(end); end
tw = (1 - P.steadyFraction) * T;
L = T - tw;
ref = P.TH_ref;
hasU = isfield(S, 'u');
if hasU, u = S.u(:); else, u = zeros(size(t)); end

M.T = T;
M.t_window = tw;

% time-weighted window measures
M.TH_mean  = win_int(t, S.TH, tw, T) / L;
M.GPi_mean = win_int(t, S.GPi, tw, T) / L;
M.TH_RMSE  = sqrt(win_int(t, (S.TH - ref).^2, tw, T) / L);
M.u_late   = win_int(t, u, tw, T) / L;

% unweighted means of the recorded samples j0..Nt, j0 = max(1, round(0.8 Nt))
keep = t <= T + 1e-12;
n = sum(keep);
j0 = max(1, round((1 - P.steadyFraction) * n));
idx = j0:n;
M.TH_mean_s  = mean(S.TH(idx));
M.GPi_mean_s = mean(S.GPi(idx));
M.TH_RMSE_s  = sqrt(mean((S.TH(idx) - ref).^2));
M.u_late_s   = mean(u(idx));

% means over a uniform 1-kHz grid of the late window
tg = tw + (0:round(L / 1e-3))' * 1e-3;
tg = tg(tg <= T + 1e-12);
M.TH_mean_g  = mean(on_grid(t, S.TH, tg));
M.GPi_mean_g = mean(on_grid(t, S.GPi, tg));
M.TH_RMSE_g  = sqrt(mean((on_grid(t, S.TH, tg) - ref).^2));
M.u_late_g   = mean(on_grid(t, u, tg));

% full-horizon error and stimulation use, split at the late window
e2 = (S.TH - ref).^2;
M.Je_start = win_int(t, e2, 0, tw);
M.Je_late  = win_int(t, e2, tw, T);
M.Je       = M.Je_start + M.Je_late;
M.Ju_start = win_int(t, u.^2, 0, tw);
M.Ju_late  = win_int(t, u.^2, tw, T);
M.Ju       = M.Ju_start + M.Ju_late;
M.U1       = win_int(t, u, 0, T);
M.u_end    = on_grid(t, u, T);
M.u_sd_late = sqrt(max(0, win_int(t, (u - M.u_late).^2, tw, T) / L));
M.sat_late = win_int(t, double(u >= P.DBS_max - 1e-9), tw, T) / L;

% settling, smoothed peak, stimulation used until settling
[M.t_settle, M.TH_smooth_max] = settling(t, S.TH, ref, P.onTargetTol, 0, T, 5);
if isnan(M.t_settle), M.Ju_settle = NaN;
else, M.Ju_settle = win_int(t, u.^2, 0, max(M.t_settle, 0)); end

M.TH_peak = max(S.TH(keep));
[~, th, fs] = psd_signal(t, S.TH, P, T);
[~, gpi]    = psd_signal(t, S.GPi, P, T);
M.TH_beta  = beta_power(th, fs, P.betaBand);
M.GPi_beta = beta_power(gpi, fs, P.betaBand);
M.on_target = double(abs(M.TH_mean - ref) < P.onTargetTol);
end
