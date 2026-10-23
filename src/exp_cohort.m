function exp_cohort(resDir, subjects, partDir)
%EXP_COHORT Virtual cohort of 200 subjects (E8).
%   EXP_COHORT(RESDIR) draws the 200-subject Latin hypercube design of
%   COHORT_DESIGN with seed P.randomSeed and, for every subject,
%     1. calibration: CALIBRATE_SUBJECT with 30-s open-loop runs at the
%        commands 0, 0.1, ..., 0.6 at the subject's dopamine level D and at
%        D_low = max(0, D - dD), giving the individually optimized commands
%        u*(D), u*(D_low), the best constant for the state-change schedule
%        and the best constant after the change (CALIBRATE_SUBJECT);
%     2. stationary protocol: 120-s runs at D with no DBS, open loop at
%        u_OL = 0.12, open loop at the command tuned to nominal parameters
%        (closed-loop u_late at D = 0.35 over 120 s in horizon_metrics.csv),
%        open loop at u*(D), and closed loop;
%     3. state-change protocol: 270-s runs with D for 0-90 s, D_low for
%        90-180 s and D for 180-270 s (SIMULATE_SCHEDULE), with no DBS, open
%        loop at u*(D), at u*(D_low), at the best constant for the schedule
%        and at the best constant after the change, and closed loop.
%   Calibration uses the calibration noise seeds and the protocols use the
%   evaluation seeds of SUBJECT_PARAMS. Writes cohort_subjects.csv,
%   cohort_stationary.csv and cohort_change.csv to RESDIR.
%
%   EXP_COHORT(RESDIR, SUBJECTS, PARTDIR) processes only the listed subjects
%   and writes the three files with the suffix _<first>_<last> to PARTDIR;
%   MERGE_COHORT joins such parts into the files of the full run.

N = 200;
if nargin < 2 || isempty(subjects), subjects = 1:N; end
if nargin < 3, partDir = ''; end
P0 = bgtc_params();
[X, pnames] = cohort_design(N, P0.randomSeed);
H = readtable(fullfile(resDir, 'horizon_metrics.csv'), 'TextType', 'char');
uTuned = H.u_late(abs(H.D - 0.35) < 1e-9 & H.T == 120 & strcmp(H.condition, 'closed_loop'));
mf = metric_fields();
statConds = {'no_dbs', 'open_loop', 'open_loop_tuned', 'open_loop_individual', 'closed_loop'};
chConds = {'no_dbs', 'open_loop_individual', 'open_loop_individual_low', 'open_loop_best', ...
    'open_loop_best_after', 'closed_loop'};
Tseg = 90;
subRows = cell(numel(subjects), 1 + numel(pnames) + 12);
statRows = cell(numel(subjects)*numel(statConds), 3 + numel(mf));
chRows = cell(numel(subjects)*numel(chConds)*3, 14);
rs = 0; rc = 0;
for n = 1:numel(subjects)
    i = subjects(n);
    x = X(i, :);
    D = x(1); Dlow = max(0, x(1) - x(20));
    Cal = calibrate_subject(x, i, [D Dlow], (0:6) / 10, 30);
    subRows(n, :) = [{i}, num2cell(x), {Dlow, Cal.u_star(1), Cal.u_star(2), Cal.u_best, Cal.u_best_after, ...
        Cal.h0(1), Cal.h0(2), Cal.hmax(1), Cal.hmax(2), Cal.attainable(1), Cal.attainable(2), Cal.n_runs}];
    % stationary protocol
    uStat = [0, P0.DBS_open_effective, uTuned, Cal.u_star(1), NaN];
    for c = 1:numel(statConds)
        P = stat_params(statConds{c}, x, D, i, uStat(c));
        P.StopTime = 120;
        [~, v] = metric_fields(signal_metrics(simulate(P, 'dbs'), P, 120));
        rs = rs + 1;
        statRows(rs, :) = [{i, statConds{c}, uStat(c)}, num2cell(v)];
    end
    % state-change protocol
    uCh = [0, Cal.u_star(1), Cal.u_star(2), Cal.u_best, Cal.u_best_after, NaN];
    Dseq = [D Dlow D];
    for c = 1:numel(chConds)
        Ps = cell(1, 3);
        for s = 1:3
            Ps{s} = stat_params(chConds{c}, x, Dseq(s), i, uCh(c));
        end
        S = simulate_schedule(Ps, Tseg);
        for s = 1:3
            R = segment_metrics(S, Ps{s}, (s-1)*Tseg, s*Tseg);
            rc = rc + 1;
            chRows(rc, :) = {i, chConds{c}, uCh(c), s, Dseq(s), R.TH_last10, R.u_last10, ...
                R.Ju_segment, R.Je_segment, R.t_settle, R.TH_smooth_max, R.TH_smooth_min, ...
                R.time_off, max(S.u(S.t >= (s-1)*Tseg & S.t <= s*Tseg))};
        end
    end
    fprintf('  cohort: subject %d (%d of %d)\n', i, n, numel(subjects));
end
subHdr = [{'subject'}, pnames, {'D_low', 'u_star', 'u_star_low', 'u_best', 'u_best_after', 'h0', 'h0_low', ...
    'hmax', 'hmax_low', 'attainable', 'attainable_low', 'n_cal_runs'}];
statHdr = [{'subject', 'condition', 'u_fixed'}, mf];
chHdr = {'subject', 'condition', 'u_fixed', 'segment', 'D', 'TH_last10', 'u_last10', ...
    'Ju_segment', 'Je_segment', 't_settle', 'TH_smooth_max', 'TH_smooth_min', 'time_off', 'u_max_seg'};
if isempty(partDir)
    outDir = resDir; sfx = '';
else
    outDir = partDir; sfx = sprintf('_%03d_%03d', subjects(1), subjects(end));
    if ~exist(outDir, 'dir'), mkdir(outDir); end
end
write_csv(fullfile(outDir, ['cohort_subjects' sfx '.csv']), subHdr, subRows);
write_csv(fullfile(outDir, ['cohort_stationary' sfx '.csv']), statHdr, statRows);
write_csv(fullfile(outDir, ['cohort_change' sfx '.csv']), chHdr, chRows);
end

function P = stat_params(cond, x, D, i, u)
switch cond
    case 'no_dbs'
        P = set_scenario('no_dbs', D);
    case 'closed_loop'
        P = set_scenario('closed_loop', D);
    otherwise
        P = set_scenario('open_loop', D);
        P.DBS_open_effective = u;
end
P = subject_params(P, x, D, i);
end
