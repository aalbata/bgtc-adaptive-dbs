function exp_numerics(resDir)
%EXP_NUMERICS Sensitivity of the outcome measures to the solver settings.
%   Repeats seven runs (15 s at D = 0.35: no DBS, open loop at u_OL = 0.12,
%   closed loop; 120 s: open loop at u_OL = 0.12 at D = 0.35 and closed
%   loop at D = 0.15, 0.35 and 0.60) with the relative tolerance 1e-3 or
%   1e-6 and the maximum step 1 ms or 0.25 ms. Writes numerics.csv to
%   RESDIR.

settings = [1e-3 1e-3; 1e-6 1e-3; 1e-3 2.5e-4; 1e-6 2.5e-4];
runs = {'no_dbs', 0.35, 15; 'open_loop', 0.35, 15; 'closed_loop', 0.35, 15; ...
    'open_loop', 0.35, 120; 'closed_loop', 0.15, 120; 'closed_loop', 0.35, 120; ...
    'closed_loop', 0.60, 120};
mf = metric_fields();
rows = cell(0, 6 + numel(mf));
for s = 1:size(settings, 1)
    for k = 1:size(runs, 1)
        P = set_scenario(runs{k, 1}, runs{k, 2});
        P.RelTol = settings(s, 1); P.MaxStep = settings(s, 2); P.StopTime = runs{k, 3};
        S = simulate(P, 'dbs');
        [~, v] = metric_fields(signal_metrics(S, P, runs{k, 3}));
        rows(end+1, :) = [{settings(s, 1), settings(s, 2), runs{k, 1}, runs{k, 2}, runs{k, 3}, ...
            numel(S.t)}, num2cell(v)]; %#ok<AGROW>
    end
    fprintf('  numerics: setting %d of %d\n', s, size(settings, 1));
end
write_csv(fullfile(resDir, 'numerics.csv'), [{'RelTol', 'MaxStep', 'condition', 'D', 'T', 'n_samples'}, mf], rows);
end
