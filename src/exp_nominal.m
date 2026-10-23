function exp_nominal(resDir)
%EXP_NOMINAL Nominal 15-s comparison at D = 0.35 with matched open loops (E2).
%   Runs no DBS, open-loop DBS (u_OL = 0.12) and closed-loop DBS with the
%   nominal noise seeds, then open-loop DBS at four constant commands
%   matched to the closed loop over the same 15 s:
%     late_command   the closed-loop late-window mean command u_late
%     mean_command   equal cumulative command, int_0^T u dt
%     effort         equal stimulation use Ju(T) = int_0^T u^2 dt
%     performance    equal full-horizon error Je(T) = int_0^T (TH - TH_ref)^2 dt
%                    (smallest such command, PERF_MATCH_GRID on 0:0.05:0.60)
%   Writes nominal_metrics.csv and nominal_traces.csv (5-ms grid) to RESDIR.

T = 15;
conds = {'no_dbs', 'open_loop', 'closed_loop', 'late_command', 'mean_command', ...
    'effort', 'performance'};
tg = (0:round(T/0.005))' * 0.005;
mf = metric_fields();
rows = cell(numel(conds), 2 + numel(mf)); tr = tg;
P0 = set_scenario('open_loop');
P0.StopTime = T;
for k = 1:numel(conds)
    switch conds{k}
        case {'no_dbs', 'open_loop', 'closed_loop'}
            P = set_scenario(conds{k}); P.StopTime = T;
            S = simulate(P, 'dbs');
            M = signal_metrics(S, P, T);
            uFix = P.DBS_open_effective * (P.DBS_mode == 0);
            if strcmp(conds{k}, 'closed_loop')
                uFix = NaN;
                [uMatch, mNames] = matched_commands(M);
                JeCL = M.Je;
            end
        case {'late_command', 'mean_command', 'effort'}
            uFix = uMatch(strcmp(mNames, conds{k}));
            [M, S] = run_fixed(P0, uFix, T);
        case 'performance'
            uFix = perf_match_grid(P0, JeCL, T, 0:0.05:0.60);
            [M, S] = run_fixed(P0, uFix, T);
    end
    [~, v] = metric_fields(M);
    rows(k, :) = [{conds{k}, uFix}, num2cell(v)];
    tr = [tr, on_grid(S.t, S.C, tg), on_grid(S.t, S.STN, tg), on_grid(S.t, S.GPi, tg), ...
        on_grid(S.t, S.TH, tg), on_grid(S.t, S.u, tg, 'previous')]; %#ok<AGROW>
    fprintf('  nominal: %s\n', conds{k});
end
write_csv(fullfile(resDir, 'nominal_metrics.csv'), [{'condition', 'u_fixed'}, mf], rows);
hdr = {'t'};
for k = 1:numel(conds)
    hdr = [hdr, strcat({'C_', 'STN_', 'GPi_', 'TH_', 'u_'}, conds{k})]; %#ok<AGROW>
end
write_csv(fullfile(resDir, 'nominal_traces.csv'), hdr, tr);
end
