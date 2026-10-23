function exp_command_map(resDir)
%EXP_COMMAND_MAP Fixed-command map across dopamine levels (E5).
%   Runs 120-s open-loop simulations with constant commands u = 0, 0.01,
%   ..., 0.60 at D = 0.05, 0.15, 0.20, 0.35, 0.50 and 0.60 with the nominal
%   noise seeds, and evaluates the outcome measures over the horizons
%   T = 15, 60 and 120 s (the first T seconds of each run). Because the
%   command is constant and the noise sequences restart from the same
%   seeds, these prefixes equal runs of length T. Writes command_map.csv to
%   RESDIR.

Ds = [0.05 0.15 0.20 0.35 0.50 0.60];
us = (0:60)' / 100;
Ts = [15 60 120];
mf = metric_fields();
rows = zeros(numel(Ds)*numel(us)*numel(Ts), 3 + numel(mf)); r = 0;
for i = 1:numel(Ds)
    P = set_scenario('open_loop', Ds(i));
    for j = 1:numel(us)
        [~, S] = run_fixed(P, us(j), 120);
        for k = 1:numel(Ts)
            [~, v] = metric_fields(signal_metrics(S, P, Ts(k)));
            r = r + 1;
            rows(r, :) = [Ds(i), us(j), Ts(k), v];
        end
    end
    fprintf('  command map: D = %.2f\n', Ds(i));
end
write_csv(fullfile(resDir, 'command_map.csv'), [{'D', 'u', 'T'}, mf], rows);
end
