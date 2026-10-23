function exp_baseline(resDir)
%EXP_BASELINE Healthy (D = 1) and moderate-PD (D = 0.35) baselines (E1).
%   Writes baseline_metrics.csv and baseline_traces.csv (5-ms grid) to
%   RESDIR. The baseline model has no noise and no stimulation.

names = {'healthy', 'moderate_pd'};
tg = (0:3000)' * 0.005;
rows = cell(2, 8); tr = tg;
for k = 1:2
    P = set_scenario(names{k});
    S = simulate(P, 'baseline');
    M = signal_metrics(S, P);
    C_mean = win_int(S.t, S.C, M.t_window, M.T) / (M.T - M.t_window);
    rows(k, :) = {names{k}, P.D, M.TH_mean, M.GPi_mean, C_mean, ...
        M.TH_peak, M.TH_beta, M.GPi_beta};
    tr = [tr, on_grid(S.t, S.C, tg), on_grid(S.t, S.GPi, tg), on_grid(S.t, S.TH, tg)]; %#ok<AGROW>
end
write_csv(fullfile(resDir, 'baseline_metrics.csv'), ...
    {'condition', 'D', 'TH_mean', 'GPi_mean', 'C_mean', 'TH_peak', 'TH_beta', 'GPi_beta'}, rows);
write_csv(fullfile(resDir, 'baseline_traces.csv'), ...
    {'t', 'C_healthy', 'GPi_healthy', 'TH_healthy', 'C_pd', 'GPi_pd', 'TH_pd'}, tr);
end
