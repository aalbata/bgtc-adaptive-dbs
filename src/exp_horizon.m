function exp_horizon(resDir)
%EXP_HORIZON Runs at five dopamine levels over 15, 60 and 120 s (E4).
%   At D = 0.15, 0.20, 0.35, 0.50 and 0.60, runs no DBS, open loop at
%   u_OL = 0.12 and closed loop for 120 s and evaluates them over the
%   horizons T = 15, 60 and 120 s. For each D and T it then runs the four
%   constant commands matched to the closed loop over [0, T]
%   (MATCHED_COMMANDS and, for equal Je(T), PERF_MATCH_GRID bracketed by
%   the fixed-command map of EXP_COMMAND_MAP, which must run first).
%   Writes horizon_metrics.csv and horizon_traces.csv (0.05-s grid of the
%   120-s runs) to RESDIR.

Ds = [0.15 0.20 0.35 0.50 0.60];
Ts = [15 60 120];
base = {'no_dbs', 'open_loop', 'closed_loop'};
matched = {'late_command', 'mean_command', 'effort', 'performance'};
C = readtable(fullfile(resDir, 'command_map.csv'));
mf = metric_fields();
rows = cell(numel(Ds)*numel(Ts)*(numel(base) + numel(matched)), 4 + numel(mf)); r = 0;
tg = (0:2400)' * 0.05;
tr = tg; hdr = {'t'};
for i = 1:numel(Ds)
    P0 = set_scenario('open_loop', Ds(i));
    for b = 1:numel(base)
        P = set_scenario(base{b}, Ds(i)); P.StopTime = 120;
        S = simulate(P, 'dbs');
        uFix = P.DBS_open_effective * (P.DBS_mode == 0);
        if strcmp(base{b}, 'closed_loop'), uFix = NaN; Scl = S; Pcl = P; end
        for k = 1:numel(Ts)
            [~, v] = metric_fields(signal_metrics(S, P, Ts(k)));
            r = r + 1;
            rows(r, :) = [{Ds(i), Ts(k), base{b}, uFix}, num2cell(v)];
        end
        tr = [tr, on_grid(S.t, S.TH, tg), on_grid(S.t, S.u, tg, 'previous')]; %#ok<AGROW>
        tag = sprintf('%s_D%03d', base{b}, round(100*Ds(i)));
        hdr = [hdr, {['TH_' tag], ['u_' tag]}]; %#ok<AGROW>
    end
    for k = 1:numel(Ts)
        Mcl = signal_metrics(Scl, Pcl, Ts(k));
        [uMatch, mNames] = matched_commands(Mcl);
        x = C(abs(C.D - Ds(i)) < 1e-9 & C.T == Ts(k), :);
        for m = 1:numel(matched)
            if strcmp(matched{m}, 'performance')
                uFix = perf_match_grid(P0, Mcl.Je, Ts(k), x.u, x.Je);
            else
                uFix = uMatch(strcmp(mNames, matched{m}));
            end
            [~, v] = metric_fields(run_fixed(P0, uFix, Ts(k)));
            r = r + 1;
            rows(r, :) = [{Ds(i), Ts(k), matched{m}, uFix}, num2cell(v)];
        end
    end
    fprintf('  horizon: D = %.2f\n', Ds(i));
end
write_csv(fullfile(resDir, 'horizon_metrics.csv'), [{'D', 'T', 'condition', 'u_fixed'}, mf], rows);
write_csv(fullfile(resDir, 'horizon_traces.csv'), hdr, tr);
end
