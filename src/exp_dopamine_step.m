function exp_dopamine_step(resDir)
%EXP_DOPAMINE_STEP Dopamine changes within a run (E6).
%   Dopamine is held at 0.50 for 0-90 s, 0.20 for 90-180 s and 0.50 again
%   for 180-270 s (SIMULATE_SCHEDULE). Seven conditions: no DBS; open loop at
%   u_OL = 0.12; open loop at the command to which the closed loop settles
%   at D = 0.50 and at D = 0.20 in the 120-s runs (horizon_metrics.csv);
%   open loop at the best constant for the schedule, the command that
%   minimizes (2/3)(h_0.50(u) - TH_ref)^2 + (1/3)(h_0.20(u) - TH_ref)^2 with
%   h_D the 120-s late means of the fixed-command map (command_map.csv);
%   open loop at the best constant after the change, which minimizes the
%   same error with the weights 1/2 and 1/2 of the 90-270-s window; and
%   closed loop. Segment measures follow SEGMENT_METRICS. Writes
%   dopamine_step_metrics.csv and dopamine_step_traces.csv to RESDIR. The
%   traces hold TH and the command on a 0.05-s grid and the accumulated
%   tracking error J_e(t), integrated by the trapezoidal rule over the
%   solver steps and sampled on the same grid.

Dseq = [0.50 0.20 0.50];
Tseg = 90;
H = readtable(fullfile(resDir, 'horizon_metrics.csv'), 'TextType', 'char');
C = readtable(fullfile(resDir, 'command_map.csv'));
uSettled = @(D) H.u_late(abs(H.D - D) < 1e-9 & H.T == 120 & strcmp(H.condition, 'closed_loop'));
P0 = bgtc_params();
m1 = C(abs(C.D - 0.50) < 1e-9 & C.T == 120, :);
m2 = C(abs(C.D - 0.20) < 1e-9 & C.T == 120, :);
uBest = best_constant(m1.u, [m1.TH_mean, m2.TH_mean], [2/3 1/3], P0.TH_ref, P0.DBS_max);
uBestAfter = best_constant(m1.u, [m1.TH_mean, m2.TH_mean], [1/2 1/2], P0.TH_ref, P0.DBS_max);
conds = {'no_dbs', 'open_loop', 'open_loop_tuned', 'open_loop_tuned_low', ...
    'open_loop_best', 'open_loop_best_after', 'closed_loop'};
uFixed = [0, P0.DBS_open_effective, uSettled(0.50), uSettled(0.20), uBest, uBestAfter, NaN];
tg = (0:round(Tseg*numel(Dseq)/0.05))' * 0.05;
rows = cell(numel(conds)*numel(Dseq), 13); tr = tg; hdr = {'t'}; r = 0;
for c = 1:numel(conds)
    Ps = cell(1, numel(Dseq));
    for s = 1:numel(Dseq)
        switch conds{c}
            case {'no_dbs', 'closed_loop'}
                P = set_scenario(conds{c}, Dseq(s));
            otherwise
                P = set_scenario('open_loop', Dseq(s));
                P.DBS_open_effective = uFixed(c);
        end
        Ps{s} = P;
    end
    S = simulate_schedule(Ps, Tseg);
    for s = 1:numel(Dseq)
        R = segment_metrics(S, Ps{s}, (s-1)*Tseg, s*Tseg);
        r = r + 1;
        rows(r, :) = {conds{c}, uFixed(c), s, Dseq(s), R.TH_last10, R.u_last10, R.TH_RMSE_last10, ...
            R.Ju_segment, R.Je_segment, R.t_settle, R.TH_smooth_max, R.TH_smooth_min, R.time_off};
    end
    [tu, iu] = unique(S.t, 'last');
    e2 = (S.TH(iu) - P0.TH_ref).^2;
    Je = [0; cumsum(0.5 * diff(tu) .* (e2(1:end-1) + e2(2:end)))];
    tr = [tr, on_grid(S.t, S.TH, tg), on_grid(S.t, S.u, tg, 'previous'), interp1(tu, Je, tg)]; %#ok<AGROW>
    hdr = [hdr, {['TH_' conds{c}], ['u_' conds{c}], ['Je_' conds{c}]}]; %#ok<AGROW>
    fprintf('  dopamine step: %s\n', conds{c});
end
write_csv(fullfile(resDir, 'dopamine_step_metrics.csv'), ...
    {'condition', 'u_fixed', 'segment', 'D', 'TH_last10', 'u_last10', 'TH_RMSE_last10', ...
    'Ju_segment', 'Je_segment', 't_settle', 'TH_smooth_max', 'TH_smooth_min', 'time_off'}, rows);
write_csv(fullfile(resDir, 'dopamine_step_traces.csv'), hdr, tr);
end
