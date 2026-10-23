function exp_noise_seeds(resDir, K)
%EXP_NOISE_SEEDS Nominal comparison repeated with independent noise sequences (E3).
%   For K seed pairs (default 20), seeds 1000+k (cortex) and 2000+k (STN),
%   runs the seven conditions of EXP_NOMINAL at D = 0.35 for 15 s; the
%   matched open-loop commands are computed from the closed loop of the
%   same seed pair. Writes noise_seeds.csv to RESDIR.

if nargin < 2, K = 20; end
T = 15;
conds = {'no_dbs', 'open_loop', 'closed_loop', 'late_command', 'mean_command', ...
    'effort', 'performance'};
mf = metric_fields();
rows = cell(numel(conds)*K, 5 + numel(mf)); r = 0;
for k = 1:K
    P0 = set_scenario('open_loop');
    P0.seedC = 1000 + k; P0.seedSTN = 2000 + k; P0.StopTime = T;
    for c = 1:numel(conds)
        switch conds{c}
            case {'no_dbs', 'open_loop', 'closed_loop'}
                P = set_scenario(conds{c});
                P.seedC = P0.seedC; P.seedSTN = P0.seedSTN; P.StopTime = T;
                M = signal_metrics(simulate(P, 'dbs'), P, T);
                uFix = P.DBS_open_effective * (P.DBS_mode == 0);
                if strcmp(conds{c}, 'closed_loop')
                    uFix = NaN;
                    [uMatch, mNames] = matched_commands(M);
                    JeCL = M.Je;
                end
            case {'late_command', 'mean_command', 'effort'}
                uFix = uMatch(strcmp(mNames, conds{c}));
                M = run_fixed(P0, uFix, T);
            case 'performance'
                uFix = perf_match_grid(P0, JeCL, T, 0:0.05:0.60);
                M = run_fixed(P0, uFix, T);
        end
        [~, v] = metric_fields(M);
        r = r + 1;
        rows(r, :) = [{k, P0.seedC, P0.seedSTN, conds{c}, uFix}, num2cell(v)];
    end
    fprintf('  noise seeds: pair %d of %d\n', k, K);
end
write_csv(fullfile(resDir, 'noise_seeds.csv'), ...
    [{'pair', 'seedC', 'seedSTN', 'condition', 'u_fixed'}, mf], rows);
end
